use strict;
use warnings;
use 5.10.0;
use Test::More;

use Time::Piece::Plus;

my $localtime = localtime();
my $gmtime    = gmtime();

isa_ok($localtime => 'Time::Piece::Plus', 'localtime returns Time::Piece::Plus instance');
isa_ok($localtime => 'Time::Piece',       'Time::Piece::Plus is subclass of Time::Piece');
isa_ok($gmtime    => 'Time::Piece::Plus', 'gmtime returns Time::Piece::Plus instance');
isa_ok($gmtime    => 'Time::Piece',       'Time::Piece::Plus is subclass of Time::Piece');

done_testing();
