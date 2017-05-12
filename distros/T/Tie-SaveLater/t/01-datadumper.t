#
# $Id: 01-datadumper.t,v 0.3 2006/03/22 22:10:28 dankogai Exp $
#
use strict;
use Data::Dumper;
use Test::More 'no_plan';
BEGIN{ use_ok('Tie::DataDumper') };

my $scalar = 7;
my @array  = qw(Sun Mon Tue Wed Thu Fri Sat);
my %hash   = map { $_ => 7 } @array;
my $src;
{
    tie my %dst => 'Tie::DataDumper', 'hash.dd';
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    %dst = %{$src};
}{
    tie my %dst => 'Tie::DataDumper', 'hash.dd';
    is_deeply(\%dst, $src, 'Tie::DataDumper - hash');
    # print Dumper \%dst;
}
{
    tie my @dst => 'Tie::DataDumper', 'array.dd';
    $src = [ $scalar, [@array], {%hash} ];
    @dst = @{$src};
}{
    tie my @dst => 'Tie::DataDumper', 'array.dd';
    is_deeply(\@dst, $src, 'Tie::DataDumper - array');
    # print Dumper \@dst;
}
{
    tie my $dst => 'Tie::DataDumper', 'scalar.dd';
    $src = $scalar;
    $dst = $src;
}{
    tie my $dst => 'Tie::DataDumper', 'scalar.dd';
    is_deeply($dst, $src, 'Tie::DataDumper - scalar');
    # print Dumper \$dst;
}
{
    tie my $dst => 'Tie::DataDumper', 'scalar.dd';
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    bless $src, 'object';
    $dst = $src;
}{
    tie my $dst => 'Tie::DataDumper', 'scalar.dd';
    is_deeply($dst, $src, 'Tie::DataDumper - object');
}
=pod

{
    tie my $dst => 'Tie::DataDumper::More', 'scalar.dd', 0666;
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    $dst = $src;
}{
    tie my $dst => 'Tie::DataDumper::More', 'scalar.dd', 0444;
    is_deeply($dst, $src, 'Tie::DataDumper::More');
    eval{ $dst = '' };
    ok($@, 'Tie::DataDumper::More - readonly');
}

=cut
unlink 'hash.dd', 'array.dd', 'scalar.dd';
