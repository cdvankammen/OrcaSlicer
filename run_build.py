import subprocess
import sys
import os

# Change to the OrcaSlicer directory
os.chdir(r'J:\github orca\OrcaSlicer')

# Execute the batch file
print("Starting OrcaSlicer build...")
print("=" * 60)

try:
    result = subprocess.run(
        [r'J:\github orca\OrcaSlicer\build\temp_build.bat'],
        shell=True,
        capture_output=False,
        text=True,
        cwd=r'J:\github orca\OrcaSlicer'
    )

    if result.returncode == 0:
        print("\n" + "=" * 60)
        print("BUILD SUCCESSFUL!")
        print("=" * 60)
    else:
        print("\n" + "=" * 60)
        print(f"BUILD FAILED with exit code {result.returncode}")
        print("=" * 60)
        sys.exit(result.returncode)

except Exception as e:
    print(f"\nERROR: {e}")
    sys.exit(1)
