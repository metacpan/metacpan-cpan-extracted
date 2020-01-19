use strict;
use warnings;
use Path::Tiny;
use Test::More tests => 4;

use lib qw(./lib);

use Text::vCard::Precisely::V4;

my $vc = Text::vCard::Precisely::V4->new();

my $in_file = path( 't', 'V4', 'Node', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->fn('Forrest Gump');
$vc->nickname('Gumpy');
$vc->org('Bubba Gump Shrimp Co.');
$vc->impp('aim:johndoe@aol.com');
$vc->lang('en-us');
$vc->title('Shrimp Man');
$vc->role('Section 9');
$vc->categories('fisher');
$vc->note("It's a note!");
$vc->xml('<b>Not an xCard XML element</b>');
$vc->geo('39.95;-75.1667');
is $vc->as_string, $expected_content, 'Node(Str)';                      # 1

$in_file = path( 't', 'V4', 'Node', 'hash.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->key({ types => ['PGP'], content => 'http://example.com/key.pgp' });
is $vc->as_string, $expected_content, 'Node(HashRef)';                  # 2

$in_file = path( 't', 'V4', 'Node', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->fn([{ content => 'Forrest Gump'}]);
$vc->nickname([{ content => 'Gumpy' }]);
$vc->org([{ content => 'Bubba Gump Shrimp Co.' }]);
$vc->impp([{ content => 'aim:johndoe@aol.com' }]);
$vc->lang([{ content => 'en-us' }, { content => 'ja-jp' }]);
$vc->title([{ content => 'Shrimp Man' }]);
$vc->role([{ content => 'Section 9' }]);
$vc->categories([{ content => 'fisher' }]);
$vc->note([{ content => "It's a note!" }]);
$vc->xml([{ content => '<b>Not an xCard XML element</b>' }]);
$vc->geo([{ content => '39.95;-75.1667' }]);
$vc->key([{ types => ['PGP'], content => 'http://example.com/key.pgp' }]);

is $vc->as_string, $expected_content, 'Node(ArrayRef of HashRef)';      # 3

$in_file = path( 't', 'V4', 'Node', 'utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->nickname([{ content => '一期一会' }]);
is $vc->as_string, $expected_content, 'Node(HashRef with utf8)';        # 4

done_testing;
