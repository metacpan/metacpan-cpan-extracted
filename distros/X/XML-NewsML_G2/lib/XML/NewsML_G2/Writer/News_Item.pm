package XML::NewsML_G2::Writer::News_Item;

use Scalar::Util qw(looks_like_number);
use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::Writer::Substancial_Item';

has 'news_item',
    isa      => 'XML::NewsML_G2::News_Item',
    is       => 'ro',
    required => 1;

sub _build__root_item {
    my $self = shift;
    return $self->news_item;
}

sub _create_rights_info {
    my ( $self, $root ) = @_;
    return unless $self->news_item->copyright_holder;

    my $ri = $self->create_element('rightsInfo');

    $ri->appendChild(
        my $crh = $self->create_element(
            'copyrightHolder',
            _name_text => $self->news_item->copyright_holder
        )
    );
    $crh->setAttribute( 'uri', $self->news_item->copyright_holder->uri )
        if $self->news_item->copyright_holder->uri;
    if ( my $qcode = $self->news_item->copyright_holder->qcode ) {
        $self->scheme_manager->add_qcode_or_literal( $crh,
            'copyright_holder', $qcode );
    }

    $self->_create_copyright_holder_remoteinfo($crh);

    my $notice = $self->news_item->copyright_holder->notice;
    $ri->appendChild(
        $self->create_element( 'copyrightNotice', _text => $notice ) )
        if $notice;
    $ri->appendChild(
        $self->create_element(
            'usageTerms', _text => $self->news_item->usage_terms
        )
    ) if $self->news_item->usage_terms;

    $root->appendChild($ri);
    return;
}

sub _create_hierarchy {

    # my ($self, $node, $schema) = @_;
    # code moved to Writer_2_9
    return;
}

sub _create_icon {

    #overwrite me
    return;
}

sub _create_subjects_desk {
    my $self = shift;
    my @res;

    push @res, $self->doc->createComment('desks')
        if $self->news_item->has_desks;
    foreach ( sort { $a->qcode cmp $b->qcode } @{ $self->news_item->desks } )
    {
        push @res,
            my $s = $self->create_element(
            'subject',
            type       => 'cpnat:abstract',
            _name_text => $_
            );
        $self->scheme_manager->add_qcode_or_literal( $s, 'desk', $_->qcode );
    }
    return @res;
}

sub _create_subjects_storytypes {
    my $self = shift;
    my @res;

    push @res, $self->doc->createComment('storytypes')
        if ( @{ $self->news_item->storytypes } );

    foreach ( sort { $a->qcode cmp $b->qcode }
        @{ $self->news_item->storytypes } ) {
        push @res,
            my $s = $self->create_element(
            'subject',
            type       => 'cpnat:abstract',
            _name_text => $_
            );
        $self->scheme_manager->add_qcode_or_literal( $s, 'storytype',
            $_->qcode );
    }
    return @res;
}

