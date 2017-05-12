#!/usr/local/bin/perl 
# ====================================================================
# Copyright (C) 1998 Stephen Farrell <stephen@farrell.org>
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
# ====================================================================

use ExtUtils::MakeMaker;

WriteMakefile(
	      "NAME"	=>	"Text::Graphics",
	      "PREREQ_PM" =>	{ "Text::Wrapper" => 0.007 }
);
