use strict;
use warnings;
use 5.010;
use Test::More;
use Test::Warnings qw/ :report_warnings /;

use FindBin '$Bin';
use YAML::Tidy;

my $dir = "$Bin/data";

my $cfg = YAML::Tidy::Config->new( configfile => "$dir/comments-config.yaml" );
my $yt = YAML::Tidy->new( cfg => $cfg );

my ($yaml, $tidied, $exp);

$yaml = do { open my $fh, '<', "$dir/comments.yaml" or die $!; local $/; <$fh> };
$exp = do { open my $fh, '<', "$dir/comments.yaml.tdy" or die $!; local $/; <$fh> };

$tidied = $yt->tidy($yaml);
is $tidied, $exp, "Serialize reused anchors";

done_testing;
