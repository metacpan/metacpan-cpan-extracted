package NewsML_G2_Test_Helpers;

use Exporter 'import';
use File::Spec::Functions qw(catfile);
use XML::LibXML;
use Test::More;
use Test::Exception;
use utf8;

use warnings;
use strict;

use XML::NewsML_G2;

our @EXPORT_OK =
    qw(validate_g2 create_ni_text create_ni_picture create_ni_video create_ni_audio create_ni_graphics test_ni_picture test_ni_versions);

our %EXPORT_TAGS = (
    vars => [
        qw($guid_text $guid_picture
            $see_also_guid $derived_from_guid $embargo $apa_id $title $subtitle
            $slugline $creditline $embargo_text $note $prov_apa $svc_apa_bd $time1
            $time2 @text @genres $org $desk @keywords)
    ]
);

Exporter::export_ok_tags('vars');

our $guid_text         = 'urn:newsml:apa.at:20120315:APA0379';
our $guid_picture      = 'urn:newsml:apa.at:20120315:ABD0111';
our $see_also_guid     = 'urn:newsml:apa.at:20120315:APA0123';
our $derived_from_guid = 'urn:newsml:apa.at:20120315:APA0120';
our $apa_id            = 'APA0379';
our $title = 'Saisonstart im Schweizerhaus: Run aufs Krügerl im Prater';
our $subtitle =
    'Großer Andrang am Eröffnungstag - Auch der Rummelplatz startsete heute den Betrieb';
our $slugline =
    'Buntes/Freizeit/Bauten/Eröffnung/Unterhaltung/Wien/Kommunales';
our $creditline   = 'APA/John Doe';
our $embargo      = '2012-03-15T12:00:00+01:00';
our $embargo_text = 'frei für Dienstagsausgaben';
our $note =
    'Bilder zum Schweizerhaus sind im AOM, z.B. ABD0019 vom 23. März 2006, abrufbar';
our $time1 = '2012-03-15T09:09:00+01:00';
our $time2 = '2012-03-15T10:10:00+01:00';

ok( our $mt10000000 = XML::NewsML_G2::Media_Topic->new(
        name  => 'Freizeit, Modernes Leben',
        qcode => 10000000
    ),
    'create media topic 1'
);
ok( $mt10000000->add_translation( 'en', 'lifestyle and leisure' ),
    'add translation' );

our $mt20000538 =
    XML::NewsML_G2::Media_Topic->new( name => 'Freizeit', qcode => 20000538 );
ok( $mt20000538->add_translation( 'en', 'leisure' ), 'set translation' );
ok( $mt20000538->parent($mt10000000), 'set parent' );

our $mt20000553 = XML::NewsML_G2::Media_Topic->new(
    name   => 'Veranstaltungsort',
    qcode  => 20000553,
    direct => 1
);
$mt20000553->add_translation( 'en', 'leisure venue' );
$mt20000553->parent($mt20000538);

ok( our $prov_apa = XML::NewsML_G2::Provider->new(
        qcode => 'apa',
        name  => 'APA - Austria Presse Agentur',
    ),
    'create Provider instance'
);
ok( our $remote_info = XML::NewsML_G2::Remote_Info->new(
        reluri => 'http://www.iana.org/assignments/relation/icon',
        href   => 'http://test.com/123.jpg'
    ),
    'create remote info for copyright holder'
);

ok( our $copy_hold = XML::NewsML_G2::Copyright_Holder->new(
        qcode       => 'apa',
        name        => 'APA - Austria Presse Agentur',
        notice      => '(c) 2014 http://www.apa.at',
        uri         => 'http://www.apa.at',
        remote_info => $remote_info
    ),
    'create copyright holder instance'
);

ok( our $svc_apa_bd = XML::NewsML_G2::Service->new(
        qcode => 'bd',
        name  => 'Basisdienst'
    ),
    'create Service instance'
);

ok( our @genres = (
        XML::NewsML_G2::Genre->new(
            name  => 'Berichterstattung',
            qcode => 'Current'
        ),
        XML::NewsML_G2::Genre->new(
            name  => 'Extra',
            qcode => 'Extra'
        )
    ),
    'create Genre instances'
);

