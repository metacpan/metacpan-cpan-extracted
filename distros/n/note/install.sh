#!/bin/sh
# installer for note 0.8 >

# $Id: install.sh,v 1.1 2000/03/19 03:33:28 thomas Exp thomas $

die ()
{
	MSG=$1
	echo $MSG
	exit 1
}

SRC=.

NOTEDB="$SRC/NOTEDB"

BIN="$SRC/bin"

echo "Enter the destination for the note perl modules [/usr/local/lib] :"

read LIBDIR

echo "Enter the destination for the note program [/usr/local/bin] :"

read BINDIR

if [ "${LIBDIR}" = "" ] ; then
	LIBDIR=/usr/local/lib
fi

if [ "${BINDIR}" = "" ] ; then
	BINDIR=/usr/local/bin
fi

if [ ! -d ${LIBDIR} ] ; then
	mkdir -p ${LIBDIR} || die "Could not create ${LIBDIR}!"
fi

if [ ! -d ${BINDIR} ] ; then
	mkdir -p ${BINDIR} || die "Could not create ${BINDIR}!"
fi

echo "Installing note ..."

cp -ri ${NOTEDB} ${LIBDIR} || die "Could not copy modules!"

cp -i "${BIN}/note" ${BINDIR} || die "Could not copy note script!"

chmod 755 ${BINDIR}/note
chmod 755 ${LIBDIR}/NOTEDB
chmod 644 ${LIBDIR}/NOTEDB/*

echo "done. Please copy ${SRC}/config/noterc to ~/.noterc"
echo "and edit it if you like. "
echo
echo "Thanks for using note 0.8!"
