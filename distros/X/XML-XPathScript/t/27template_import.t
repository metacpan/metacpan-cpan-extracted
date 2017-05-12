use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

use XML::XPathScript::Template;

my $template = XML::XPathScript::Template->new;

$template->set( foo => { pre => 'bar' } );
$template->set( fee => { post => 'fi' } );

my $imported = XML::XPathScript::Template->new;

$imported->set( foo => { post => 'fum' }, );

$template->import_template( $imported );

ok 1, "import_template() invocation";

is $template->{foo}{pre} => 'bar', 
    'already-present value unchanged';

is $template->{foo}{post} => 'fum', 
    'new value present';

$imported->set( foo => { post => 'changed' } );

is $template->{foo}{post} => 'fum', 
    'imported value is a copy not a reference';

