package ZMQ::Declare::DSL;
{
  $ZMQ::Declare::DSL::VERSION = '0.03';
}

use 5.008001;
use strict;
use warnings;

use Carp ();
use ZeroMQ ();

use ZMQ::Declare;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
  declare_zdcf
  app
  context
  iothreads
  device
  name
  type
  sock
  bnd
  conn
  option
);
our %EXPORT_TAGS = (
  'all' => \@EXPORT,
);

our $ZDCF;
our $App;
our $Context;
our $Device;
our $Socket;
# Valid scopes: zdcf, app, context, device, socket
our $CurScope;

sub _check_scope {
  my $expected_scope = shift;
  my $global_state_var_ref = shift;
  (undef, undef, undef, my $function) = caller(1);
  $function =~ s/^.*:://;

  Carp::croak("'$function' outside ZDCF found: Did you fail to call 'declare_zdcf'?")
    if not defined $CurScope;
  Carp::croak("Wrongly nested or out-of-place '$function' detected: You cannot nest ZDCF '${function}'s")
    if ($global_state_var_ref && $$global_state_var_ref)
    or $CurScope ne $expected_scope;
}

sub declare_zdcf(&) {
  local $ZDCF = {version => "1.0"};
  local $CurScope = 'zdcf';
  # Clear the various components in this dynamic scope
  local $App;
  local $Context;
  local $Device;
  local $Socket;
  $_[0]->();
  return ZMQ::Declare::ZDCF->new(tree => $ZDCF);
}

sub app(&) {
  _check_scope('zdcf', \$App);

  local $CurScope = 'app';
  local $App = {};
  $_[0]->();

  my $name = delete $App->{name};
  Carp::croak("Missing app name!") if not defined $name;
  $ZDCF->{apps}{$name} = $App;
}

sub context(&) {
  _check_scope('app' => \$Context);

  local $Context = {};
  local $CurScope = 'context';
  $_[0]->();
  $App->{context} = $Context;
}

sub iothreads($) {
  _check_scope('context');
  $Context->{iothreads} = $_[0];
}

sub device(&) {
  _check_scope('app' => \$Device);

  local $Device = {};
  local $CurScope = 'device';
  $_[0]->();

  my $name = delete $Device->{name};
  if (not defined $name) {
    $name = $App->{name};
  }

  Carp::croak("Missing device name!") if not defined $name;
  $App->{devices}{$name} = $Device;
}

sub name($) {
  if (not defined $CurScope) {
    Carp::croak("Error 'name()' outside app, device, and socket. Did you fail to call 'declare_zdcf'?");
  }
  elsif ($CurScope eq 'device') { $Device->{name} = shift }
  elsif ($CurScope eq 'socket') { $Socket->{name} = shift }
  elsif ($CurScope eq 'app')    { $App->{name} = shift }
  else { Carp::croak("Error 'name()' outside app, device, and socket") }
}

sub type($) {
  if (not defined $CurScope) {
    Carp::croak("Error 'type()' outside device, and socket. Did you fail to call 'declare_zdcf'?");
  }
  elsif ($CurScope eq 'device') { $Device->{type} = shift }
  elsif ($CurScope eq 'socket') { $Socket->{type} = shift }
  else { Carp::croak("Error 'type()' outside device, and socket") }
}

sub sock(&) {
  _check_scope('device' => \$Socket);

  local $Socket = {};
  local $CurScope = 'socket';
  $_[0]->();

  my $name = delete $Socket->{name};
  Carp::croak("Missing socket name!") if not defined $name;
  $Device->{sockets}{$name} = $Socket;
}

sub bnd(@) {
  Carp::croak("Error: bnd (bind) outside socket")
    if not defined $CurScope or $CurScope ne 'socket';
  push @{ $Socket->{bind} }, @_;
}

sub conn(@) {
  Carp::croak("Error: conn (connect) outside socket")
    if not defined $CurScope or $CurScope ne 'socket';
  push @{ $Socket->{connect} }, @_;
}

sub option(%) {
  Carp::croak("Error: option() outside socket")
    if not defined $CurScope or $CurScope ne 'socket';
  while (@_) {
    my $k = shift;
    $Socket->{option}->{$k} = shift;
  }
}

1;
__END__

=head1 NAME

