import getpass
import os
import shutil


def main():
    # Get the current Windows username dynamically
    username = getpass.getuser()
    cache_dir = rf"C:\Users\{username}\.cache\huggingface\hub"

    print(f"🧭 Whisper cache directory: {cache_dir}")

    if not os.path.exists(cache_dir):
        print("⚠️  Whisper cache directory not found.")
        return

    models = [
        d for d in os.listdir(cache_dir) if os.path.isdir(os.path.join(cache_dir, d))
    ]

    if not models:
        print("No Whisper models found in cache.")
        return

    print("\n📦 Found Whisper models:")
    for m in models:
        print(f"  - {m}")

    confirm = input("\nDelete ALL Whisper models? (y/N): ").strip().lower()
    if confirm != "y":
        print("❎ Operation cancelled.")
        return

    for m in models:
        path = os.path.join(cache_dir, m)
        print(f"🗑️  Deleting {path} ...")
        shutil.rmtree(path, ignore_errors=True)

    print("\n✅ All Whisper models deleted successfully.")


if __name__ == "__main__":
    main()
