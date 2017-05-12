use strict;
use Test::More tests => 2;

use_ok 'Text::Variations';

my $tv1 = Text::Variations->new("one {{val}}");
my $tv2 = Text::Variations->new("two {{val}}");

my $combo = Text::Variations->new( [ $tv1, $tv2 ] );

my %results = ();

for ( 1 .. 1000 ) {
    my $out = $combo->generate( { val => 'foo' } );
    $results{$out}++;
}

# use Data::Dumper;
# warn Dumper( \%results );

is_deeply                      #
    [ sort keys %results ],    #
    [ 'one foo', 'two foo' ],  #
    "nested T::V objects correctly handled";
