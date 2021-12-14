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
set(RE_CMAKE_MINOR_VERSION 4)
set(RE_CMAKE_PATCH_VERSION 0)

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
# release-1.11.0 => e2239ee6043f73722e7aa812a459f54a28552929
#------------------------------------------------------------------------
set(googletest_GIT_TAG "e2239ee6043f73722e7aa812a459f54a28552929" CACHE STRING "googletest git tag")

#------------------------------------------------------------------------
# Option for invoking RE2DRender for hi res build
# Set to 'hi-res-only' by default. If the device does not fully support
# hi-res (no HD custom display background), set this option to 'hi-res'
#------------------------------------------------------------------------
set(RE_CMAKE_RE_2D_RENDER_HI_RES_OPTION "hi-res-only" CACHE STRING "Option for invoking RE2DRender for hi res build (hi-res or hi-res-only)")

#------------------------------------------------------------------------
# Git repo/tag for re-mock
#------------------------------------------------------------------------
set(re-mock_GIT_REPO "https://github.com/pongasoft/re-mock" CACHE STRING "re-mock git repository url")
set(re-mock_GIT_TAG "v1.0.0" CACHE STRING "re-cmake git tag")
