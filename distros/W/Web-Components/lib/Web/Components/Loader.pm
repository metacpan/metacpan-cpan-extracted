package Web::Components::Loader;

use strictures;
use namespace::autoclean;

use HTTP::Status          qw( HTTP_BAD_REQUEST HTTP_FOUND
                              HTTP_INTERNAL_SERVER_ERROR );
use Try::Tiny;
use Unexpected::Types     qw( ArrayRef CodeRef HashRef NonEmptySimpleStr
                              Object RequestFactory );
use Web::Components::Util qw( deref exception is_arrayref
                              load_components throw );
use Web::ComposableRequest;
use Web::Simple::Role;

requires qw( config log );

# Attribute constructors
my $_build_factory_args = sub {
   my $self = shift;

   my $prefix = deref $self->config, 'name';

   return sub {
      my ($self, $attr) = @_;

      $prefix and $attr->{domain_prefix} = $prefix;

      return $attr;
   };
};

my $_build__factory = sub {
   my $self = shift;

   return Web::ComposableRequest->new
      ( buildargs => $self->factory_args, config => $self->config );
};

my $_build__routes = sub {
   my $controllers = $_[ 0 ]->controllers; my @keys = keys %{ $controllers };

   return [ map { $controllers->{ $_ }->dispatch_request } sort @keys ];
};

# Public attributes
has 'factory_args' => is => 'lazy', isa => CodeRef,
   builder => $_build_factory_args;

has 'controllers' => is => 'lazy', isa => HashRef[Object], builder => sub {
   load_components 'Controller', application => $_[ 0 ] };

has 'models' => is => 'lazy', isa => HashRef[Object], builder => sub {
   load_components 'Model', application => $_[ 0 ], views => $_[ 0 ]->views };

has 'views' => is => 'lazy', isa => HashRef[Object], builder => sub {
   load_components 'View', application => $_[ 0 ] };

# Private attributes
has '_action_suffix' => is => 'lazy', isa => NonEmptySimpleStr,
   builder => sub { deref $_[ 0 ]->config, 'action_suffix', '_action' };

has '_factory' => is => 'lazy', isa => RequestFactory,
   builder => $_build__factory, handles => [ 'new_from_simple_request' ];

has '_routes' => is => 'lazy', isa => ArrayRef[CodeRef],
   builder => $_build__routes;

has '_tunnel_method' => is => 'lazy', isa => NonEmptySimpleStr,
   builder => sub { deref $_[ 0 ]->config, 'tunnel_method', 'from_request' };

