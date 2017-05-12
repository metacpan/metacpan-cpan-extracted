package Tree::Predicate;

use warnings;
use strict;

use base 'Exporter';

use Storable qw(dclone);

our @EXPORT_OK = qw(AND OR NOT);
our %EXPORT_TAGS = (logical => [qw(AND OR NOT)]);

use constant SPLIT_LIMIT => 50;

=head1 NAME

Tree::Predicate - a balanced, splittable tree for SQL predicates

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Tree::Predicate allows the composition of a tree of SQL predicates that
can then be "split" into UNION-able predicats that do not contain an OR.

    use Tree::Predicate qw(:logical);
    
    my $left_branch = OR('a', 'b');
    my $right_branch = OR('c', 'd');
    my $tree = AND($left_branch, $right_branch);
    
    print $tree->as_string; # ((a OR b) AND (c OR d))
    
    my @trees = $tree->split;
    # four trees
    # (a AND c)
    # (a AND d)
    # (b AND c)
    # (b AND d)
    
    $tree->negate;
    print $tree->as_string; # ((NOT(a) AND NOT(b)) OR (NOT(c) AND NOT(d)))

=head1 EXPORT

AND/OR/NOT may be individually imported, or they may be collectively
imported with :logical.

=head1 FUNCTIONS

=head2 as_string

expresses the tree as a string suitable for including in SQL

=cut

sub as_string {
    my $self = shift;

    '(' . join(" $self->{OP} ", map { $_->as_string } @{$self->{OPERANDS}}) . ')';
}

=head2 negate

negates the tree

=cut

# negating means to change the node form AND/OR to OR/AND and to negate
# the children
sub negate {
    my $self = shift;

    $self->{OP} = $self->{OP} eq 'AND' ? 'OR' : 'AND';
    for (@{$self->{OPERANDS}}) {
        $_->negate;
    }
}

=head2 operands

returns a list (or reference) of the tree's operands, for whatever
you might want that

=cut

sub operands {
    my $self = shift;

    wantarray ? @{$self->{OPERANDS}} : $self->{OPERANDS};
}

=head2 split

returns a list of subtrees that can be used in a UNION statement to
produce a logically equivalent query.

dies if number of children exceeds SPLIT_LIMIT

=cut

sub split {
    my $self = shift;

    my @results;
    if ($self->{OP} eq 'AND') {
        my @children;
        for (@{$self->{OPERANDS}}) {
            my $child = dclone $_;
            push @children, [$child->split];
        }
        @results = _produce_combinations(@children);
    } elsif ($self->{OP} eq 'OR') {
        push @results, $_->split for (@{$self->{OPERANDS}});
    } else {
        die "unknown operand $self->{OP}";
    }
    die "too many children" if @results > SPLIT_LIMIT;
    @results;
}

=head2 AND/OR/NOT

constructors for trees

=cut

sub AND { __PACKAGE__->_new_AND(@_); }
sub OR  { __PACKAGE__->_new_OR(@_);  }

sub NOT {
    my $operand = shift || die "operand required";
    die "too many operands" if @_;

    if (UNIVERSAL::isa($operand, __PACKAGE__)) {
        $operand->negate;
        $operand;
    } else {
        require Tree::Predicate::Leaf;
        Tree::Predicate::Leaf->new($operand, negated => 1);
    }
}

# internal constructors and mutators.  Invited guests only!

sub _new {
    my $op = shift;
    
    return sub {
        my $class = shift;
        
        my @operands;
        for (@_) {
            if (UNIVERSAL::isa($_, __PACKAGE__)) {
                if (defined($_->{OP}) && $_->{OP} eq $op) {
                    push @operands, $_->operands;
                } else {
                    push @operands, $_;
                }
            } else {
                require Tree::Predicate::Leaf;
                push @operands, Tree::Predicate::Leaf->new($_);
            }
        }
        return $operands[0] if @operands == 1;
        
        my $self = {
            OP => $op,
            OPERANDS => \@operands,
        };
        bless $self, $class;
    };
}

*_new_AND = _new('AND');
*_new_OR  = _new('OR');

sub _produce_combinations {
    my $aryref = shift;
    
    my @combinations;
    if (@_) {
        for my $term (@$aryref) {
            push @combinations,
                map { AND(dclone $term, $_) } _produce_combinations(@_);
        }
        die "too many children" if @combinations > SPLIT_LIMIT;
        @combinations;
    } else {
        map { dclone $_ } @$aryref;
    }
}

=head1 AUTHOR

David Marshall, C<< <dmarshal at yahoo-inc.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-predicate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tree-Predicate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tree::Predicate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Predicate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tree-Predicate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tree-Predicate>

=item * Search CPAN

L<http://search.cpan.org/dist/Tree-Predicate/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Yahoo! Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Tree::Predicate
