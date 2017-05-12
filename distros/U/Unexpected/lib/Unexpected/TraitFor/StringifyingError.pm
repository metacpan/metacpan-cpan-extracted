package Unexpected::TraitFor::StringifyingError;

use namespace::autoclean;

use Unexpected::Functions qw( inflate_placeholders parse_arg_list );
use Unexpected::Types     qw( ArrayRef Bool Str );
use Moo::Role;

requires qw( BUILD );

# Object attributes (public)
has 'args'  => is => 'ro', isa => ArrayRef, default => sub { [] };

has 'error' => is => 'ro', isa => Str, default => 'Unknown error';

has 'no_quote_bind_values' => is => 'ro', isa => Bool, default => 0;

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = parse_arg_list( @args );

   my $e = delete $attr->{error};

   $e and ref $e eq 'CODE' and $e = $e->( $self, $attr );
   $e and $e .= q() and chomp $e;
   $e and $attr->{error} = $e;
   return $attr;
};

after 'BUILD' => sub {
   # Fixes 98c94be8-d01e-11e2-8bc5-3f0fbdbf7481 WTF? Stringify fails.
   # Bug only happens when Moose class inherits from Moo class which
   # uses overload string. Moose class inherits from Moose class which
   # has consumed a ::Role::WithOverloading works. Moo inherits from
   # Moo also works
   my $self = shift; $self->as_string; return;
};

# Public methods
sub as_boolean {
   return 1;
}

sub as_string { # Stringifies the error and inflates the placeholders
   my $self = shift; my $e = $self->error;

   0 > index $e, '[_' and return "${e}\n";

   my $opts = [ '[?]', '[]', $self->no_quote_bind_values ];

   return inflate_placeholders( $opts, $e, @{ $self->args } )."\n";
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Unexpected::TraitFor::StringifyingError - Base role for exception handling

=head1 Synopsis

   use Moo;

   with 'Unexpected::TraitFor::StringifyingError';

=head1 Description

Base role for exception handling

=head1 Configuration and Environment

Defines the following list of read only attributes;

=over 3

=item C<args>

An array ref of parameters substituted in for the placeholders in the
error message when the error is localised

=item C<error>

The actual error message which defaults to C<Unknown error>. Can contain
placeholders of the form C<< [_<n>] >> where C<< <n> >> is an integer
starting at one. If passed a code ref it will be called passing in the
calling classname and constructor hash ref, the return value will be
used as the error string

=item C<no_quote_bind_values>

A boolean that defaults to C<FALSE>. If set to C<TRUE> then when the
placeholder values are substituted in the calls to
L<inflate_placeholers|Unexpected::Functions/inflate_placeholders>
(stringification) they are not wrapped in quotes

=back

=head1 Subroutines/Methods

=head2 BUILD

After construction call the L</as_string> method to work around a bug in
L<Moo>

=head2 BUILDARGS

Customises the constructor. Accepts either a coderef, an object ref,
a hashref, a scalar, or a list of key / value pairs

=head2 as_boolean

   $bool = $self->as_boolean;

Returns true. Behaviour maybe changed by a subclass

=head2 as_string

   $error_text = $self->as_string;

This is what the object stringifies to

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<namespace::autoclean>

=item L<Moo::Role>

=item L<Unexpected::Types>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
