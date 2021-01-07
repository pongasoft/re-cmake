# Location of RE SDK: can be set when invoking cmake => cmake -D "RE_SDK_ROOT:PATH=/path/to/re_sdk"
# or via -p option in configure.py script or in cmake-gui
if(APPLE)
  set(RE_SDK_ROOT "/Users/Shared/ReasonStudios/JukeboxSDK_${RE_SDK_VERSION}/SDK" CACHE PATH "Location of RE SDK")
else()
  set(RE_SDK_ROOT "C:/Users/Public/Documents/ReasonStudios/JukeboxSDK_${RE_SDK_VERSION}/SDK" CACHE PATH "Location of RE SDK")
endif()

# Location of RE2DRender (can be set similarly to RE_SDK_ROOT)
set(RE_2D_RENDER_ROOT "${RE_SDK_ROOT}/../RE2DRender" CACHE PATH "Location of RE2DRender")

# At this time, the latest version of the SDK (4.2.0) does not support the new Apple chipset
# => we force a compilation in x86_64 to ensure that Recon can load the plugin in local native builds.
# If a later version of the SDK supports native build the following code will be updated accordingly
if(APPLE)
  set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "")
endif()
