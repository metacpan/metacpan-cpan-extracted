package Web::ComposableRequest::Role::Headers;

use Type::Utils qw( class_type );
use HTTP::Headers::Fast;
use Moo::Role;

requires qw( _env );

has 'headers' => is => 'lazy', isa => class_type('HTTP::Headers::Fast'),
   builder => sub {
      my $self = shift;
      my $env  = $self->_env;

      return HTTP::Headers::Fast->new(
         map  { (my $field = $_) =~ s{\A HTTPS?_}{}mx;
                (lc($field) => $env->{$_});
         }
         grep { m{ \A (?:HTTP|CONTENT) }imx } keys %{$env}
      );
   };

sub header {
   my ($self, $name) = @_; return $self->headers->header($name);
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Role::Headers - Composable request class for web frameworks

=head1 Synopsis

   use Web::ComposableRequest::Role::Headers;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

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
