use strict;
use warnings;
use Path::Tiny;
use Data::UUID;

use Test::More tests => 2;

use lib qw(./lib);

use Text::vCard::Precisely::V4;

my $vc = Text::vCard::Precisely::V4->new();
my $ug = Data::UUID->new;
my $uuid = $ug->create_from_name_str( NameSpace_URL, 'www.exsample.com' );
$vc->clientpidmap("1;urn:uuid:$uuid");

my $in_file = path( 't', 'V4', 'Clientpidmap', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

is $vc->as_string, $expected_content, 'clientpidmap(\d+;Data::UUID)';                # 1



my $uuid2 = $ug->create_from_name_str( NameSpace_URL, 'blog.exsample.com' );
$vc->clientpidmap(["1;urn:uuid:$uuid","2;urn:uuid:$uuid2"]);

$in_file = path( 't', 'V4', 'Clientpidmap', 'multiple.vcf' );
$expected_content = $in_file->slurp_utf8;

is $vc->as_string, $expected_content, 'clientpidmap(\d+;Data::UUID)';                # 2

done_testing;
