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

script_name = ''

if platform.system() == 'Darwin':
    script_name = 're.sh'
else:
    script_name = 're.bat'


parser = argparse.ArgumentParser(allow_abbrev=False,
                                 usage=f'{script_name} [-hnvbdtR] <command> [<command> ...] [-- [native-options]]',
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog='''
Commands
  ---- Native build commands ----
  build       : build the RE (.dylib)
  install     : build (code/gui) and install the RE for use in Recon

  ---- Jbox build commands (build45 / sandbox toolchain) ----
  local45     : build (code/gui) and install the RE for use in Recon ('Deployment' type or -d/-t to change) 
  universal45 : build the package for uploading to Reason Studio servers (.u45)
  validate45  : runs the Recon validate process on local45 (equivalent to ./re.sh local45 validate)

  ---- Common commands ----
  clean       : clean all builds
  render      : runs RE2DRender to generate the GUI (necessary for running in Recon)
  preview     : runs RE2DPreview to generate the device preview (useful for shop images)
  uninstall   : deletes the installed RE
  validate    : runs the Recon validate process on the currently installed plugin

  ---- CMake target ----
  <command>   : Any unknown <command> is treated as a cmake target
  
  --- Native options ----
  Pass remaining options to the native tool (ex: -- -j 8 for parallel build) 
''')
parser.add_argument("-n", "--dry-run", help="Dry run (prints what it is going to do)", action="store_true", dest="dry_run")
parser.add_argument("-v", "--verbose", help="Verbose build", action="store_true")
parser.add_argument("-b", "--banner", help="Display a banner before every command", action="store_true")
parser.add_argument("-d", "--debugging", help="Use 'Debugging' for local45 command", action="store_true")
parser.add_argument("-t", "--testing", help="Use 'Testing' for local45 command", action="store_true")
parser.add_argument("-R", "--release", help="Invoke CMake in Release mode (for multi-config generators)", action="store_true")
parser.add_argument('command', help='See "Commands" section', nargs=argparse.REMAINDER)

args = parser.parse_args()

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

available_commands = {
    'clean':       'common-clean',
    'render':      'common-render',
    'preview':     'common-preview',
    'uninstall':   'common-uninstall',
    'validate':    'common-validate',

    'build':       'native-build',
    'install':     'native-install',

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
        import os
        import sys
        import subprocess

        this_script_root_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
        cp = subprocess.run(cmake_command, cwd=this_script_root_dir)
        if cp.returncode != 0:
            import sys
            args = ' '.join(cp.args)
            print(f'Error: Command "{command}" [{args}] failed with error code {cp.returncode}', file=sys.stderr)
            exit(cp.returncode)
