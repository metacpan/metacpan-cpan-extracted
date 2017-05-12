#!/usr/bin/perl

; use Sub::Uplevel
; use strict
; package main

; use Test::More tests => 8

; BEGIN { use_ok( 'basis' ) }

########################################################
# Test with inline classes

; package My::Base

; sub import { $My::Base::v="i" }

; sub wildlife { 0 }

; my $skip;
; BEGIN
    { eval "require base"
    ; $skip = !!$@
    }

; SKIP:
    { package main
    ; skip("module base specific tests", 7) if $skip
    ; local $basis::base = 'base'
    ; package My::Shoe
    ; eval "use basis 'My::Base', 'Exporter'"
  
    ; our @EXPORT_OK=qw/guard/
  
    ; sub guard { 1 }

    ; package Kan::Guru
    ; eval "use basis 'My::Shoe' => ['guard']"

    ; package main

    ; ok(! My::Shoe->isa("Sub::Uplevel"))
    ; ok(My::Shoe->isa("My::Base") , "isa")
    ; ok(My::Shoe->isa("Exporter"))
    ; is($My::Base::v , "i"        , "import call")
  
    ; ok(Kan::Guru->can('guard') && Kan::Guru->guard)

    ; { no warnings 'ambiguous'
      ; is("@My::Shoe::ISA","My::Base Exporter")
      ; is("@Kan::Guru::ISA","My::Shoe")
      }
    }

