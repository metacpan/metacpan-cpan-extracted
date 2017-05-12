#! /usr/bin/perl
use Perlude;
use Test::More;

my $expected = [qw< romanes eunt domus >];

sub is_reference_to ($$;$) {
    my ( $isa, $v, $desc ) = @_;
    $desc //= "which is a ref to $isa";
    is ((ref $v), $isa, $desc); 
}

for
( ['t/data/brian']
, ['t/data/brian', '<:encoding(utf8)'] ) {

    my $mean = sprintf 'open_file(%s)'
        , join ','
        , map { (ref $_) || $_ } @$_;

    my $fh = open_file @$_
        or die "$! while $mean";

    is_reference_to GLOB => $fh
    , "$mean returns a GLOB";

    is_deeply [fold lines $fh] => $expected
    , "$mean read as expected";

}

done_testing;

