use strict;
use XML::Builder;
use Test::More tests => 6;

my $xb = XML::Builder->new;
my $x  = $xb->null_ns;

# Tags
is $x->br->as_string, '<br/>', 'simple closed tag';
is $x->b( '' )->as_string, '<b></b>', 'simple forced open-close pair tag';
is $x->b( 'a', )->as_string, '<b>a</b>', 'simple tag';
is $x->b( 'a', 'b' )->as_string, '<b>ab</b>', 'simple tag with multiple content';

# Attributes
is $x->p( { class => 'normal' }, '' )->as_string, '<p class="normal"></p>', 'attributes';
is $x->p( { class => 'normal', style => undef }, '' )->as_string, '<p class="normal"></p>', 'skipping undefined attribute values';
