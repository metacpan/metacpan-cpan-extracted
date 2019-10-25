package XML::NewsML_G2::Writer;

use Carp;
use Moose;
use Moose::Util;
use DateTime;
use DateTime::Format::XSD;
use XML::NewsML_G2::Scheme_Manager;
use namespace::autoclean;

has '_root_item', is => 'ro', lazy => 1, builder => '_build__root_item';

has 'encoding', isa => 'Str', is => 'ro', default => 'utf-8';

has 'scheme_manager',
    isa     => 'XML::NewsML_G2::Scheme_Manager',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_scheme_manager';
has 'doc',
    isa     => 'XML::LibXML::Document',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_doc';
has '_formatter', is => 'ro', default => sub { DateTime::Format::XSD->new() };

has 'g2_ns',
    isa     => 'Str',
    is      => 'ro',
    default => 'http://iptc.org/std/nar/2006-10-01/';
has 'xhtml_ns',
    isa     => 'Str',
    is      => 'ro',
    default => 'http://www.w3.org/1999/xhtml';

has 'g2_version',      isa => 'Str', is => 'ro', default => '2.18';
has '_root_node_name', isa => 'Str', is => 'ro', default => 'newsItem';
has 'generator_version',
    is      => 'Str',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_generator_version';

# attributes set by version-specific role
has 'schema_location', isa => 'Str', is => 'ro';
has 'g2_catalog_url',  isa => 'Str', is => 'ro';
has 'g2_catalog_schemes',
    isa     => 'HashRef',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_g2_catalog_schemes';

# builders

sub _build__root_item {
    croak 'Override in subclass';
}

sub _build_g2_catalog_schemes {
    return {
        isrol       => undef,
        nprov       => undef,
        ninat       => undef,
        stat        => undef,
        sig         => undef,
        genre       => undef,
        isin        => undef,
        medtop      => undef,
        crol        => undef,
        drol        => undef,
        pgrmod      => undef,
        iso3166_1a2 => 'iso3166-1a2'
    };
}

sub _build_doc {
    my $self = shift;
    return XML::LibXML->createDocument( '1.0', $self->encoding );
}

sub _build_scheme_manager {
    my $self = shift;
    return XML::NewsML_G2::Scheme_Manager->new();
}

sub _build_generator_version {
    return XML::NewsML_G2->VERSION;
}

# Apply roles needed for writing
sub BUILD {
    my $self = shift;

    ( my $ni_cls ) = reverse split( '::', $self->_root_item->meta->name );
    my $type_role = sprintf( 'XML::NewsML_G2::Role::Writer::%s', $ni_cls );

    my $g2_version = $self->g2_version;
    $g2_version =~ s/\./_/;
    my $version_role = 'XML::NewsML_G2::Role::Writer_' . $g2_version;

    Moose::Util::apply_all_roles( $self, $type_role, $version_role );

    return;
}

# DOM creating methods

sub _create_creator {
    my ( $self, $name ) = @_;
    return $self->create_element( 'creator', _name_text => $name );
}

