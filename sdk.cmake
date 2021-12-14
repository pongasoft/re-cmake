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

cmake_minimum_required(VERSION 3.17)

# Making sure we are on macOS and Win10
if(NOT (APPLE OR WIN32))
  message(FATAL_ERROR "Only macOS or Windows supported")
endif()

# Capturing this outside function call due to scope...
set(BUILD45_SRC_DIR ${CMAKE_CURRENT_LIST_DIR})

#------------------------------------------------------------------------
# Adding cmake folder to cmake path => allow for re-cmake cmake files
#------------------------------------------------------------------------
list(APPEND CMAKE_MODULE_PATH "${BUILD45_SRC_DIR}/cmake")

if(RE_CMAKE_ENABLE_TESTING)
  enable_testing()
endif()

##########################################################
# Main method called to add/create the RE plugin
##########################################################
function(add_re_plugin)

  #############################################
  # Argument parsing / default values
  #############################################
  set(options ENABLE_DEBUG_LOGGING)
  set(oneValueArgs RE_SDK_VERSION RE_SDK_ROOT RE_2D_RENDER_ROOT RE_2D_PREVIEW_ROOT INFO_LUA MOTHERBOARD_DEF_LUA REALTIME_CONTROLLER_LUA DISPLAY_LUA RESOURCES_DIR PYTHON3_EXECUTABLE RE_RECON_EXECUTABLE)
  set(multiValueArgs BUILD_SOURCES RENDER_2D_SOURCES INCLUDE_DIRECTORIES COMPILE_DEFINITIONS COMPILE_OPTIONS
                     JBOX_COMPILE_DEFINITIONS JBOX_COMPILE_OPTIONS
                     NATIVE_BUILD_SOURCES NATIVE_BUILD_LIBS NATIVE_COMPILE_DEFINITIONS NATIVE_COMPILE_OPTIONS NATIVE_LINK_OPTIONS
                     TEST_CASE_SOURCES TEST_SOURCES TEST_INCLUDE_DIRECTORIES TEST_COMPILE_DEFINITIONS TEST_COMPILE_OPTIONS TEST_LINK_LIBS)
  cmake_parse_arguments(
      "ARG" # prefix
      "${options}" # options
      "${oneValueArgs}" # single values
      "${multiValueArgs}" # multiple values
      ${ARGN}
  )

  # ARG_RE_SDK_VERSION is required
  if(NOT ARG_RE_SDK_VERSION)
    message(FATAL_ERROR "RE_SDK_VERSION is required")
  endif()

  # Check for version (primitive for now, but will be improved with new versions)
  if(ARG_RE_SDK_VERSION VERSION_LESS 4.1.0)
    message(FATAL_ERROR "This framework supports SDK 4.1.0+")
  endif()

  # Detecting support for hi res builds
  if(ARG_RE_SDK_VERSION VERSION_GREATER_EQUAL 4.3.0)
    set(RE_SDK_SUPPORT_HI_RES ON)
    message(STATUS "RE SDK supports Hi Res builds")
  endif()


  macro(set_default_value name default_value)
    if(NOT ${name})
      set(${name} ${default_value})
    endif()
  endmacro()

  # ARG_RE_SDK_ROOT : location of the sdk
  if(APPLE)
    set_default_value(ARG_RE_SDK_ROOT "/Users/Shared/ReasonStudios/JukeboxSDK_${ARG_RE_SDK_VERSION}/SDK")
  else()
    set_default_value(ARG_RE_SDK_ROOT "C:/Users/Public/Documents/ReasonStudios/JukeboxSDK_${ARG_RE_SDK_VERSION}/SDK")
  endif()

  # Checking for the existence of version.txt
  set(ARG_RE_SDK_VERSION_FILE "${ARG_RE_SDK_ROOT}/version.txt")
  if(EXISTS "${ARG_RE_SDK_VERSION_FILE}")
    file(STRINGS "${ARG_RE_SDK_VERSION_FILE}" RE_SDK_INFO)
    message(STATUS "Detected RE SDK: ${RE_SDK_INFO}")
  else()
    message(FATAL_ERROR "Could not locate RE SDK version file. Make sure that RE_SDK_ROOT=${ARG_RE_SDK_ROOT} points to the root of the SDK.")
  endif()

  set_default_value(ARG_INFO_LUA ${CMAKE_CURRENT_LIST_DIR}/info.lua)
  set_default_value(ARG_MOTHERBOARD_DEF_LUA ${CMAKE_CURRENT_LIST_DIR}/motherboard_def.lua)
  set_default_value(ARG_REALTIME_CONTROLLER_LUA ${CMAKE_CURRENT_LIST_DIR}/realtime_controller.lua)
  set_default_value(ARG_DISPLAY_LUA ${CMAKE_CURRENT_LIST_DIR}/display.lua)
  set_default_value(ARG_RESOURCES_DIR ${CMAKE_CURRENT_LIST_DIR}/Resources)

  # Determine lua exe
  if(APPLE)
    set(LUA_EXECUTABLE "${ARG_RE_SDK_ROOT}/Tools/Build/Lua/Mac/lua")
  else()
    set(LUA_EXECUTABLE "${ARG_RE_SDK_ROOT}/Tools/Build/Lua/Win/lua.exe")
  endif()

  # Determine RE2DRender executable
  set_default_value(ARG_RE_2D_RENDER_ROOT "${ARG_RE_SDK_ROOT}/../RE2DRender")

  find_program(
      RE_2D_RENDER_EXECUTABLE RE2DRender
      PATHS "${ARG_RE_2D_RENDER_ROOT}" "${ARG_RE_2D_RENDER_ROOT}/RE2DRender" "${ARG_RE_SDK_ROOT}/.."
      NO_DEFAULT_PATH
  )

  if(${RE_2D_RENDER_EXECUTABLE} STREQUAL "RE_2D_RENDER_EXECUTABLE-NOTFOUND")
    message(FATAL_ERROR "Could not find RE2DRender executable in its expected location. Make sure that RE2DRender is unzipped or provide RE_2D_RENDER_ROOT argument.")
  endif()

  # Determine RE2DPreview executable
  set_default_value(ARG_RE_2D_PREVIEW_ROOT "${ARG_RE_SDK_ROOT}/../RE2DPreview")

  find_program(
      RE_2D_PREVIEW_EXECUTABLE RE2DPreview
      PATHS "${ARG_RE_2D_PREVIEW_ROOT}" "${ARG_RE_2D_PREVIEW_ROOT}/RE2DPreview" "${ARG_RE_SDK_ROOT}/.."
      NO_DEFAULT_PATH
  )

  if(${RE_2D_PREVIEW_EXECUTABLE} STREQUAL "RE_2D_PREVIEW_EXECUTABLE-NOTFOUND")
    message(WARNING "Could not find RE2DPreview executable in its expected location. Make sure that RE2DPreview is unzipped or provide RE_2D_PREVIEW_ROOT argument.")
  endif()

  set(JBOX_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/jbox)

  #############################################
  # Extract product id from info.lua
  # RE_ID will contain the unique ID required by the SDK
  #############################################
  configure_file("${ARG_INFO_LUA}" "${CMAKE_BINARY_DIR}/info.lua" COPYONLY) # ensures cmake reruns if info.lua changes

  execute_process(
      COMMAND ${LUA_EXECUTABLE} -e "dofile('${CMAKE_BINARY_DIR}/info.lua'); print(product_id .. ';' .. version_number)"
      RESULT_VARIABLE result
      OUTPUT_VARIABLE RE_FULL_PRODUCT_ID
      OUTPUT_STRIP_TRAILING_WHITESPACE)

  list(POP_BACK RE_FULL_PRODUCT_ID RE_VERSION_NUMBER) # RE_VERSION_NUMBER contains the version
  string(REPLACE "." ";" RE_FULL_PRODUCT_ID_LIST "${RE_FULL_PRODUCT_ID}")
  list(POP_BACK RE_FULL_PRODUCT_ID_LIST RE_ID) # RE_ID contains the unique ID

  set(RE_FULL_PRODUCT_ID "${RE_FULL_PRODUCT_ID}" PARENT_SCOPE) # export
  set(RE_VERSION_NUMBER "${RE_VERSION_NUMBER}" PARENT_SCOPE) # export

  message(STATUS "product_id=${RE_FULL_PRODUCT_ID};version_number=${RE_VERSION_NUMBER}")

  # Add the target to create the (internal) RE SDK static library ("z-" prefix is so that it appears last in
  # the list because it is an internal target...)
  internal_add_re_sdk("z-re-sdk-lib")

  # Enabling log debugging if requested
  if(ARG_ENABLE_DEBUG_LOGGING)
    list(APPEND ARG_NATIVE_COMPILE_DEFINITIONS "DEBUG=1")
  endif()

  # Generate the re_cmake_build.h file
  set(GENERATED_FILES_DIR "${CMAKE_BINARY_DIR}/generated")
  file(TO_NATIVE_PATH "${CMAKE_CURRENT_LIST_DIR}" PROJECT_DIR_NATIVE_PATH)
  file(TO_NATIVE_PATH "${ARG_MOTHERBOARD_DEF_LUA}" MOTHERBOARD_DEF_LUA_NATIVE_PATH)
  file(TO_NATIVE_PATH "${ARG_REALTIME_CONTROLLER_LUA}" REALTIME_CONTROLLER_LUA_NATIVE_PATH)
  file(TO_NATIVE_PATH "${ARG_RE_SDK_ROOT}" RE_SDK_ROOT_NATIVE_PATH)
  configure_file("${BUILD45_SRC_DIR}/re_cmake_build.h.in" "${GENERATED_FILES_DIR}/re_cmake_build.h")
  list(APPEND ARG_INCLUDE_DIRECTORIES "${GENERATED_FILES_DIR}")

  # Create the native build targets
  internal_add_native_build()

  # Optionally setup testing
  if(RE_CMAKE_ENABLE_TESTING AND DEFINED ARG_TEST_CASE_SOURCES)
    include(RECMakeAddTest)
    internal_add_plugin_library("native-test-lib" "STATIC")
    set_target_properties("native-test-lib" PROPERTIES EXCLUDE_FROM_ALL TRUE)
    re_cmake_add_test()
  endif()

  # Determine python executable
  if(ARG_PYTHON3_EXECUTABLE)
    set(Python3_EXECUTABLE ${ARG_PYTHON3_EXECUTABLE})
  else()
    find_package(Python3 COMPONENTS Interpreter)

    if(${Python3_EXECUTABLE} STREQUAL "Python3_EXECUTABLE-NOTFOUND")
      set(Python3_EXECUTABLE "python")
      message(STATUS "python library not found => using \"${Python3_EXECUTABLE}\" as the executable (make sure it is in the PATH)")
    endif()
  endif()

  # Create the build45 build targets
  internal_add_jbox_build()

  # Add validation targets
  internal_add_validation()

  # Copy the convenient script wrapper(s)
  if(APPLE)
    configure_file(${BUILD45_SRC_DIR}/re.sh.in ${CMAKE_BINARY_DIR}/re.sh @ONLY)
  else()
    configure_file(${BUILD45_SRC_DIR}/re.bat.in ${CMAKE_BINARY_DIR}/re.bat @ONLY)
  endif()
  configure_file(${BUILD45_SRC_DIR}/re-cmake.py ${CMAKE_BINARY_DIR} COPYONLY)

  # Handling Multi-config generators
  get_cmake_property(MULTI_CONFIG GENERATOR_IS_MULTI_CONFIG)

  if(MULTI_CONFIG)
    set(ignoreMe ${CMAKE_BUILD_TYPE}) # remove warning
    message(STATUS "Detected Multi-config generator. You can use -R option for re.sh (resp. re.bat) for a Release build. No option will default to Debug build")
  endif()
