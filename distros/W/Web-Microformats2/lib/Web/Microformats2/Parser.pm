package Web::Microformats2::Parser;

use Moo;
use Types::Standard qw(InstanceOf);
use HTML::TreeBuilder::XPath;
use HTML::Entities;
use v5.10;
use Scalar::Util qw(blessed);
use JSON;
use DateTime::Format::ISO8601;
use URI;
use Carp;

use Web::Microformats2::Item;
use Web::Microformats2::Document;

use Readonly;

has 'url_context' => (
    is => 'rw',
    isa => InstanceOf['URI'],
    coerce => sub { URI->new( $_[0] ) },
    lazy => 1,
    clearer => '_clear_url_context',
    default => sub { URI->new( 'http://example.com/' ) },
);

sub parse {
    my $self = shift;
    my ( $html, %args ) = @_;

    $self->_clear;
    if ( $args{ url_context } ) {
        $self->url_context( $args{url_context} );
    }

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->ignore_unknown( 0 );
    $tree->no_space_compacting( 1 );
    $tree->ignore_ignorable_whitespace( 0 );
    $tree->no_expand_entities( 1 );

    # Adding HTML5 elements because it's 2018.
    foreach (qw(article aside details figcaption figure footer header main mark nav section summary time)) {
        $HTML::TreeBuilder::isBodyElement{$_}=1;
    }

    $tree->parse( $html );

    if ( my $base_url = $tree->findvalue( './/base/@href' ) ) {
        $self->url_context( $base_url );
    }

    my $document = Web::Microformats2::Document->new;
    $self->analyze_element( $document, $tree );
    return $document;
}

