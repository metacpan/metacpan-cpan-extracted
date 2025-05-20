package Web::ComposableRequest::Role::Compat;

use Encode                            qw( decode );
use Web::ComposableRequest::Constants qw( FALSE TRUE );
use Moo::Role;

requires qw( body_params query_params uri_params );

sub args {
   my $self = shift;

   return $self->uri_params->({ optional => TRUE, scrubber => FALSE });
}

sub body_parameters {
   my $self = shift;

   return $self->body_params->({
      hashref => FALSE, optional => TRUE, scrubber => FALSE
   });
}

sub parameters {
   my ($self, $options) = @_;

   return {
      %{$self->query_parameters($options)}, %{$self->body_parameters($options)}
   };
}

sub query_parameters {
   my $self = shift;

   return $self->query_params->({ optional => TRUE, scrubber => FALSE });
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Role::Compat - Composable request class for web frameworks

=head1 Synopsis

   use Web::ComposableRequest::Role::Compat;
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