# Private functions
my $_header = sub {
   return [ 'Content-Type' => 'text/plain', @{ $_[ 0 ] // [] } ];
};

# Private methods
my $_internal_server_error = sub {
   my ($self, $e) = @_; $self->log->error( $e );

   return [ HTTP_INTERNAL_SERVER_ERROR, $_header->(), [ $e ] ];
};

my $_parse_sig = sub {
   my ($self, $args) = @_;

   exists $self->models->{ $args->[ 0 ] } and return @{ $args };

   my ($moniker, $method) = split m{ / }mx, $args->[ 0 ], 2;

   exists $self->models->{ $moniker } and shift @{ $args }
      and return $moniker, $method, @{ $args };

   return;
};

my $_recognise_signature = sub {
   my ($self, $args) = @_;

   is_arrayref $args and $args->[ 0 ]
      and exists $self->models->{ $args->[ 0 ] } and return 1;

   my ($moniker, $method) = split m{ / }mx, $args->[ 0 ], 2;

   $moniker and exists $self->models->{ $moniker } and return 1;

   return 0;
};

my $_redirect = sub {
   my ($self, $req, $stash) = @_;

   my $code     = $stash->{code} // HTTP_FOUND;
   my $redirect = $stash->{redirect};
   my $message  = $redirect->{message};
   my $location = $redirect->{location};

   if ($message and $req->can( 'session' )) {
      $req->can( 'loc_default' )
         and $self->log->info( $req->loc_default( @{ $message } ) );

      my $mid; $mid = $req->session->add_status_message( $message )
         and $location->query_form( $location->query_form, 'mid' => $mid );
   }

   return [ $code, [ 'Location', $location ], [] ];
};

my $_render_view = sub {
   my ($self, $moniker, $method, $req, $stash) = @_;

   is_arrayref $stash and return $stash; # Plack response short circuits view

   exists $stash->{redirect} and return $self->$_redirect( $req, $stash );

   $stash->{view}
      or throw 'Model [_1] method [_2] stashed no view', [ $moniker, $method ];

   my $view = $self->views->{ $stash->{view} }
      or throw 'Model [_1] method [_2] unknown view [_3]',
               [ $moniker, $method, $stash->{view} ];
   my $res  = $view->serialize( $req, $stash )
      or throw 'View [_1] returned false', [ $stash->{view} ];

   return $res
};

my $_render_exception = sub {
   my ($self, $moniker, $req, $e) = @_; my $res;

   ($e->can( 'rv' ) and $e->rv > HTTP_BAD_REQUEST)
      or $e = exception $e, { rv => HTTP_BAD_REQUEST };

   my $attr = deref $self->config, 'loader_attr', { should_log_errors => 1 };

   if ($attr->{should_log_errors}) {
      my $username = $req->can( 'username' ) ? $req->username : 'unknown';
      my $msg = "${e}"; chomp $msg; $self->log->error( "${msg} (${username})" );
   }

   try   {
      my $stash = $self->models->{ $moniker }->exception_handler( $req, $e );

      $res = $self->$_render_view( $moniker, 'exception_handler', $req, $stash);
   }
   catch { $res = $self->$_internal_server_error( "${e}\n${_}" ) };

   return $res;
};

my $_render = sub {
   my ($self, @args) = @_;

   $self->$_recognise_signature( $args[ 0 ] ) or return @args;

   my ($moniker, $method, undef, @request) = $self->$_parse_sig( $args[ 0 ] );

   my $opts = { domain => $moniker }; my ($req, $res);

   try   { $req = $self->new_from_simple_request( $opts, @request ) }
   catch { $res = $self->$_internal_server_error( $_ ) };

   $res and return $res;

   try   {
      $method eq $self->_tunnel_method
         and $method = $req->tunnel_method.$self->_action_suffix;

      my $stash = $self->models->{ $moniker }->execute( $method, $req );

      $res = $self->$_render_view( $moniker, $method, $req, $stash );
   }
   catch { $res = $self->$_render_exception( $moniker, $req, $_ ) };

   $req->can( 'session' ) and $req->session->update;

   return $res;
};

my $_filter = sub () {
   my $self = shift; return response_filter { $self->$_render( @_ ) };
};

# Construction
sub dispatch_request { # uncoverable subroutine
   # Not applied if it already exists in the consuming class
}

around 'dispatch_request' => sub {
   return $_filter, @{ $_[ 1 ]->_routes };
};

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Loader - Loads and instantiates MVC components

=head1 Synopsis

   package Component::Server;

   use Class::Usul;
   use Plack::Builder;
   use Web::Simple;
   use Moo;

   has '_usul' => is => 'lazy', builder => sub {
      Class::Usul->new( config => { appclass => __PACKAGE__  } ) },
      handles  => [ 'config', 'debug', 'l10n', 'lock', 'log' ];

   with q(Web::Components::Loader);

=head1 Description

Loads and instantiates MVC components. Searches the namespaces; C<Controller>,
C<Model>, and C<View> in the consuming classes library root. Any components
found are loaded and instantiated

The component collection references are passed to the component constructors
so that a component can discover any dependent components. The collection
references are not fully populated when the component is instantiated so
attributes that default to component references should be marked as lazy

=head1 Configuration and Environment

This role requires C<config> and C<log> methods in the consuming class

Defines the following attributes;

=over 3

=item C<controllers>

An array reference of controller object reference sorted into C<moniker>
order

=item C<models>

A hash reference of model object references

=item C<view>

A hash reference of view object references

=back

=head1 Subroutines/Methods

=head2 C<dispatch_request>

Installs a response filter that processes and renders the responses from
the controller methods

Controller responses that do not match the expected signature are allowed to
bubble up

The expected controller return value signature is;

   [ 'model_moniker', 'method_name', @web_simple_request_parameters ]

The L<Web::Simple> request parameters are used to instantiate an instance of
L<Web::ComposableRequest::Base>

The specified method on the model select by the moniker is called passing the
request object in. A hash references, the stash, is the expected response and
this is passed along with the request object into the view which renders the
response

Array references, a L<Plack> response, are allowed to bubble up and bypass
the call to the view

If the stash contains a redirect attribute then a redirect response is
generated. Any message intended to be viewed by the user is stored in the
session and is retrieved by the next request

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTTP::Message>

=item L<Try::Tiny>

=item L<Unexpected>

=item L<Web::Simple>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components.
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
