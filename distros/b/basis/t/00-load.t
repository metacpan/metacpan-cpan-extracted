#!/usr/bin/perl

; use Sub::Uplevel
; use strict
; package main

; use Test::More tests => 4

; BEGIN { use_ok( 'basis' ) }

; diag( "Testing basis $basis::VERSION, Perl $], $^X" )

########################################################
# Test with inline classes

; package My::Base
; our $VERSION = "0.78";

; sub import { $My::Base::v="i" }

; my $skip
; BEGIN 
    { eval "require base"
    ; $skip = !!$@
    }

SKIP:
    { package main
    ; skip("module base specific test",3) if $skip
    ; local $basis::base = 'base'
    ; package My::Shoe
    ; eval "use basis 'My::Base'"

    ; package main

    ; ok(! My::Shoe->isa("Sub::Uplevel"))
    ; ok(My::Shoe->isa("My::Base") , "isa")
    ; is($My::Base::v , "i", "import call")
    }

