# Copyright (c) 2020-2021 pongasoft
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#
# @author Yan Pujante

set(RE_CMAKE_MAJOR_VERSION 1)
set(RE_CMAKE_MINOR_VERSION 6)
set(RE_CMAKE_PATCH_VERSION 1)

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

if(WIN32)
  # We are enabling Clang toolchain by default because the compiler that comes with the SDK is Clang
  # To install the Clang toolchain use the Visual Studio Installer tool, then select the proper
  # build tools (at this time 2019 or 2022), then make sure to select the Optional component:
  # "C++ Clang Tools for Windows"
  # If not installed properly you will get this error: "No CMAKE_CXX_COMPILER could be found." in which
  # case you can either set this variable to OFF in your CMakeLists.txt or install it.
  option(RE_CMAKE_ENABLE_CLANG_TOOLCHAIN "Enable Clang toolchain" ON)
  if(RE_CMAKE_ENABLE_CLANG_TOOLCHAIN)
    message(STATUS "Enabling Clang toolchain for Windows.")
    set(CMAKE_GENERATOR_TOOLSET "ClangCL")
  endif()
endif()

#------------------------------------------------------------------------
# Option to enable/disable testing (includes GoogleTest)
# Simply set to OFF if you want to use your own testing methodology
# You can also write your own RECMakeAddTest.cmake module instead.
#------------------------------------------------------------------------
option(RE_CMAKE_ENABLE_TESTING "Enable Testing (GoogleTest)" ON)

#------------------------------------------------------------------------
# The git respository to fetch googletest from
#------------------------------------------------------------------------
set(googletest_GIT_REPO "https://github.com/google/googletest" CACHE STRING "googletest git repository URL")

#------------------------------------------------------------------------
# The git tag for googletest
#------------------------------------------------------------------------
set(googletest_GIT_TAG "v1.13.0" CACHE STRING "googletest git tag")

#------------------------------------------------------------------------
# The download URL for googletest
#------------------------------------------------------------------------
set(googletest_DOWNLOAD_URL "${googletest_GIT_REPO}/archive/refs/tags/${googletest_GIT_TAG}.zip" CACHE STRING "googletest download url" FORCE)

#------------------------------------------------------------------------
# The download URL hash for googletest
#------------------------------------------------------------------------
set(googletest_DOWNLOAD_URL_HASH "SHA256=ffa17fbc5953900994e2deec164bb8949879ea09b411e07f215bfbb1f87f4632" CACHE STRING "googletest download url hash" FORCE)

#------------------------------------------------------------------------
# Option for invoking RE2DRender for hi res build
# Set to 'hi-res-only' by default. If the device does not fully support
# hi-res (no HD custom display background), set this option to 'hi-res'
#------------------------------------------------------------------------
set(RE_CMAKE_RE_2D_RENDER_HI_RES_OPTION "hi-res-only" CACHE STRING "Option for invoking RE2DRender for hi res build (hi-res or hi-res-only)")

#------------------------------------------------------------------------
# Git repo/tag for re-logging
#------------------------------------------------------------------------
set(re-logging_GIT_REPO "https://github.com/pongasoft/re-logging" CACHE STRING "re-logging git repository url")
set(re-logging_GIT_TAG "v1.0.1" CACHE STRING "re-logging git tag")
set(re-logging_DOWNLOAD_URL "${re-logging_GIT_REPO}/archive/refs/tags/${re-logging_GIT_TAG}.zip" CACHE STRING "re-logging download url" FORCE)
set(re-logging_DOWNLOAD_URL_HASH "SHA256=e71898bfb4234505e5714a726139ad21ac0bd17d63f41af80d7cc9b5760dd57f" CACHE STRING "re-logging download url hash" FORCE)

#------------------------------------------------------------------------
# Git repo/tag for re-mock
#------------------------------------------------------------------------
set(re-mock_GIT_REPO "https://github.com/pongasoft/re-mock" CACHE STRING "re-mock git repository url")
set(re-mock_GIT_TAG "v1.4.2" CACHE STRING "re-mock git tag")
set(re-mock_DOWNLOAD_URL "${re-mock_GIT_REPO}/archive/refs/tags/${re-mock_GIT_TAG}.zip" CACHE STRING "re-mock download url" FORCE)
set(re-mock_DOWNLOAD_URL_HASH "SHA256=f19e41cde101334e5c99adebba17d23eed08aa3039120d6c0794402f3ee491b8" CACHE STRING "re-mock download url hash" FORCE)