ok( our $org = XML::NewsML_G2::Organisation->new(
        name     => 'Ottakringer Brauerei',
        qcode    => '161616',
        isins    => ['AT0000758032'],
        websites => ['http://www.ottakringer.at'],
        markets  => [ 'Wien', 'Prag' ]
    ),
    'create Organisation instance'
);

ok( our $desk = XML::NewsML_G2::Desk->new(
        qcode => 'CI',
        name  => 'Chronik Inland'
    ),
    'create Desk instance'
);

ok( my $wien = XML::NewsML_G2::Location->new(
        name      => 'Wien',
        qcode     => '1111',
        relevance => 100,
        direct    => 1,
        latitude  => 48.2000,
        longitude => 16.3667
    ),
    'create Location Wien'
);

my $aut = XML::NewsML_G2::Location->new(
    name      => 'Österreich',
    iso_code  => 'AT',
    qcode     => '2222',
    relevance => 40
);

ok( $wien->parent($aut), 'set parent' );

my $europe = XML::NewsML_G2::Location->new(
    name      => 'Europe',
    qcode     => '3333',
    relevance => 30
);
$aut->parent($europe);

ok( my $topic =
        XML::NewsML_G2::Topic->new( name => 'Budget 2012', qcode => 'bbbb' ),
    'create Topic'
);
ok( my $product = XML::NewsML_G2::Product->new( isbn => 3442162637 ),
    'create Product' );

our @keywords = qw(beer vienna prater kolarik schweizerhaus);

{
    local $/ = undef;
    our @text = split /\n\n+/, <DATA>;
}

our %ni_std_opts = (
    guid             => $guid_text,                     # overwrite in $hash
    provider         => $prov_apa,
    copyright_holder => $copy_hold,
    usage_terms      => 'view only with a full beer',
    message_id       => $apa_id,
    subtitle         => $subtitle,
    slugline         => $slugline,
    embargo          => DateTime::Format::XSD->parse_datetime($embargo),
    embargo_text     => $embargo_text,
    language         => 'de',
    note             => $note,
    closing          => 'Schluss',
    credit           => $creditline,
    content_created  => DateTime::Format::XSD->parse_datetime($time1),
    content_modified => DateTime::Format::XSD->parse_datetime($time2),

);

sub validate_g2 {
    my ( $dom, $version ) = @_;
    $version ||=
        XML::NewsML_G2::Writer->meta->get_attribute('g2_version')->default;

SKIP: {
        skip
            'libxml2 before 2.8 reports bogus violation on children of "broader"',
            2
            if ( 20800 > XML::LibXML::LIBXML_RUNTIME_VERSION );
        $version =~ tr/./_/;
        my $xsd =
            catfile( 't', 'xsds', "NewsML-G2_$version-spec-All-Power.xsd" );
        ok( my $xmlschema = XML::LibXML::Schema->new( location => $xsd ),
            "parsing $version XSD" );

        lives_ok(
            sub { $xmlschema->validate($dom) },
            "XML validates against $version XSD"
        );
    }

    return;
}

