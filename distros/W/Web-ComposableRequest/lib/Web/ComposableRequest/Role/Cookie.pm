package Web::ComposableRequest::Role::Cookie;

use namespace::autoclean;

use CGI::Simple::Cookie;
use Unexpected::Types            qw( HashRef );
use Web::ComposableRequest::Util qw( add_config_role );
use Moo::Role;

requires qw( _config _env );

add_config_role __PACKAGE__.'::Config';

my $_decode = sub {
   my ($cookies, $prefix, $name) = @_; my $cname = "${prefix}_${name}";

   my $attr = {}; ($name and exists $cookies->{ $cname }) or return $attr;

   for (split m{ \+ }mx, $cookies->{ $cname }->value) {
      my ($k, $v) = split m{ ~ }mx, $_; $k and $attr->{ $k } = $v;
   }

   return $attr;
};

has 'cookies' => is => 'lazy', isa => HashRef, builder => sub {
   my %v = CGI::Simple::Cookie->parse( $_[ 0 ]->_env->{ 'HTTP_COOKIE' } ); \%v;
};

sub get_cookie_hash {
   return $_decode->( $_[ 0 ]->cookies, $_[ 0 ]->_config->prefix, $_[ 1 ] );
};

package Web::ComposableRequest::Role::Cookie::Config;

use namespace::autoclean;

use Unexpected::Types                 qw( NonEmptySimpleStr );
use Web::ComposableRequest::Constants qw( TRUE );
use Moo::Role;

has 'prefix' => is => 'ro', isa => NonEmptySimpleStr, required => TRUE;

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Role::Cookie - Adds cookies to the request class

=head1 Synopsis

   package Your::Request::Class;

   use Moo;

   extends 'Web::ComposableRequest::Base';
   with    'Web::ComposableRequest::Role::Cookie';

=head1 Description

Adds cookies to the request class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<cookies>

A hash reference of cookies supplied with the request

=back

Defines the following configuration attributes

=over 3

=item C<prefix>

A required non empty simple string. Prepended to the cookie name

=back

=head1 Subroutines/Methods

=head2 C<get_cookie_hash>

   my $hash_ref = $req->get_cookie_hash( $cookie_name );

The configuration prefix is prepended to the cookie name. That key is used
lookup a cookie in the L</cookies> hash. That cookie is decoded to produce
the hash reference returned by this method. The encoding separates pairs
with the C<+> character and separates keys and values with the C<~>
character

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<CGI::Simple::Cookie>

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
