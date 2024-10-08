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
set(RE_CMAKE_MINOR_VERSION 7)
set(RE_CMAKE_PATCH_VERSION 3)

# Location of RE SDK: can be set when invoking cmake => cmake -D "RE_SDK_ROOT:PATH=/path/to/re_sdk"
# or via -p option in configure.py script or in cmake-gui
if(APPLE)
  set(RE_SDK_ROOT "/Users/Shared/ReasonStudios/JukeboxSDK_${RE_SDK_VERSION}/SDK" CACHE PATH "Location of RE SDK")
else()
  set(RE_SDK_ROOT "C:/Users/Public/Documents/ReasonStudios/JukeboxSDK_${RE_SDK_VERSION}/SDK" CACHE PATH "Location of RE SDK")
endif()

# Location of RE2DRender (can be set similarly to RE_SDK_ROOT)
set(RE_2D_RENDER_ROOT "${RE_SDK_ROOT}/../RE2DRender" CACHE PATH "Location of RE2DRender")

# Since 4.4.0, build in native arm64. Otherwise we force x86_64
if(APPLE)
  # on macOS "uname -m" returns the architecture (x86_64 or arm64)
  execute_process(
      COMMAND uname -m
      RESULT_VARIABLE result
      OUTPUT_VARIABLE RE_CMAKE_OSX_NATIVE_ARCHITECTURE
      OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if("${RE_SDK_VERSION}" VERSION_LESS "4.4.0")
    set(RE_CMAKE_APPLE_ARM64_BUIlD OFF)
    if("${RE_CMAKE_OSX_NATIVE_ARCHITECTURE}" STREQUAL "arm64")
      set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "")
      message(STATUS "macOS forcing x86_64 build on arm64 (upgrade to SDK 4.4.0 for arm64 build)")
    else()
      message(STATUS "macOS native ${RE_CMAKE_OSX_NATIVE_ARCHITECTURE} build")
    endif()
  else()
    if("${RE_CMAKE_OSX_NATIVE_ARCHITECTURE}" STREQUAL "arm64")
      set(RE_CMAKE_APPLE_ARM64_BUIlD ON)
    else()
      set(RE_CMAKE_APPLE_ARM64_BUIlD OFF)
    endif()
    message(STATUS "macOS native ${RE_CMAKE_OSX_NATIVE_ARCHITECTURE} build")
  endif()
elseif(WIN32)
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
# re_cmake_test_and_set_git_tag (issue warning if differs)
#------------------------------------------------------------------------
macro(re_cmake_test_and_set_git_tag name tag)
  set("${name}_GIT_TAG" "${tag}" CACHE STRING "${name} git tag")
  if(NOT "${${name}_GIT_TAG}" STREQUAL "${tag}")
    message(STATUS "[INFO] This project uses a different (potentially older) version of ${name} (${tag} != ${${name}_GIT_TAG})")
  endif()
endmacro()

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
re_cmake_test_and_set_git_tag(googletest "v1.13.0")

#------------------------------------------------------------------------
# The download URL for googletest
#------------------------------------------------------------------------
set(googletest_DOWNLOAD_URL "${googletest_GIT_REPO}/archive/refs/tags/${googletest_GIT_TAG}.zip" CACHE STRING "googletest download url")

#------------------------------------------------------------------------
# The download URL hash for googletest
#------------------------------------------------------------------------
set(googletest_DOWNLOAD_URL_HASH "SHA256=ffa17fbc5953900994e2deec164bb8949879ea09b411e07f215bfbb1f87f4632" CACHE STRING "googletest download url hash")

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
re_cmake_test_and_set_git_tag(re-logging "v1.0.2")
set(re-logging_DOWNLOAD_URL "${re-logging_GIT_REPO}/archive/refs/tags/${re-logging_GIT_TAG}.zip" CACHE STRING "re-logging download url")
set(re-logging_DOWNLOAD_URL_HASH "SHA256=e09c3796c06583d6d55b8c28539121f69716140f5e7f05df661c4875b807bc80" CACHE STRING "re-logging download url hash")

#------------------------------------------------------------------------
# Git repo/tag for re-mock
#------------------------------------------------------------------------
set(re-mock_GIT_REPO "https://github.com/pongasoft/re-mock" CACHE STRING "re-mock git repository url")
re_cmake_test_and_set_git_tag(re-mock "v1.7.0")
set(re-mock_DOWNLOAD_URL "${re-mock_GIT_REPO}/archive/refs/tags/${re-mock_GIT_TAG}.zip" CACHE STRING "re-mock download url")
set(re-mock_DOWNLOAD_URL_HASH "SHA256=39a5503c07b05ce482179e63a60a5a2c32a4be9083d809090d7a7f8c6a093a02" CACHE STRING "re-mock download url hash")
