# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# $Log: 1.t,v $
# Revision 1.2  2003/01/10 22:30:55  daniel
# version 0.3 (perl 5.6 and sablot 0.90)
#
# Revision 1.1.1.1  2002/11/24 17:18:15  daniel
# initial checkin
#

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 3;
use Test;
BEGIN { plan test => 2 }
#BEGIN { use_ok('XML::YYLex') };
BEGIN { use XML::YYLex };

use lib qw(t); ## to find Demo.pm

#########################

SKIP: {
    eval "use XML::DOM;";
    skip "XML::DOM not found", 1 if $@;

    ok( &demo_xml_dom );
}

SKIP: {
    eval "use XML::Sablotron::DOM;";
    skip "XML::SablotronDOM not found", 1 if $@;

    ok( &demo_xml_sablotron_dom );
}

sub demo_xml_dom {
    my $parser = new XML::DOM::Parser;
    my $dom_document = $parser->parsefile( "t/demo.xml" );
    return demo( $dom_document );
}

sub demo_xml_sablotron_dom {
    my $sit = new XML::Sablotron::Situation;
    my $dom_document = XML::Sablotron::DOM::parse( $sit, "t/demo.xml" );
    return demo( $dom_document );
}

sub demo {
    my $dom_document = shift;
    my $p = XML::YYLex::create_object( document => $dom_document );
    my $res = $p->run( "Demo" );
    return $res eq "titleneedle";
}

