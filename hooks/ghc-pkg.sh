#!/bin/bash
#
# ghc-pkg hook for haskell modules
#
# Copyright (C) 2009-2012
#       Marius Tolzmann <tolzmann@molgen.mpg.de>
#       Tobias Dreyer <dreyer@molgen.mpg.de>
#       and other bee developers
#
# This file is part of bee.
#
# bee is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

action=${1}
pkg=${2}
content=${3}

: ${content:=${BEE_METADIR}/${pkg}/CONTENT}
: ${GHC_PKG:=ghc-pkg}

if [ -z ${BEE_VERSION} ] ; then
    echo >&2 "BEE-ERROR: cannot call $0 from the outside of bee .."
    exit 1
fi

if ! type ${GHC_PKG} >/dev/null ; then
    exit 0
fi

case "${action}" in
    "post-remove"|"post-install")
        if [ "${action}" = "post-remove" ]; then
            pattern="file=.*/bee-unregister-haskell-module.sh$"
        else
            pattern="file=.*/bee-register-haskell-module.sh$"
        fi

        files=( $(grep "${pattern}" "${content}" \
                  | sed 's@.*file=@@' ) )

        if [ "${#files[@]}" -gt 1 ]; then
            echo >&2 "WARNING: found more than one (un)register script for haskell module ${pkg}"
        fi

        for file in "${files[@]}"; do
            echo "executing script: ${file}"
            ${file}
        done
        ;;
esac
