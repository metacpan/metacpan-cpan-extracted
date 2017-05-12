package Text::TOC::OutputHandler::HTML;
{
  $Text::TOC::OutputHandler::HTML::VERSION = '0.10';
}

use strict;
use warnings;
use namespace::autoclean;

use List::AllUtils qw( max );
use Text::TOC::Types qw( CodeRef Str );

use Moose;
use MooseX::StrictConstructor;

with 'Text::TOC::Role::OutputHandler';

has _toc => (
    is       => 'ro',
    isa      => 'HTML::DOM',
    init_arg => undef,
    lazy     => 1,
    default  => sub { HTML::DOM->new() },
);

has _link_generator => (
    is       => 'ro',
    isa      => CodeRef,
    init_arg => 'link_generator',
    required => 1,
);

has _style => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'style',
    default  => 'unordered',
);


sub process_node_list {
    my $self  = shift;
    my $nodes = shift;

    my $toc = $self->_toc();

    my $list_tag = $self->_style() eq 'unordered' ? 'ul' : 'ol';

    my $list = $toc->createElement($list_tag);
    $toc->appendChild($list);

    my $max_level = max map { $self->_node_level($_) } @{$nodes};

    my @lists = $list;

    my $last_node;

    for my $node ( @{$nodes} ) {
        $self->_insert_anchor($node);

        my $diff
            = $last_node
            ? $self->_node_level_difference( $node, $last_node )
            : $max_level - $self->_node_level($node);

        if ( $diff > 0 ) {
            for ( 1..$diff ) {
                my $new_list = $toc->createElement($list_tag);
                my $last_li  = $lists[-1]->lastChild();

                if ( ! $last_li ) {
                    $last_li = $toc->createElement('li');
                    $lists[-1]->appendChild($last_li);
                }

                $last_li->appendChild($new_list);

                push @lists, $new_list;
            }
        }
        elsif ( $diff < 0 ) {
            pop @lists for 1..abs($diff);
        }

        my $li   = $toc->createElement('li');
        my $link = $toc->createElement('a');
        $link->setAttribute(
            href => $self->_link_generator->( $node ) );
        $link->appendChild( $toc->createTextNode( $node->contents()->as_text() ) );

        $li->appendChild($link);

        $lists[-1]->appendChild($li);

        $last_node = $node;
    }

    return $toc;
}

sub _node_level_difference {
    my $self      = shift;
    my $this_node = shift;
    my $last_node = shift;

    return 0 unless defined $last_node;

    return $self->_node_level($last_node) - $self->_node_level($this_node);
}

{
    my %node_levels = (
        h1 => 7,
        h2 => 6,
        h3 => 5,
        h4 => 4,
        h5 => 3,
        h6 => 2,
    );

    sub _node_level {
        my $self = shift;
        my $node = shift;

        return $node_levels{ $node->type() } || 1;
    }
}

sub _insert_anchor {
    my $self = shift;
    my $node = shift;

    my $domlet = $node->contents();
    my $anchor = $domlet->ownerDocument()->createElement('a');
    $anchor->setAttribute( name => $node->anchor_name() );

    $domlet->insertBefore( $anchor, $domlet->firstChild() );

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Implements an output handler for HTML documents


__END__
=pod

=head1 NAME

Text::TOC::OutputHandler::HTML - Implements an output handler for HTML documents

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This class is responsible for generating a complete table of contents, and
inserting anchors into an HTML node.

It has no end-user facing parts at the moment.

=for Pod::Coverage process_node_list

=head1 ROLES

This class does the L<Text::TOC::Role::OutputHandler> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

