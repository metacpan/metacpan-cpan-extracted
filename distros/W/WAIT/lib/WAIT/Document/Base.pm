#                              -*- Mode: Perl -*- 
# Base.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sun Sep 15 16:09:13 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:48 1998
# Language        : CPerl
# Update Count    : 9
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Document::Base;
use Carp;
#require Tie::Hash;

#@ISA = (Tie::Hash);

sub STORE {
  croak "$_[0] is read-only\n";
}

sub CLEAR {
  croak "$_[0] is read-only\n";
}

sub close {}

1;
