Rack Extension CMake build framework
====================================

This project implements a CMake based build framework in order to help building [Rack Extensions](https://developer.reasonstudios.com/) which are audio plugins for Reason, the Reason Studios DAW. 

Features
--------

* native support in IDEs handling CMake directly, like `CLion` or `Visual Studio Code` (with the CMake extension)
* project generation for most of the generators supported by CMake, like `XCode` for macOS, `Visual Studio` for Windows, `Unix Makefiles`, and many more
* completely isolated build (no polluting the source tree)
* much faster builds (due to proper dependency management, no need to recompile everything all the time)
* proper integration with IDEs for debugging (for example starting Recon from CLion in debug mode and putting a breakpoint in the source tree)
* native toolchain builds allowing for non-sandboxed builds for easy development (use of `std::string`, `std::cout`, etc...)
* easy to use script (`re.sh` for macOS, `re.bat` for Windows) to invoke all the various phases of the build so no need to remember long and complicated syntax

Requirements
------------

* This project requires CMake (minimum version 3.24) to be properly installed (`cmake` executable must be in your `PATH`)
* This project currently expects RE SDK 4.3.0 (Hi Res support), 4.2.0 or 4.1.0 to be installed on the machine (it will not download it for you)
* Due to the RE SDK requirements, this project also requires python 3 to be installed
* It has been tested on macOS Big Sur (11.7) / Xcode 13.2.1 (requires macOS 15+)
* It has been tested on macOS 12.6 / Xcode 13.3 installed and Apple Silicon (forces `x86_64` build to compile and run)
* It has been tested on Windows 10 with Visual Studio 16 2019 build tools + Clang toolchain

> #### Note
> For Windows, since re-cmake 1.6.0, the default setup is to use the Clang toolchain, for 2 main reasons:
>  * SIMD support out of the box (SIMD does not work without Clang)
>  * Use a similar compiler provided with the RE SDK
> 
> Make sure you provision the build tools properly: using the Visual Studio Installer, select the "Individual components" tab, search for "clang" and make sure that "C++ Clang..." is selected (there may be more than one entry, so select all of them).
> 
> ![Visual Studio Installer](https://github.com/pongasoft/re-cmake/releases/download/v1.6.0/Visual_Studio_Installer.png)
> 
> If you want to disable the use of Clang (and revert to the behavior prior to v1.6.0), you can set the (CMake) option `RE_CMAKE_ENABLE_CLANG_TOOLCHAIN` to `OFF` before including `re-cmake` (and rerun `configure.py` after deleting the `build` folder).


Quick Starting guide
--------------------

For the sake of keeping this project lean, it does not include any example, but you should check [re-blank-plugin](https://github.com/pongasoft/re-blank-plugin) which is the official example project for this framework.

> #### Tip
> If you want to easily create a blank plugin check the [Rack Extension - Quick Start](https://pongasoft.com/re-quickstart/index.html) tool which sets everything up for you.

This project offers a main CMake file `main.cmake` which simply needs to be included in your `CMakeLists.txt` for your plugin.

You should then call:

* `re_cmake_before_project_init()` **before** the `project()` call in your `CMakeLists.txt`
* `re_cmake_init()` after `project()` and optionally provide a list of `INCLUDES`: `re-logging` (for logging) and/or `re-mock` (for unit testing)
* finally, call `add_re_plugin`.

```
# Example assuming re-cmake is local (check re-blank-plugin for a better way)
include(re-cmake/main.cmake)

# Initializes the proper toolchain
re_cmake_before_project_init()

# defines the project
project(MyProject)

# initializes re-cmake and uses both re-logging and re-mock
re_cmake_init(INCLUDES re-logging re-mock)

# Call add_re_plugin to create the targets and script
add_re_plugin(xxx)
```

> #### Note
> There are many ways to bring this framework into your own project and how you do it depends on your preferences and structure. Here are a few examples:
> 1. `re-cmake` is local but "out of tree", somewhere on the user's system, for example where multiple projects share one instance of it. This would require cloning or copying this project somewhere.
> 2. `re-cmake` is local, but "in tree", within the RE project directory (or somewhere below), for example where using git submodules or git subtree, or even when just copied directly into the RE project (good for people who love 100% reproducible builds).
> 3. `re-cmake` is remote, and fetched by CMake during the `configure` phase (which is the way the official example does it since you don't really have to worry about it)

#### Note about the RE SDK location

You can install the SDK wherever you want on your system and provide it as an argument to `add_re_plugin` or you can install (or create a link) in a default location:

* `/Users/Shared/ReasonStudios/JukeboxSDK_<RE_SDK_VERSION>/SDK` for macOS
* `C:/Users/Public/Documents/ReasonStudios/JukeboxSDK_<RE_SDK_VERSION>/SDK` for Windows

By default, the `RE2DRender` program needs to be unzipped and is expected to be a sibling of `SDK` but this can also be provided as an argument to `add_re_plugin`.

If you want to use the (optional) `preview` command, by default, the `RE2DPreview` program needs to be unzipped and is expected to be a sibling of `SDK` but this can also be provided as an argument to `add_re_plugin`.

`re_cmake_before_project_init`
------------------------------
This macro should be called **before** defining the `project()` section in your `CMakeLists.txt`. It must be called before because it defines the proper toolchain.

`re_cmake_init`
---------------
The macro initializes re-cmake and should be called after `project()`. It optionally takes a list of `INCLUDES` to include additional frameworks:

* `re-logging` is a logging framework (based on loguru) to easily add debugging/checks to the plugin under development. It defines a variable `re-logging_SOURCES` which needs to be added to the `NATIVE_BUILD_SOURCES` argument (see `add_re_plugin`)
* `re-mock` is a [framework](https://github.com/pongasoft/re-mock) that implements the full Jukebox API in order to help in writing unit test for the plugin under development. This call defines a variable `re-mock_LIBRARY_NAME` which needs to be added to the `TEST_LINK_LIBS` argument (see `add_re_plugin`)

`add_re_plugin`
---------------
The framework exposes a function to create the plugin targets and script. It can take many arguments, very few being actually required

```
add_re_plugin(
       # Required arguments
              RE_SDK_VERSION reSdkVersion
              BUILD_SOURCES src1 [src2...]
              RENDER_2D_SOURCES src1 [scr2...]

       # Optional paths
              [RE_SDK_ROOT path_to_RE_SDK]
              [RE_2D_RENDER_ROOT path_to_RE2DRender_folder]
              [RE_2D_PREVIEW_ROOT path_to_RE2DPreview_folder]
              [RE_RECON_EXECUTABLE path_to_Recon_executable]
              [PYTHON3_EXECUTABLE path_to_python3_executable]

       # Optional paths to plugin files (defaults matching RE SDK Examples)
              [INFO_LUA path_to_info.lua]
              [MOTHERBOARD_DEF_LUA path_to_motherboard_def.lua]
              [REALTIME_CONTROLLER_LUA path_to_realtime_controller.lua]
              [DISPLAY_LUA path_to_display.lua]
              [RESOURCES_DIR path_to_Resources]

       # Optional include directories (to include extra '.h' files)
              [INCLUDE_DIRECTORIES dir1 [dir2...]]

       # Optional native build sources and libraries (for sources and libraries that 
       # won't compile in jbox build)
              [NATIVE_BUILD_SOURCES src1 [src2...]]
              [NATIVE_BUILD_LIBS lib1 [lib2...]]

       # Optional compile definitions (ex: FOOBAR=3)
              [COMPILE_DEFINITIONS def1 [def2...]]
              [NATIVE_COMPILE_DEFINITIONS def1 [def2...]]
              [JBOX_COMPILE_DEFINITIONS def1 [def2...]]

       # Optional compile options (ex: -Wall)
              [COMPILE_OPTIONS option1 [option2...]]
              [NATIVE_COMPILE_OPTIONS option1 [option2...]]
              [JBOX_COMPILE_OPTIONS option1 [option2...]]

       # Optional link options (for native build only)
              [NATIVE_LINK_OPTIONS option1 [option2...]]

       # Optional toggle to enable debugging (for example JBOX_TRACE) (disabled otherwise)
              [ENABLE_DEBUG_LOGGING]
       
       # Optional testing entries
              [TEST_CASE_SOURCES src1 [src2...]]
              [TEST_SOURCES src1 [src2...]]
              [TEST_INCLUDE_DIRECTORIES dir1 [dir2...]]
              [TEST_COMPILE_DEFINITIONS def1 [def2...]]
              [TEST_COMPILE_OPTIONS option1 [option2...]]
              [TEST_LINK_LIBS lib1 [lib2...]]
)
```

Detailed description

| Argument / Option            | Required | Description                                                                                                                                                                                                                            | Example                                                                           |
|------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| `RE_SDK_VERSION`             | Yes      | The version of the SDK this RE is being built for                                                                                                                                                                                      | `"4.3.0"`                                                                         |
| `BUILD_SOURCES`              | Yes      | The list of sources (cpp) files that are compiled to create the RE logic                                                                                                                                                               | Usually refers to some list `${re_sources_cpp}`                                   |
| `RENDER_2D_SOURCES`          | Yes      | The list of 2D GUI files that composes the UI layer of the RE (must include `device_2D.lua` and `hdgui_2D.lua`)                                                                                                                        | Usually refers to some list `${re_sources_2d}`                                    |
| `RE_SDK_ROOT`                | No       | The (absolute) path to the root of the RE SDK. It will default to `/Users/Shared/ReasonStudios/JukeboxSDK_${RE_SDK_VERSION}/SDK` on macOS and `C:/Users/Public/Documents/ReasonStudios/JukeboxSDK_${RE_SDK_VERSION}/SDK` on Windows 10 | `/local/Jukebox_4.3.0/SDK`                                                        |
| `RE_2D_RENDER_ROOT`          | No       | The (absolute) path to the `RE2DRender` folder. It will default to `${RE_SDK_ROOT}/../RE2DRender`                                                                                                                                      | `/local/RE2DRender`                                                               |
| `RE_2D_PREVIEW_ROOT`         | No       | The (absolute) path to the `RE2DPreview` folder. It will default to `${RE_SDK_ROOT}/../RE2DPreview`                                                                                                                                    | `/local/RE2DPreview`                                                              |
| `INFO_LUA`                   | No       | The path to `info.lua` which by default is at the root                                                                                                                                                                                 | `defs/info.lua`                                                                   |
| `MOTHERBOARD_DEF_LUA`        | No       | The path to `motherboard_def.lua` which by default is at the root                                                                                                                                                                      | `defs/motherboard_def.lua`                                                        |
| `REALTIME_CONTROLLER_LUA`    | No       | The path to `realtime_controller.lua` which by default is at the root                                                                                                                                                                  | `defs/realtime_controller.lua`                                                    |
| `DISPLAY_LUA`                | No       | The path to `display.lua` which by default is at the root (note that `display.lua` is only required if you have any custom displays)                                                                                                   | `src/lua/display.lua`                                                             |
| `RESOURCES_DIR`              | No       | The path to the `Resources` folder which by default is at the root                                                                                                                                                                     | `i18n/Resources`                                                                  |
| `INCLUDE_DIRECTORIES`        | No       | The list of directories that need to be included for searching for `.h` files. Note that it is a list of directories so it does not contain `-I`.                                                                                      | Usually refers to some list `${logging_include_dir}`                              |
| `PYTHON3_EXECUTABLE`         | No       | The python 3 executable which is determined by default but you can override it here                                                                                                                                                    | `/opt/local/bin/python3`                                                          |
| `NATIVE_BUILD_SOURCES`       | No       | The list of sources (cpp) files that are compiled ONLY during the native build (for example to add debugging/tracing libraries that cannot be compiled during the jbox build due to the sandbox)                                       | Usually refers to some list `${logging_sources}`                                  |
| `NATIVE_BUILD_LIBS`          | No       | The list of libraries that are linked ONLY during the native build (for example to add debugging/tracing libraries that cannot be linked during the jbox build due to the sandbox)                                                     | `loguru`                                                                          |
| `COMPILE_DEFINITIONS`        | No       | The list of compile definitions applied to native and jbox compilers. Note that `-D` should not be included.                                                                                                                           | `BOOST_MODE=1` `BOOST2`                                                           |
| `NATIVE_COMPILE_DEFINITIONS` | No       | The list of compile definitions applied to native compiler only. Note that `-D` should not be included.                                                                                                                                | `BOOST_MODE=1` `BOOST2`                                                           |
| `JBOX_COMPILE_DEFINITIONS`   | No       | The list of compile definitions applied to jbox compiler only. Note that `-D` should not be included.                                                                                                                                  | `BOOST_MODE=1` `BOOST2`                                                           |
| `COMPILE_OPTIONS`            | No       | The list of compile options applied to native and jbox compilers.                                                                                                                                                                      | `-Wall`                                                                           |
| `NATIVE_COMPILE_OPTIONS`     | No       | The list of compile options applied to native compiler only.                                                                                                                                                                           | `-Wall`                                                                           |
| `JBOX_COMPILE_OPTIONS`       | No       | The list of compile options applied to jbox compiler only.                                                                                                                                                                             | `-Wall`                                                                           |
| `NATIVE_LINK_OPTIONS`        | No       | The list of link options applied to native linker only. Note that there is no equivalent for jbox build.                                                                                                                               |                                                                                   |
| `ENABLE_DEBUG_LOGGING`       | No       | Option to turn on debug logging (enable `JBOX_TRACE`). Equivalent to `NATIVE_COMPILE_OPTIONS DEBUG=1`                                                                                                                                  |                                                                                   |
| `RE_RECON_EXECUTABLE`        | No       | The Recon executable which is determined by looking in a default location but you can override it here                                                                                                                                 | `"/Applications/Reason Recon 11 RESDK41 Logging.app/Contents/MacOS/Reason Recon"` |
| `TEST_CASE_SOURCES`          | No       | The list of sources (cpp) files that contains the unit test cases.                                                                                                                                                                     | Usually refers to some list `${re_test_cpp}`                                      |
| `TEST_SOURCES`               | No       | The list of sources (cpp) files that need to be compiled alongside the tests.                                                                                                                                                          | Usually refers to some list `${logging_sources}`                                  |
| `TEST_INCLUDE_DIRECTORIES`   | No       | The list of directories that need to be included for searching for `.h` files for compiling tests. Note that it is a list of directories so it does not contain `-I`.                                                                  | Usually refers to some list `${RE_CPP_SRC_DIR}`                                   |
| `TEST_COMPILE_DEFINITIONS`   | No       | The list of compile definitions for compiling the tests. Note that `-D` should not be included.                                                                                                                                        | `BOOST_MODE=1` `BOOST2`                                                           |
| `TEST_COMPILE_OPTIONS`       | No       | The list of compile options applied for compiling the tests.                                                                                                                                                                           | `-Wall`                                                                           |
| `TEST_LINK_LIBS`             | No       | The list of libraries that needs to be linked with the tests.                                                                                                                                                                          | `native-build` (note that it can be a target)                                     |

Convenient script (`re.sh`/`re.bat`)
------------------------------------

Calling `add_re_plugin` will automatically generate a script in the build folder called `re.sh` for macOS (resp.`re.bat` for Windows). This script is essentially a convenient wrapper around invoking `cmake` manually but with a simplified syntax (and help) to make it more user friendly to use.

Note that this script is expecting the `cmake` command line tool to be in the `PATH` (use `cmake -version` to confirm it is properly installed).

```
# ./re.sh -h
usage: re.sh [-hnvlbdtRZ] <command> [<command> ...] [-- [native-options]]

positional arguments:
  command          See "Commands" section

optional arguments:
  -h, --help       show this help message and exit
  -n, --dry-run    Dry run (prints what it is going to do)
  -v, --verbose    Verbose build
  -l, --low-res    Forces low res build (4.3.0+)
  -b, --banner     Display a banner before every command
  -d, --debugging  Use 'Debugging' for local45 command
  -t, --testing    Use 'Testing' for local45 command
  -R, --release    Invoke CMake in Release mode (for multi-config generators)
  -Z               Clears the Recon Graphics Cache (workaround)

Commands
  ---- Native build commands ----
  build       : build the RE (.dylib)
  install     : build (code/gui) and install the RE for use in Recon
  test        : run the unit tests

  ---- Jbox build commands (build45 / sandbox toolchain) ----
  local45     : build (code/gui) and install the RE for use in Recon ('Deployment' type or -d/-t to change)
  universal45 : build the package for uploading to Reason Studio servers (.u45)
  validate45  : runs the Recon validate process on local45 (equivalent to ./re.sh local45 validate)

  ---- Common commands ----
  clean       : clean all builds
  render      : runs RE2DRender to generate the GUI (necessary for running in Recon)
  edit        : runs RE Edit to edit the device (UI)
  preview     : runs RE2DPreview to generate the device preview (useful for shop images)
  uninstall   : deletes the installed RE
  validate    : runs the Recon validate process on the currently installed plugin

  ---- CMake target ----
  <command>   : Any unknown <command> is treated as a cmake target

  --- Native options ----
  Pass remaining options to the native tool (ex: -- -j 8 for parallel build)
```

Targets & Commands
------------------
Here is a quick rundown of the list of targets and associated commands. Note that the _native_ targets handle changes properly and only rebuild what is necessary. 

| CMake Target                  | Script Command | Description                                                                                                                                                                                            |
|-------------------------------|----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `native-build`                | `build`        | Builds the plugin with the native toolchain (generate the `.dylib` or `.dll` only)                                                                                                                     |
| `native-install-hi-res`       | `install`      | Builds the plugin with the native toolchain, generates the GUI (Hi Res) and installs the plugin in its default location (ready to be used in Recon) (not available if the SDK does not support Hi Res) |
| `native-install-low-res`      | `-l install`   | Builds the plugin with the native toolchain, generates the GUI (Low Res) and installs the plugin in its default location (ready to be used in Recon)                                                   |
| `native-install`              | `install`      | Shortcut to `native-install-hi-res` if the SDK supports Hi Res, `native-install-low-res` otherwise                                                                                                     |
| `native-run-test`             | `test`         | Runs the unit tests (only available for the native toolchain)                                                                                                                                          |
| `common-render-hi-res`        | `render`       | Generates the Hi Res GUI (not available if the SDK does not support Hi Res)                                                                                                                            |
| `common-render-low-res`       | `-l render`    | Generates the Low Res GUI                                                                                                                                                                              |
| `common-render`               | `render`       | Shortcut to `common-render-hi-res` if the SDK supports Hi Res, `common-render-low-res` otherwise                                                                                                       |
| `common-preview`              | `preview`      | Generates a 2D preview of the device front, back, folded front and folded back (generated at full 5x resolution (3770x345*u), useful for shop images)                                                  |
| `common-uninstall`            | `uninstall`    | Uninstalls the plugin from its default location (for example you can run: `./re.sh uninstall install`)                                                                                                 |
| `common-clean`                | `clean`        | Cleans any previous build (forces a rebuild of everything on next build)                                                                                                                               |
| `common-edit`                 | `edit`         | Runs [RE Edit](https://pongasoft.com/re-edit/) for this device                                                                                                                                         |
| `common-validate`             | `validate`     | Runs Recon validation on the currently installed plugin. It does **not** install the plugin prior.                                                                                                     |
| `jbox-l45-deployment-install` | `local45`      | Builds the (sandboxed) plugin with the jbox toolchain (`local45 Deployment`), generates the GUI and installs the plugin in its default location (ready to be used in Recon)                            |
| `jbox-l45-testing-install`    | `-t local45`   | Builds the (sandboxed) plugin with the jbox toolchain (`local45 Testing`), generates the GUI and installs the plugin in its default location (ready to be used in Recon)                               |
| `jbox-l45-debugging-install`  | `-d local45`   | Builds the (sandboxed) plugin with the jbox toolchain (`local45 Debugging`), generates the GUI and installs the plugin in its default location (ready to be used in Recon)                             |
| `jbox-u45-build`              | `universal45`  | Builds the universal45 (`.u45`) package with the jbox toolchain ready to be uploaded to Reason servers                                                                                                 |
| `jbox-validate45`             | `validate45`   | Builds the (sandboxed) plugin with the jbox toolchain (`local45`) and runs Recon validation on it                                                                                                      |

> #### Note
> 2021/10/30: Due to a caching issue with Recon 12 and Hi Res graphics, you can use `-Z` command line argument to delete the cache directory (this is a hack/workaround) 

Options
-------

Check the [RECMakeOptions.cmake](cmake/RECMakeOptions.cmake) file for options that can be set **prior** to calling `re_cmake_before_project_init()`.

Understanding the different kinds of builds
-------------------------------------------
It is pretty critical to understand the various kinds of builds that are available for a Rack Extension. They are very specific to the RE SDK.

### local vs universal
The RE SDK provides Recon which is a special version of Reason that outputs (a ton of) debugging messages and which can run RE that are built **locally**. When you want to publish your RE to the Reason Studios build servers, you need to build what is called a universal45. The 2 kind of builds are very different.

#### local build
Because the local build needs to run on a given machine, the build needs to produce machine specific artifacts (`.dylib` for macOS and `.dll` for Windows).

Because the local build needs to run inside Recon, it needs to be packaged in a way that Recon can use, which involves for example processing the `GUI2D` folder through the `RE2DRender` program to generate the GUI files in their proper format/dimension (`GUI` folder).

#### universal build
The universal build compiles the code to bitcode and packages the original graphics (`GUI2D`) in a `.u45` (which is nothing more than a zip file with a different suffix). The Reason Studio build servers will then produce the final packaged RE with DRM protection for every platform.

### native vs sandbox
It is very important to understand that a RE, which is a plugin, ends up running in a sandbox (the Reason DAW). It is a sandbox in the sense that the plugin is very limited in what it can and cannot do. For example, allocating memory in the `renderBatch` main call is absolutely prohibited. This makes development quite painful as simply displaying log messages without being able to do string manipulations is quite a challenge. Thankfully, inside Recon, there are no restrictions so it is possible to do a native build using the full power of C++ (strings, `std::cout`, etc...).

Of course the plugin in the end will run in a sandbox so care must be taken to protect native build code properly, but it is a minor inconvenience for the massive productivity gained. For this purpose, the local/native build gets compile with the define `LOCAL_NATIVE_BUILD=1` which lets you write code like this:

```
#if LOCAL_NATIVE_BUILD
  // this code is executed ONLY during the native build so it can use loguru for example
  ABORT_F("Unknown operation [%s] passed to JBox_Export_CreateNativeObject", iOperation);
#else
  // this code is executed for jbox builds (local45/universal45)
  return nullptr;
#endif
```

> #### Note
> In this framework, the sandbox build is called `jbox` because it uses the toolchain coming from the _Jukebox_ (which is a Reason Studios specific name for their framework) 

> #### Note
> Due to the limitations of the jbox toolchain (which has a very limited subset of C++ available), testing is only available as a local native command.

### Summary

| &nbsp;                 | **local native**                                    | **local jbox**                                                                                             | **universal**                                    |
|------------------------|-----------------------------------------------------|------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| **Runs in**            | Recon                                               | Recon                                                                                                      | Reason                                           |
| **Description**        | Full power of C++                                   | Sandbox / C++ subset                                                                                       | Sandbox / C++ subset                             |
| **CMake Build**        | Invokes native build commands / toolchain           | Invokes proprietary build system (`local45`)                                                               | Invokes proprietary build system (`universal45`) |
| **CMake Targets**      | `native-build`, `native-install`, `native-run-test` | `jbox-l45-debugging-install`, `jbox-l45-testing-install`, `jbox-l45-deployment-install`, `jbox-validate45` | `jbox-u45-build`                                 |
| **Commands (`re.sh`)** | `build`, `install`, `test`                          | `local45`, `validate45`                                                                                    | `universal45`                                    |

Example Usage
-------------

It is strongly recommended checking the [re-blank-plugin](https://github.com/pongasoft/re-blank-plugin) project which is the official example/documentation for this framework. It shows how to use it properly including:

- `CMakeLists.txt` demonstrating how to include and invoke the framework while allowing the user of the project to configure it (like specifying the location of the SDK)
- `re-cmake.cmake` which is a CMake script to automatically download this framework (you specify the framework version via `re-cmake_GIT_TAG`)
- `configure.py` which is a script abstracting how to invoke `cmake` to configure the project and provides a useful help/usage documentation

Release notes
-------------
#### 1.7.2 - 2024/06/20

- Updated `re-mock` version (added support for `device_categories`)

#### 1.7.1 - 2023/09/11

- Fixes issue locating RE2DRender and RE2DPreview after SDK 4.4.0 final release

#### 1.7.0 - 2023/07/02

- Handles RE SDK 4.4.0 (beta): on macOS/arm64 platform, generate an arm64 binary (with proper name)
- Fixed options (removed `FORCE` since the rack extension can define it first thus can override it!)
- Prints a message when re-cmake detects a mismatch in version

#### 1.6.1 - 2023/04/28

- Upgraded google test to 1.13.0 and introduced url hashes in order to guarantee that the code is not tempered with (incidentally it speeds up the build since CMake can simply compare the hash of a previously downloaded dependency)

#### 1.6.0 - 2023/04/21

- Uses Clang toolchain on Windows by default. See the "Notes" in the "Requirements" section on how to properly configure the compiler on Windows.
- This change ensures that SIMD works out of the box on Windows and that the compiler is similar to the one provided with the SDK (hence getting similar runtime behavior)

#### 1.5.2 - 2023/04/14

- Uses re-mock 1.4.1 (fixes multi bindings/same source in `rtc_bindings`)

#### 1.5.1 - 2023/04/11

- Uses re-mock 1.4.0

#### 1.5.0 - 2023/01/02

- Added `edit` command (which uses [RE Edit](https://pongasoft.com/re-edit/))
- Bumped CMake minimum version to 3.24
- Uses re-mock 1.3.2
- Uses GoogleTest 1.12.1
- Added a new `DOWNLOAD_URL` option for `re_cmake_fetch_content` to avoid downloading the whole git history

#### 1.4.4 - 2022/10/29

- Uses re-mock 1.2.0 (better error reporting / bug fixes)
- Due to upgrade to Big Sur (macOS 11.7), this is now the macOS version that re-cmake is tested on (although it is expected to work on 10.15+).

#### 1.4.3 - 2022/02/01

- Fixes for Win 10

#### 1.4.2 - 2022/01/24

- Extracted `re-logging` into its own project

#### 1.4.1 - 2022/01/23

- Added `JBOX_LOGVALUES` (simpler api than `JBOX_TRACEVALUES`)
- Added `loguru::init_for_re` to make loguru output nicer for Rack Extensions (replace (useless) thread by RE name)
- Added `loguru::init_for_test` to make loguru throw exception instead of aborting when running tests
- Added generic `loguru::add_preamble_handler` to display any kind of information when logging 

#### 1.4.0 - 2022/01/22

- Introduced `main.cmake` with convenient macros to make writing the `CMakeLists.txt` file for the plugin easier and less error-prone
- Added `re-logging` directly in this project in order to provide central updates
- Added support for `re-mock`
- Fixed issue with spaces in path

> #### Note
> This version is backward compatible so if your project already includes `sdk.cmake` directly, you do not have to change it

#### 1.3.9 - 2021/12/09

- Added `RE_CMAKE_RE_2D_RENDER_HI_RES_OPTION` option to be able to change the type of Hi Res build when the device is not fully Hi Res compliant (applies to custom display backgrounds).

#### 1.3.8 - 2021/10/30

- Added `-Z` command line option to the script to work around the graphics caching issue of Recon 12

#### 1.3.7 - 2021/10/28

- Added Recon12 name to list of Recon executables

#### 1.3.6 - 2021/10/26

- Added support for 4.3.0 / Hi Res toolchain
- new targets: `common-render-low-res` / `common-render-hi-res` and `common-render` is a now a shortcut
- new targets: `native-install-low-res` / `native-install-hi-res` and `native-install` is now a shortcut
- new `-l` option added to script to force a low res build with 4.3.0+

#### 1.3.5 - 2021/10/02

- Properly regenerates CMake project when `info.lua` changes
- Extracts version from `info.lua` and generates a universal 45 package with better naming (`<product_id>-<version_number>.u45`)

#### 1.3.4 - 2021/09/12

- Generates a new `re_cmake_build.h` file which can be included in the code to get access to information from the build itself (particularly useful for testing).

#### 1.3.3 - 2021/07/11

- Use `gtest_discover_tests` to minimize CMake invocation when building tests

#### 1.3.2 - 2021/07/07

- Fixed unnecessary build of tests when running `install`
- Removed dependency on internal Jukebox classes when running tests (preventing mocking)

#### 1.3.1 - 2021/07/05

- Introduced static library for running tests (was generating symbol not found when using shared one)

#### 1.3.0 - 2021/07/04

- Added (optional) unit testing capabilities (new target `native-run-test`, new command `test`, and new `TEST_XX` optional arguments to `add_re_plugin()`)

#### 1.2.0 - 2021/01/07

- Introduced `cmake/RECMakeOptions.cmake` so that it can be invoked **prior** to `project()`.
- Builds properly on Apple chipset (by forcing the build in `x86_64` architecture)

This change is optional but if you want your project to adopt the new structure, you can simply [generate a new blank plugin](https://pongasoft.com/re-quickstart/index.html) to see the changes (only affects `CMakeLists.txt`) or check the [re-blank-plugin](https://github.com/pongasoft/re-blank-plugin) project.

#### 1.1.0 - 2020/09/21

- Added `preview` command (resp. `common-preview` build target) which runs the RE2DPreview tool provided with the SDK. This tool generates a 2D preview of the device front, back, folded front and folded back (generated at full 5x resolution (3770x345*u)). This can be useful to generate images required for the shop (vs running Reason and capturing a low resolution image).

#### 1.0.1 - 2020/09/04

- When providing multiple commands to the script, the script now properly fails on the failed command and terminates with the error code of the failing process
- Added `-b` option to the script to add a banner between multiple commands to make the output easier to follow 

#### 1.0.0 - 2020/06/18

- First release.

Licensing
---------

- Apache 2.0 License. This project can be used according to the terms of the Apache 2.0 license.

- Note that the primary goal of this project is to help build a RE plugin and as a result you should check the [Rack Extension SDK License Agreement](https://developer.reasonstudios.com/agreements/agreements#_rack_extension_sdk_license_agreement) in order to determine under which terms your plugin needs to be licensed.

Thanks
------

- A big thanks to @DavidAntliff for helping with testing and providing great feedback during the development of the framework

Contributing
------------
If you would like to contribute to this project, the recommended way is to open a ticket and discuss what you want to do. Once you have implemented the changes, then submit a Pull Request.
