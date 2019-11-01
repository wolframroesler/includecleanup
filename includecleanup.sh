#!/bin/bash
# C/C++ include file cleanup
# by Wolfram Rösler 2019-11-01

BUILDCMD="cd build && make"
VERBOSE=0

# Run the build command in a subshell and forward its exit status.
# If $1 is "-e" then won't discard stderr (unless in verbose mode).
trybuild() {
    if ((VERBOSE));then
        (eval "$BUILDCMD")
    elif [ "$1" = "-e" ];then
        (eval "$BUILDCMD") >/dev/null
    else
        (eval "$BUILDCMD") &>/dev/null
    fi
}

# If no parameters are given, default to help output
[ $# = 0 ] && set -- --help

# Process command line parameters
while [ $# -gt 0 ];do

    # Process options
    if [ "$1" = "-h" -o "$1" = "--help" ];then
        # Show help
        echo "C/C++ include file clean-up"
        echo "Usage: $0 [ --build BUILDCMD ] [ --verbose ] file ..."
        echo "-b, --build: Run BUILDCMD to check if the source builds cleanly"
        echo "-v, --verbose: Verbose mode (show build output)"
        exit
    elif [ "$1" = "-b" -o "$1" = "--build" ];then
        # Define the build command
        BUILDCMD="$2"
        shift 2
        continue
    elif [ "$1" = "-v" -o "$1" = "--verbose" ];then
        # Activate verbose mode
        VERBOSE=1
        shift
        continue
    fi

    # Not an option, so it's a file name
    FILE="$1"
    shift
    if [ ! -f "$FILE" ];then
        echo "$FILE doesn't exist"
        exit 1
    fi
    echo $FILE

    # Before processing the file, check for a clean build.
    # If we don't build cleanly even before changing the
    # file, there no point in going on. Let the build's
    # stderr pass through for convenience in case of failure.
    echo -en "\tValidating build ... "
    if trybuild -e;then

        # So building unchanged source works cleanly, but will
        # the build command catch an error?
        sed -i '1i#error Testing build failure' "$FILE"
        trybuild
        RESULT=$?
        sed -i 1d "$FILE"
        if ((RESULT));then

            # Build has failed as expected
            echo "OK"
        else

            # Build passes despite the error: The build command
            # isn't useful for our purpose
            echo "Build command doesn't catch errors, skipping $FILE"
            continue
        fi
    else
        echo "No clean build with unchanged source, aborting."
        exit 1
    fi

    # For every #include in the file:
    for LINE in $(grep -n "^#include" "$FILE" | cut -d: -f1);do

        # Show the include file name
        echo -en "\tChecking" $(sed -n "${LINE}s/#include //p" "$FILE") "... "

        # Comment out this line
        sed -i "${LINE}s-^-// -" "$FILE" || exit

        # Try if it still builds
        if trybuild;then

            # It does, leave it commented out
            echo "removed!"
        else

            # Doesn't build, undo the change
            echo "needed"
            sed -i "${LINE}s-^// --" "$FILE" || exit
        fi
    done

    # Done with this file, remove the unneeded includes
    sed -i "/^\/\/ #include/d" "$FILE" || exit
done
