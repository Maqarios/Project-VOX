# Speech-to-Text Artillery Command Processor

## Configuration

### Custom Commands (settings.json)

You can customize the application by editing `settings.json`:

#### General Settings
- **wake_word**: The wake word to activate voice recognition (default: "hey_jarvis")
  - Available options: "hey_jarvis", "alexa", "hey_mycroft", "hey_rhasspy", etc.
- **stt_model**: The speech-to-text model to use (default: "small.en")
  - Available options: "tiny.en", "base.en", "small.en", "medium.en", "large-v2", etc.
  - Larger models are more accurate but slower
- **output_directory**: Directory path where the command JSON file will be saved (default: current directory)
  - Example: `"C:\\Users\\YourName\\Documents\\My Games\\ArmaReforger\\profile"`
  - Leave empty (`""`) to save in the current directory
  - Supports environment variables like `%USERPROFILE%` or `~`

#### Command Patterns
Each command has:
- **intent** (required): The name of the command action
- **pattern** (optional): Regex pattern to match voice commands

If you don't provide a pattern, it will be auto-generated from the intent name.

**Example:**
```json
{
  "wake_word": "hey_jarvis",
  "stt_model": "small.en",
  "output_directory": "C:\\Users\\YourName\\Documents\\My Games\\ArmaReforger\\profile",
  "commands": [
    {
      "intent": "call_large_mortar_barrage",
      "pattern": "\\blarge\\s+(?:mortar\\s+)?barrage\\b"
    },
    {
      "intent": "call_danger_close_strike"
    }
  ]
}
```

The second command will automatically match phrases like "danger close strike" based on its intent name.