sub _sort_subjects_locations {
    if ( looks_like_number($a) && looks_like_number($b) ) {
        return ( $b->relevance // 0 ) <=> ( $a->relevance // 0 )
            || $a->qcode <=> $b->qcode;
    }
    else {
        return ( $b->relevance // 0 ) <=> ( $a->relevance // 0 )
            || $a->qcode cmp $b->qcode;
    }
}

sub _create_subjects_location {
    my $self = shift;
    my @res;

    push @res, $self->doc->createComment('locations')
        if $self->news_item->has_locations;

    foreach my $l (
        sort _sort_subjects_locations values %{ $self->news_item->locations }
    ) {
        my $why = $l->direct ? 'why:direct' : 'why:ancestor';
        push @res,
            my $s = $self->create_element(
            'subject',
            type       => 'cpnat:geoArea',
            why        => $why,
            _name_text => $l
            );
        $s->setAttribute( 'relevance', $l->relevance )
            if defined $l->relevance;
        $self->scheme_manager->add_qcode_or_literal( $s, 'geo', $l->qcode );
        if ( $l->iso_code ) {
            $s->appendChild( my $sa = $self->create_element('sameAs') );
            $self->scheme_manager->add_qcode_or_literal( $sa, 'iso3166_1a2',
                $l->iso_code );
        }
        if ( $l->parent ) {
            $s->appendChild( my $b = $self->create_element('broader') );
            $self->scheme_manager->add_qcode_or_literal( $b, 'geo',
                $l->parent->qcode );
            my $hierarchy = $self->_create_hierarchy( $l, 'geo' );
            $b->appendChild($hierarchy) if $hierarchy;
        }
    }
    return @res;
}

sub _create_subjects_organisation {
    my $self = shift;
    my @res;

    push @res, $self->doc->createComment('organisations')
        if $self->news_item->has_organisations;
    foreach my $org ( @{ $self->news_item->organisations } ) {
        push @res,
            my $o = $self->create_element(
            'subject',
            type       => 'cpnat:organisation',
            _name_text => $org
            );
        $self->scheme_manager->add_qcode_or_literal( $o, 'org', $org->qcode );
    }
    return @res;
}

sub _create_subjects_topic {
    my $self = shift;
    my @res;

    push @res, $self->doc->createComment('topics')
        if $self->news_item->has_topics;

    foreach my $topic ( @{ $self->news_item->topics } ) {
        push @res,
            my $t = $self->create_element(
            'subject',
            type       => 'cpnat:abstract',
            _name_text => $topic
            );
        $self->scheme_manager->add_qcode_or_literal( $t, 'topic',
            $topic->qcode );
    }

    return @res;
}

sub _create_subjects_product {
    my $self = shift;
    my @res;

    push @res, $self->doc->createComment('products')
        if $self->news_item->has_products;

    foreach my $product ( @{ $self->news_item->products } ) {
        push @res,
            my $p = $self->create_element(
            'subject',
            type       => 'cpnat:object',
            _name_text => $product
            );
        if ( $product->isbn ) {
            $self->scheme_manager->add_qcode_or_literal( $p, 'isbn',
                $product->isbn );
        }
        elsif ( $product->ean ) {
            $self->scheme_manager->add_qcode_or_literal( $p, 'ean',
                $product->ean );
        }
    }

    return @res;
}

sub _create_subjects_event_refs {
    my $self = shift;

    my @res;

    push @res, $self->doc->createComment('events')
        if $self->news_item->has_event_references;

    foreach my $event_ref ( @{ $self->news_item->event_references } ) {
        push @res,
            my $p = $self->create_element(
            'subject',
            type       => 'cpnat:event',
            _name_text => $event_ref->name
            );
        $self->scheme_manager->add_qcode_or_literal( $p, 'eventid',
            $event_ref->event_id );
    }
    return @res;
}

sub _create_subjects {
    my $self = shift;
    my @res;

    push @res, $self->_create_subjects_storytypes();
    push @res, $self->_create_subjects_desk();
    push @res, $self->_create_subjects_event_refs();
    push @res, $self->_create_subjects_media_topic();
    push @res, $self->_create_subjects_concepts()
        if ( $self->news_item->has_concepts );
    push @res, $self->_create_subjects_location();
    push @res, $self->_create_subjects_organisation();
    push @res, $self->_create_subjects_topic();
    push @res, $self->_create_subjects_product();

    return @res;
}

sub _create_company_data {
    my ( $self, $org, $root ) = @_;
    return unless ( $self->scheme_manager->crel );

    my $crel_alias = $self->scheme_manager->crel->alias;
    $root->appendChild(
        $self->create_element(
            'related',
            rel        => "$crel_alias:index",
            _name_text => $_
        )
    ) foreach ( @{ $org->indices } );
    $root->appendChild(
        $self->create_element(
            'related',
            rel        => "$crel_alias:exchange",
            _name_text => $_
        )
    ) foreach ( @{ $org->stock_exchanges } );
    return;
}

sub _create_asserts_organisation {
    my $self = shift;

    my @res;
    push @res, $self->doc->createComment('organisations')
        if $self->news_item->has_organisations;

    foreach my $org ( @{ $self->news_item->organisations } ) {
        push @res,
            my $a = $self->create_element( 'assert', _name_text => $org );
        $self->scheme_manager->add_qcode_or_literal( $a, 'org', $org->qcode );

        foreach ( @{ $org->isins } ) {
            $a->appendChild( my $sa = $self->create_element('sameAs') );
            $self->scheme_manager->add_qcode_or_literal( $sa, 'isin', $_ );
        }
        if ( $org->has_websites ) {
            $a->appendChild( my $od =
                    $self->create_element('organisationDetails') );
            $od->appendChild( my $ci = $self->create_element('contactInfo') );
            $ci->appendChild( $self->create_element( 'web', _text => $_ ) )
                foreach @{ $org->websites };
        }
        $self->_create_company_data( $org, $a );
    }
    return @res;
}

sub _create_asserts_location {
    my $self = shift;
    my @res;

    foreach my $loc_k ( sort keys %{ $self->news_item->locations } ) {
        my $location = $self->news_item->locations->{$loc_k};
        next
            unless ( defined $location->longitude
            && defined $location->latitude );
        push @res, my $l = $self->create_element('assert');
        $self->scheme_manager->add_qcode_or_literal( $l, 'geo',
            $location->qcode );

        $l->appendChild( my $geo_area_details =
                $self->create_element('geoAreaDetails') );
        $geo_area_details->appendChild( my $pos =
                $self->create_element('position') );

        $pos->setAttribute( $_, $location->$_ ) for qw/latitude longitude/;
    }

    return @res;
}

sub _create_asserts {
    my $self = shift;
    my @res;

    push @res, $self->_create_asserts_organisation();
    push @res, $self->_create_asserts_location();

    return @res;
}

sub _create_infosources {
    my ( $self, $root ) = @_;
    foreach ( @{ $self->news_item->sources } ) {
        next if $_ eq uc $self->news_item->provider->qcode;
        $root->appendChild( my $i =
                $self->create_element( 'infoSource', _name_text => $_ ) );
        $self->scheme_manager->add_role( $i, 'isrol', 'originfo' );
    }
    return;
}

sub _create_authors {
    my ( $self, $root ) = @_;
    foreach ( @{ $self->news_item->authors } ) {
        $root->appendChild( $self->_create_creator($_) );
    }
    return;
}

sub _create_content_meta {
    my ( $self, $root ) = @_;

    my $cm = $self->create_element('contentMeta');

    $self->_create_icon($cm);

    $cm->appendChild(
        $self->create_element(
            'urgency', _text => $self->news_item->priority
        )
    );

    if ( $self->news_item->content_created ) {
        my $t =
            $self->_formatter->format_datetime(
            $self->news_item->content_created );
        $cm->appendChild(
            $self->create_element( 'contentCreated', _text => $t ) );
    }
    if (    $self->news_item->content_modified
        and $self->news_item->content_created !=
        $self->news_item->content_modified ) {
        my $t =
            $self->_formatter->format_datetime(
            $self->news_item->content_modified );
        $cm->appendChild(
            $self->create_element( 'contentModified', _text => $t ) );
    }

    foreach ( @{ $self->news_item->cities } ) {
        $cm->appendChild(
            $self->create_element( 'located', _name_text => $_ ) );
    }

    if ( my $electiondistrict = $self->news_item->electiondistrict ) {
        $cm->appendChild(
            my $ed = $self->create_element(
                'located', _text => $electiondistrict->name
            )
        );
        $self->scheme_manager->add_qcode( $ed, 'electiondistrict',
            $electiondistrict->qcode );

        if ( my $electionprovince = $electiondistrict->province ) {
            my $ep = $self->create_element( 'located',
                _text => $electionprovince->name );
            $self->scheme_manager->add_qcode( $ep, 'electionprovince',
                $electionprovince->qcode );

            $ed->appendChild($ep);
        }
    }

    $self->_create_infosources($cm);
    $self->_create_authors($cm);

    if ( $self->news_item->message_id ) {
        $cm->appendChild(
            $self->create_element(
                'altId', _text => $self->news_item->message_id
            )
        );
    }

    if ( $self->news_item->byline ) {
        $cm->appendChild(
            $self->create_element( 'by', _text => $self->news_item->byline )
        );
    }

    if ( $self->news_item->dateline ) {
        $cm->appendChild(
            $self->create_element(
                'dateline', _text => $self->news_item->dateline
            )
        );
    }

    $cm->appendChild(
        $self->create_element(
            'language', tag => $self->news_item->language
        )
    );

    foreach ( @{ $self->news_item->genres } ) {
        $cm->appendChild( my $gn =
                $self->create_element( 'genre', _name_text => $_ ) );
        $self->scheme_manager->add_qcode_or_literal( $gn, 'genre',
            $_->qcode );
    }

    my @subjects = $self->_create_subjects();
    $cm->appendChild($_) foreach (@subjects);

    if ( $self->news_item->slugline ) {
        my $slug =
            $self->create_element( 'slugline',
            _text => $self->news_item->slugline );
        if ( $self->news_item->slugline_sep ) {
            $slug->setAttribute( 'separator',
                $self->news_item->slugline_sep );
        }
        $cm->appendChild($slug);
    }

    $cm->appendChild(
        my $hl1 = $self->create_element(
            'headline', _text => $self->news_item->title
        )
    );
    $self->scheme_manager->add_role( $hl1, 'hltype', 'title' );

    if ( $self->news_item->subtitle ) {
        $cm->appendChild(
            my $hl2 = $self->create_element(
                'headline', _text => $self->news_item->subtitle
            )
        );
        $self->scheme_manager->add_role( $hl2, 'hltype', 'subtitle' );
    }

    if ( $self->news_item->credit ) {
        $cm->appendChild(
            $self->create_element(
                'creditline', _text => $self->news_item->credit
            )
        );
    }

    foreach ( @{ $self->news_item->keywords } ) {
        $cm->appendChild( $self->create_element( 'keyword', _text => $_ ) );
    }

    if ( $self->news_item->caption ) {
        $cm->appendChild(
            my $desc = $self->create_element(
                'description', _text => $self->news_item->caption
            )
        );
        $self->scheme_manager->add_role( $desc, 'drol', 'caption' );
    }

    if ( $self->news_item->summary ) {
        $cm->appendChild(
            my $smry = $self->create_element(
                'description', _text => $self->news_item->summary
            )
        );
        $self->scheme_manager->add_role( $smry, 'drol', 'summary' );
    }

    $self->_create_teaser($cm);

    $root->appendChild($cm);

    my @asserts = $self->_create_asserts();
    $root->appendChild($_) foreach @asserts;
    return;
}

sub _create_content {
    my ( $self, $root ) = @_;

    $root->appendChild( my $cs = $self->create_element('contentSet') );
    my $inlinexml = $self->create_element( 'inlineXML',
        contenttype => 'application/xhtml+xml' );
    my $html = $self->create_element( 'html', _ns => $self->xhtml_ns );
    $html->appendChild( my $head =
            $self->create_element( 'head', _ns => $self->xhtml_ns ) );
    $head->appendChild(
        $self->create_element(
            'title',
            _ns   => $self->xhtml_ns,
            _text => $self->news_item->title
        )
    );
    $inlinexml->appendChild($html);

    $html->appendChild( my $body =
            $self->create_element( 'body', _ns => $self->xhtml_ns ) );

    $body->appendChild(
        $self->create_element(
            'h1',
            _ns   => $self->xhtml_ns,
            _text => $self->news_item->title
        )
    );
    $body->appendChild(
        $self->create_element(
            'h2',
            _ns   => $self->xhtml_ns,
            _text => $self->news_item->subtitle
        )
    ) if $self->news_item->subtitle;

    my @paras =
          $self->news_item->paragraphs
        ? $self->news_item->paragraphs->getChildNodes()
        : ();
    $body->appendChild($_) foreach (@paras);

    $cs->appendChild($inlinexml);
    foreach ( sort keys %{ $self->news_item->remotes } ) {
        my $rc = $self->create_element( 'remoteContent', href => $_ );
        $self->_create_remote_content( $rc, $self->news_item->remotes->{$_} );
        $cs->appendChild($rc);
    }
    foreach ( @{ $self->news_item->inlinedata } ) {
        my %args;
        if ( $_->isa('XML::NewsML_G2::Inline_CData') ) {
            $args{_cdata} = $_->data;
        }
        else {
            $args{_text} = $_->data;
        }
        $args{contenttype} = $_->mimetype if $_->mimetype;
        my $data = $self->create_element( 'inlineData', %args );
        $cs->appendChild($data);
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Writer::News_Item - create DOM tree conforming to
NewsML-G2 for News Items

=for test_synopsis
    my ($ni, $sm);

=head1 SYNOPSIS

    my $w = XML::NewsML_G2::Writer::News_Item->new
        (news_item => $ni, scheme_manager => $sm);

    my $p = $w->create_element('p', class => 'main', _text => 'blah');

    my $dom = $w->create_dom();

=head1 DESCRIPTION

This module implements the creation of a DOM tree conforming to
NewsML-G2 for News Items.  Depending on the version of the standard
specified, a version-dependent role will be applied. For the API of
this module, see the documentation of the superclass L<XML::NewsML_G2::Writer>.

=head1 ATTRIBUTES

=over 4

=item news_item

L<XML::NewsML_G2::News_Item> instance used to create the output document

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
