# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Weather::GHCN::Measures;

package Weather::GHCN::Measures;

use Test::More tests => 17;
use Test::Exception;

use Const::Fast;

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';

use_ok 'Weather::GHCN::Measures';

my $mobj;
my @expected;
my @got;

$mobj = new_ok 'Weather::GHCN::Measures';

can_ok $mobj, 'measures';
can_ok $mobj, 're';

@got = $mobj->measures;
@expected = qw( TMAX TMIN Tavg );
is_deeply \@got,\@expected, 'no args returns TMAX TMIN Tavg';
ok _matches($mobj->re, @got), 're _matches all measures';

$mobj = Weather::GHCN::Measures->new( { tavg => 1 } );
@got = $mobj->measures;
@expected = qw( TMAX TMIN Tavg TAVG);
is_deeply \@got,\@expected, 'no args returns ' . join ' ', @expected;
ok _matches($mobj->re, @got), 're _matches all measures';

$mobj = Weather::GHCN::Measures->new( { precip => 1 } );
@got = $mobj->measures;
@expected = qw( TMAX TMIN Tavg PRCP SNOW SNWD);
is_deeply \@got,\@expected, 'no args returns ' . join ' ', @expected;
ok _matches($mobj->re, @got), 're _matches all measures';

$mobj = Weather::GHCN::Measures->new( { anomalies => 1 } );
@got = $mobj->measures;
@expected = qw( TMAX TMIN Tavg A_TMAX A_TMIN A_Tavg );
is_deeply \@got,\@expected, 'no args returns ' . join ' ', @expected;
ok _matches($mobj->re, @got), 're _matches all measures';

$mobj = Weather::GHCN::Measures->new( { anomalies => 1, tavg => 1 } );
@got = $mobj->measures;
@expected = qw( TMAX TMIN Tavg TAVG A_TMAX A_TMIN A_Tavg A_TAVG );
is_deeply \@got,\@expected, 'no args returns ' . join ' ', @expected;
ok _matches($mobj->re, @got), 're _matches all measures';

$mobj = Weather::GHCN::Measures->new( { anomalies => 1, tavg => 1, precip => 1 } );
@got = $mobj->measures;
@expected = qw( TMAX TMIN Tavg TAVG PRCP SNOW SNWD A_TMAX A_TMIN A_Tavg A_TAVG A_PRCP A_SNOW A_SNWD);
is_deeply \@got,\@expected, 'no args returns ' . join ' ', @expected;
ok _matches($mobj->re, @got), 're _matches all measures';

push @got, 'BAD MEASURE NAME';
ok !_matches($mobj->re, @got), 're fails on bad measure name';


sub _matches {
    my ($re, @measures) = @_;
    
    my $match_count = 0;
    foreach my $m (@measures) {
        $match_count++ if $m =~ $re;
    }
    
    return $match_count == @measures;
}