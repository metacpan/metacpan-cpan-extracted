#
# $Id: 03-yaml.t,v 0.3 2006/03/22 22:10:28 dankogai Exp $
#
use strict;
use Data::Dumper;
use Test::More;
BEGIN{ 
    eval { require YAML };
    if ($@){
	plan skip_all => 'YAML not available';
    }else{
	plan 'no_plan';
	require_ok('Tie::YAML')
    }
};

my $scalar = 7;
my @array  = qw(Sun Mon Tue Wed Thu Fri Sat);
my %hash   = map { $_ => 7 } @array;
my $src;
{
    tie my %dst => 'Tie::YAML', 'hash.yaml';
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    %dst = %{$src};
}{
    tie my %dst => 'Tie::YAML', 'hash.yaml';
    is_deeply(\%dst, $src, 'Tie::YAML - hash');
    # print Dumper \%dst;
}
{
    tie my @dst => 'Tie::YAML', 'array.yaml';
    $src = [ $scalar, [@array], {%hash} ];
    @dst = @{$src};
}{
    tie my @dst => 'Tie::YAML', 'array.yaml';
    is_deeply(\@dst, $src, 'Tie::YAML - array');
    # print Dumper \@dst;
}
{
    tie my $dst => 'Tie::YAML', 'scalar.yaml';
    $src = $scalar;
    $dst = $src;
}{
    tie my $dst => 'Tie::YAML', 'scalar.yaml';
    is_deeply($dst, $src, 'Tie::YAML - scalar');
    # print Dumper \$dst;
}
{
    tie my $dst => 'Tie::YAML', 'scalar.yaml';
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    bless $src, 'object';
    $dst = $src;
}{
    tie my $dst => 'Tie::YAML', 'scalar.yaml';
    is_deeply($dst, $src, 'Tie::YAML - object');
}
=pod

{
    tie my $dst => 'Tie::YAML::More', 'scalar.yaml', 0666;
    $src = { scalar => $scalar, array => [@array], hash=>{%hash} };
    $dst = $src;
}{
    tie my $dst => 'Tie::YAML::More', 'scalar.yaml', 0444;
    is_deeply($dst, $src, 'Tie::YAML::More');
    eval{ $dst = '' };
    ok($@, 'Tie::YAML::More - readonly');
}

=cut
unlink 'hash.yaml', 'array.yaml', 'scalar.yaml';
