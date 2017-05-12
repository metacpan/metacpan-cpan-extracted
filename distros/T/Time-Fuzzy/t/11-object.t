#!perl
#
# This file is part of Time::Fuzzy.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

BEGIN {
    # some cpan testers have a weird env with no local timezone.
    $ENV{TZ} = 'UTC';
}

use Test::More tests => 3;
use Time::Fuzzy;

my $dt = DateTime->new(year=>1976);


my $fuzzy = Time::Fuzzy->new( dt => DateTime->new(year=>2008,hour=>8,minute=>2) );
$fuzzy->fuzziness('high');   like( $fuzzy->as_str, qr/^week|week$/,     'as_str() - high' );
$fuzzy->fuzziness('medium'); like( $fuzzy->as_str, qr/ning|noon|night/, 'as_str() - medium' );
$fuzzy->fuzziness('low');    is  ( $fuzzy->as_str, "eight o'clock",     'as_str() - low' );


exit;
