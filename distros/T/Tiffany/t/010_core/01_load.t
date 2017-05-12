use strict;
use warnings;
use Test::Requires 'Text::Xslate';
use Tiffany;
use Test::More;

my $tmpl = Tiffany->load( 'Text::Xslate', { syntax => 'TTerse' } );
is $tmpl->render( \'Hello, [% name %]', { name => 'John' } ), 'Hello, John';

done_testing;

