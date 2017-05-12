#!perl
#
# This file is part of XML-Jing
#
# This software is copyright (c) 2013 by BYU Translation Research Group.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Test::More;

eval "use Test::Vars";
plan skip_all => "Test::Vars required for testing unused vars"
  if $@;
all_vars_ok();
