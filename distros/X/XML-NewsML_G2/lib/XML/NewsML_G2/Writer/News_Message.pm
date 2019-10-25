package XML::NewsML_G2::Writer::News_Message;

use Moose;
use List::MoreUtils qw(uniq);
use namespace::autoclean;

extends 'XML::NewsML_G2::Writer';

has 'news_message',
    isa      => 'XML::NewsML_G2::News_Message',
    is       => 'ro',
    required => 1;
has '+_root_node_name', default => 'newsMessage';

sub _build__root_item {
    my $self = shift;
    return $self->news_message;
}

sub _create_header {
    my ( $self, $root ) = @_;

    my $header = $self->create_element('header');
    $header->appendChild(
        $self->create_element(
            'sent',
            _text => $self->_formatter->format_datetime(
                $self->news_message->sent
            )
        )
    );
    for my $dest ( @{ $self->news_message->destination } ) {
        next unless $dest;
        my %attr = ( '_text' => $dest->name );
        $attr{role} = $dest->role if $dest->role;
        $header->appendChild( $self->create_element( 'destination', %attr ) );
    }

    $root->appendChild($header);
    return;
}

sub _create_itemSet {
    my ( $self, $root ) = @_;
    my $item_set = $self->create_element('itemSet');

    my $writer;
    for my $item ( @{ $self->news_message->items } ) {
        if ( $item->isa('XML::NewsML_G2::News_Item') ) {
            $writer = XML::NewsML_G2::Writer::News_Item->new(
                news_item      => $item,
                scheme_manager => $self->scheme_manager,
                g2_version     => $self->g2_version
            );
        }
        elsif ( $item->isa('XML::NewsML_G2::Package_Item') ) {
            $writer = XML::NewsML_G2::Writer::Package_Item->new(
                package_item   => $item,
                scheme_manager => $self->scheme_manager,
                g2_version     => $self->g2_version
            );
        }

        $item_set->appendChild( $writer->create_dom()->documentElement() );
    }
    $root->appendChild($item_set);
    return;
}

override '_create_root_element' => sub {
    my $self = shift;

    my $root =
        $self->doc->createElementNS( $self->g2_ns, $self->_root_node_name );
    $self->doc->setDocumentElement($root);
    return $root;
};

override 'create_dom' => sub {
    my $self = shift;
    $self->_import_iptc_catalog();

    my $root = $self->_create_root_element();
    $self->_create_header($root);
    $self->_create_itemSet($root);

    return $self->doc;
};

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Writer::News_Message - create DOM tree conforming to
NewsML-G2 for News Messages

=for test_synopsis
    my ($nm, $sm);

=head1 SYNOPSIS

    my $w = XML::NewsML_G2::Writer::News_Message->new
        (news_message => $nm, scheme_manager => $sm);

    my $dom = $w->create_dom();

=head1 DESCRIPTION

This module implements the creation of a DOM tree conforming to
NewsML-G2 for News messages.  Depending on the version of the standard
specified, a version-dependent role will be applied. For the API of
this module, see the documentation of the superclass L<XML::NewsML_G2::Writer>.

=head1 ATTRIBUTES

=over 4

=item news_message

L<XML::NewsML_G2::News_Message> instance used to create the output document

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