# analyze_element: Recursive method that scans an element for new microformat
# definitions (h-*) or properties (u|dt|e|p-*) and then does the right thing.
# It also builds up the MF2 document's rels and rel-urls as it goes.
sub analyze_element {
    my $self = shift;
    my ( $document, $element, $current_item ) = @_;

    return unless blessed( $element) && $element->isa( 'HTML::Element' );

    $self->_add_element_rels_to_mf2_document( $element, $document );

    my $mf2_attrs = $self->_tease_out_mf2_attrs( $element );

    my $h_attrs = delete $mf2_attrs->{h};
    my $new_item;
    if ( $h_attrs->[0] ) {
        $new_item = Web::Microformats2::Item->new( {
            types => $h_attrs,
            parent => $current_item,
        } );
        $document->add_item( $new_item );
        unless ( $current_item ) {
            $document->add_top_level_item( $new_item );
        }
    }

    while (my ($mf2_type, $properties_ref ) = each( %$mf2_attrs ) ) {
        next unless $current_item;
        next unless @{ $properties_ref };
        if ( $mf2_type eq 'p' ) {
            # p-property:
            # A catch-all generic property to store on the current
            # MF2 item being defined.
            # (If this same element begins an h-* microformat, we don't parse
            # this p-* any further; instead we'll store the new item under
            # this property name.)
            unless ( $new_item ) {
                for my $property ( @$properties_ref ) {
                    my $value = $self->_parse_property_value( $element );
                    if ( defined $value ) {
                        $current_item->add_property(
                            "p-$property",
                            $value,
                        );
                    }
                }
            }
        }
        elsif ( $mf2_type eq 'u' ) {
            # u-property:
            # Look for a URL in child attributes, and store it as a property.

            # (But not if a new h-format has been defined, in which case we'll
            # just use the u-property's name to store it. Why would you do that
            # instead of using a p-property? I don't know, but the tests demand
            # it.)
            unless ( $new_item ) {
                for my $property ( @$properties_ref ) {
                    my $vcp_fragments_ref =
                        $self->_seek_value_class_pattern( $element );
                    if ( my $url = $self->_tease_out_url( $element ) ) {
                        $current_item->add_property( "u-$property", $url );
                    }
                    elsif ( @$vcp_fragments_ref ) {
                        $current_item->add_property(
                            "u-$property",
                            join q{}, @$vcp_fragments_ref,
                        )
                    }
                    elsif ( $url = $self->_tease_out_unlikely_url($element)) {
                        $current_item->add_property( "u-$property", $url );
                    }
                    else {
                        $current_item->add_property(
                            "u-$property",
                            _trim( $element->as_text ),
                        );
                    }
                }
            }
        }
        elsif ( $mf2_type eq 'e' ) {
            # e-property:
            # Create a struct with keys "html" and "value", and then
            # store this in a new property.
            for my $property ( @$properties_ref ) {
                my %e_data;
                for my $content_piece ( $element->content_list ) {

                    # Make sure all URLs found in certain HTML attrs are
                    # absolute.
                    if ( ref $content_piece ) {
                        # XXX This is probably a bit too loose about what tags
                        #     these attrs can appear on.
                        for my $href_element ( $content_piece, $content_piece->findnodes('.//*[@href|@src]') ) {
                            foreach ( qw( href src ) ) {
                                my $url = $href_element->attr($_);
                                if ( $url ) {
                                    my $abs_url = URI->new_abs( $url, $self->url_context)->as_string;
                                    $href_element->attr( $_=> $abs_url );
                                }
                            }
                        }
                        $e_data{html} .= $content_piece->as_HTML( '<>&', undef, {} );

                    }
                    else {

                        $e_data{html} .= $content_piece;
                    }
                }
                $e_data{ value } = _trim (decode_entities( $element->as_text) );

                # The official tests specifically trim space-glyphs per se;
                # all other trailing whitespace stays. Shrug.
                $e_data{ html } =~ s/ +$//;

                $current_item->add_property( "e-$property", \%e_data );
            }
        }
        elsif ( $mf2_type eq 'dt' ) {
            # dt-property:
            # Read a child attribute as an ISO-8601 date-time string.
            # Store it as a property in the MF2 date-time representation format.
            for my $property ( @$properties_ref ) {
                my $dt_string;
                my $vcp_fragments_ref =
                    $self->_seek_value_class_pattern( $element );
                if ( @$vcp_fragments_ref ) {
                    $dt_string = $self->_format_datetime(join (q{T}, @$vcp_fragments_ref), $current_item);
                }
                elsif ( my $alt = $element->findvalue( './@datetime|@title|@value' ) ) {
                    $dt_string = $alt;
                }
                elsif ( my $text = $element->as_trimmed_text ) {
                    $dt_string = $text;
                }
                if ( defined $dt_string ) {
                    $current_item->add_property(
                        "dt-$property",
                        $dt_string,
                    );
                }
            }
        }
    }

    if ( $new_item ) {
        for my $child_element ( $element->content_list ) {
            $self->analyze_element( $document, $child_element, $new_item );
        }

        # Now that the new item's been recursively scanned, perform
        # some post-processing.
        # First, add any implied properties.
        for my $impliable_property (qw(name photo url)) {
             unless ( $new_item->has_property( $impliable_property ) ) {
                 my $method = "_set_implied_$impliable_property";
                $self->$method( $new_item, $element );
            }
        }

        # Put this onto the parent item's property-list, or its children-list,
        # depending on context.
        my @item_properties;
        for my $prefix (qw( u p ) ) {
            push @item_properties, map { "$prefix-$_" } @{ $mf2_attrs->{$prefix} };
        }
        if ( $current_item && @item_properties ) {
            for my $item_property ( @item_properties ) {
                # We place a clone of the new item into the current item's
                # property list, rather than the item itself. This allows for
                # edge cases where the same item needs to go under multiple
                # properties, but carry different 'value' attributes.
                my $cloned_new_item =
                    bless { %$new_item }, ref $new_item;

                $current_item
                    ->add_property( "$item_property", $cloned_new_item );

                # Now add a "value" attribute to this new item, if appropriate,
                # according to the MF2 spec.
                my $value_attribute;
                if ( $item_property =~ /^p-/ ) {
                    if ( my $name = $new_item->get_properties('name')->[0] ) {
                        $value_attribute = $name;
                    }
                    else {
                        $value_attribute =
                            $self->_parse_property_value( $element );
                    }
                }
                elsif ( $item_property =~ /^u-/ ) {
                    $value_attribute = $new_item->get_properties('url')->[0];
                }

                $cloned_new_item->value( $value_attribute ) if defined ($value_attribute);
            }
        }
        elsif ($current_item) {
            $current_item->add_child ( $new_item );
        }

    }
    else {
        for my $child_element ( $element->content_list ) {
            $self->analyze_element( $document, $child_element, $current_item );
        }
    }
}

