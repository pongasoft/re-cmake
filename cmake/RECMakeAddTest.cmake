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

#------------------------------------------------------------------------
# This module add testing (via Google Test)
# Must define re_cmake_add_test()
#------------------------------------------------------------------------
# Download and unpack googletest at configure time
include(RECMakeFetchGoogleTest)
include(GoogleTest)

#------------------------------------------------------------------------
# re_cmake_add_test - Testing
#------------------------------------------------------------------------
function(re_cmake_add_test)
  message(STATUS "Adding target native-test for test cases: ${ARG_TEST_CASE_SOURCES}")
  set(target "native-build-test")
  add_executable("${target}" "${ARG_TEST_CASE_SOURCES}" "${ARG_TEST_SOURCES}")
  target_link_libraries("${target}" gtest_main "${ARG_TEST_LINK_LIBS}")
  target_include_directories("${target}" PUBLIC "${PROJECT_SOURCE_DIR}" "${ARG_TEST_INCLUDE_DIRECTORIES}")
  set_target_properties(${target} PROPERTIES EXCLUDE_FROM_ALL TRUE)

  # Extra compile definitions?
  if(ARG_TEST_COMPILE_DEFINITIONS)
    target_compile_definitions("${target}" PUBLIC "${ARG_TEST_COMPILE_DEFINITIONS}")
  endif()

  # Extra compile options?
  if(ARG_TEST_COMPILE_OPTIONS)
    target_compile_options("${target}" PUBLIC "${ARG_TEST_COMPILE_OPTIONS}")
  endif()

  gtest_discover_tests("${target}")

  #------------------------------------------------------------------------
  # native-run-test target | run the tests
  #------------------------------------------------------------------------
  add_custom_target("native-run-test"
      COMMAND ${CMAKE_COMMAND} -E echo "Running tests using $<TARGET_FILE:${target}>"
      COMMAND "${CMAKE_CTEST_COMMAND}" -C $<CONFIG>
      DEPENDS "${target}"
      )
endfunction()

