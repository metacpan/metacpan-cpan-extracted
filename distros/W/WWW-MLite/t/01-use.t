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
# $Id: 01-use.t 44 2019-05-31 10:06:54Z minus $
#
#########################################################################
use Test::More tests => 1;
BEGIN { use_ok('WWW::MLite') };
1;
