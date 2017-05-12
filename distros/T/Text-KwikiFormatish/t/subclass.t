use warnings;
use strict;
use Test::More tests => 2;

package My::Formatter;
use base 'Text::KwikiFormatish';
sub bold { 'HONK' }

package main;
my $out = My::Formatter->new->process('*test*');
like $out, qr/HONK/;
unlike $out, qr/<b>/;

