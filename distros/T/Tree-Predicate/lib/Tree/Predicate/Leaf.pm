package Tree::Predicate::Leaf;
use warnings;
use strict;

use base 'Tree::Predicate';

=head1 NAME

Tree::Predicate::Leaf - internal subclass for Tree::Predicate

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module is None of Your Business (tm).

Please see Tree::Predicate

=head1 FUNCTIONS

=head2 new

creates a new Tree::Predicate::Leaf

=cut

sub new {
    my $class = shift;
    my $atom = shift;
    my %options = @_;
    
    my $self = {
        ATOM => $atom,
        NEGATED => exists $options{negated},
    };
    
    bless $self, $class;
}

=head2 as_string

expresses the tree as a string suitable for including in SQL

=cut

sub as_string {
    my $self = shift;
    
    if ($self->{NEGATED}) {
        "NOT($self->{ATOM})";
    } else {
        $self->{ATOM};
    }
}

=head2 negate

flips the NEGATED bit

=cut

sub negate {
    my $self = shift;
    
    $self->{NEGATED} ^= 1;
}

=head2 operands

a leaf has no operands!

=cut

sub operands { }

=head2 split

unsplittable, that's what it is
so unsplittable, mind your own biz

=cut

sub split { @_; }

1;
