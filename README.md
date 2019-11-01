# C/C++ Include File Cleanup

Have you ever wondered how many of your C/C++ source files contain `#include`s that aren't needed? That were put in at some point during development but have become obsolete as the source code evolved?

The usual way to check for unneeded includes is to comment out a `#include` line and see if the program still builds. If it does, the `#include` was unneeded and can be removed. If the build fails, it's still needed, so you leave it in.

Well, that's essentially what the `includecleanup.sh` script does for you.

## Prerequsites

Requires bash and sed.

## Installation

No installation required. Just copy `includecleanup.sh` somewhere and run it with bash, or put it on your $PATH and make it executable. The following examples simply assume that `includecleanup.sh` is in the current directory.

## What It Does

In the C/C++ source files specified on the command line, the script iterates over all `#include` lines, comments them out (by adding `// ` at the beginning of the line), and checks if the source still builds successfully. If it does, the `#include` is obviously not needed, and the line is removed from the file; if the build fails, the change is undone.

The script will never modify any file that's not specified on the command line.

## How To Use It

The script will modify your source code so you want to start with a clean working tree. So, if anything doesn't work to your liking, you can `git reset --hard` to undo any changes.

On the command line, pass the names of the C/C++ files that you want checked. For example:

```
$ bash includecleanup.sh *.c *.cpp
```

or, to process files in subdirectories:

```
$ bash includecleanup.sh $(find . -name "*.cpp")
```

The script requires a _build command_, i. e. a shell command that compiles the source files we're checking and that fails if we removed a `#include` that's still needed. The default build command is `cd build && make`; you can supply your own build command with the `--build` option, for example

```
$ bash includecleanup.sh --build "cd mybuild && make -j myproject" *.cpp
```

When the script is done, use `git diff` to review the changes before committing them.

## More Information

The script will abort if the build command fails on unchanged sources (e. g. because there's no `build` directory). If the build command fails to catch errors in one of the specified source files (e. g. because it contains something like `make myproject` but the source file isn't compiled as part of that project, or if you're building on Linux but the source file is only compiled on macOS), that source file is skipped (=not processed any further and left unchanged).

The script only processes `#include` at the beginning of a line (with no white space in front of it, and no white space after the `#`). It doesn't care if the `#include` is within `/* ... */` or `#ifdef ... #endif`, in which case it will happily remove it because the build still works. That means that platform-dependent includes may be removed when building on another platform, so be careful when using the script on multi-platform code.

If the script is aborted, the current file may be left in a modified state (with one or more `#include`s comment out) that may or may not build. If this happens, use git to revert to the previous version.

If any source file contains a `#include` that is commented out with `// ` at the beginning of the line, that line will also be removed from the file.

The script decides whether a `#include` can be removed entirely based on whether removing it breaks the build. Under certain circumstances, however, removing a `#include` can change the semantics of the program without breaking the build; in these cases, the script would remove it anyway. Imagine you had the following two include files:

```cpp
// magic1.h
#define MAGIC 1
```

```cpp
// magic2.h
#ifndef MAGIC
#define MAGIC 0
#endif
```

Now, if your source file contained

```cpp
#include <magic1.h>
#include <magic2.h>
```

then `includecleanup.sh` would remove `#include <magic1.h>` because the program still builds without it, but this silently changes the value of `MAGIC` seen by the program. For that reason, always review the results of the script and test your program thoroughly before comitting the changes. Also, avoid such stunts.

Use the `--verbose` option to display all build output.

Run the script with `--help` or without any parameters for command line help.

## Practical Example

Running `includecleanup.sh` on a subdirectory of the source code of [KeePassXC](https://github.com/keepassxreboot/keepassxc).

```
$ cd keepassxc

$ git status
On branch develop
Your branch is up to date with 'origin/develop'.

nothing to commit, working tree clean

$ bash ~/Nextcloud/src/includecleanup/includecleanup.sh --build "cd build && make -j4" src/gui/dbsettings/*.cpp
src/gui/dbsettings/DatabaseSettingsDialog.cpp
	Validating build ... OK
	Checking "DatabaseSettingsDialog.h" ... removed!
	Checking "ui_DatabaseSettingsDialog.h" ... needed
	Checking "DatabaseSettingsPageStatistics.h" ... needed
	Checking "DatabaseSettingsWidgetEncryption.h" ... needed
	Checking "DatabaseSettingsWidgetGeneral.h" ... needed
	Checking "DatabaseSettingsWidgetMasterKey.h" ... needed
	Checking "DatabaseSettingsWidgetBrowser.h" ... needed
	Checking "keeshare/DatabaseSettingsPageKeeShare.h" ... needed
	Checking "fdosecrets/DatabaseSettingsPageFdoSecrets.h" ... needed
	Checking "core/Config.h" ... needed
	Checking "core/Database.h" ... removed!
	Checking "core/FilePath.h" ... needed
	Checking "core/Global.h" ... removed!
	Checking "touchid/TouchID.h" ... removed!
src/gui/dbsettings/DatabaseSettingsPageStatistics.cpp
	Validating build ... OK
	Checking "DatabaseSettingsPageStatistics.h" ... needed
	Checking "DatabaseSettingsWidgetStatistics.h" ... needed
	Checking "core/Database.h" ... removed!
	Checking "core/FilePath.h" ... needed
	Checking "core/Group.h" ... removed!
	Checking <QApplication> ... needed
src/gui/dbsettings/DatabaseSettingsWidget.cpp
	Validating build ... OK
	Checking "DatabaseSettingsWidget.h" ... needed
	Checking "core/Database.h" ... removed!
	Checking <utility> ... removed!
	Checking <QTimer> ... removed!
	Checking <QWidget> ... removed!
...

$ git diff -U0
diff --git a/src/gui/dbsettings/DatabaseSettingsDialog.cpp b/src/gui/dbsettings/DatabaseSettingsDialog.cpp
index 33c4df2c..9225a096 100644
--- a/src/gui/dbsettings/DatabaseSettingsDialog.cpp
+++ b/src/gui/dbsettings/DatabaseSettingsDialog.cpp
@@ -19 +18,0 @@
-#include "DatabaseSettingsDialog.h"
@@ -37 +35,0 @@
-#include "core/Database.h"
@@ -39,2 +36,0 @@
-#include "core/Global.h"
-#include "touchid/TouchID.h"
diff --git a/src/gui/dbsettings/DatabaseSettingsPageStatistics.cpp b/src/gui/dbsettings/DatabaseSettingsPageStatistics.cpp
index 6fe24ff0..53929f04 100644
--- a/src/gui/dbsettings/DatabaseSettingsPageStatistics.cpp
+++ b/src/gui/dbsettings/DatabaseSettingsPageStatistics.cpp
@@ -21 +20,0 @@
-#include "core/Database.h"
@@ -23 +21,0 @@
-#include "core/Group.h"
diff --git a/src/gui/dbsettings/DatabaseSettingsWidget.cpp b/src/gui/dbsettings/DatabaseSettingsWidget.cpp
index 224c4e56..718ecb58 100644
--- a/src/gui/dbsettings/DatabaseSettingsWidget.cpp
+++ b/src/gui/dbsettings/DatabaseSettingsWidget.cpp
@@ -19 +18,0 @@
-#include "core/Database.h"
@@ -21 +19,0 @@
-#include <utility>
@@ -23,2 +20,0 @@
-#include <QTimer>
-#include <QWidget>
...
```

---
*Wolfram Rösler • wolfram@roesler-ac.de • https://gitlab.com/wolframroesler • https://twitter.com/wolframroesler • https://www.linkedin.com/in/wolframroesler/*
