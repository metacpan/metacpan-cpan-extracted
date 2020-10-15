use strict;
use warnings;
use Path::Tiny;
use Test::More tests => 3;

use Text::vCard::Precisely::V4;
my $vc = Text::vCard::Precisely::V4->new();

my $in_file          = path( 't', 'V4', 'Sort_as', 'n.vcf' );
my $expected_content = $in_file->slurp_utf8;

$vc->fn('Forrest Gump');
$vc->n( { content => 'Gump;Forrest;;Mr.;', sort_as => "Gump,Forrest" } );
$vc->org('Bubba Gump Shrimp Co.');
is $vc->as_string, $expected_content, 'N with Sort_as';    # 1

$in_file          = path( 't', 'V4', 'Sort_as', 'fn.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->fn( { content => 'Forrest Gump', sort_as => "Gump,Forrest" } );
$vc->n('Gump;Forrest;;Mr.;');
$vc->org('Bubba Gump Shrimp Co.');
is $vc->as_string, $expected_content, 'FN with Sort_as';    # 2

$in_file          = path( 't', 'V4', 'Sort_as', 'org.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->fn('Forrest Gump');
$vc->n('Gump;Forrest;;Mr.;');
$vc->org( { content => 'Bubba Gump Shrimp Co.', sort_as => "Bubba Gump Shrimp Co." } );
is $vc->as_string, $expected_content, 'ORG with Sort_as';    # 3

done_testing;
