package Web::ComposableRequest::Exception;

use namespace::autoclean;

use Unexpected::Functions qw( has_exception );
use Unexpected::Types     qw( Int );
use Moo;

extends q(Unexpected);
with    q(Unexpected::TraitFor::ErrorLeader);
with    q(Unexpected::TraitFor::ExceptionClasses);

my $class = __PACKAGE__;

$class->ignore_class( 'Sub::Quote' );

has_exception $class;

has '+class' => default => $class;

has 'rv'     => is => 'ro', isa => Int, default => 1;

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Exception - Defines the exception class thrown by this distribution

=head1 Synopsis

   use Web::ComposableRequest::Exception;

=head1 Description

Defines the exception class thrown by this distribution

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<rv>

An integer which defaults to one. The exception return value

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Differentiate the constructor method signatures

=head2 C<as_string>

Stringifies the exception error message

=head2 C<clone>

Clones the invocant

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-ComposableRequest.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

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
# vim: expandtab shiftwidth=3:
