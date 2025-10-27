"""
Speech-to-Text Artillery Command Processor
Listens for artillery call commands and extracts grid coordinates.
"""

import os
import warnings

# Suppress warnings from dependencies
warnings.filterwarnings("ignore", category=DeprecationWarning, module="pkg_resources")
warnings.filterwarnings("ignore", message="pkg_resources is deprecated")
os.environ["CT2_VERBOSE"] = "0"
warnings.filterwarnings("ignore", message=".*compute type.*")

import json
import logging
import re
from pathlib import Path
from typing import Optional

from RealtimeSTT import AudioToTextRecorder


# ====== Configuration ======
class Config:
    """Application configuration"""

    WAKE_WORD = "hey_jarvis"
    STT_MODEL = "medium.en"
    OUTPUT_FILE = "arma_command.json"

    # Keypad layout for grid precision upgrade
    # 1 2 3
    # 4 5 6
    # 7 8 9
    # Normalized offsets (0.0 to 1.0) within the current grid square
    KEYPAD_OFFSETS = {
        1: (0.1666, 0.8333),  # top-left (inverted Y for north-up)
        2: (0.5000, 0.8333),  # top-center
        3: (0.8333, 0.8333),  # top-right
        4: (0.1666, 0.5000),  # middle-left
        5: (0.5000, 0.5000),  # center
        6: (0.8333, 0.5000),  # middle-right
        7: (0.1666, 0.1666),  # bottom-left
        8: (0.5000, 0.1666),  # bottom-center
        9: (0.8333, 0.1666),  # bottom-right
    }

    # MGRS precision levels (digits per axis)
    # 2x2 = 4 digits total (1km precision)
    # 3x3 = 6 digits total (100m precision)
    # 4x4 = 8 digits total (10m precision)
    # 5x5 = 10 digits total (1m precision)


# ====== Logging Setup ======
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