sub _create_ni {
    my $ni_cls = shift;
    my $hash   = shift;
    my %opts   = @_;

    $hash->{service} = $svc_apa_bd unless ( $opts{no_required_scheme} );

    ok( my $ni = $ni_cls->new(
            %ni_std_opts,
            title => ( $opts{id} ? "$title $opts{id}" : $title ),
            %$hash
        ),
        'create News Item instance'
    );

    ok( $ni->add_derived_from(
            XML::NewsML_G2::Link->new(
                residref => $derived_from_guid,
                version  => 3
            )
        ),
        'add_drived_from works'
    );
    ok( $ni->add_see_also($see_also_guid), 'add_see_also works for text' );
    ok( $ni->add_see_also(
            XML::NewsML_G2::Link->new(
                href    => 'https://www.youtube.com/watch?v=dQw4w9WgXcQa',
                version => 9001
            )
        ),
        'add_see_also works for instances'
    );
    ok( $ni->add_genre(@genres),     'add_genre works' );
    ok( $ni->add_organisation($org), 'add_organisation works' );
    ok( $ni->add_source( 'APA', 'DPA' ), 'add_source works' );
    ok( $ni->add_city('Wien'), 'add_city works' );
    ok( $ni->add_desk($desk),  'add_desk works' );

    $ni->add_author($_) foreach (qw(dw dk wh));
    ok( $ni->authors, 'add_author works' );

    $ni->add_keyword($_) foreach (@keywords);

    ok( $ni->add_media_topic($mt20000553), 'adding media topic' );
    ok( !$ni->add_media_topic($mt20000553),
        'adding media topic again fails' );

    ok( exists $ni->media_topics->{20000553}, 'media topic in news item' );
    ok( exists $ni->media_topics->{20000538}, 'parent in news item' );
    ok( exists $ni->media_topics->{10000000}, 'grandparent in news item' );

    ok( $ni->add_location($wien),      'adding location' );
    ok( !$ni->add_location($wien),     'adding location again fails' );
    ok( exists $ni->locations->{1111}, 'Wien in locations' );
    ok( exists $ni->locations->{2222}, 'Österreich in locations' );
    ok( exists $ni->locations->{3333}, 'Europe in locations' );

    ok( $ni->add_topic($topic),     'adding Topic' );
    ok( $ni->add_product($product), 'adding product' );

    unless ( $opts{no_required_scheme} ) {
        $ni->add_indicator('BILD');
        $ni->add_indicator('VIDEO');
    }

    return $ni;
}

sub create_ni_text {
    _create_ni( 'XML::NewsML_G2::News_Item_Text', {}, @_ );
}

sub create_ni_picture {
    _create_ni( 'XML::NewsML_G2::News_Item_Picture',
        { photographer => 'Homer Simpson', guid => $guid_picture }, @_ );
}

sub create_ni_graphics {
    _create_ni( 'XML::NewsML_G2::News_Item_Graphics',
        { photographer => 'Homer Simpson' }, @_ );
}

sub create_ni_video {
    _create_ni( 'XML::NewsML_G2::News_Item_Video', @_ );
}

sub create_ni_audio {
    _create_ni( 'XML::NewsML_G2::News_Item_Audio', @_ );
}

