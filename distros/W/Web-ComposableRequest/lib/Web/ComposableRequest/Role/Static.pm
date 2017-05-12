package Web::ComposableRequest::Role::Static;

use namespace::autoclean;

use Web::ComposableRequest::Constants qw( FALSE NUL TRUE );
use Web::ComposableRequest::Util      qw( first_char is_arrayref
                                          is_hashref new_uri );
use Moo::Role;

requires qw( locale path query_params scheme _base );

around '_build__base' => sub {
   my ($orig, $self) = @_; $self->mode eq 'static' or return $orig->( $self );

   my $count = () = split m{ / }mx, $self->path, -1;

   return '../' x $count;
};

around '_build_uri' => sub {
   my ($orig, $self) = @_; $self->mode eq 'static' or return $orig->( $self );

   my $path = $self->_base.$self->locale.'/'.$self->path.'.html';

   return new_uri $self->scheme, $path;
};

around 'uri_for' => sub {
   my ($orig, $self, $path, @args) = @_; $path //= NUL;

   ($self->mode eq 'static' and '/' ne substr $path, -1, 1)
      or return $orig->( $self, $path, @args );

   my $base = $self->_base; my $extn = '.html';

   my @query_params = (); my $uri_params = [];

   if (is_arrayref $args[ 0 ]) {
      $uri_params = shift @args; @query_params = @args;
   }
   elsif (is_hashref $args[ 0 ]) {
      $uri_params   =    $args[ 0 ]->{uri_params  } // [];
      @query_params = @{ $args[ 0 ]->{query_params} // [] };
      $args[ 0 ]->{base     } and $base = $args[ 0 ]->{base     };
      $args[ 0 ]->{extension} and $extn = $args[ 0 ]->{extension};
   }

   $path or $path = 'index'; $path = $base.$self->locale."/${path}";

   $uri_params->[ 0 ] and $path = join '/', $path, @{ $uri_params };

   my $uri = new_uri $self->scheme, $path.$extn;

   $query_params[ 0 ] and $uri->query_form( @query_params );

   return $uri;
};

sub mode {
   return $_[ 0 ]->query_params->( 'mode', { optional => TRUE } ) // 'online';
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Role::Static - Generate static web site URIs

=head1 Synopsis

   package Your::Request::Class;

   use Moo;

   extends 'Web::ComposableRequest::Base';
   with    'Web::ComposableRequest::Role::Static';

=head1 Description

Causes the L<uri_for|Web::ComposableRequest::Base/uri_for> method to return
static URIs

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 C<mode>

The mode of the current request. Set to C<online> if this is a live request,
set to C<static> of this request is generating a static page

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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
