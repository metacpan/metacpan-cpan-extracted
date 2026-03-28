use strict;
use warnings;
use Test::More tests => 3;
use XML::Parser;

# Test 1: module loads
ok( 1, 'XML::Parser loaded' );

# Test that whitespace after root closing tag triggers Char handler,
# not Default handler (rt.cpan.org #46685 / GitHub issue #47)

my @char_data;
my @dflt_data;

my $p = XML::Parser->new(
    Handlers => {
        Char    => sub { push @char_data, $_[1] },
        Default => sub { push @dflt_data, $_[1] },
    }
);

$p->parse("<doc>foo</doc>\n \n");

# Test 2: trailing whitespace should go to Char handler
my $trailing = join( '', grep { /^\s+$/ } @char_data );
is( $trailing, "\n \n", 'trailing whitespace delivered to Char handler' );

# Test 3: Default handler should NOT receive the trailing whitespace
my $dflt_trailing = join( '', grep { /^\s+$/ } @dflt_data );
is( $dflt_trailing, '', 'Default handler does not receive trailing whitespace' );
