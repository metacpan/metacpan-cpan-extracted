#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More tests => 2;
use WWW::Suffit::Util qw/fdatetime/;

ok(WWW::Suffit::Util->VERSION, 'Version');
ok(fdatetime(time), 'DateTime');

1;

__END__