endfunction()

##########################################################
# Internal function to create the re_sdk static lib to link to
##########################################################
function(internal_add_re_sdk target)
  if(APPLE)
    # For macOS we need to link with crtbegind.o and crtendd.o
    set(RE_SDK_LLC_CMD ${ARG_RE_SDK_ROOT}/Tools/LLVM/Mac/bin/llc -mtriple=x86_64-apple-darwin9.0.0 -march=x86-64 -mcpu=x86-64 -mattr=+sse3 -relocation-model=pic -static-init-in-data -dwarf-version=4 -asm-verbose -debugger-tune=lldb -O0 -filetype=obj)
    # SDK provides .obc files which needs to be natively compiled to .o
    macro(compile_obc OBC_INPUT_FILE OUTPUT_FILE)
      add_custom_command(OUTPUT "${OUTPUT_FILE}"
          COMMAND ${RE_SDK_LLC_CMD} ${OBC_INPUT_FILE} -o "${OUTPUT_FILE}"
          DEPENDS ${OBC_INPUT_FILE}
          )
    endmacro()

    # crtbegind.o.bc
    set(CRTBEGIND_O ${CMAKE_CURRENT_BINARY_DIR}/crtbegind.o)
    compile_obc(${ARG_RE_SDK_ROOT}/Tools/LLVM/Jukebox/libc/lib/phdsp64/crtbegind.o.bc ${CRTBEGIND_O})

    # crtendd.o.bc
    set(CRTENDD_O ${CMAKE_CURRENT_BINARY_DIR}/crtendd.o)
    compile_obc(${ARG_RE_SDK_ROOT}/Tools/LLVM/Jukebox/libc/lib/phdsp64/crtendd.o.bc ${CRTENDD_O})

    set(RE_COMPILE_OPTIONS "-femulated-tls")
    set(RE_LINK_OPTIONS
        "LINKER:-keep_private_externs"
        "LINKER:-exported_symbol,_JukeboxExport_InitializeDLL"
        "LINKER:-exported_symbol,_JukeboxExport_CreateNativeObject"
        "LINKER:-exported_symbol,_JukeboxExport_RenderRealtime"
        )
  else()
    # For Windows, we need to include WinDLLExports.txt
    # Impl note: the link option @${ARG_RE_SDK_ROOT}/Tools/Libs/RackExtensionWrapper/x64/WinDLLExports.txt does
    # not work when doing a Visual Studio build for some reason => reading the file myself
    file(STRINGS "${ARG_RE_SDK_ROOT}/Tools/Libs/RackExtensionWrapper/x64/WinDLLExports.txt" WIN_DLL_EXPORTS)
    set(RE_LINK_OPTIONS ${WIN_DLL_EXPORTS} "/NODEFAULTLIB:libcmt")
  endif()

  # locate RackExtWrapperLib
  find_library(
      SDK_WRAPPER_LIB
      RackExtWrapperLib
      PATHS "${ARG_RE_SDK_ROOT}/Tools/Libs/RackExtensionWrapper/Mac/Deployment"
            "${ARG_RE_SDK_ROOT}/Tools/Libs/RackExtensionWrapper/x64/Deployment"
      NO_DEFAULT_PATH
  )

  add_library(${target} STATIC ${ARG_RE_SDK_ROOT}/Tools/Libs/Jukebox/ShimABI/JukeboxABI.cpp ${CRTBEGIND_O} ${CRTENDD_O})
  target_include_directories(${target} PRIVATE ${ARG_RE_SDK_ROOT}/Tools/Libs/Jukebox/ShimABI) # internal API
  target_include_directories(${target} PUBLIC ${ARG_RE_SDK_ROOT}/API) # exporting SDK API to plugin
  target_compile_options(${target} PUBLIC ${RE_COMPILE_OPTIONS})
  target_link_libraries(${target} PUBLIC ${SDK_WRAPPER_LIB})
  target_link_options(${target} PUBLIC ${RE_LINK_OPTIONS} ${ARG_NATIVE_LINK_OPTIONS})

