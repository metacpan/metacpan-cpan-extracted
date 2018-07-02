use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

use XML::XPathScript::Template;
use XML::XPathScript::Template::Tag;

my $template = XML::XPathScript::Template->new;

$template->( 'foo' => { rename => 'bar' } );

is $template->{foo}{rename} => 'bar', 'Template &{} overloading';

like $template => qr/^XML::XPathScript::Template/;

my $tag = XML::XPathScript::Template::Tag->new;

$tag->({ pre => 'alpha' });

is $tag->get( 'pre' ) => 'alpha', 'Tag &{} overloading';

like $tag => qr/^XML::XPathScript::Template/;