sub _tease_out_mf2_attrs {
    my $self = shift;
    my ( $element ) = @_;

    my %mf2_attrs;
    foreach ( qw( h e u dt p ) ) {
        $mf2_attrs{ $_ } = [];
    }

    my $class_attr = $element->attr('class');
    if ( $class_attr ) {
        while ($class_attr =~ /\b(h|e|u|dt|p)-([a-z]+(\-[a-z]+)*)($|\s)/g ) {
            my $mf2_type = $1;
            my $mf2_attr = $2;

            push @{ $mf2_attrs{ $mf2_type } }, $mf2_attr;
        }
    }

    return \%mf2_attrs;
}

sub _tease_out_url {
    my $self = shift;
    my ( $element ) = @_;

    my $xpath;
    my $url;
    if ( $element->tag =~ /^(a|area|link)$/ ) {
        $xpath = './@href';
    }
    elsif ( $element->tag =~ /^(img|audio)$/ ) {
        $xpath = './@src';
    }
    elsif ( $element->tag eq 'video' ) {
        $xpath = './@src|@poster';
    }
    elsif ( $element->tag eq 'object' ) {
        $xpath = './@data';
    }

    if ( $xpath ) {
        $url = $element->findvalue( $xpath );
    }

    if ( defined $url ) {
        $url = URI->new_abs( $url, $self->url_context )->as_string;
    }

    return $url;
}

sub _tease_out_unlikely_url {
    my $self = shift;
    my ( $element ) = @_;

    my $xpath;
    my $url;
    if ( $element->tag eq 'abbr' ) {
        $xpath = './@title';
    }
    elsif ( $element->tag =~ /^(data|input)$/ ) {
        $xpath = './@value';
    }

    if ( $xpath ) {
        $url = $element->findvalue( $xpath );
    }

    return $url;
}

sub _set_implied_name {
    my $self = shift;
    my ( $item, $element ) = @_;

    my $types = $item->types;

    return if $item->has_properties || $item->has_children;

    my $xpath;
    my $name;
    my $kid;
    my $accept_if_empty = 1; # If true, then null-string names are okay.
    if ( $element->tag =~ /^(img|area)$/ ) {
        $xpath = './@alt';
    }
    elsif ( $element->tag eq 'abbr' ) {
        $xpath = './@title';
    }
    elsif (
        ( $kid = $self->_non_h_unique_child( $element, 'img' ) )
        || ( $kid = $self->_non_h_unique_child( $element, 'area' ) )
    ) {
        $xpath = './@alt';
        $accept_if_empty = 0;
    }
    elsif ( $kid = $self->_non_h_unique_child( $element, 'abbr' ) ) {
        $xpath = './@title';
        $accept_if_empty = 0;
    }
    elsif (
        ( $kid = $self->_non_h_unique_grandchild( $element, 'img' ) )
        || ( $kid = $self->_non_h_unique_grandchild( $element, 'area' ) )
    ) {
        $xpath = './@alt';
        $accept_if_empty = 0;
    }
    elsif ( $kid = $self->_non_h_unique_grandchild( $element, 'abbr' ) ) {
        $xpath = './@title';
        $accept_if_empty = 0;
    }

    my $foo = $kid || $element;

    if ( $xpath ) {
        my $element_to_check = $kid || $element;
        my $value = $element_to_check->findvalue( $xpath );
         if ( ( $value ne q{} ) || $accept_if_empty ) {
            $name = $value;
         }
    }

    unless ( defined $name ) {
        $name = _trim( $element->as_text );
    }

    if ( length $name > 0 ) {
         $item->add_property( 'p-name', $name );
    }

}

sub _set_implied_photo {
    my $self = shift;
    my ( $item, $element ) = @_;

    my $xpath;
    my $url;
    my $kid;

    if ( $element->tag eq 'img' ) {
        $xpath = './@src';
    }
    elsif ( $element->tag eq 'object' ) {
        $xpath = './@data';
    }
    elsif ( $kid = $self->_non_h_unique_child( $element, 'img' ) ) {
        $xpath = './@src';
        $element = $kid;
    }
    elsif ( $kid = $self->_non_h_unique_child( $element, 'object' ) ) {
        $xpath = './@data';
        $element = $kid;
    }
    elsif ( $kid = $self->_non_h_unique_grandchild( $element, 'img' ) ) {
        $xpath = './@src';
        $element = $kid;
    }
    elsif ( $kid = $self->_non_h_unique_grandchild( $element, 'object' ) ) {
        $xpath = './@data';
        $element = $kid;
    }

    if ( $xpath ) {
        $url = $element->findvalue( $xpath );
    }

    if ( defined $url ) {
        $url = URI->new_abs( $url, $self->url_context )->as_string;
        $item->add_property( 'u-photo', $url );
    }

}

