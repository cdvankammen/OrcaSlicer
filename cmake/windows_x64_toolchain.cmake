# Windows x64 Toolchain File
# Forces CMake to use x64 architecture and correct library paths

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)

# Set Visual Studio paths
set(MSVC_ROOT "J:/visualstudio/vs studio/VC/Tools/MSVC/14.50.35717")
set(WIN_SDK_ROOT "C:/Program Files (x86)/Windows Kits/10")
set(WIN_SDK_VERSION "10.0.26100.0")

# Set compilers to x64 versions
set(CMAKE_C_COMPILER "${MSVC_ROOT}/bin/Hostx64/x64/cl.exe" CACHE FILEPATH "C compiler")
set(CMAKE_CXX_COMPILER "${MSVC_ROOT}/bin/Hostx64/x64/cl.exe" CACHE FILEPATH "C++ compiler")

# Set RC and MT tools to x64 versions
set(CMAKE_RC_COMPILER "${WIN_SDK_ROOT}/bin/${WIN_SDK_VERSION}/x64/rc.exe" CACHE FILEPATH "RC compiler")
set(CMAKE_MT "${WIN_SDK_ROOT}/bin/${WIN_SDK_VERSION}/x64/mt.exe" CACHE FILEPATH "Manifest tool")

# Force x64 library paths
set(CMAKE_LIBRARY_ARCHITECTURE "x64")

# Set library search paths explicitly to x64
set(CMAKE_SYSTEM_LIBRARY_PATH
    "${MSVC_ROOT}/lib/x64"
    "${WIN_SDK_ROOT}/Lib/${WIN_SDK_VERSION}/um/x64"
    "${WIN_SDK_ROOT}/Lib/${WIN_SDK_VERSION}/ucrt/x64"
    CACHE PATH "System library search path")

# Set include search paths
set(CMAKE_SYSTEM_INCLUDE_PATH
    "${MSVC_ROOT}/include"
    "${WIN_SDK_ROOT}/Include/${WIN_SDK_VERSION}/um"
    "${WIN_SDK_ROOT}/Include/${WIN_SDK_VERSION}/ucrt"
    "${WIN_SDK_ROOT}/Include/${WIN_SDK_VERSION}/shared"
    CACHE PATH "System include search path")

# Ensure we're building for x64
set(CMAKE_GENERATOR_PLATFORM "x64" CACHE STRING "Platform")

# Additional flags to ensure x64 linking
set(CMAKE_EXE_LINKER_FLAGS_INIT "/machine:x64")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "/machine:x64")
set(CMAKE_STATIC_LINKER_FLAGS_INIT "/machine:x64")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "/machine:x64")
