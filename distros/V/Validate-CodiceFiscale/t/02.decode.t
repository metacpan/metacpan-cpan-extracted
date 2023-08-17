#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';

use Test::More;
my $cf = $ENV{TEST_CF} // 'RSICRL99C51A355B';

binmode STDERR, ':encoding(utf-8)';

use Validate::CodiceFiscale qw< decode_cf >;
use Data::Dumper;
$Data::Dumper::Indent = 1;

my $d = decode_cf($cf);
ok defined($d), "got decoding for cf<$cf>";
ok exists($d->{portions}), 'decoding has "portions"';
diag Dumper($d);
say {*STDERR} "# place<$d->{place}>";

done_testing();
