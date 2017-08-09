use strict;
use warnings;
use Path::Tiny;
use Data::UUID;

use Test::More tests => 1;

use lib qw(./lib);

use Text::vCard::Precisely::V4;

my $vc = Text::vCard::Precisely::V4->new();

my $ug = Data::UUID->new;
my $org = 'Bubba Gump Shrimp Co.';

my $uuid  = $ug->create_from_name_str( NameSpace_URL, 'www.example.com' );
my $uuidj = $ug->create_from_name_str( NameSpace_URL, 'john@example.com' );
my $uuidt = $ug->create_from_name_str( NameSpace_URL, 'tim@example.com' );
$vc->uid("urn:uuid:$uuid");
$vc->member(["urn:uuid:$uuidj","urn:uuid:$uuidt"]);
$vc->org($org);
$vc->fn($org);

my $in_file = path( 't', 'V4', 'member.vcf' );
my $expected_content = $in_file->slurp_utf8;

is $vc->as_string, $expected_content, 'uid(Data::UUID)';                # 1

done_testing;
