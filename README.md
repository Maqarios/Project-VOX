# Speech-to-Text Artillery Command Processor

## Configuration

### Custom Commands (settings.json)

You can customize command patterns by editing `settings.json`. Each command has:
- **intent** (required): The name of the command action
- **pattern** (optional): Regex pattern to match voice commands

If you don't provide a pattern, it will be auto-generated from the intent name.

**Example:**
```json
{
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