sub _set_implied_url {
    my $self = shift;
    my ( $item, $element ) = @_;

    my $xpath;
    my $url;

    my $kid;
    if ( $element->tag =~ /^(a|area)$/ ) {
        $xpath = './@href';
    }
    elsif (
        ( $kid = $self->_non_h_unique_child( $element, 'a' ) )
        || ( $kid = $self->_non_h_unique_child( $element, 'area' ) )
        || ( $kid = $self->_non_h_unique_grandchild( $element, 'a' ) )
        || ( $kid = $self->_non_h_unique_grandchild( $element, 'area' ) )
    ) {
        $xpath = './@href';
        $element = $kid;
    }

    if ( $xpath ) {
        $url = $element->findvalue( $xpath );
    }

    if ( defined $url ) {
        $url = URI->new_abs( $url, $self->url_context )->as_string;
        $item->add_property( 'u-url', $url );
    }

}

sub _non_h_unique_child {
    my $self = shift;
    my ( $element, $tag ) = @_;

    my @children = grep { (ref $_) && $_->tag eq $tag  } $element->content_list;

    if ( @children == 1 ) {
        my $mf2_attrs = $self->_tease_out_mf2_attrs( $children[0] );
        if (not ( $mf2_attrs->{h}->[0] ) ) {
            return $children[0];
        }
    }

    return;
}

sub _non_h_unique_grandchild {
    my $self = shift;
    my ( $element, $tag ) = @_;

    my @children = grep { ref $_ } $element->content_list;

    if ( @children == 1 ) {
        my $mf2_attrs = $self->_tease_out_mf2_attrs( $children[0] );
        if (not ( $mf2_attrs->{h}->[0] ) ) {
            return $self->_non_h_unique_child( $children[0], $tag );
        }
    }

    return;
}

sub _clear {
    my $self = shift;

    $self->_clear_url_context;
}

sub _seek_value_class_pattern {
    my $self = shift;

    my ( $element, $vcp_fragments_ref ) = @_;

    $vcp_fragments_ref ||= [];

    my $class = $element->attr( 'class' );
    if ( $class && $class =~ /\bvalue(-title)?\b/ ) {
        if ( $1 ) {
            push @$vcp_fragments_ref, $element->attr( 'title' );
        }
        elsif ( ( $element->tag =~ /^(del|ins|time)$/ ) && defined( $element->attr('datetime'))) {
            push @$vcp_fragments_ref, $element->attr('datetime');
        }
        else {
            my $html;
            for my $content_piece ( $element->content_list ) {
                if ( ref $content_piece ) {
                    $html .= $content_piece->as_HTML;
                }
                else {
                    $html .= $content_piece;
                }
            }
            push @$vcp_fragments_ref, $html;
        }
    }
    else {
        for my $child_element ( grep { ref $_ } $element->content_list ) {
            $self->_seek_value_class_pattern(
                $child_element, $vcp_fragments_ref
            );
        }
    }

    return $vcp_fragments_ref;
}

