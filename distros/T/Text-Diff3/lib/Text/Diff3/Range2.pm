package Text::Diff3::Range2;
use 5.006;
use strict;
use warnings;
use base qw(Text::Diff3::Base);

use version; our $VERSION = '0.08';

## no critic (NamingConventions::Capitalization)

__PACKAGE__->mk_attr_accessor(qw(type loA hiA loB hiB));

sub set_type_a { return shift->set_type('a') }
sub set_type_c { return shift->set_type('c') }
sub set_type_d { return shift->set_type('d') }
sub rangeA { return ($_[0]->loA .. $_[0]->hiA) }
sub rangeB { return ($_[0]->loB .. $_[0]->hiB) }

sub set_type {
    my($self, $x) = @_;
    $self->{type} = $x;
    return $self;
}

sub as_array {
    my($self) = @_;
    return @{$self}{qw(type loA hiA loB hiB)};
}

sub as_string {
    my($self) = @_;
    return $self->_as_line_range($self->loA, $self->hiA)
         . $self->type
         . $self->_as_line_range($self->loB, $self->hiB);
}

sub initialize {
    my($self, @arg) = @_;
    $self->SUPER::initialize(@arg);
    @{$self}{qw(type loA hiA loB hiB)} = @arg[1 .. 5];
    return $self;
}

sub _as_line_range {
    my($self, $lo, $hi) = @_;
    return $lo >= $hi ? $hi : $lo . q{,} . $hi;
}

1;

__END__

=pod

=head1 NAME

Text::Diff3::Range2 - two way difference container

=head1 VERSION

0.08

=head1 SYNOPSIS

    use Text::Diff3;
    my $f = Text::Diff3::Factory;
    my $range2 = $f->create_range2('c', 100,102, 104,110);
    $type = $range2->type;    # 'c'
    $line_no = $range2->loA;  # 100
    $line_no = $range2->hiA;  # 102
    $line_no = $range2->loB;  # 104
    $line_no = $range2->hiB;  # 110
    print $range2->as_string, "\n"; # 100,102c104,110

=head1 DESCRIPTION

This module provides you to handle two way difference sets.

=head1 METHODS

=over

=item C<< $r->as_string >>

Returns values as string like as '100,102c104,110'.

=item C<< $r->as_array >>

Returns values as array (type, loA, hiA, loB, hiB).

=item C<< $r->type >>

Has one of types of range. c: change, a: append, d: delete.

=item C<< $r->loA >>

Has a low line number of range in text A.
 
=item C<< $r->hiA >>

Has a hi line number of range in text A.

=item C<< $r->rangeA >>

Returns ($r->loA .. $r->hiA).

=item C<< $r->loB >>

Has a low line number of range in text B.

=item C<< $r->hiB >>

Has a hi line number of range in text B.

=item C<< $r->rangeB >>

Returns ($r->loB .. $r->hiB).

=item C<< $r->set_type($c) >>

Sets type.

=item C<< $r->set_type_a >>

Lets type a: append.

=item C<< $r->set_type_c >>

Lets type c: change.

=item C<< $r->set_type_d >>

Lets type d: delete.

=item C<< $r->initialize >>

Initializes the instance.

=back

=head1 COMPATIBILITY

Use new function style interfaces introduced from version 0.08.
This module remained for backward compatibility before version 0.07.
This module is no longer maintenance after version 0.08.

=head1 AUTHOR

MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 MIZUTANI Tociyuki

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

=cut

