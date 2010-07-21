#!/bin/sh


ME="`pwd`/$0"
BINDIR="`dirname $ME`"
HTMLDIR=/tmp/black-board-nytprof
EXT=".out"

[ -d "${HTMLDIR}" ] || mkdir "${HTMLDIR}" || exit 1

chdir "${BINDIR}"
for i in *.pl; do
    name="${i%.pl}"

    (
        NYTPROF="file=${BINDIR}/${name}${EXT}" perl -d:NYTProf "-I${BINDIR}/../lib" "${BINDIR}/${i}"
    ) || exit 1

    [ -d "${HTMLDIR}/${name}" ] || mkdir "${HTMLDIR}/${name}" || exit 1
    (
        cd "${HTMLDIR}/${name}"
        nytprofhtml -f "${BINDIR}/${name}${EXT}"
    ) || exit 1
done

