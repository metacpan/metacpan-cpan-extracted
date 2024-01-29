use strict;
use warnings;
use 5.010;
use Test::More;
use Test::Warnings qw/ :report_warnings /;

use FindBin '$Bin';
use YAML::Tidy;

my $dir = "$Bin/../etc/serialize-aliases";

my $cfg = YAML::Tidy::Config->new( configfile => "$dir/config.yaml" );
my $yt = YAML::Tidy->new( cfg => $cfg );

my ($yaml, $tidied, $exp);

$yaml = do { open my $fh, '<', "$dir/example1.yaml" or die $!; local $/; <$fh> };
$exp = do { open my $fh, '<', "$dir/example1.yaml.tdy" or die $!; local $/; <$fh> };

$tidied = $yt->tidy($yaml);
is $tidied, $exp, "Serialize reused anchors";


$yaml = do { open my $fh, '<', "$dir/example2.yaml" or die $!; local $/; <$fh> };
$exp = do { open my $fh, '<', "$dir/example2.yaml.tdy" or die $!; local $/; <$fh> };

$tidied = $yt->tidy($yaml);
is $tidied, $exp, "Serialize additional reused anchors";

done_testing;
