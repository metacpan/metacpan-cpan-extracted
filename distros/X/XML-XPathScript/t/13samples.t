use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
    use_ok( 'XML::XPathScript' );
}

sub test_file {
    my $filename = shift;

    print "testing $filename\n";

    local $/ = undef;

    open my $xml, "$filename.xml" or die;

    my $xps = XML::XPathScript->new(xml => join( '', <$xml> ), 
                                    stylesheetfile => "$filename.xps" );

    my $doc;
    $xps->process( \$doc );

    open my $expected, "$filename.expected" 
        or die "can't open file $filename.expected: $!";

    is( $doc, <$expected>, "t/testdocs/$filename.xml" );
}

chdir "t/testdocs" or die "can't change dir to t/testdocs\n";
opendir my $dir, "." or die;
my @files = readdir $dir;
test_file( $_ ) for grep { s/\.xml$// } @files;