sub _trim {
    my ($string) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub _format_datetime {
    my ($self, $dt_string, $current_item) = @_;

    my $dt;

    # Knock off leading/trailing whitespace.
    $dt_string = _trim($dt_string);

    $dt_string =~ s/t/T/;

    # Note presence of AM/PM, but toss it out of the string.
    $dt_string =~ s/((?:a|p)\.?m\.?)//i;
    my $am_or_pm = $1 || '';

    # Store the provided TZ offset.
    my ($provided_offset) = $dt_string =~ /([\-\+Z](?:\d\d:?\d\d)?)$/;
    $provided_offset ||= '';

    # Reformat HHMM offset as HH:MM.
    $dt_string =~ s/(-|\+)(\d\d)(\d\d)/$1$2:$3/;

    # Store the provided seconds.
    my ($seconds) = $dt_string =~ /\d\d:\d\d:(\d\d)/;
    $seconds = '' unless defined $seconds;

    # Insert :00 seconds on time when paired with a TZ offset.
    $dt_string =~ s/T(\d\d:\d\d)([\-\+Z])/T$1:00$2/;
    $dt_string =~ s/^(\d\d:\d\d)([\-\+Z])/$1:00$2/;

    # Zero-pad hours when only a single-digit hour appears.
    $dt_string =~ s/T(\d)$/T0$1/;
    $dt_string =~ s/T(\d):/T0$1:/;

    # Insert :00 minutes on time when only an hour is listed.
    $dt_string =~ s/T(\d\d)$/T$1:00/;

    # Treat a space separator between date & time as a 'T'.
    $dt_string =~ s/ /T/;

    # If this is a time with no date, try to apply a previously-seen
    # date to it.
    my $date_is_defined = 1;
    if ( $dt_string =~ /^\d\d:/ ) {
        if ( my $previous_dt = $current_item->last_seen_date ) {
            $dt_string = $previous_dt->ymd . "T$dt_string";
        }
        else {
            $date_is_defined = 0;
            carp "Encountered a value-class datetime with only a time, "
                 . "no date, and no date defined earlier. Results may "
                 . "not be what you expect. (Data: $dt_string)";
        }
    }

    eval {
    $dt = DateTime::Format::ISO8601->new
              ->parse_datetime( $dt_string );
    };

    return if $@;

    if ($date_is_defined) {
        $current_item->last_seen_date( $dt );
    }

    if ($am_or_pm =~ /^[pP]/) {
        # There was a 'pm' specified, so add 12 hours.
        $dt->add( hours => 12 );
    }

    my $format;
    if ( ($dt_string =~ /-/) && ($dt_string =~ /[ T]/) ) {
        my $offset;
        if ($provided_offset eq 'Z') {
            $offset = 'Z';
        }
        elsif ($provided_offset) {
            $offset = '%z';
        }
        else {
            $offset = '';
        }
        $seconds = ":$seconds" if length $seconds;
        $format = "%Y-%m-%d %H:%M$seconds$offset";
    }
    elsif ( $dt_string =~ /-/ ) {
        $format = '%Y-%m-%d';
    }

    return $dt->strftime( $format );
}

sub _parse_property_value {
    my ( $self, $element ) = @_;

    my $value;

    my $vcp_fragments_ref =
        $self->_seek_value_class_pattern( $element );
    if ( @$vcp_fragments_ref ) {
        $value = join q{}, @$vcp_fragments_ref;
    }
    elsif ( my $alt = $element->findvalue( './@title|@value|@alt' ) ) {
        $value = $alt;
    }
    elsif ( my $text = _trim( decode_entities($element->as_text) ) ) {
        $value = $text;
    }

    return $value;
}

sub _add_element_rels_to_mf2_document {
    my ( $self, $element, $document ) = @_;

    return unless $element->tag =~ /^(a|link)$/;

    my $rel = $element->attr( 'rel' );
    return unless defined $rel;

    my $href = $element->attr( 'href' );
    my $url = URI->new_abs( $href, $self->url_context)->as_string;

    my @rels = split /\s+/, $rel;
    for my $rel ( @rels ) {
        $document->add_rel( $rel, $url );
    }

    my $rel_url_value = {};
    foreach (qw( hreflang media title type ) ) {
        next if defined $rel_url_value->{ $_ };
        my $value = $element->attr( $_ );
        if ( defined $value ) {
            $rel_url_value->{ $_ } = $value;
        }
    }
    my $text = ($element->as_text);
    if ( defined $text ) {
        $rel_url_value->{ text } = $text;
    }

    $rel_url_value->{ rels } = \@rels;

    $document->add_rel_url( $url, $rel_url_value );

}

1;

=pod

=head1 NAME

Web::Microformats2::Parser - Read Microformats2 information from HTML

=head1 DESCRIPTION

An object of this class represents a Microformats2 parser.

See L<Web::Microformats2> for further context and purpose.

=head1 METHODS

=head2 Class Methods

=head3 new

 $parser = Web::Microformats2::Parser->new;

Returns a parser object.

=head2 Object Methods

=head3 parse

 $doc = $parser->parse( $html, %args );

Pass in a string containing HTML which itself contains Microformats2
metadata, and receive a L<Web::Microformats2::Document> object in return.

The optional args hash recognizes the following keys:

=over

=item url_context

A L<URI> object or URI-shaped string that will be used as a context for
transforming all relative URL properties encountered within MF2 tags
into absolute URLs.

The default value is C<http://example.com>, so you'll probably want to
set this to something more interesting, such as the absolute URL of the
HTML that we are parsing.

=back

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jason McIntosh.

This is free software, licensed under:

  The MIT (X11) License
