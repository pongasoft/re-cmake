#!/usr/bin/env python3

# Copyright (c) 2020 pongasoft
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

import argparse
import platform
import os

script_name = ''

if platform.system() == 'Darwin':
    script_name = 're.sh'
else:
    script_name = 're.bat'


parser = argparse.ArgumentParser(allow_abbrev=False,
                                 usage=f'{script_name} [-hnvlbdtRZ] <command> [<command> ...] [-- [native-options]]',
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog='''
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
  preview     : runs RE2DPreview to generate the device preview (useful for shop images)
  edit        : runs RE Edit to edit the device (UI)
  uninstall   : deletes the installed RE
  validate    : runs the Recon validate process on the currently installed plugin

  ---- CMake target ----
  <command>   : Any unknown <command> is treated as a cmake target
  
  --- Native options ----
  Pass remaining options to the native tool (ex: -- -j 8 for parallel build) 
''')
parser.add_argument("-n", "--dry-run", help="Dry run (prints what it is going to do)", action="store_true", dest="dry_run")
parser.add_argument("-v", "--verbose", help="Verbose build", action="store_true")
parser.add_argument("-l", "--low-res", help="Forces low res build (4.3.0+)", action="store_true", dest="low_res")
parser.add_argument("-b", "--banner", help="Display a banner before every command", action="store_true")
parser.add_argument("-d", "--debugging", help="Use 'Debugging' for local45 command", action="store_true")
parser.add_argument("-t", "--testing", help="Use 'Testing' for local45 command", action="store_true")
parser.add_argument("-R", "--release", help="Invoke CMake in Release mode (for multi-config generators)", action="store_true")
parser.add_argument("-Z", help="Clears the Recon Graphics Cache (workaround)", action="store_true", dest="clear_recon_graphics_cache")
parser.add_argument('command', help='See "Commands" section', nargs=argparse.REMAINDER)

args = parser.parse_args()

# compute Recon cache dir path
def recon_cache_dirpath():
    if os.name == 'nt':
        dirpath_localappdata = os.path.normpath(os.getenv('LOCALAPPDATA') )
        r = os.path.join(dirpath_localappdata, 'Propellerhead Software', 'Reason Recon', 'GraphicsCache')
    else:
        dirpath_userprofile = os.path.normpath(os.path.expanduser('~') )
        r = os.path.join(dirpath_userprofile, 'Library', 'Caches', 'Reason Recon', 'GraphicsCache')

    return r


# Clear the cache
def clear_recon_graphics_cache():
    import shutil

    dirpath = recon_cache_dirpath()
    if os.path.isdir(dirpath):
        if args.dry_run:
            print(f'Deleting "{dirpath}"')
        else:
            shutil.rmtree(dirpath)
            print(f'Deleted "{dirpath}"')

# Check for clearing cache
if args.clear_recon_graphics_cache:
    clear_recon_graphics_cache()

# determines '--' position
commands = args.command
native_tool_options = []
pos = next((i for i, x in enumerate(commands) if x == '--'), -1)
if pos > -1:
    commands = args.command[:pos]
    native_tool_options = args.command[pos:]

if not commands:
    parser.print_help()
    exit(0)

local45_type = 'debugging' if args.debugging else 'testing' if args.testing else 'deployment'
gui_type = 'low-res' if args.low_res else 'hi-res'

available_commands = {
    'clean':       'common-clean',
    'render':      f'common-render-{gui_type}',
    'preview':     'common-preview',
    'edit':        'common-edit',
    'uninstall':   'common-uninstall',
    'validate':    'common-validate',

    'build':       'native-build',
    'install':     f'native-install-{gui_type}',
    'test':        'native-run-test',

    'local45':     f'jbox-l45-{local45_type}-install',
    'universal45': 'jbox-u45-build',
    'validate45':  'jbox-validate45'
}

cmake_verbose = [] if not args.verbose else ['--verbose']

cmake_config = ['--config', 'Release' if args.release else 'Debug']

step = 0

for command in commands:
    step += 1
    if args.banner:
        if step > 1:
            print("")
            print("")
        print("=============================================================")
        print("==")
        print(f"== Step {step} : {command}")
        print("==")
        print("=============================================================")
    if command in available_commands:
        cmake_target = available_commands[command]
    else:
        cmake_target = command
    cmake_command = ['cmake', '--build', '.', *cmake_verbose, *cmake_config, '--target', cmake_target, *native_tool_options]
    if args.dry_run:
        print(' '.join(cmake_command))
    else:
        import sys
        import subprocess

        this_script_root_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
        cp = subprocess.run(cmake_command, cwd=this_script_root_dir)
        if cp.returncode != 0:
            import sys
            args = ' '.join(cp.args)
            print(f'Error: Command "{command}" [{args}] failed with error code {cp.returncode}', file=sys.stderr)
            exit(cp.returncode)
