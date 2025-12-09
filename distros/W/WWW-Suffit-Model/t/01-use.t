#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('WWW::Suffit::Model') };
ok(WWW::Suffit::Model->VERSION,'Version');

1;

__END__
