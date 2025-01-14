#!/bin/sh

# /bin/sh on Solaris is not a POSIX compatible shell, but /usr/bin/ksh is.
if [ `uname -s` = 'SunOS' -a "${POSIX_SHELL}" != "true" ]; then
    POSIX_SHELL="true"
    export POSIX_SHELL
    exec /usr/bin/ksh $0 $@
fi
unset POSIX_SHELL # clear it so if we invoke other scripts, they run as ksh as well

LEVELDB_VSN="2.0.35"

set -e

if [ `basename $PWD` != "c_src" ]; then
    # originally "pushd c_src" of bash
    # but no need to use directory stack push here
    cd c_src
fi

BASEDIR="$PWD"

# detecting gmake and if exists use it
# if not use make
# (code from github.com/tuncer/re2/c_src/build_deps.sh
which gmake 1>/dev/null 2>/dev/null && MAKE=gmake
MAKE=${MAKE:-make}

# Changed "make" to $MAKE

case "$1" in
    rm-deps)
        rm -rf leveldb system
        ;;

    clean)
        rm -rf system
        if [ -d leveldb ]; then
            (cd leveldb && $MAKE clean)
        fi
        ;;

    test)
        export CFLAGS="$CFLAGS -I $BASEDIR/system/include"
        export CXXFLAGS="$CXXFLAGS -I $BASEDIR/system/include"
        export LDFLAGS="$LDFLAGS -L$BASEDIR/system/lib"
        export LD_LIBRARY_PATH="$BASEDIR/system/lib:$LD_LIBRARY_PATH"

        (cd leveldb && $MAKE check)

        ;;

    get-deps)
        if [ ! -d leveldb ]; then
            git clone https://github.com/basho/leveldb
            (cd leveldb && git checkout $LEVELDB_VSN && \
                    curl -fSL https://patch-diff.githubusercontent.com/raw/ioolkos/leveldb/pull/1.diff -o 1.diff && \
                    patch -p1 -i 1.diff && \
                    rm -rf 1.diff)
        fi
        ;;

    *)
        export MACOSX_DEPLOYMENT_TARGET=10.8

        export CFLAGS="$CFLAGS -I $BASEDIR/system/include"
        export CXXFLAGS="$CXXFLAGS -I $BASEDIR/system/include"
        export LDFLAGS="$LDFLAGS -L$BASEDIR/system/lib"
        export LD_LIBRARY_PATH="$BASEDIR/system/lib:$LD_LIBRARY_PATH"
        export LEVELDB_VSN="$LEVELDB_VSN"

        if [ ! -d leveldb ]; then
            git clone https://github.com/basho/leveldb
            (cd leveldb && git checkout $LEVELDB_VSN && \
                    curl -fSL https://patch-diff.githubusercontent.com/raw/ioolkos/leveldb/pull/1.diff -o 1.diff && \
                    patch -p1 -i 1.diff && \
                    rm -rf 1.diff)
        fi

        (cd leveldb && $MAKE -j 3 all)

        ;;
esac
