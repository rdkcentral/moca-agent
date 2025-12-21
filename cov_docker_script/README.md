# Generic Component Build System

Complete dependency management and build system for native components. Fully generic and driven by `component_config.json`.

---

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Script Usage](#script-usage)
- [JSON Configuration Reference](#json-configuration-reference)
- [Examples](#examples)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What It Does

Automates the complete build process for native components:
1. **Clones dependencies** from git repositories
2. **Builds libraries** using CMake, Meson, or Autotools
3. **Copies headers** to standard location
4. **Builds your component** using its build system
5. **Installs everything** to predictable locations

### Key Features

- ✅ **100% Generic** - Works with any component
- ✅ **JSON-Driven** - All configuration in one file
- ✅ **Multi Build System** - Supports autotools, CMake, Meson
- ✅ **Validated** - Checks prerequisites and configuration
- ✅ **Portable** - Copy to any component and reuse

### Files

| File | Purpose |
|------|---------|
| `setup_dependencies.sh` | Install all header and library dependencies |
| `build_native.sh` | Build your component |
| `component_config.json` | Configuration file (customize this) |
| `common_external_build.sh` | Orchestrator (runs both scripts) |

### Directory Structure After Build

```
$HOME/
├── usr/
│   ├── include/rdkb/        # All headers installed here
│   │   ├── ccsp/
│   │   ├── rbus/
│   │   └── hal_interfaces/
│   └── local/
│       └── lib/             # All libraries installed here
│           ├── librbus.so
│           ├── libtrower-base64.so
│           └── your-component/
└── build/                   # Temporary (auto-cleaned)
```

---

## Quick Start

### For Existing Components (Already Configured)

```bash
cd your-component/cov_docker_script

# Install all dependencies
./setup_dependencies.sh

# Build your component
./build_native.sh

# Or run both with one command
./common_external_build.sh
```

### For New Components

```bash
# 1. Copy the build system to your component
mkdir -p your-component/cov_docker_script
cd your-component/cov_docker_script

# Copy from template (e.g., moca-agent)
cp /path/to/moca-agent/cov_docker_script/setup_dependencies.sh .
cp /path/to/moca-agent/cov_docker_script/build_native.sh .
cp /path/to/moca-agent/cov_docker_script/common_external_build.sh .
cp /path/to/moca-agent/cov_docker_script/component_config.json .

# Make scripts executable
chmod +x *.sh

# 2. Edit component_config.json for your component
vi component_config.json
# Update: name, build_system, cflags, dependencies

# 3. Build
./setup_dependencies.sh
./build_native.sh
```

**Minimum changes needed in JSON:**
1. `native_component.name` → Your component name
2. `native_component.build_system` → autotools/cmake/meson
3. `native_component.cflags` → Your compiler flags
4. `header_dependencies` → Your header-only repos
5. `library_dependencies` → Your library repos

---

## Script Usage

### setup_dependencies.sh

Installs all dependencies defined in `component_config.json`.

**What it does:**
1. Clones header-only dependencies
2. Copies headers to `$HOME/usr/include/rdkb/`
3. Clones library dependencies
4. Builds libraries (CMake/Meson/Autotools)
5. Installs libraries to `$HOME/usr/local/lib/`
6. Cleans up build artifacts

**Usage:**
```bash
./setup_dependencies.sh
```

**Environment Variables:**
```bash
# Change installation paths
export HEADER_PREFIX=$HOME/custom/include
export INSTALL_PREFIX=$HOME/custom/lib
export BUILD_DIR=/tmp/build
export BUILD_JOBS=16

./setup_dependencies.sh
```

**Options via JSON:**
```json
{
  "build_options": {
    "skip_header_dependencies": false,    // Skip header cloning
    "skip_library_dependencies": false,   // Skip library building
    "clean_before_build": true            // Clean previous builds
  }
}
```

---

### build_native.sh

Builds your native component.

**What it does:**
1. Reads component configuration from JSON
2. Applies source patches if defined
3. Runs pre-build commands
4. Configures build system (./configure, cmake, or meson)
5. Builds component with make/ninja
6. Installs libraries and headers

**Usage:**
```bash
./build_native.sh
```

**Environment Variables:**
```bash
# Same as setup_dependencies.sh
export HEADER_PREFIX=$HOME/custom/include
export INSTALL_PREFIX=$HOME/custom/lib
export BUILD_JOBS=8

./build_native.sh
```

---

### common_external_build.sh

Orchestrator that runs both scripts in sequence.

**Usage:**
```bash
./common_external_build.sh
```

Equivalent to:
```bash
./setup_dependencies.sh && ./build_native.sh
```

---

## JSON Configuration Reference

### Complete Structure

```json
{
  "build_options": { ... },
  "native_component": { ... },
  "header_dependencies": [ ... ],
  "library_dependencies": [ ... ]
}
```

---

### build_options

Controls global build behavior.

```json
{
  "build_options": {
    "skip_header_dependencies": false,
    "skip_library_dependencies": false,
    "clean_before_build": true,
    "auto_discover_libraries": true
  }
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `skip_header_dependencies` | boolean | false | Skip cloning/copying headers |
| `skip_library_dependencies` | boolean | false | Skip building libraries |
| `clean_before_build` | boolean | true | Remove previous installations |
| `auto_discover_libraries` | boolean | true | Auto-find .so/.a files to install |

**Use Cases:**
- Incremental builds: `"clean_before_build": false`
- Headers only: `"skip_library_dependencies": true`
- Skip all deps: Both skip flags = `true`

---

### native_component

Your component's build configuration.

#### Required Fields

```json
{
  "native_component": {
    "name": "my-component",
    "build_system": "autotools"
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **YES** | Component name |
| `build_system` | string | **YES** | "autotools", "cmake", or "meson" |

#### Compiler/Linker Flags

```json
{
  "native_component": {
    "cflags": ["-DSAFEC_DUMMY_API", "-D_DEBUG", "-O2"],
    "ldflags": ["-Wl,--allow-shlib-undefined"],
    "system_includes": ["/usr/include/dbus-1.0"],
    "dependency_include_dirs": ["$HOME/usr/include/rdkb/hal"]
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `cflags` | array | Compiler flags |
| `ldflags` | array | Linker flags |
| `system_includes` | array | System header paths (supports *) |
| `dependency_include_dirs` | array | Additional include paths |

#### Build System Options

**Autotools:**
```json
{
  "build_system": "autotools",
  "configure_options": ["--enable-shared", "--disable-static"]
}
```

**CMake:**
```json
{
  "build_system": "cmake",
  "cmake_options": [
    "-DCMAKE_BUILD_TYPE=Release",
    "-DENABLE_TESTS=OFF"
  ]
}
```

**Meson:**
```json
{
  "build_system": "meson",
  "meson_options": ["-Dtests=disabled"]
}
```

#### Source Patches

**Insert text before a line:**
```json
{
  "source_header_patches": [
    {
      "source": "$HOME/usr/include/rdkb/header.h",
      "patch_line": "typedef struct SomeStruct",
      "insert_before": "typedef struct PrereqStruct PrereqStruct;"
    }
  ]
}
```

**Search and replace:**
```json
{
  "source_header_patches": [
    {
      "source": "source/file.c",
      "type": "replace",
      "search": "old_function(arg1)",
      "replace": "new_function(arg1, arg2)"
    }
  ]
}
```

**Sed command:**
```json
{
  "source_header_patches": [
    {
      "source": "source/file.c",
      "type": "replace",
      "sed_command": "s/OldFunc(\\(.*\\))$/NewFunc(\\1, NULL)/g"
    }
  ]
}
```

#### Pre-Build Commands

```json
{
  "pre_build_commands": [
    {
      "description": "Generate code from XML",
      "command": "python3 $HOME/usr/include/rdkb/codegen.py input.xml output.c"
    }
  ]
}
```

#### Component Installation

**Install headers:**
```json
{
  "component_header_dirs": [
    {
      "source": "include",
      "destination": "mycomponent"
    }
  ]
}
```

**Install libraries (manual patterns):**
```json
{
  "component_libraries": ["source/**/*.so"],
  "component_install_subdir": "mycomponent"
}
```

---

### header_dependencies

Header-only dependencies (no build required).

```json
{
  "header_dependencies": [
    {
      "name": "rdkb-halif-wifi",
      "repository": "https://github.com/rdkcentral/rdkb-halif-wifi.git",
      "branch": "main",
      "header_paths": [
        {
          "source": "include",
          "destination": "."
        }
      ]
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Dependency name |
| `repository` | string | Git URL |
| `branch` | string | Git branch |
| `header_paths` | array | Source→destination mappings |
| `header_paths[].source` | string | Path in repo |
| `header_paths[].destination` | string | Path under `$HOME/usr/include/rdkb/` |

---

### library_dependencies

Libraries that need to be built.

**CMake Library:**
```json
{
  "library_dependencies": [
    {
      "name": "rbus",
      "repository": "https://github.com/rdkcentral/rbus.git",
      "branch": "main",
      "build_system": "cmake",
      "cmake_options": ["-DBUILD_TESTING=OFF"]
    }
  ]
}
```

**Autotools Library:**
```json
{
  "library_dependencies": [
    {
      "name": "libsafec",
      "repository": "https://github.com/rdkcentral/libsafec.git",
      "branch": "main",
      "build_system": "autotools",
      "configure_options": ["--enable-shared"]
    }
  ]
}
```

**Meson Library:**
```json
{
  "library_dependencies": [
    {
      "name": "msgpack",
      "repository": "https://github.com/msgpack/msgpack-c.git",
      "branch": "master",
      "build_system": "meson",
      "meson_options": ["-Ddefault_library=shared"]
    }
  ]
}
```

**With source subdirectory:**
```json
{
  "name": "protobuf",
  "repository": "https://github.com/protocolbuffers/protobuf.git",
  "branch": "main",
  "build_system": "cmake",
  "source_subdir": "cmake",
  "cmake_options": ["-Dprotobuf_BUILD_TESTS=OFF"]
}
```

**With dependency script:**
```json
{
  "name": "complex-lib",
  "repository": "https://github.com/example/lib.git",
  "branch": "main",
  "build_system": "cmake",
  "dependency_script": "setup_deps.sh",
  "cmake_options": ["-DBUILD_SHARED_LIBS=ON"]
}
```

**Complete field reference:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | YES | Library name |
| `repository` | string | YES | Git URL |
| `branch` | string | YES | Git branch |
| `build_system` | string | YES | autotools/cmake/meson/custom |
| `configure_options` | array | No | Autotools options |
| `cmake_options` | array | No | CMake options |
| `meson_options` | array | No | Meson options |
| `source_subdir` | string | No | Build subdirectory |
| `dependency_script` | string | No | Pre-build script |
| `source_patches` | array | No | Patches to apply |

---

## Examples

### Example 1: Simple Autotools Component

```json
{
  "build_options": {
    "skip_header_dependencies": false,
    "skip_library_dependencies": false,
    "clean_before_build": true,
    "auto_discover_libraries": true
  },
  "native_component": {
    "name": "simple-daemon",
    "build_system": "autotools",
    "cflags": ["-O2", "-Wall"],
    "system_includes": [],
    "dependency_include_dirs": [],
    "ldflags": [],
    "configure_options": ["--enable-shared"],
    "source_header_patches": [],
    "pre_build_commands": [],
    "component_header_dirs": [],
    "component_libraries": [],
    "component_install_subdir": ""
  },
  "header_dependencies": [],
  "library_dependencies": []
}
```

### Example 2: WiFi Agent with Dependencies

```json
{
  "build_options": {
    "skip_header_dependencies": false,
    "skip_library_dependencies": false,
    "clean_before_build": true,
    "auto_discover_libraries": true
  },
  "native_component": {
    "name": "wifi-agent",
    "build_system": "autotools",
    "cflags": ["-DENABLE_WIFI_6", "-D_DEBUG"],
    "system_includes": ["/usr/include/libnl3"],
    "dependency_include_dirs": ["$HOME/usr/include/rdkb/wifi_hal"],
    "ldflags": ["-Wl,--allow-shlib-undefined"],
    "configure_options": ["--enable-shared"],
    "source_header_patches": [],
    "pre_build_commands": [],
    "component_header_dirs": [],
    "component_libraries": [],
    "component_install_subdir": "wifi"
  },
  "header_dependencies": [
    {
      "name": "rdkb-halif-wifi",
      "repository": "https://github.com/rdkcentral/rdkb-halif-wifi.git",
      "branch": "main",
      "header_paths": [
        {
          "source": "include",
          "destination": "."
        }
      ]
    }
  ],
  "library_dependencies": [
    {
      "name": "rbus",
      "repository": "https://github.com/rdkcentral/rbus.git",
      "branch": "main",
      "build_system": "cmake",
      "cmake_options": ["-DBUILD_TESTING=OFF"]
    }
  ]
}
```

### Example 3: CMake Component with Code Generation

```json
{
  "build_options": {
    "skip_header_dependencies": false,
    "skip_library_dependencies": false,
    "clean_before_build": true,
    "auto_discover_libraries": false
  },
  "native_component": {
    "name": "my-cmake-app",
    "build_system": "cmake",
    "cflags": ["-DCUSTOM_BUILD", "-O3"],
    "system_includes": [],
    "dependency_include_dirs": [],
    "ldflags": [],
    "cmake_options": [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DENABLE_TESTS=OFF"
    ],
    "source_header_patches": [],
    "pre_build_commands": [
      {
        "description": "Generate protocol buffers",
        "command": "protoc --cpp_out=src proto/*.proto"
      }
    ],
    "component_header_dirs": [
      {
        "source": "include",
        "destination": "myapp"
      }
    ],
    "component_libraries": ["build/lib/*.so"],
    "component_install_subdir": "myapp"
  },
  "header_dependencies": [],
  "library_dependencies": [
    {
      "name": "protobuf",
      "repository": "https://github.com/protocolbuffers/protobuf.git",
      "branch": "main",
      "build_system": "cmake",
      "source_subdir": "cmake",
      "cmake_options": ["-Dprotobuf_BUILD_TESTS=OFF"]
    }
  ]
}
```

### Example 4: Component with Patches

```json
{
  "build_options": {
    "skip_header_dependencies": false,
    "skip_library_dependencies": false,
    "clean_before_build": true,
    "auto_discover_libraries": true
  },
  "native_component": {
    "name": "patched-component",
    "build_system": "autotools",
    "cflags": ["-DSAFEC_DUMMY_API"],
    "system_includes": ["/usr/include/dbus-1.0"],
    "dependency_include_dirs": [],
    "ldflags": [],
    "configure_options": [],
    "source_header_patches": [
      {
        "source": "$HOME/usr/include/rdkb/ccsp_message_bus.h",
        "patch_line": "typedef struct _CCSP_MESSAGE_BUS_CONNECTION",
        "insert_before": "typedef struct DBusLoop DBusLoop;"
      },
      {
        "source": "source/main.c",
        "type": "replace",
        "sed_command": "s/OldFunc(arg1, arg2)$/NewFunc(arg1, arg2, NULL)/g"
      }
    ],
    "pre_build_commands": [
      {
        "description": "Generate datamodel",
        "command": "python3 $HOME/usr/include/rdkb/codegen.py config.xml output.c"
      }
    ],
    "component_header_dirs": [],
    "component_libraries": [],
    "component_install_subdir": ""
  },
  "header_dependencies": [
    {
      "name": "CcspCommonLibrary",
      "repository": "https://github.com/rdkcentral/common-library.git",
      "branch": "main",
      "header_paths": [
        {
          "source": "source/ccsp/include",
          "destination": "."
        }
      ]
    }
  ],
  "library_dependencies": []
}
```

---

## Advanced Usage

### Environment Variables

```bash
# Header installation path
export HEADER_PREFIX=$HOME/custom/include

# Library installation path
export INSTALL_PREFIX=$HOME/custom/lib

# Build directory
export BUILD_DIR=/tmp/build

# Parallel jobs
export BUILD_JOBS=16

./setup_dependencies.sh
./build_native.sh
```

### Incremental Builds

```json
{
  "build_options": {
    "skip_header_dependencies": true,
    "skip_library_dependencies": true,
    "clean_before_build": false
  }
}
```

### Cross-Compilation

**CMake:**
```json
{
  "native_component": {
    "build_system": "cmake",
    "cmake_options": [
      "-DCMAKE_SYSTEM_NAME=Linux",
      "-DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc",
      "-DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++"
    ]
  }
}
```

**Autotools:**
```json
{
  "native_component": {
    "build_system": "autotools",
    "configure_options": [
      "--host=aarch64-linux-gnu",
      "--build=x86_64-linux-gnu"
    ]
  }
}
```

### Debug Mode

```bash
bash -x ./setup_dependencies.sh
bash -x ./build_native.sh
```

### Reset Everything

```bash
rm -rf $HOME/usr $HOME/build
./setup_dependencies.sh
./build_native.sh
```

---

## Troubleshooting

### Common Errors

**"jq is not installed"**
```bash
sudo apt-get install jq
```

**"git is not installed"**
```bash
sudo apt-get install git
```

**"Missing required field in JSON"**
```bash
# Validate JSON syntax
jq empty component_config.json

# Check required fields exist:
# - build_options
# - native_component
# - native_component.name
# - native_component.build_system
# - header_dependencies
# - library_dependencies
```

**"configure: command not found"**
```json
{
  "pre_build_commands": [
    {
      "description": "Generate configure",
      "command": "./autogen.sh"
    }
  ]
}
```

**Library not found during build**
1. Check dependencies built: `ls $HOME/usr/local/lib`
2. Verify PKG_CONFIG_PATH (scripts handle automatically)
3. Check library names for typos

**Headers not found during build**
1. Check headers installed: `ls $HOME/usr/include/rdkb`
2. Add to `dependency_include_dirs`:
```json
{
  "native_component": {
    "dependency_include_dirs": ["$HOME/usr/include/rdkb/missing_hal"]
  }
}
```

**Permission denied**
```bash
chmod -R u+w $HOME/usr $HOME/build
rm -rf $HOME/usr $HOME/build
```

### Validation Checklist

- [ ] `component_config.json` exists
- [ ] JSON syntax valid: `jq empty component_config.json`
- [ ] `native_component.name` set
- [ ] `native_component.build_system` correct
- [ ] Dependencies listed
- [ ] Scripts executable: `chmod +x *.sh`

---

## Summary

### Workflow

1. Copy scripts to your component
2. Edit `component_config.json`
3. Run `./setup_dependencies.sh`
4. Run `./build_native.sh`

### Key Points

- ✅ Scripts are **100% generic**
- ✅ All config in **component_config.json**
- ✅ Supports **autotools/cmake/meson**
- ✅ **Validated** with clear errors
- ✅ **Reusable** across components

### Files

```
cov_docker_script/
├── README.md                   ← This file
├── setup_dependencies.sh       ← Install dependencies
├── build_native.sh             ← Build component
├── common_external_build.sh    ← Run both
└── component_config.json       ← Your configuration
```

**That's it!** Copy, configure, build.
