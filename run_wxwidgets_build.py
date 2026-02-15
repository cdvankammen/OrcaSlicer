import subprocess
import sys
import os

os.chdir(r'J:\github orca\OrcaSlicer')

print("=" * 70)
print("Building wxWidgets")
print("=" * 70)
print()

try:
    result = subprocess.run(
        [r'J:\github orca\OrcaSlicer\build_wxwidgets.bat'],
        shell=True,
        capture_output=False,
        text=True,
        cwd=r'J:\github orca\OrcaSlicer'
    )

    print()
    print("=" * 70)
    if result.returncode == 0:
        print("wxWidgets BUILD SUCCESSFUL!")
        print("=" * 70)
    else:
        print(f"wxWidgets BUILD FAILED with exit code {result.returncode}")
        print("=" * 70)
        sys.exit(result.returncode)

except Exception as e:
    print(f"\nERROR: {e}")
    sys.exit(1)
