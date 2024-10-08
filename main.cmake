# Copyright (c) 2021 pongasoft
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

cmake_minimum_required(VERSION 3.28)

set(re-cmake_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

# MUST be called before project!!!
macro(re_cmake_before_project_init)
  include("${re-cmake_ROOT_DIR}/cmake/RECMakeOptions.cmake")
endmacro()

# Must be called right after project
macro(re_cmake_init)

  cmake_parse_arguments(
      "ARG" # prefix
      "" # options
      "" # single values
      "INCLUDES" # multiple values
      ${ARGN}
  )

  include("${re-cmake_ROOT_DIR}/sdk.cmake")

  if(ARG_INCLUDES)
    re_cmake_include(${ARG_INCLUDES})
  endif()

endmacro()

# Use to include other frameworks
macro(re_cmake_include)

  set(re_cmake_include_options re-logging re-mock)

  cmake_parse_arguments(
      "ARG" # prefix
      "${re_cmake_include_options}" # options
      "" # single values
      "" # multiple values
      ${ARGN}
  )

  if(ARG_re-logging)
    include("${re-cmake_ROOT_DIR}/cmake/RECMakeFetchContent.cmake")
    re_cmake_fetch_content(NAME re-logging)
    include("${re-logging_ROOT_DIR}/re-logging.cmake")
  endif()

  if(ARG_re-mock)
    include("${re-cmake_ROOT_DIR}/cmake/RECMakeFetchContent.cmake")
    re_cmake_fetch_content(NAME re-mock)
    # re-mock is a library to link with
    set(re-mock_LIBRARY_NAME "re-mock")
  endif()

endmacro()