ZMQ::Declare::DSL - DSL for declaring 0MQ infrastructure

=head1 SYNOPSIS

  use ZMQ::Declare::DSL;
  
  my $zdcf = declare_zdcf {
  
      app {
          name 'weather';
  
          context { iothreads 1 };
  
          device {
              name 'client';
              sock {
                  name 'weather_stream';
                  type 'sub';
                  conn qw(tcp://localhost:12345);
                  option subscribe => "70123"; # ZIP code in this example
              };
          };
  
          device {
              name 'server';
              sock {
                  name 'weather_publisher';
                  type 'pub';
                  bnd qw(tcp://*:12345);
              };
          };
      };
  
  };
  
  # elsewhere
  my $server = $zdcf->application("weather")->device('server');
  $server->implementation(sub {
    my ($runtime) = @_;
    # server main loop here
    return();
  });
  $server->run();
  
  # yet elsewhere
  my $client = $zdcf->application("weather")->device('client');
  $client->implementation(sub {
    my ($runtime) = @_;
    # client main loop here
    return();
  });
  $client->run();

=head1 DESCRIPTION

B<This is experimental software. Interfaces and implementation are subject to
change. If you are interested in using this in production, please get in touch
to gauge the current state of stability.>

This module defines a domain specific language (which just so happens to be valid
Perl that's slightly beaten into shape) for declaring 0MQ infrastructure.
Please read L<ZMQ::Declare> before you proceed with this document.

This module is just a thin syntax-sugar layer on top of simply creating a regular
nested Perl data structure and passing it to C<ZMQ::Declare::ZDCF->new()>. It
adds no features beyond a different syntax. Unless you find the syntax very
attractive, consider using a simpler way to declare 0MQ infrastructure.

Generally speaking, there are multiple kinds of functions in this module:
There are those that have a notion of scope, such as the outer C<declare_zdcf BLOCK>
and C<app BLOCK>, C<context BLOCK>, C<device BLOCK>, and C<socket BLOCK>.
And there are those that simply set a property of the enclosing object (well, scope):
C<name STRING>, C<type STRING>, C<bnd LIST>, C<conn LIST>, C<option LIST>,
and C<iothreads INTEGER>.

Most of these can only occurr within certain scopes. For example, C<iothreads> can
only be set within a C<context> and a C<context> can only appear within an C<app>,
but a C<name> is valid in an C<app>, a C<device>, or a C<socket>. Etc.

=head2 EXPORTS

This module exports a plethora of functions (as of this writing, all functions
that are documented below) by default. That's the point.

=head1 FUNCTIONS

=head2 declare_zdcf

The outermost function that starts the declaration of a new ZDCF specification
containing zero or more apps.

=head2 app

Defines a new app within a ZDCF specification. Only valid within the outermost
C<declare_zdcf> block. Must cointain at least a C<name> property.

Can contain one or more devices.

=head2 context

Defines a threading context of an app. Can occur zero or one time per app,
but cannot be used outside an app or inside its substructures (like devices).

=head2 iothreads

Defines the number of iothreads in a threading context. Defaults to one.
This is the only property that is currently valid in a C<context>.

=head2 device

Defines a single device within an app. Can occur zero or more times
in each app. Not valid outside of an app definition or within its substructures.

Can contain zero or more sockets. May have a type and a name property.
The name defaults to the app name, but that requires that the app name
declaration appears before the device declaration.

=head2 sock

Defines a single socket within a device. Can occur zero or more times in each device.
Not valid outside of a device definition or within its substructures.

Requires at least a name and a type property and at least one bind or connect
property.

=head2 name

Defines the name of the enclosing object. Valid for apps, devices, and sockets.

=head2 type

Defines the type of the enclosing object. Valid for devices and sockets.

=head2 bnd

Given a list of endpoints (strings), adds to the set of endpoints that the
enclosing socket is to bind to.

Valid any number of times within a socket. Either C<bnd> or C<conn> need
to appear at least once in a socket.

=head2 conn

Same as C<bnd>, but for connecting to sockets instead of binding.

=head2 option

Given a list of key/value pairs, sets socket options. Valid any number of
times within a socket.

=head1 SEE ALSO

L<ZMQ::Declare>

L<ZeroMQ>

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
