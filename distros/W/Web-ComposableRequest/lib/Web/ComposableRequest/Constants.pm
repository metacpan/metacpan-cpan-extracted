package Web::ComposableRequest::Constants;

use strictures;
use parent 'Exporter::Tiny';

use Web::ComposableRequest::Exception;
use Role::Tiny ();

our @EXPORT = qw( COMMA EXCEPTION_CLASS FALSE LANG NUL SPC TRUE );

my $Exception_Class = 'Web::ComposableRequest::Exception';

sub COMMA () { q(,) }
sub FALSE () { 0    }
sub LANG  () { 'en' }
sub NUL   () { q()  }
sub SPC   () { q( ) }
sub TRUE  () { 1    }

sub EXCEPTION_CLASS () { __PACKAGE__->Exception_Class }

sub Exception_Class {
   my ($self, $class) = @_; defined $class or return $Exception_Class;

   $class->can( 'throw' ) or $Exception_Class->throw
      ( "Exception class ${class} is not loaded or has no throw method" );

   return $Exception_Class = $class;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Constants - Functions that return constant values

=head1 Synopsis

   use Web::ComposableRequest::Constants qw( EXCEPTION_CLASS );

=head1 Description

Functions that return constant values

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<Exception_Class>

The name of the class used to throw exceptions. Defaults to
L<Web::ComposableRequest::Exception>

=back

=head1 Subroutines/Methods

=head2 C<EXCEPTION_CLASS>

The value of the L</Exception_Class> attribute

=head2 C<FALSE>

The digit zero

=head2 C<LANG>

The default language C<en>

=head2 C<NUL>

The null (zero length) string

=head2 C<TRUE>

The digit one

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Exporter::Tiny>

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
