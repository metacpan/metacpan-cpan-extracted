use strict;
use warnings;
use 5.010;
 
use Test::Simple tests => 1;
use Word2vec::Interface;

my $interface = Word2vec::Interface->new( undef, 0, 0, 1 );
ok( $interface->RunFileChecks( $interface->GetWord2VecDir() ) == 1 );

undef( $interface );