endfunction()

##########################################################
# Internal function to create the plugin library (shared for RE/static for tests)
##########################################################
function(internal_add_plugin_library target type)
  add_library(${target} ${type} ${ARG_BUILD_SOURCES} ${ARG_NATIVE_BUILD_SOURCES})
  target_link_libraries(${target} PUBLIC ${ARG_NATIVE_BUILD_LIBS})
  target_compile_definitions(${target} PUBLIC LOCAL_NATIVE_BUILD=1 ${ARG_COMPILE_DEFINITIONS} ${ARG_NATIVE_COMPILE_DEFINITIONS})
  target_compile_options(${target} PUBLIC ${ARG_COMPILE_OPTIONS} ${ARG_NATIVE_COMPILE_OPTIONS})
  target_include_directories(${target} PUBLIC "${ARG_INCLUDE_DIRECTORIES}" "${ARG_RE_SDK_ROOT}/API") # exporting SDK API to plugin
  set_target_properties(${target} PROPERTIES PREFIX "") # library name without lib
  if(APPLE)
    set_target_properties(${target} PROPERTIES OUTPUT_NAME ${RE_ID})
  else()
    set_target_properties(${target} PROPERTIES OUTPUT_NAME "${RE_ID}64")
  endif()
endfunction()

##########################################################
# Internal function to create native build targets
##########################################################
function(internal_add_native_build)
  #############################################
  # native-build target
  # Compilation / Creation of the plugin library
  #############################################
  set(target "native-build")
  internal_add_plugin_library("${target}" "SHARED")
  target_link_libraries(${target} PUBLIC z-re-sdk-lib)

  #############################################
  # common-render target (common-render-low-res / common-render-hi-res)
  # execute RE2DRender with the proper arguments
  #############################################
  set(RE_GUI2D_DIR ${JBOX_BUILD_DIR}/GUI2D) # using this folder in order not to duplicate files
  set(RE_GUI_DIR ${JBOX_BUILD_DIR}/GUI)

  # Render low res / 4.2.0 and less
  set(GUI_LOW_RES_ICON ${RE_GUI_DIR}/Output/DeviceIcon.png)
  add_custom_command(
      OUTPUT ${GUI_LOW_RES_ICON}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${RE_GUI2D_DIR}
      COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ARG_RENDER_2D_SOURCES} ${RE_GUI2D_DIR}
      COMMAND ${RE_2D_RENDER_EXECUTABLE} ${RE_GUI2D_DIR} ${RE_GUI_DIR}
      DEPENDS ${ARG_RENDER_2D_SOURCES}
  )
  add_custom_target(common-render-low-res DEPENDS ${GUI_LOW_RES_ICON})

  # Render hi res / 4.3.0+
  if(RE_SDK_SUPPORT_HI_RES)
    set(GUI_HI_RES_ICON ${RE_GUI_DIR}/Output/HD/DeviceIcon.png)
    add_custom_command(
        OUTPUT ${GUI_HI_RES_ICON}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${RE_GUI2D_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ARG_RENDER_2D_SOURCES} ${RE_GUI2D_DIR}
        COMMAND ${RE_2D_RENDER_EXECUTABLE} ${RE_GUI2D_DIR} ${RE_GUI_DIR} ${RE_CMAKE_RE_2D_RENDER_HI_RES_OPTION}
        DEPENDS ${ARG_RENDER_2D_SOURCES}
    )
    add_custom_target(common-render-hi-res DEPENDS ${GUI_HI_RES_ICON})
    add_custom_target(common-render DEPENDS common-render-hi-res)
  else()
    add_custom_target(common-render DEPENDS common-render-low-res)
  endif()

  #############################################
  # common-preview target
  # execute RE2DPreview
  #############################################
  set(RE_PREVIEW_DIR "${JBOX_BUILD_DIR}/GUIPreview2D")

  set(RE_PREVIEW_FILMSTRIPS_DIR "${RE_PREVIEW_DIR}/Intermediate/Filmstrips")
  set(RE_PREVIEW_FILES
      "${RE_PREVIEW_FILMSTRIPS_DIR}/Snapshot_Panel_Back.png"
      "${RE_PREVIEW_FILMSTRIPS_DIR}/Snapshot_Panel_Folded_Back.png"
      "${RE_PREVIEW_FILMSTRIPS_DIR}/Snapshot_Panel_Folded_Front.png"
      "${RE_PREVIEW_FILMSTRIPS_DIR}/Snapshot_Panel_Front.png"
      )

  if(${RE_2D_PREVIEW_EXECUTABLE} STREQUAL "RE_2D_PREVIEW_EXECUTABLE-NOTFOUND")
    add_custom_command(
        OUTPUT ${RE_PREVIEW_FILES}
        COMMAND ${CMAKE_COMMAND} -E echo "Preview functionality not available [Could not find RE2DPreview executable in its expected location]. To fix this issue, make sure that RE2DPreview is unzipped or provide RE_2D_PREVIEW_ROOT argument"
        DEPENDS ${ARG_RENDER_2D_SOURCES}
    )
  else()
    add_custom_command(
        OUTPUT ${RE_PREVIEW_FILES}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${RE_GUI2D_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ARG_RENDER_2D_SOURCES} ${RE_GUI2D_DIR}
        COMMAND ${RE_2D_PREVIEW_EXECUTABLE} ${RE_GUI2D_DIR} ${RE_PREVIEW_DIR}
        COMMAND ${CMAKE_COMMAND} -E echo "Generated preview files under ${RE_PREVIEW_FILMSTRIPS_DIR}."
        DEPENDS ${ARG_RENDER_2D_SOURCES}
    )
  endif()

  add_custom_target(common-preview DEPENDS ${RE_PREVIEW_FILES})

  #############################################
  # install target
  # install the plugin to be loaded by Recon
  #############################################

  # Installation directory
  if(APPLE)
    set(INSTALL_DIR "$ENV{HOME}/Library/Application Support/Propellerhead Software/RackExtensions_Dev/${RE_ID}")
  else()
    file(TO_CMAKE_PATH "$ENV{APPDATA}" APPDATA_DIR)
    set(INSTALL_DIR "${APPDATA_DIR}/Propellerhead Software/RackExtensions_Dev/${RE_ID}")
  endif()

  # exporting INSTALL_DIR
  set(INSTALL_DIR ${INSTALL_DIR} PARENT_SCOPE)

  message (STATUS "RE will be installed under ${INSTALL_DIR}")

  # Install library
  install(
      TARGETS ${target}
      DESTINATION ${INSTALL_DIR}
  )

  # Install info.lua, motherboard_def.lua and realtime_controller.lua
  install(
      FILES ${ARG_INFO_LUA} ${ARG_MOTHERBOARD_DEF_LUA} ${ARG_REALTIME_CONTROLLER_LUA} ${ARG_RE_SDK_VERSION_FILE}
      DESTINATION ${INSTALL_DIR}
  )

  # Installing display.lua if it exists (only required if there are custom displays)
  if(EXISTS ${ARG_DISPLAY_LUA})
    install(
        FILES ${ARG_DISPLAY_LUA}
        DESTINATION ${INSTALL_DIR}
    )
  else()
    set(ARG_DISPLAY_LUA "" PARENT_SCOPE)
    message(STATUS "No custom display (display.lua) found")
  endif()

  # Install Resources (i18n files)
  install(
      DIRECTORY ${ARG_RESOURCES_DIR}/
      DESTINATION ${INSTALL_DIR}
  )

  # Install GUI
  install(
      DIRECTORY ${RE_GUI_DIR}/Output/
      DESTINATION ${INSTALL_DIR}
  )

  #############################################
  # native-install target
  # executes native-install-hi-res or native-install-low-res
  #############################################
  add_custom_target(native-install-low-res
      COMMAND ${CMAKE_COMMAND} --build . --target install
      COMMAND ${CMAKE_COMMAND} -E echo "Installed plugin under ${INSTALL_DIR}"
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      DEPENDS common-render-low-res
      )

  if(RE_SDK_SUPPORT_HI_RES)
    add_custom_target(native-install-hi-res
        COMMAND ${CMAKE_COMMAND} --build . --target install
        COMMAND ${CMAKE_COMMAND} -E echo "Installed plugin under ${INSTALL_DIR}"
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        DEPENDS common-render-hi-res
        )
    add_custom_target(native-install DEPENDS native-install-hi-res)
  else()
    add_custom_target(native-install DEPENDS native-install-low-res)
  endif()

  #############################################
  # common-uninstall target
  # common-uninstall the plugin
  #############################################
  add_custom_target(common-uninstall
      COMMAND ${CMAKE_COMMAND} -E remove_directory ${INSTALL_DIR}
      COMMAND ${CMAKE_COMMAND} -E echo "Removed plugin from ${INSTALL_DIR}"
      )

