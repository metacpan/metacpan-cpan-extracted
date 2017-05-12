package XML::Generator::RSS10::content;
{
  $XML::Generator::RSS10::content::VERSION = '0.02';
}

use strict;

use base 'XML::Generator::RSS10::Module';

use Params::Validate qw( validate SCALAR ARRAYREF );

sub NamespaceURI { 'http://purl.org/rss/1.0/modules/content/' }

use constant CONTENTS_SPEC => {
    encoded => { type => SCALAR,   optional => 1 },
    items   => { type => ARRAYREF, optional => 1 },
};

sub contents {
    my $class = shift;
    my $rss   = shift;
    my %p     = validate( @_, CONTENTS_SPEC );

    if ( exists $p{encoding} ) {
        $rss->_element( $class->Prefix, 'encoding', $p{encoding} );
    }

    if ( exists $p{encoded} ) {
        $rss->_element_with_cdata( 'content', 'encoded', $p{encoded} );
        $rss->_newline_if_pretty;
    }

    if ( exists $p{items} ) {
        $rss->_start_element( 'content', 'items' );
        $rss->_newline_if_pretty;

        $rss->_start_element( 'rdf', 'Bag' );
        $rss->_newline_if_pretty;

        foreach my $item ( @{ $p{items} } ) {
            $class->_item( $rss, $item );
        }

        $rss->_end_element( 'rdf', 'Bag' );
        $rss->_newline_if_pretty;

        $rss->_end_element( 'content', 'items' );
        $rss->_newline_if_pretty;
    }
}

use constant _ITEM_SPEC => {
    format   => { type => SCALAR },
    encoding => { type => SCALAR, optional => 1 },
    content  => { type => SCALAR, optional => 1 },
    about    => { type => SCALAR, optional => 1 },
};

sub _item {
    my $class = shift;
    my $rss   = shift;
    my %p     = validate( @_, _ITEM_SPEC );

    die
        "Must provide either content or about parameter for a content module item.\n"
        unless exists $p{about} || exists $p{content};

    $rss->_start_element( 'rdf', 'li' );
    $rss->_newline_if_pretty;

    my @att = exists $p{about} ? ( 'rdf', 'about', $p{about} ) : ();
    $rss->_start_element( 'content', 'item', \@att );
    $rss->_newline_if_pretty;

    $rss->_element(
        'content', 'format',
        [ 'rdf', 'resource', $p{format} ],
    );
    $rss->_newline_if_pretty;

    if ( exists $p{encoding} ) {
        $rss->_element(
            'content', 'encoding',
            [ 'rdf', 'resource', $p{encoding} ],
        );
        $rss->_newline_if_pretty;
    }

    if ( exists $p{content} ) {
        $rss->_element_with_cdata( 'rdf', 'value', $p{content} );
        $rss->_newline_if_pretty;
    }

    $rss->_end_element( 'content', 'item' );
    $rss->_newline_if_pretty;

    $rss->_end_element( 'rdf', 'li' );
    $rss->_newline_if_pretty;
}

1;

# ABSTRACT: Support for the Dublin Core (dc) RSS 1.0 module



=pod

=head1 NAME

XML::Generator::RSS10::content - Support for the Dublin Core (dc) RSS 1.0 module

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use XML::Generator::RSS10;

    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler );

    $rss->channel( title => 'Pants',
                   link  => 'http://pants.example.com/',
                   description => 'A fascinating pants site',
                   content     =>
                   { items =>
                     [ { format   => 'http://www.w3.org/1999/xhtml',
                         content  => '<b>Axis</b> Love',
                       },
                       { format   => 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional',
                         about    => 'http://example.com/content-elsewhere',
                       },
                       { format   => 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional',
                         encoding => 'http://www.w3.org/TR/REC-xml#dt-wellformed',
                         content  => '<i>italics</i>',
                       },
                     ],
                   },
                 );

=head1 DESCRIPTION

This module provides support for the Content (content) RSS 1.0 module.

=head1 PARAMETERS

This module expects to receive a single parameter, "items".  This
parameter should be an arrayref of hash references.  Each of these
hash references should contain a single item's content.

The hash references may contain the following parameters:

=over 4

=item * format

The value for the C<content:format> element.  Required.

=item * about

If this is given, then this key's value will be used for the
C<content:item> element's C<rdf:resource> attribute.  One of this key
or the "content" key is required.

=item * content

The content for the item.  One of this key or the "about" key is
required.

=item * encoding

If the content is well-formed XML, then this should be included, with
the value "http://www.w3.org/TR/REC-xml#dt-wellformed".

=back

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

