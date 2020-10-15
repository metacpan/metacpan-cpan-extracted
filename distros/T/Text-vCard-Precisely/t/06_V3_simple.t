use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 2;

use Text::vCard::Precisely::V3;

my $vc = Text::vCard::Precisely::V3->new();
$vc->fn('Rene van der Harten');
$vc->n('van der Harten;Rene;J.;Sir;R.D.O.N.');
$vc->sort_string('Harten');
$vc->bday('19960415');
$vc->prodid('-//ONLINE DIRECTORY//NONSGML Version 1//EN');

my $in_file          = path( 't', 'V3', 'Simple', 'base.vcf' );
my $expected_content = $in_file->slurp_utf8;

is $vc->as_string, $expected_content, 'simples(Str)';    # 1

$in_file          = path( 't', 'V3', 'Simple', 'utf8.vcf' );
$expected_content = $in_file->slurp_utf8;

$vc->fn('太宰治');
$vc->n('太宰;治');
$vc->sort_string('だざいおさむ');
is $vc->as_string, $expected_content, 'simples(Str with utf8 )';    # 2

done_testing;
