package Text::Diff3::List;
# list of difference sets
use 5.006;
use strict;
use warnings;
use base qw(Text::Diff3::ListMixin Text::Diff3::Base);

use version; our $VERSION = '0.08';

sub list { return $_[0]->{list} }

sub initialize {
    my($self, @arg) = @_;
    $self->SUPER::initialize(@arg);
    shift @arg; # drop factory
    $self->{list} = \@arg;
    return $self;
}

sub as_array {
    my($self) = @_;
    return map { [$_->as_array] } @{$self->list};
}

1;

__END__

=pod

=head1 NAME

Text::Diff3::List - a list of difference sets

=head1 VERSION

0.08

=head1 SYNOPSIS

  use Text::Diff3;
  my $f = Text::Diff3::Factory->new;
  my $diff2 = $f->create_list2;
  my $diff3 = $f->create_list3;

=head1 DESCRIPTION

=head1 METHODS

=over

=item C<< $obj->as_array >>

Returns the clone of array.

=item C<< $obj->list >>

Returns the body of array reference.

=item C<< $obj->initialize >>

Sets up the object.

=back

=head1 SEE ALSO

L<Text::Diff3::ListMixin>

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

