#!/usr/bin/perl

; use Sub::Uplevel
; use strict
; use warnings
; package main

; use Test::More tests => 5

; BEGIN { use_ok( 'basis' ) }
########################################################
# Test with inline classes

; package My::Base

; sub import { $My::Base::v="i" }

; my $skip
; BEGIN
    { eval "require parent"
    ; $skip = !!$@
    }

; SKIP:
    { package main
    ; skip("parent specific test",4) if $skip
    ; local $basis::base = 'parent';
    ; package My::Shoe
    ; eval "use basis -norequire => 'My::Base'"

    ; package main
    ; ok(! My::Shoe->isa("Sub::Uplevel"))
    ; ok(! My::Shoe->isa("parent"))
    ; ok(My::Shoe->isa("My::Base") , "isa")
    ; is($My::Base::v , "i"        , "import call")
    }

