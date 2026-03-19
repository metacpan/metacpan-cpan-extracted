BEGIN { print "1..3\n"; }
END { print "not ok 1\n" unless $loaded; }
use XML::Parser;
$loaded = 1;
print "ok 1\n";

# Test that whitespace after root closing tag triggers Char handler,
# not Default handler (rt.cpan.org #46685 / GitHub issue #47)

my @char_data;
my @dflt_data;

sub char_handler {
    my ( $xp, $data ) = @_;
    push @char_data, $data;
}

sub dflt_handler {
    my ( $xp, $data ) = @_;
    push @dflt_data, $data;
}

my $p = XML::Parser->new(
    Handlers => {
        Char    => \&char_handler,
        Default => \&dflt_handler,
    }
);

$p->parse("<doc>foo</doc>\n \n");

# Test 2: trailing whitespace should go to Char handler
my $trailing = join( '', grep { /^\s+$/ } @char_data );
if ( $trailing eq "\n \n" ) {
    print "ok 2\n";
}
else {
    print "not ok 2 # Char handler did not receive trailing whitespace\n";
}

# Test 3: Default handler should NOT receive the trailing whitespace
my $dflt_trailing = join( '', grep { /^\s+$/ } @dflt_data );
if ( $dflt_trailing eq '' ) {
    print "ok 3\n";
}
else {
    print "not ok 3 # Default handler received trailing whitespace: '$dflt_trailing'\n";
}
