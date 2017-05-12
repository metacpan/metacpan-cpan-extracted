# $Id: auto_add_modules.t,v 1.3 2004/04/21 02:44:40 kellan Exp $

use Test::More tests => 5;
use XML::RSS;
use File::Spec;

$XML::RSS::AUTO_ADD = 1;

my $URL = 'http://freshmeat.net/backend/fm-releases-0.1.dtd';
my $TAG = 'fm';

{
    my $rss = XML::RSS->new();
    # TEST
    isa_ok( $rss, 'XML::RSS' );

    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(), 't', 'data', 'freshmeat.rdf'
        )
    );

    #use Data::Dumper;
    #print Data::Dumper::Dumper( $rss );


    # TEST
    ok( exists $rss->{modules}{$URL}, 'Freshmeat module exists' );
    # TEST
    is( $rss->{modules}{$URL}, $TAG, 'Freshmeat module has right URI' );
}

{
    my $rss = XML::RSS->new();

    my $text;
    {
        local $/;
        local *I;
        open I, "<", File::Spec->catfile(
            File::Spec->curdir(), 't', 'data', 'freshmeat.rdf'
        );
        $text = <I>;
        close(I);
    }

    $rss->parse(
        $text,
    );

    # TEST
    ok( exists $rss->{modules}{$URL}, 'Freshmeat module exists' );
    # TEST
    is( $rss->{modules}{$URL}, $TAG, 'Freshmeat module has right URI' );
}


