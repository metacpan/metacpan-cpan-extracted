use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

my $err;

my $obj = Digest::MD5->new;
isa_ok( $obj, 'Digest::MD5' );

$err = exception { DoesNotExist->new };
like( $err, qr/Can't locate DoesNotExist\.pm/, "missing module croaks" );

$err = exception { File::Spec->new };
like( $err, qr/Can't locate object method new/, "missing new method croaks" );

1;

#
# This file is part of UNIVERSAL-new
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
