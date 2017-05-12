use Test;
BEGIN { plan tests => 38}
END { ok(0) unless $loaded }
use XML::GDOME;
use IO::File;
$loaded = 1;
ok(1);

my $using_globals = '';

my $parser = XML::GDOME->new();
ok($parser);

$parser->match_callback( \&match );
$parser->read_callback( \&read );
$parser->open_callback( \&open );
$parser->close_callback( \&close );

$parser->expand_xinclude( 1 );

$dom = $parser->parse_file("t/xml/xinclude.xml");

ok($dom);

my $root = $dom->getDocumentElement();

my @nodes = $root->findnodes( 'xml/xsl' );
ok( scalar @nodes );

chdir("t/xml/complex") || die "chdir: $!";
open(F, "complex.xml") || die "Cannot open complex.xml: $!";
local $/;
my $str = <F>;
close F;
$dom = $parser->parse_string($str);
ok($dom);

$using_globals = 1;
$XML::GDOME::match_cb = \&match;
$XML::GDOME::open_cb = \&open;
$XML::GDOME::read_cb = \&read;
$XML::GDOME::close_cb = \&close;

ok($parser->parse_string($str));

# warn $dom->toString() , "\n";

sub match {
# warn "match: $_[0]\n";
    ok($using_globals, defined($XML::GDOME::match_cb));
    return 1;
}

sub close {
# warn "close $_[0]\n";
    ok($using_globals, defined($XML::GDOME::close_cb));
    if ( $_[0] ) {
        $_[0]->close();
    }
    return 1;
}

sub open {
# warn("open: $_[0]\n");
    $file = new IO::File;
    if ( $file->open( "<$_[0]" ) ){
#        warn "open!\n";
        ok($using_globals, defined($XML::GDOME::open_cb));
    }
    else {
#        warn "cannot open $_[0] $!\n";
        $file = 0;
    }   
# warn("opened $file\n");
   
    return $file;
}

sub read {
#    warn "read!";
    my $rv = undef;
    my $n = 0;
    if ( $_[0] ) {
#        warn "read $_[1] bytes!\n";
        $n = $_[0]->read( $rv , $_[1] );
        ok($using_globals, defined($XML::GDOME::read_cb)) if $n > 0
    }
    return $rv;
}