sub _create_root_element {
    my ($self) = @_;
    my $root =
        $self->doc->createElementNS( $self->g2_ns, $self->_root_node_name );
    $self->doc->setDocumentElement($root);
    $root->setAttributeNS( 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation', $self->schema_location );

    $root->setAttribute( 'standard',        'NewsML-G2' );
    $root->setAttribute( 'standardversion', $self->g2_version );
    $root->setAttribute( 'conformance',     'power' );
    $root->setAttribute( 'xml:lang',        $self->_root_item->language );

    $root->setAttribute( 'guid',    $self->_root_item->guid );
    $root->setAttribute( 'version', $self->_root_item->doc_version );
    return $root;
}

sub _create_catalogs {
    my ( $self, $root ) = @_;

    my %catalogs = ( $self->g2_catalog_url => 1 );

    my $cat;
    foreach my $scheme ( $self->scheme_manager->get_all_schemes() ) {
        if ( my $catalog = $scheme->catalog ) {
            $catalogs{$catalog} = 1;
        }
        elsif ($scheme) {
            $root->appendChild( $cat = $self->create_element('catalog') )
                unless $cat;
            $cat->appendChild(
                $self->create_element(
                    'scheme',
                    alias => $scheme->alias,
                    uri   => $scheme->uri
                )
            );
        }
    }

    foreach my $url ( sort keys %catalogs ) {
        $root->appendChild(
            $self->create_element( 'catalogRef', href => $url ) );
    }

    return;
}

sub _create_copyright_holder_remoteinfo {
    my ( $self, $crh ) = @_;
    if ( my $remote_info = $self->news_item->copyright_holder->remote_info ) {
        my %args;
        $args{reluri} = $remote_info->reluri if $remote_info->reluri;
        $args{href}   = $remote_info->href   if $remote_info->href;
        $crh->appendChild( $self->create_element( 'remoteInfo', %args ) )
            if keys %args;
    }
    return;
}

sub _create_item_meta_title {
}

sub _create_teaser {
    my ( $self, $cm ) = @_;

    if ( $self->news_item->teaser ) {
        $cm->appendChild(
            my $teaser = $self->create_element(
                'description', _text => $self->news_item->teaser
            )
        );
        $self->scheme_manager->add_role( $teaser, 'drol', 'teaser' );
    }
    return;
}

sub _create_item_meta {
    my ( $self, $root ) = @_;

    my $im = $self->create_element('itemMeta');
    $im->appendChild( my $ic = $self->create_element('itemClass') );
    $self->scheme_manager->add_qcode( $ic, 'ninat',
        $self->_root_item->nature );

    $im->appendChild(
        my $p = $self->create_element(
            'provider', _name_text => $self->_root_item->provider
        )
    );
    $self->scheme_manager->add_qcode_or_literal( $p, 'nprov',
        $self->_root_item->provider->qcode );
    $im->appendChild(
        $self->create_element(
            'versionCreated',
            _text => $self->_formatter->format_datetime(
                DateTime->now( time_zone => 'local' )
            )
        )
    );

    if ( $self->_root_item->embargo ) {
        my $e =
            $self->_formatter->format_datetime( $self->_root_item->embargo );
        $im->appendChild( $self->create_element( 'embargoed', _text => $e ) );
    }

    $im->appendChild( my $ps = $self->create_element('pubStatus') );
    $self->scheme_manager->add_qcode( $ps, 'stat',
        $self->_root_item->doc_status );
    $im->appendChild(
        $self->create_element(
            'generator',
            versioninfo => $self->generator_version,
            _text       => 'XML::NewsML_G2'
        )
    );
    if ( $self->_root_item->has_service ) {
        $im->appendChild(
            my $svc = $self->create_element(
                'service', _name_text => $self->_root_item->service
            )
        );
        $self->scheme_manager->add_qcode( $svc, 'svc',
            $self->_root_item->service->qcode );

    }
    $self->_create_item_meta_title($im);

    if ( $self->_root_item->embargo_text ) {
        $im->appendChild(
            my $e = $self->create_element(
                'edNote', _text => $self->_root_item->embargo_text
            )
        );
        $self->scheme_manager->add_role( $e, 'role', 'embargotext' );
    }
    if ( $self->_root_item->closing ) {
        $im->appendChild(
            my $e = $self->create_element(
                'edNote', _text => $self->_root_item->closing
            )
        );
        $self->scheme_manager->add_role( $e, 'role', 'closing' );
    }
    if ( $self->_root_item->note ) {
        $im->appendChild(
            my $e = $self->create_element(
                'edNote', _text => $self->_root_item->note
            )
        );
        $self->scheme_manager->add_role( $e, 'role', 'note' );
    }

    if ( $self->_root_item->doc_version > 1 ) {
        $im->appendChild( my $s = $self->create_element('signal') );
        $self->scheme_manager->add_qcode( $s, 'sig', 'correction' );
    }

    foreach ( @{ $self->_root_item->indicators } ) {
        $im->appendChild( my $s = $self->create_element('signal') );
        $self->scheme_manager->add_qcode( $s, 'ind', lc );
    }

    foreach my $attr (qw(see_alsos derived_froms processed_froms)) {
        if ( $self->_root_item->$attr ) {
            my $arrayref = $self->_root_item->$attr;
            for my $v (@$arrayref) {
                ( my $rel = $attr ) =~ s/_(\w)/uc $1/ge;
                $rel =~ s/s$//;
                my $linkelem = $self->create_element(
                    'link',
                    rel     => "irel:$rel",
                    version => $v->version
                );
                for my $attribute (qw/residref href/) {
                    next unless $v->$attribute;
                    $linkelem->setAttribute( $attribute => $v->$attribute );
                }

                $im->appendChild($linkelem);
            }
        }
    }

    $root->appendChild($im);
    return;
}

sub _import_iptc_catalog {
    my $self = shift;

    while ( my ( $attr, $alias ) = each %{ $self->g2_catalog_schemes } ) {
        $alias ||= $attr;
        my $getter_setter = $self->scheme_manager->can($attr)
            or die "Unknown scheme '$attr'\n";
        next
            if ( $getter_setter->( $self->scheme_manager ) )
            ;    # attribute ist already set by user
        my $scheme = XML::NewsML_G2::Scheme->new(
            alias   => $alias,
            catalog => $self->g2_catalog_url
        );
        $getter_setter->( $self->scheme_manager, $scheme );
    }
    return;
}

# public methods

sub create_element {
    my ( $self, $name, %attrs ) = @_;
    my $text      = delete $attrs{_text};
    my $cdata     = delete $attrs{_cdata};
    my $name_text = delete $attrs{_name_text};
    my $ns        = delete $attrs{_ns} || $self->g2_ns;
    my $elem      = $self->doc->createElementNS( $ns, $name );
    for my $attr_name ( sort keys %attrs ) {
        $elem->setAttribute( $attr_name, $attrs{$attr_name} );
    }
    if ($text) {
        $elem->appendChild( $self->doc->createTextNode($text) );
    }
    elsif ($cdata) {
        $elem->appendChild( $self->doc->createCDATASection($cdata) );
    }
    elsif ($name_text) {
        $name_text = $name_text->name
            if ( ref $name_text and $name_text->can('name') );
        $elem->appendChild(
            $self->create_element( 'name', _text => $name_text ) );
    }
    return $elem;
}

sub create_dom {
    my $self = shift;

    $self->_import_iptc_catalog();
    my $root = $self->_create_root_element();
    $self->_create_catalogs($root);
    $self->_create_rights_info($root);
    $self->_create_item_meta($root);
    $self->_create_content_meta($root);
    $self->_create_content($root);
    return $self->doc;

}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Writer - base class for XML DOM tree creation
conforming to NewsML-G2 News Items, Package Items and News Messages

=for test_synopsis
    my ($ni, $sm);

=head1 SYNOPSIS

    my $w = XML::NewsML_G2::Writer::News_Item->new
        (news_item => $ni, scheme_manager => $sm, g2_version => 2.18);

    my $p = $w->create_element('p', class => 'main', _text => 'blah');

    my $dom = $w->create_dom();

=head1 DESCRIPTION

This module acts as a NewsML-G2 version-independent base class for all
writer classes. Depending on whether you want to create output for a
News Item, Package Item or News Message, use one of the subclasses
L<XML::NewsML_G2::Writer::News_Item>,
L<XML::NewsML_G2::Writer::Package_Item> or
L<XML::NewsML_G2::Writer::News_Message> instead.

=head1 ATTRIBUTES

=over 4

=item news_item

L<XML::NewsML_G2::News_Item> instance used to create the output document

=item encoding

Encoding used to create the output document, defaults to utf-8

=item scheme_manager

L<XML::NewsML_G2::Scheme_Manager> instance used to create qcodes

=item doc

L<XML::LibXML::Document> instance used to create the output document

=item g2_ns

XML Namespace of NewsML-G2

=item xhtml_n2

XML Namespace of XHTML

=item g2_version

Use this attribute to specify the NewsML-G2 version to be
created. Defaults to 2.18, other valid options are: 2.9, 2.12 and
2.15. Be aware that only the later versions offer all features.

=item schema_location

Specified by subclass.

=item g2_catalog_url

URL of the G2 catalog, specified by subclass.

=item g2_catalog_schemes

Reference to a hash of schemes that are covered by the G2 catalog. If
the value is undefined, it defaults to the name of the scheme.

=item generator_version

Version of the generating software, as written to the output. Defaults
to the version of XML::NewsML_G2, but can be overwritten here (mainly
to ease automated testing).

=back

=head1 METHODS

=over 4

=item create_element

Helper method that creates XML elements, e.g. to be used in the
C<paragraphs> element of the L<XML::NewsML_G2::News_Item>.

=item create_dom

Returns the L<XML::LibXML::Document> element containing the requested
output. Be careful I<not> to use C<< $dom->serialize(2) >> for formatting,
as this creates invalid NewsML-G2 files because it adds whitespace
where none is allowed (e.g. in xs:dateTime elements).

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
