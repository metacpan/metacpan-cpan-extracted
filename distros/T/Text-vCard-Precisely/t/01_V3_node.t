use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 4;

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();

my $in_file          = path( 't', 'V3', 'Node', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->fn('Forrest Gump');
$vc->nickname('Gumpy');
$vc->org('Bubba Gump Shrimp Co.');
$vc->title('Shrimp Man');
$vc->role('Section 9');
$vc->categories('fisher');
$vc->note("It's a note!");
$vc->geo('39.95;-75.1667');
$vc->label('123 Main St.\nSpringfield, IL 12345\nUSA');    # DEPRECATED in vCard4.0
is $vc->as_string, $expected_content, 'Node(Str)';         # 1

$in_file          = path( 't', 'V3', 'Node', 'hash.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->label(
    {   types   => ['home'],
        content => '123 Main St.\nSpringfield, IL 12345\nUSA'
    }
);                                                         # DEPRECATED in vCard4.0
$vc->key( { types => ['PGP'], content => 'http://example.com/key.pgp' } );
is $vc->as_string, $expected_content, 'Node(HashRef)';     # 2

$in_file          = path( 't', 'V3', 'Node', 'maltiple.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->fn( [ { content => 'Forrest Gump' } ] );
$vc->nickname( ['Gumpy'] );
$vc->org( [ { content => 'Bubba Gump Shrimp Co.' } ] );
$vc->title( [ { content => 'Shrimp Man' } ] );
$vc->role( [ { content => 'Section 9' } ] );
$vc->categories( ['fisher'] );
$vc->note( [ { content => "It's a note!" } ] );
$vc->geo( [ { content => '39.95;-75.1667' } ] );
$vc->label(    # DEPRECATED in vCard4.0
    [   {   types   => ['home'],
            content => '123 Main St.\nSpringfield, IL 12345\nUSA'
        }
    ]
);
$vc->key( [ { types => ['PGP'], content => 'http://example.com/key.pgp' } ] );

is $vc->as_string, $expected_content, 'Node(ArrayRef of HashRef)';    # 3

$in_file          = path( 't', 'V3', 'Node', 'utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->nickname( ['一期一会'] );
is $vc->as_string, $expected_content, 'Node(HashRef with utf8)';      # 4

done_testing;
