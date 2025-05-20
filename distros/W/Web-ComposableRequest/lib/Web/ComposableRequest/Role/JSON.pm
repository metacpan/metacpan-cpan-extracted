package Web::ComposableRequest::Role::JSON;

use Encode                            qw( decode );
use JSON::MaybeXS                     qw( );
use Web::ComposableRequest::Constants qw( FALSE TRUE );
use Web::ComposableRequest::Util      qw( add_config_role );
use Unexpected::Types                 qw( Object );
use Moo::Role;

requires qw( content_type _config _decode_body );

add_config_role __PACKAGE__.'::Config';

has '_json' => is => 'lazy', isa => Object,
   builder  => sub { JSON::MaybeXS->new( allow_nonref => TRUE, utf8 => FALSE )};

around '_decode_body' => sub {
   my ($orig, $self, $body, $content) = @_;

   return $orig->($self, $body, $content)
      unless $self->content_type eq 'application/json';

   $body->{$self->_config->json_body_attribute} = $self->_json->decode(
      decode($self->_config->encoding, $content)
   );

   return;
};

use namespace::autoclean;

package Web::ComposableRequest::Role::JSON::Config;

use Unexpected::Types qw( Str );
use Moo::Role;

# Public attributes
has 'json_body_attribute' => is => 'ro', isa => Str, default => 'param';

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Role::JSON - Decodes JSON request bodies

=head1 Synopsis

   package Your::Request::Class;

   use Moo;

   extends 'Web::ComposableRequest::Base';
   with    'Web::ComposableRequest::Role::JSON';

=head1 Description

Decodes JSON request bodies

=head1 Configuration and Environment

Defines no public attributes

=head1 Subroutines/Methods

=head2 C<decode_body>

Decodes the body as JSON if the content type is C<application/json>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Encode>

=item L<JSON::MaybeXS>

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
