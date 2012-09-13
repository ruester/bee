#!/bin/bash

PROG=beesep
COLOR_RED="\\033[0;31m"
COLOR_GREEN="\\033[0;32m"
COLOR_NORMAL="\\033[0;39m\\033[0;22m"

function test() {
    echo -n "$@"
}

function failed() {
    if [ -t 1 ]; then
        echo -e ${COLOR_RED}failed${COLOR_NORMAL}
    else
        echo failed
    fi
}

function success() {
    if [ -t 1 ]; then
        echo -e ${COLOR_GREEN}success${COLOR_NORMAL}
    else
        echo success
    fi
}

function equals() {
    local a="$1"
    local b="$2"

    if [ "$a" != "$b" ]; then
        failed
    else
        success
    fi
}

function expect_success() {
    if [ "$?" == "0" ]; then
        success
    else
        failed
    fi
}

function expect_failure() {
    if [ "$?" != "0" ]; then
        success
    else
        failed
    fi
}

test "${PROG}: Testing separation: "
OUTPUT=$(./${PROG} foo=bar:bar=foo 2>/dev/null)
COMPARE=$(echo -e "foo='bar'\nbar='foo'")
equals "${OUTPUT[@]}" "${COMPARE[@]}"

test "${PROG}: Testing escape characters: "
OUTPUT=$(./${PROG} "foo=bar':bar=f'oo" 2>/dev/null)
COMPARE=$(echo -e "foo='bar'\'''\nbar='f'\''oo'")
equals "${OUTPUT[@]}" "${COMPARE[@]}"

test "${PROG}: Testing empty values: "
OUTPUT=$(./${PROG} "foo=:bar=" 2>/dev/null)
COMPARE=$(echo -e "foo=''\nbar=''")
equals "${OUTPUT[@]}" "${COMPARE[@]}"

test "${PROG}: Testing empty key in value: "
OUTPUT=$(./${PROG} "ffff=foo:=foo:foo=bar" 2>/dev/null)
COMPARE=$(echo -e "ffff='foo:=foo'\nfoo='bar'")
equals "${OUTPUT[@]}" "${COMPARE[@]}"

test "${PROG}: Testing ':' character in value: "
OUTPUT=$(./${PROG} "file=aaa=bbbb:ccc:ffff=xxxx" 2>/dev/null)
COMPARE=$(echo -e "file='aaa=bbbb:ccc'\nffff='xxxx'")
equals "${OUTPUT[@]}" "${COMPARE[@]}"

test "${PROG}: Testing '=' character in value: "
OUTPUT=$(./${PROG} "file=foo=bar:foo=bar" 2>/dev/null)
COMPARE=$(echo -e "file='foo=bar'\nfoo='bar'")
equals "${OUTPUT[@]}" "${COMPARE[@]}"

test "${PROG}: Testing values with many ' characters: "
OUTPUT=$(./${PROG} "file='foo'bar:foo=bar:baz=b'o'b:twak='b'q'':foo=ba123':bar='''" 2>/dev/null)
COMPARE=$(echo -e "file=''\''foo'\''bar'\nfoo='bar'\nbaz='b'\''o'\''b'\ntwak=''\''b'\''q'\'''\'''\nfoo='ba123'\'''\nbar=''\'''\'''\'''")
equals "${OUTPUT[@]}" "${COMPARE[@]}"

test "${PROG}: Testing ':' character at the beginning: "
./${PROG} ":ffff=xxxx" 1>/dev/null 2>&1
expect_failure

test "${PROG}: Testing '=' character at the beginning: "
./${PROG} "=ffff=xxxx" 1>/dev/null 2>&1
expect_failure

test "${PROG}: Testing missing argument: "
./${PROG} 1>/dev/null 2>&1
expect_failure

test "${PROG}: Testing key-like value: "
./${PROG} "foo=bar:fo,o=bar" 1>/dev/null 2>&1
expect_success

test "${PROG}: Testing non-alnum characters in key: "
./${PROG} "foo,2=bar:foo=bar" 1>/dev/null 2>&1
expect_failure

test "${PROG}: Testing missing equal sign: "
./${PROG} "foo=bar:foo:bar=r" 1>/dev/null 2>&1
expect_success

test "${PROG}: Testing missing equal sign at the beginning: "
./${PROG} "foo:bar=r" 1>/dev/null 2>&1
expect_failure

test "${PROG}: Testing return value on success: "
./${PROG} "foo=bar:bar=foo" 1>/dev/null 2>&1
expect_success

exit 0