sub _picture_checks {
    my ( $dom, $xpc, $version ) = @_;

    like( $xpc->findvalue('//nar:contentSet/nar:remoteContent/@rendition'),
        qr|rnd:highRes|, 'correct rendition in XML' );
    like( $xpc->findvalue('//nar:contentSet/nar:remoteContent/@rendition'),
        qr|rnd:thumb|, 'correct rendition in XML' );
    like( $xpc->findvalue('//nar:contentSet/nar:remoteContent/@href'),
        qr|file://tmp/files/123.*jpg|, 'correct href in XML' );
    like( $xpc->findvalue('//nar:contentSet/nar:remoteContent/@contenttype'),
        qr|image/jpg|, 'correct mimetype in XML' );
    like( $xpc->findvalue('//nar:description'),
        qr|ricebag.*over|, 'correct description' );
    like( $xpc->findvalue('//nar:description'),
        qr|ricebag.*over|, 'correct description' );

    return;
}

sub test_ni_versions {
    my ( $ni, $sm, %version_checks ) = @_;

    if ( my $h = delete $version_checks{'*'} ) {
        $version_checks{$_} = $h foreach (qw(2.12 2.15 2.18));
    }

    while ( my ( $version, $chkfn ) = each %version_checks ) {
        ok( my $writer = XML::NewsML_G2::Writer::News_Item->new(
                news_item      => $ni,
                scheme_manager => $sm,
                g2_version     => $version
            ),
            "creating $version writer"
        );
        ok( my $dom = $writer->create_dom(), 'create DOM' );
        ok( my $xpc = XML::LibXML::XPathContext->new($dom),
            'create XPath context for DOM tree' );
        $xpc->registerNs( 'nar',   'http://iptc.org/std/nar/2006-10-01/' );
        $xpc->registerNs( 'xhtml', 'http://www.w3.org/1999/xhtml' );
        $chkfn->( $dom, $xpc, $version );
        validate_g2( $dom, $version );

        # diag($dom->serialize(1));
    }
}

sub _old_style_name_check {
    my $xpc = shift;
    like(
        $xpc->findvalue('//nar:creator/@literal'),
        qr/Homer Simpson/,
        "correct photographer in XML, 2.9-style"
    );
    like( $xpc->findvalue('//nar:creator/@literal'),
        qr/dw.*dk.*wh/, "correct authors in XML, 2.9-style" );
    return;
}

sub _new_style_name_check {
    my $xpc = shift;
    like( $xpc->findvalue('//nar:creator/nar:name'),
        qr/dw.*dk.*wh/, 'correct authors in XML, 2.12+-style' );
    like(
        $xpc->findvalue('//nar:creator/nar:name'),
        qr/Homer Simpson/,
        'correct photographer in XML, 2.12+-style'
    );
    return;
}

sub _test_ni_version_pre_2_12 {
    my ( $dom, $xpc, $version ) = @_;
    _picture_checks( $dom, $xpc, $version );
    _old_style_name_check($xpc);
}

sub _test_ni_version {
    my ( $dom, $xpc, $version ) = @_;
    _picture_checks( $dom, $xpc, $version );
    _new_style_name_check($xpc);
}

sub test_ni_picture {
    my ($ni) = @_;

    my %schemes;
    foreach (qw(crel desk geo svc role ind org topic hltype)) {
        $schemes{$_} = XML::NewsML_G2::Scheme->new(
            alias => "apa$_",
            uri   => "http://cv.apa.at/$_/"
        );
    }

    ok( my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes),
        'create Scheme Manager' );
    $ni->caption('A ricebag is about to fall over');

    my $pic = XML::NewsML_G2::Picture->new(
        mimetype  => 'image/jpg',
        width     => 1600,
        height    => 1024,
        rendition => 'highRes'
    );
    my $thumb = XML::NewsML_G2::Picture->new(
        mimetype  => 'image/jpg',
        width     => 48,
        height    => 32,
        rendition => 'thumb'
    );

    ok( $ni->add_remote( 'file://tmp/files/123.jpg', $pic ),
        'Adding remote picture works' );
    ok( $ni->add_remote( 'file://tmp/files/123.thumb.jpg', $thumb ),
        'Adding remote thumbnail works' );

    my %tests = (
        '2.9' => \&_test_ni_version_pre_2_12,
        '*'   => \&_test_ni_version
    );

    test_ni_versions( $ni, $sm, %tests );

    return $sm;
}

1;

__DATA__
Die Saison im Wiener Prater hat am Donnerstagvormittag mit der
Eröffnung des Schweizerhauses begonnen - diese findet traditionell
jedes Jahr am 15. März statt. Pünktlich um 10.00 Uhr öffnete das
Bierlokal seine Pforten. Für viele Wiener ist das ein Pflichttermin:
"Es ist ein Fest für unsere Stammgäste. Die machen sich schon zum
Saisonschluss im Oktober aus, dass sie am ersten Öffnungstag im neuen
Jahr wieder kommen", sagte der Betreiber des Schweizerhauses, Karl
Kolarik, der APA.

Das traditionelle Bierlokal Schweizerhaus geht heuer in die 93. Saison
und erstrahlt in neuem Glanz: "Wir sind nun endgültig fertig mit dem
Umbau", zeigte sich Kolarik erfreut. Vor rund zwei Jahren wurde
begonnen, die Gaststätte zu vergrößern. So bekam das Haus eine neue
Bierschank, einen Lastenaufzug und auch die Sanitäranlagen wurden
erneuert. All diese Bauarbeiten wurden pünktlich bis zum Saisonstart
im Vorjahr abgeschlossen. Kleinere Veränderungen an der Infrastruktur
des Hauses wurden in den vergangenen Monaten fertiggestellt: "Das
bekommt der Gast gar nicht mit, aber wir haben noch unser EDV-System
sowie diverse Kabel verändert", so der Hausherr.