endfunction()

##########################################################
# Internal function to create the build45 build targets
##########################################################
function(internal_add_jbox_build)

  # All variables created by caller are accessible...

  #############################################
  # Generate build45.py
  #############################################
  # Inject variables in build45.py
  # JUKEBOX_SDK_DIR => location of the SDK
  set(JUKEBOX_SDK_DIR "${ARG_RE_SDK_ROOT}")

  # BUILD45_SOURCE_FILES => sources to compile (exclude Recon only build)
  # jbox build expects only .cpp or .c so filtering anything else (like .h or .hpp)
  set(BUILD45_CPP_FILES ${ARG_BUILD_SOURCES})
  list(FILTER BUILD45_CPP_FILES INCLUDE REGEX ".*(\\.cpp|\\.c)$")
  list(JOIN BUILD45_CPP_FILES "\",\"" BUILD45_CPP_FILES)
  set(BUILD45_SOURCE_FILES "\"${BUILD45_CPP_FILES}\"")

  # BUILD45_INCLUDE_DIRS => directories to include
  list(JOIN ARG_INCLUDE_DIRECTORIES "\",\"" BUILD45_INCLUDE_DIRS)
  set(BUILD45_INCLUDE_DIRS "\"${BUILD45_INCLUDE_DIRS}\"")

  list(APPEND COMPILE_DEFINITIONS ${ARG_COMPILE_DEFINITIONS} ${ARG_JBOX_COMPILE_DEFINITIONS})

  if(COMPILE_DEFINITIONS)
    list(JOIN COMPILE_DEFINITIONS " -D" BUILD45_COMPILE_DEFINITIONS)
    set(BUILD45_COMPILE_DEFINITIONS "-D${BUILD45_COMPILE_DEFINITIONS}")
  endif()

  list(APPEND COMPILE_OPTIONS ${ARG_COMPILE_OPTIONS} ${ARG_JBOX_COMPILE_OPTIONS})

  if(COMPILE_OPTIONS)
    list(JOIN COMPILE_OPTIONS " " BUILD45_COMPILE_OPTIONS)
  endif()

  set(BUILD45_OTHER_COMPILER_FLAGS ${BUILD45_COMPILE_OPTIONS} ${BUILD45_COMPILE_DEFINITIONS})
  list(JOIN BUILD45_OTHER_COMPILER_FLAGS " " BUILD45_OTHER_COMPILER_FLAGS)
  set(BUILD45_OTHER_COMPILER_FLAGS "\"${BUILD45_OTHER_COMPILER_FLAGS}\"")

  # Generate build45.py
  set(BUILD45_FILE ${CMAKE_BINARY_DIR}/build45.py)
  configure_file(${BUILD45_SRC_DIR}/build45.py.in ${BUILD45_FILE} @ONLY)

  set(UNIVERSAL45_FILE "${CMAKE_BINARY_DIR}/${RE_FULL_PRODUCT_ID}-${RE_VERSION_NUMBER}.u45")

  macro(build45 target message extra_commands)
    add_custom_target(${target}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${JBOX_BUILD_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ARG_INFO_LUA} ${ARG_MOTHERBOARD_DEF_LUA} ${ARG_REALTIME_CONTROLLER_LUA} ${ARG_DISPLAY_LUA} ${BUILD45_FILE} ${JBOX_BUILD_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${ARG_RESOURCES_DIR} ${JBOX_BUILD_DIR}/Resources
        COMMAND ${Python3_EXECUTABLE} ${BUILD45_FILE} ${ARGN}
        ${extra_commands}
        COMMAND ${CMAKE_COMMAND} -E echo ${message}
        DEPENDS common-render
        WORKING_DIRECTORY ${JBOX_BUILD_DIR}
        )
  endmacro()

  set(INSTALL_DIR "$ENV{HOME}/Library/Application Support/Propellerhead Software/RackExtensions_Dev/${RE_ID}")

  #############################################
  # jbox-u45-build target
  # jbox-l45-debugging-install target
  # jbox-l45-testing-install target
  # jbox-l45-deployment-install target
  #############################################
  set(jbox-u45-build_commands COMMAND ${CMAKE_COMMAND} -E rename "${JBOX_BUILD_DIR}/Output/Universal45/${RE_ID}.u45" "${UNIVERSAL45_FILE}")
  build45("jbox-u45-build" "Generated: ${UNIVERSAL45_FILE}" "${jbox-u45-build_commands}" "universal45")
  build45("jbox-l45-debugging-install" "Installed local45 under ${INSTALL_DIR}" "" "local45" "Debugging")
  build45("jbox-l45-testing-install" "Installed local45 under ${INSTALL_DIR}" "" "local45" "Testing")
  build45("jbox-l45-deployment-install" "Installed local45 under ${INSTALL_DIR}" "" "local45" "Deployment")

  #############################################
  # common-clean target (removes jbox folder)
  #############################################
  add_custom_target(common-clean
      COMMAND ${CMAKE_COMMAND} --build . --config $<CONFIG>  --target clean
      COMMAND ${CMAKE_COMMAND} -E remove_directory ${JBOX_BUILD_DIR}
  )

endfunction()

##########################################################
# Internal function to add validation targets
##########################################################
function(internal_add_validation)
  if(ARG_RE_RECON_EXECUTABLE)
    set(RE_RECON_EXECUTABLE "${ARG_RE_RECON_EXECUTABLE}")
  else()
    find_program(
        RE_RECON_EXECUTABLE
        NAMES "Reason Recon" "Reason Recon 12 RESDK4 Logging" "Reason Recon 11 RESDK41 Logging"
        PATHS "/Applications" "/Applications/Reason Recon"
              "c:/Program Files/Propellerhead" "c:/Program Files/Propellerhead/Reason Recon" "c:/Program Files/Propellerhead/Reason Recon 12 RESDK4 Logging" "c:/Program Files/Propellerhead/Reason Recon 11 RESDK4 Logging"
    )
  endif()

  if(${RE_RECON_EXECUTABLE} STREQUAL "RE_RECON_EXECUTABLE-NOTFOUND")
    add_custom_target(common-validate
        COMMAND ${CMAKE_COMMAND} -E echo "'validate' cannot run because Recon executable was not found in its default location. To fix this issue you can either install/move Recon into its default location or provide its location via RE_RECON_EXECUTABLE argument."
        )
  else()
    # unclear why find_program returns %20 for space (Reason%20Recon)... need to fix
    string(REPLACE "%20" " " RE_RECON_EXECUTABLE ${RE_RECON_EXECUTABLE})
    if(APPLE)
      set(OPTION_PREFIX "--")
      set(CAT_EXE "cat")
      set(RE_DIR ${INSTALL_DIR})
      set(VALIDATE_RE_LOG "${CMAKE_CURRENT_BINARY_DIR}/validate-re.log")
#      set(VALIDATE_TEST_LOG "${CMAKE_CURRENT_BINARY_DIR}/validate-test.log")
    else()
      set(OPTION_PREFIX "/")
      set(CAT_EXE "type")
      file(TO_NATIVE_PATH "${INSTALL_DIR}" RE_DIR)
      file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/validate-re.log" VALIDATE_RE_LOG)
#      file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/validate-test.log" VALIDATE_TEST_LOG)
    endif()

    #############################################
    # common-validate target runs validate without any dependency
    #############################################
    add_custom_target(common-validate
        COMMAND ${CMAKE_COMMAND} -E echo "Running Recon validation..."
        COMMAND ${CMAKE_COMMAND} -E remove -f  "${VALIDATE_RE_LOG}"
#        COMMAND ${RE_RECON_EXECUTABLE} "${OPTION_PREFIX}validate_re" "${OPTION_PREFIX}re_dir=${RE_DIR}" "${OPTION_PREFIX}re_log=${VALIDATE_RE_LOG}" "${OPTION_PREFIX}testlogfile=${VALIDATE_TEST_LOG}" "${OPTION_PREFIX}re=${RE_FULL_PRODUCT_ID}"
        COMMAND ${RE_RECON_EXECUTABLE} "${OPTION_PREFIX}validate_re" "${OPTION_PREFIX}re_dir=${RE_DIR}" "${OPTION_PREFIX}re_log=${VALIDATE_RE_LOG}" "${OPTION_PREFIX}re=${RE_FULL_PRODUCT_ID}"
        COMMAND ${CMAKE_COMMAND} -E echo "Validation complete... displaying content of log files"
        COMMAND ${CMAKE_COMMAND} -E echo "1. Log file ${VALIDATE_RE_LOG}"
        COMMAND ${CAT_EXE} "${VALIDATE_RE_LOG}"
#        COMMAND ${CMAKE_COMMAND} -E echo "2. Log file ${VALIDATE_TEST_LOG}"
#        COMMAND ${CAT_EXE} "${VALIDATE_TEST_LOG}"
        )

    #############################################
    # jbox-validate45 target runs validate on local45 Deployment
    #############################################
    add_custom_target(jbox-validate45
        COMMAND ${CMAKE_COMMAND} --build . --target common-validate
        DEPENDS jbox-l45-deployment-install
        )
  endif()
endfunction()
