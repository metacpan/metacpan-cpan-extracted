#
# $Id: 02-storable.t,v 0.05 2020/08/05 18:26:03 dankogai Exp dankogai $
#
use strict;
use Data::Dumper;
use Test::More 'no_plan';
BEGIN{ use_ok('Tie::Storable') };

my $scalar = 7;
my @array  = qw(Sun Mon Tue Wed Thu Fri Sat);
my %hash   = map { $_ => 7 } @array;
my $src;
{
    tie my %dst => 'Tie::Storable', 'hash.po';
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    %dst = %{$src};
}{
    tie my %dst => 'Tie::Storable', 'hash.po';
    is_deeply(\%dst, $src, 'Tie::Storable - hash');
}
{
    tie my @dst => 'Tie::Storable', 'array.po';
    $src = [ $scalar, [@array], {%hash} ];
    @dst = @{$src};
}{
    tie my @dst => 'Tie::Storable', 'array.po';
    is_deeply(\@dst, $src, 'Tie::Storable - array');
}
{
    tie my $dst => 'Tie::Storable', 'scalar.po';
    $src = $scalar;
    $dst = $src;
}{
    tie my $dst => 'Tie::Storable', 'scalar.po';
    is_deeply($dst, $src, 'Tie::Storable - scalar');
}
{
    tie my $dst => 'Tie::Storable', 'scalar.po';
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    bless $src, 'object';
    $dst = $src;
}{
    tie my $dst => 'Tie::Storable', 'scalar.po';
    is_deeply($dst, $src, 'Tie::Storable - object');
}
{
    tie my $dst => 'Tie::Storable::More', 'scalar.po', 0666;
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    $dst = $src;
}{
    tie my $dst => 'Tie::Storable::More', 'scalar.po', 0444;
    is_deeply($dst, $src, 'Tie::Storable::More');
    eval{ $dst = '' };
    ok($@, 'Tie::Storable::More - readonly');
}
unlink 'hash.po', 'array.po', 'scalar.po';