# ====== Artillery Command Processor ======
class ArtilleryCommandProcessor:
    """Processes artillery call commands and extracts grid coordinates"""

    # Map of spoken numbers to digits
    WORD_TO_DIGIT = {
        "zero": "0",
        "oh": "0",
        "o": "0",
        "one": "1",
        "won": "1",
        "two": "2",
        "to": "2",
        "too": "2",
        "three": "3",
        "tree": "3",
        "four": "4",
        "for": "4",
        "five": "5",
        "fife": "5",
        "six": "6",
        "sicks": "6",
        "seven": "7",
        "eight": "8",
        "ate": "8",
        "nine": "9",
        "niner": "9",
    }

    def process(self, text: str) -> dict:
        """
        Process artillery command and extract grid coordinates

        Args:
            text: Voice command text

        Returns:
            Dictionary with raw_voice, intent, x, and y coordinates
        """
        text = text.strip()

        # Convert spoken numbers to digits
        normalized_text = self._convert_words_to_digits(text)

        # Extract grid coordinates
        coords = self._extract_and_convert_grid(normalized_text)

        if coords is None:
            return {
                "raw_voice": text,
                "intent": "call_artillery",
                "x": None,
                "y": None,
            }

        return {
            "raw_voice": text,
            "intent": "call_artillery",
            "x": coords["x"],
            "y": coords["y"],
        }

    def _convert_words_to_digits(self, text: str) -> str:
        """
        Convert spoken number words to digits

        Args:
            text: Original text with potential number words

        Returns:
            Text with number words replaced by digits
        """
        result = text.lower()

        # Replace number words with digits
        for word, digit in self.WORD_TO_DIGIT.items():
            # Use word boundaries to avoid partial matches
            result = re.sub(r"\b" + word + r"\b", digit, result, flags=re.IGNORECASE)

        logger.info(f"✓ Converted words to digits: '{text}' -> '{result}'")
        return result

    def _extract_and_convert_grid(self, text: str) -> Optional[dict]:
        """
        Extract MGRS grid coordinates and convert to meter precision format

        Output format: 5 digits + 1 decimal place (e.g., 12345.0)

        Examples:
        - 2-digit "12 45" + keypad 3 -> 12833.3, 45833.3
        - 2-digit "12 45" (no keypad) -> 12500.0, 45500.0 (defaults to center)
        - 3-digit "123 456" + keypad 8 -> 12350.0, 45616.6
        - 4-digit "1234 5678" (no keypad) -> 12345.0, 56785.0
        - 2-digit "12 45" + keypad 5 -> 12500.0, 45500.0

        Args:
            text: Command text

        Returns:
            Dict with x and y coordinates in meter format with 1 decimal, or None if not found
        """
        # Normalize comma-separated digits
        comma_pattern = r"(?:grid|Grid)\s+(.+?)(?:keypad|$)"
        comma_match = re.search(comma_pattern, text, re.IGNORECASE)

        if comma_match:
            grid_text = comma_match.group(1).strip()
            digits = re.findall(r"\b(\d)\b", grid_text)
            if len(digits) >= 4:
                digit_string = "".join(digits[:10])  # Take up to 10 digits
                # Replace in text for further processing
                text = text.replace(grid_text, digit_string)
                logger.info(f"✓ Normalized comma-separated digits: {digit_string}")

        # Find coordinate patterns (2x2, 3x3, 4x4, or 5x5)
        coord_patterns = [
            (r"\b(\d{5})\s*(\d{5})\b", 5),  # 5x5 (10 digits)
            (r"\b(\d{4})\s*(\d{4})\b", 4),  # 4x4 (8 digits)
            (r"\b(\d{3})\s*(\d{3})\b", 3),  # 3x3 (6 digits)
            (r"\b(\d{2})\s*(\d{2})\b", 2),  # 2x2 (4 digits)
        ]

        easting = None
        northing = None
        precision = 0

        for pattern, prec in coord_patterns:
            match = re.search(pattern, text)
            if match:
                easting = match.group(1)
                northing = match.group(2)
                precision = prec
                break

        if not easting or not northing:
            logger.warning("No grid coordinates found in command")
            return None

        # Check for keypad modifier
        keypad_match = re.search(r"\bkeypad\s+(\d)\b", text.lower())

        # Convert to meter precision format
        x_coord, y_coord = self._normalize_to_5digit_format(
            easting, northing, precision, keypad_match
        )

        # Log the conversion
        if keypad_match:
            keypad = int(keypad_match.group(1))
            precision_map = {2: "1km", 3: "100m", 4: "10m", 5: "1m"}
            prec_str = precision_map.get(precision, "unknown")
            logger.info(
                f"✓ {precision}x{precision} ({prec_str}) + keypad {keypad} -> x={x_coord}, y={y_coord}"
            )
        else:
            precision_map = {2: "1km", 3: "100m", 4: "10m", 5: "1m"}
            prec_str = precision_map.get(precision, "unknown")
            logger.info(
                f"✓ {precision}x{precision} ({prec_str}) + keypad 5 (center) -> x={x_coord}, y={y_coord}"
            )

        return {"x": x_coord, "y": y_coord}

    def _normalize_to_5digit_format(
        self, easting: str, northing: str, precision: int, keypad_match
    ) -> tuple:
        """
        Convert MGRS coordinates to meter precision format (5 digits + 1 decimal)

        Logic:
        - Convert input digits to base meter value (e.g., "12" -> 12000m)
        - Determine grid square size based on precision
        - Apply keypad offset within the grid square
        - Format as 5 digits + 1 decimal place

        Grid square sizes:
        - 2-digit: 1000m × 1000m
        - 3-digit: 100m × 100m
        - 4-digit: 10m × 10m
        - 5-digit: 1m × 1m

        Formula: final_coordinate = base_value + (keypad_offset × grid_square_size)

        Args:
            easting: Easting coordinate string (2-5 digits)
            northing: Northing coordinate string (2-5 digits)
            precision: Number of digits per coordinate (2-5)
            keypad_match: Regex match object for keypad number, or None

        Returns:
            Tuple of (x_coord, y_coord) as strings in format "XXXXX.X"
        """
        # Default to keypad 5 (center) if no keypad specified
        if keypad_match:
            keypad = int(keypad_match.group(1))
            if keypad not in Config.KEYPAD_OFFSETS:
                logger.error(
                    f"Invalid keypad number: {keypad} (must be 1-9), using center"
                )
                keypad = 5
        else:
            keypad = 5
            logger.info(f"  → No keypad specified, defaulting to keypad 5 (center)")

        # Get keypad offsets (normalized 0.0-1.0)
        offset_e, offset_n = Config.KEYPAD_OFFSETS[keypad]

        # Determine grid square size based on precision
        grid_square_sizes = {
            2: 1000,  # 1km
            3: 100,  # 100m
            4: 10,  # 10m
            5: 1,  # 1m
        }

        grid_size = grid_square_sizes.get(precision, 1)

        # Convert input to base meter value
        # Pad to 5 digits by adding zeros on the right
        easting_padded = easting.ljust(5, "0")
        northing_padded = northing.ljust(5, "0")

        # Parse as integer meter values
        base_e = int(easting_padded)
        base_n = int(northing_padded)

        # Apply keypad offset
        # offset is 0.0-1.0, multiply by grid size to get meters
        offset_meters_e = offset_e * grid_size
        offset_meters_n = offset_n * grid_size

        # Calculate final coordinates
        final_e = base_e + offset_meters_e
        final_n = base_n + offset_meters_n

        # Format as string with 1 decimal place
        x_coord = f"{final_e:.1f}"
        y_coord = f"{final_n:.1f}"

        if keypad_match:
            logger.info(f"  → Keypad {keypad} positioning: {x_coord}, {y_coord}")
        else:
            logger.info(f"  → Centered (keypad 5): {x_coord}, {y_coord}")

        return x_coord, y_coord


