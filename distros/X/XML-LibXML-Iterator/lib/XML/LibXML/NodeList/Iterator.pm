# $Id: Iterator.pm,v 1.1.1.1 2002/11/08 17:18:36 phish Exp $
#
package XML::LibXML::NodeList::Iterator;

use strict;
use XML::NodeFilter qw(:results);

use vars qw($VERSION);
$VERSION = "1.03";

use overload
    '++' => sub { $_[0]->nextNode();     $_[0]; },
    '--' => sub { $_[0]->previousNode(); $_[0] },
    '<>'  =>  sub {return wantarray ? $_[0]->_get_all :  $_[0]->nextNode(); },
    ;

sub new {
    my $class = shift;
    my $list  = shift;
    my $self  = undef;
    if ( defined $list ) {
        $self = bless [
            $list,
            -1,
            [],
            ], $class;
    }

    return $self;
}

sub set_filter {
    my $self = shift;
    $self->[2] = [ @_ ];
}

sub add_filter {
    my $self = shift;
    push @{$self->[2]}, @_;
}

# helper function.
sub accept_node {
    foreach ( @{$_[0][2]} ) {
        my $r = $_->accept_node($_[1]);
        return $r if $r;
    }
    # no filters or all decline ...
    return FILTER_ACCEPT;
}

sub first    {
    $_[0][1]=0;
    my $s = scalar(@{$_[0][0]});
    while ( $_[0][1] < $s ) {
        last if $_[0]->accept_node($_[0][0][$_[0][1]]) == FILTER_ACCEPT;
        $_[0][1]++;
    }
    return undef if $_[0][1] == $s;
    return $_[0][0][$_[0][1]]; 
}

sub last     {
    my $i = scalar(@{$_[0][0]})-1;
    while($i >= 0){
        if ( $_[0]->accept_node($_[0][0][$i]) == FILTER_ACCEPT ) {
            $_[0][1] = $i;
            last;
        }
        $i--;
    }

    if ( $i < 0 ) {
        # this costs a lot, but is more safe
        return $_[0]->first;
    }
    return $_[0][0][$i];
}

sub current  { 
    if ( $_[0][1] >= 0 || $_[0][1] < scalar @{$_[0][0]} ) {
        return $_[0][0][$_[0][1]]; 
    }
    return undef;
}

sub index    { 
    if ( $_[0][1] >= 0 || $_[0][1] < scalar @{$_[0][0]} ) {
        return $_[0][1]; 
    }
    return undef;
}

sub next     { return $_[0]->nextNode(); }
sub previous { return $_[0]->previousNode(); }

sub nextNode     {
    my $nlen = scalar @{$_[0][0]};
    if ( $nlen <= ($_[0][1] + 1)) {
        return undef;
    }
    my $i = $_[0][1];
    $i = -1 if $i < 0; # assure that we end up with the first 
                       # element in the first iteration
    while ( 1 ) {
        $i++;
        return undef if $i >= $nlen;
        if ( $_[0]->accept_node( $_[0][0]->[$i] ) == FILTER_ACCEPT ) {
            $_[0][1] = $i;
            last;
        }
    }
    return $_[0][0]->[$_[0][1]];
}

sub previousNode {
    if ( $_[0][1] <= 0 ) {
        return undef;
    }
    my $i = $_[0][1];
    while ( 1 ) {
        $i--;
        return undef if $i < 0;
        if ( $_[0]->accept_node( $_[0][0]->[$i] ) == FILTER_ACCEPT ) {
            $_[0][1] = $i;
            last;
        }
    }
    return $_[0][0][$_[0][1]];
}

sub iterate  {
    my $self = shift;
    my $funcref = shift;
    my $rv;

    return unless defined $funcref && ref( $funcref ) eq 'CODE';

    $self->[1] = -1; # first element
    while ( my $node = $self->next ) {
        $rv = $funcref->( $self, $node );
    }
    return $rv;
}

# helper function for the <> operator
# returns all nodes that have not yet been accessed 
sub _get_all {
    my $self = shift;
    my @retval = ();
    my $node;
    while ( $node = $self->next() ) {
        push @retval, $node; 
    }
    return @retval;
}

1;

=pod

=head1 NAME

XML::LibXML::NodeList::Iterator - Iteration Class for XML::LibXML XPath results

=head1 SYNOPSIS

  use XML::LibXML;
  use XML::LibXML::NodeList::Iterator;

  my $doc = XML::LibXML->new->parse_string( $somedata );
  my $nodelist = $doc->findnodes( $somexpathquery );

  my $iter= XML::LibXML::NodeList::Iterator->new( $nodelist );

  # more control on the flow
  while ( $iter->nextNode ) {
      # do something
  }

  # operate on the entire tree
  $iter->iterate( \&operate );

=head1 DESCRIPTION

XML::LibXML::NodeList::Iterator is very similar to
XML::LibXML::Iterator, but it does not iterate on the tree structure
but on a XML::LibXML::NodeList object. Because XML::LibXML::NodeList
is basicly an array the functionality of
XML::LibXML::NodeList::Iterator is more restircted to stepwise
foreward and backward than XML::LibXML::Iterator is.

=head1 SEE ALSO

L<XML::LibXML::NodeList>, L<XML::NodeFilter>, L<XML::LibXML::Iterator>

=head1 AUTHOR

Christian Glahn, E<lt>phish@cpan.orgE<gt>

=head1 COPYRIGHT

(c) 2002-2007, Christian Glahn. All rights reserved.

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
