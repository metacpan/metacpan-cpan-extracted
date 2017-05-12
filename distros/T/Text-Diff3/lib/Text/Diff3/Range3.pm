package Text::Diff3::Range3;
use 5.006;
use strict;
use warnings;
use base qw(Text::Diff3::Base);

use version; our $VERSION = '0.08';

## no critic (NamingConventions::Capitalization)

__PACKAGE__->mk_attr_accessor(qw(type lo0 hi0 lo1 hi1 lo2 hi2));

sub as_array {
    my($self) = @_;
    return @{$self}{qw(type lo0 hi0 lo1 hi1 lo2 hi2)};
}

sub as_string {
    my($self) = @_;
    return sprintf '%s %d,%d %d,%d %d,%d',
        @{$self}{qw(type lo0 hi0 lo1 hi1 lo2 hi2)};
}

sub set_type_diff0 { return shift->set_type('0') }
sub set_type_diff1 { return shift->set_type('1') }
sub set_type_diff2 { return shift->set_type('2') }
sub set_type_diffA { return shift->set_type('A') }
sub range0 { return ($_[0]->lo0 .. $_[0]->hi0) }
sub range1 { return ($_[0]->lo1 .. $_[0]->hi1) }
sub range2 { return ($_[0]->lo2 .. $_[0]->hi2) }

sub set_type {
    my($self, $x) = @_;
    $self->{type} = $x;
    return $self;
}

sub initialize {
    my($self, @arg) = @_;
    $self->SUPER::initialize(@arg);
    @{$self}{qw(type lo0 hi0 lo1 hi1 lo2 hi2)} = @arg[1 .. 7];
    return $self;
}

1;

__END__

=pod

=head1 NAME

Text::Diff3::Range3 - three-way difference container

=head1 VERSION

0.08

=head1 SYNOPSIS

    use Text::Diff3;
    my $f = Text::Diff3::Factory;
    my $range3 = $f->create_range3(1, 2,3, 4,5, 6,7);
    $type = $range3->type;    # 1
    $line_no = $range3->lo0;  # 2
    $line_no = $range3->hi0;  # 3
    $line_no = $range3->lo1;  # 4
    $line_no = $range3->hi1;  # 5
    $line_no = $range3->lo2;  # 6
    $line_no = $range3->hi2;  # 7
    print $range3->as_string, "\n"; # 1 2,3 4,5 6,7

=head1 DESCRIPTION

This module provides you to handle trhee way difference sets.

=head1 METHODS

=over

=item C<< $r->as_string >>

Returns values as string like as '1 2,3 4,5 6,7'.

=item C<< $r->as_array >>

Returns values as array (type lo0 hi0 lo1 hi1 lo2 hi2).

=item C<< $r->type >>

Has one of types of range.
0: change text 0, 1: change text 1, 2: change text 2, A: conflict.

=item C<< $r->lo0 >>

Has a low line number of range in text 0.
 
=item C<< $r->hi0 >>

Has a hi line number of range in text 0.

=item C<< $r->range0 >>

Returns ($r->lo0 .. $r->hi0).

=item C<< $r->lo1 >>

Has a low line number of range in text 1.
 
=item C<< $r->hi1 >>

Has a hi line number of range in text 1.

=item C<< $r->range1 >>

Returns ($r->lo1 .. $r->hi1).

=item C<< $r->lo2 >>

Has a low line number of range in text 2.
 
=item C<< $r->hi2 >>

Has a hi line number of range in text 2.

=item C<< $r->range2 >>

Returns ($r->lo2 .. $r->hi2).

=item C<< $r->set_type($c) >>

Sets type.

=item C<< $r->set_type_diff0 >>

Lets type 0: change text 0.

=item C<< $r->set_type_diff1 >>

Lets type 1: change text 1.

=item C<< $r->set_type_diff2 >>

Lets type 2: change text 2.

=item C<< $r->set_type_diffA >>

Lets type A: conflict.

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