# ====== Output Handler ======
class OutputHandler:
    """Handles command output to JSON file"""

    def __init__(self, output_file: str):
        self.output_path = Path(output_file)

    def save_command(self, command: dict) -> None:
        """Save command to JSON file"""
        try:
            with open(self.output_path, "w", encoding="utf-8") as f:
                json.dump(command, f, indent=2, ensure_ascii=False)
            logger.info(f"✓ Command saved to {self.output_path}")
        except Exception as e:
            logger.error(f"Failed to save command: {e}")


# ====== Main Application ======
def main():
    """Main application entry point"""
    try:
        logger.info("Initializing Artillery Command Processor...")

        processor = ArtilleryCommandProcessor()
        output_handler = OutputHandler(Config.OUTPUT_FILE)

        logger.info("Starting audio recorder...")
        recorder = AudioToTextRecorder(
            model=Config.STT_MODEL,
            wake_words=Config.WAKE_WORD,
            wakeword_backend="openwakeword",
            language="en",
            compute_type="int8",
        )

        logger.info(
            f"🎧 Listening for wake word '{Config.WAKE_WORD.replace('_', ' ')}'..."
        )
        logger.info("Say 'call artillery at grid [coordinates]' after the wake word.")
        logger.info("Supported MGRS formats (all output as 5x5 + 1 decimal):")
        logger.info("  Without keypad (defaults to center/keypad 5):")
        logger.info("    - 2x2: 'grid 12 34' -> x=12555.5, y=34555.5")
        logger.info("    - 3x3: 'grid 123 456' -> x=12355.5, y=45655.5")
        logger.info("    - 4x4: 'grid 1234 5678' -> x=12345.5, y=56785.5")
        logger.info("    - 5x5: 'grid 12345 67890' -> x=12345.5, y=67890.5")
        logger.info("  With keypad (positions within grid):")
        logger.info(
            "    - 2x2 + keypad 3: 'grid 12 34 keypad 3' -> x=12833.3, y=34833.3"
        )
        logger.info(
            "    - 3x3 + keypad 7: 'grid 123 456 keypad 7' -> x=12316.6, y=45616.6"
        )
        logger.info(
            "    - 4x4 + keypad 9: 'grid 1234 5678 keypad 9' -> x=12348.3, y=56788.1"
        )
        logger.info(
            "    - 5x5 + keypad 1: 'grid 12345 67890 keypad 1' -> x=12341.6, y=67890.8"
        )
        logger.info("Press Ctrl+C to exit.\n")

        # Main processing loop
        while True:
            text = recorder.text()

            if not text:
                continue

            logger.info(f"🗣️  Detected: '{text}'")

            # Process command
            command = processor.process(text)

            # Check if grid was extracted
            if command["x"] is None or command["y"] is None:
                logger.error("❌ Failed to extract valid grid coordinates")
                continue

            # Save and display results
            output_handler.save_command(command)

            logger.info(f"📋 Intent: {command['intent']}")
            logger.info(f"📍 Coordinates: x={command['x']}, y={command['y']}")
            print()  # Empty line for readability

    except KeyboardInterrupt:
        logger.info("\n👋 Shutting down gracefully...")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        raise


if __name__ == "__main__":
    main()
