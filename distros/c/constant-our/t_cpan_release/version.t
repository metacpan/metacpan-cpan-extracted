#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use constant::our();

my $RegExp_match_version = qr/\b(\d+\.\d+)\b/;
my $real_version         = $constant::our::VERSION;
my ($root_dir) = $INC{'constant/our.pm'} =~ m!^(.*)/lib/constant/our.pm$!;
$root_dir =~ s!/blib$!!;
pod_version();
changes_version();

################################################################################
sub pod_version
{
    my $file = "lib/constant/our.pm";
    my $text = read_file($file);
    my ($version) = $text =~ /=head1 VERSION\n\nVersion $RegExp_match_version\n=cut/;
    is( $version, $real_version, $file );
}
################################################################################
sub changes_version
{
    my $file = "Changes";
    my $text = read_file($file);
    my ($version) = $text =~ /^$RegExp_match_version /m;
    is( $version, $real_version, $file );
}
################################################################################
sub read_file
{
    my $file = $root_dir . '/' . shift;
    open( my $FILE, '<', $file ) or die "Can't open file[$file]: $!";
    local $/;
    return scalar <$FILE>;
}
################################################################################
