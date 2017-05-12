#!/bin/sh
#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

# Create a repository and sandbox for testing lcvs-st

# The repository and sandbox contain files with many different states.
# Hopefully all those that are relevant to lcvs-st.

# The name of the directory in which everything is to be created is expected as
# arg1 to the script.  Within this directory will be created directories called
# repository, sandbox1, sandbox2.  A CVS repository will be created in
# repository, and checked out into sandbox[12].  Then files will be created in
# the repository and manipulated in the working directories, in order to
# provide all the possible states recognized by lcvs-st.  The test should be run
# from sandbox1 where each file will have the same name as the three letter
# status code reported by lcvs-st.  (Including some absent from the working
# directory.)

################################################################################

### Create the repository and working directories

base=$1

if [ -z $base ] ; then
  echo "$0: Base directory not specified" 1>&2
  exit 1
fi
if [ -e $base/repository ] ; then 
  echo -e \\n"Repository exists, skipping creation" 1>&2
  exit 0
fi

echo -n -e \\n"Creating test repository, please be patient:" 1>&2

mkdir -p $base/repository
cd $base

export CVSROOT=$base/repository
cvs init
mkdir repository/dir1

mkdir sandbox1
cd sandbox1
cvs co dir1 > /dev/null 2>&1
cd ..

mkdir sandbox2
cd sandbox2
cvs co dir1 > /dev/null 2>&1
cd ..

### Define routines for manipulating files, including CVS operations

# Basic routines:
# Each routine expects to be in the sandbox directory, and uses the variable
# $name as the name of the file

Commit () { cvs ci -m '' $name > /dev/null 2>&1 ; }
Update () { cvs up $name > /dev/null 2>&1 ; }
Checkout () { cvs co $name > /dev/null 2>&1 ; }
Add    () { cvs add $name > /dev/null 2>&1 ; }
Remove () { rm -f $name ; cvs rm -f $name > /dev/null 2>&1 ; }
Modify () { newData=$(( $newData + 1 ))
    i=0; while [ $i -le 10 ] ; do echo $newData >> $name ; i=$(( $i + 1 )); done
}

# Change the top of the file, not the bottom, won't conflict with other modify
ModifyTop () { 
    newData=$(( $newData + 1 )) ; 
    echo $newData > ${name}-foo ;
    if [ -f "$name" ] ; then 
        cat $name >> ${name}-foo ;
    fi
    mv ${name}-foo $name
}

# Change working directory from one sandbox to the other
toggle_dir () { cd $(pwd | sed "s#^$base/sandbox1#xxxxxxxxxxxxxx#
                                s#^$base/sandbox2#$base/sandbox1#
                                s#^xxxxxxxxxxxxxx#$base/sandbox2#") ; }

# Advanced routines:

# They expect to be in the sandbox directory, and they put the file named $name
# into a specific state.  See the lcvs-st and LibCVS documentation for
# explanation of the various states.  The routines are in three groups to
# reflect the three types of state: Local Admin State, Local File State, and
# Repository State.  They are named by taking their state type (la, lf, rs) and
# appending the state to it (eg. N, U, A, R for Local Admin).

# Assumptions:
#   + Variable $name is the name of the file
#   + $base/sandbox[12] are defined
#   + current working directory is $base/sandbox1/dir1

# The routines uses this variable to communicate:
inRepository=false     # true if file $name has been committed to the repository
                       # and is not in the Attic

### 1] Local Admin State

# None
laN () { true ; }

# Available
laU () { Modify; Add; Commit; inRepository=true; }

# Added
laA () { Modify; Add; }

# Removed
laR () { Modify; Add; Commit; Remove; inRepository=true; }


### 2] Local File State

# Up-To-Date  
# After step 1] this will always be U
lfU () { true ; }

# Absent
lfB () { rm -f $name ; }

# Modified
lfM () { Modify ; }

# Modified with Conflict
lfC () {
    if ! $inRepository ; then
        Modify; Add; Commit; inRepository=true
    else
        Update
    fi

    Modify

    toggle_dir

    Update; Modify; Commit

    toggle_dir

    Update
}

### 3] Repository State

# Up-To-Date
rsU () { true ; }

# Absent
rsB () { cd $base/repository/dir1; rm -f $name,v ; cd $base/sandbox1/dir1 ; }

# Modified
rsM () {
    toggle_dir
    if ! $inRepository ; then
        Modify; Add; Commit; inRepository=true
    else
        Update; ModifyTop; Commit
    fi
    toggle_dir
}

# Modified will Conflict
# We can assume that the file is already locally modified,
# since this status only makes sense in those cases.
rsC () {
    if ! $inRepository ; then
        Modify; Add; Commit; inRepository=true
    fi

    toggle_dir

    Update; Modify; ModifyTop; Commit

    toggle_dir
}

### Now create all of the files.
# Loop through all the possible cases, but skip some of the impossible ones.
# Files are named by their state as it is seen from sandbox1.

cd $base/sandbox1/dir1 > /dev/null

for localRev in A N R U ; do

for localState in B C M U ; do

# report progress
echo -n . 1>&2

for reposState in B M U C; do

    name=$localRev$localState$reposState

    # Skip impossible situations

    # NUU, no file anywhere, won't appear in lcvs-st output
    if [ $name = "NUU" ] ; then continue ; fi
    # If there's no local revision it can't be locally or remotely absent
    if [ $localRev = "N" ] ; then
        if [ $localState = "B" -o $reposState = "B" ] ; then continue ; fi
    fi
    # Locally Added means that repository absent is "Up-To-Date"
    if [ $localRev = "A" -a $reposState = "B" ] ; then continue ; fi
    # Locally Added means that can't be locally modified
    if [ $localRev = "A" -a $localState = "M" ] ; then continue ; fi
    # Locally Removed means that can't be locally absent
    if [ $localRev = "R" -a $localState = "B" ] ; then continue ; fi
    # Locally Modified/Conflict means there must be a local revision
    if [ $localState = "C" -a ! $localRev = "U" ] ; then continue ; fi
    # Will Conflict on Merge means must be locally modified, and have state
    if [ $reposState = "C" ] ; then
        if [ $localState != "M" -a $localState != "C" ] ; then continue ; fi
        if [ $localRev != "U" ] ; then continue ; fi
    fi

    # Initialize communication between the routines
    inRepository=false

    # Call the advanced routines for this file
    eval la$localRev
    eval lf$localState
    eval rs$reposState

done
done
done

echo done 1>&2
