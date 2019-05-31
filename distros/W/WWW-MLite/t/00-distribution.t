#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-distribution.t 41 2019-05-29 17:01:36Z minus $
#
#########################################################################
use strict;
use Test::More;

eval "use Test::Distribution('only' => [qw(pod sig description versions use)])";
plan skip_all => 'Test::Distribution not installed' if($@);

1;

__END__
