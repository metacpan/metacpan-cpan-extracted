use t::boilerplate;

use Test::More;

use_ok 'Web::Components';

{  package TestApp::Controller::Dummy;

   use Web::Simple;

   with 'Web::Components::Role';

   has '+moniker' => default => 'dummy';

   sub dispatch_request {
      return (
         'GET  + /      + ?*' => sub { [ 'dummy/get_index', @_ ] },
         'GET  + /other + ?*' => sub { [ 'dummy/get_other', @_ ] },
      );
   }

   $INC{ 'TestApp/Controller/Dummy.pm' } = __FILE__;
}

{  package TestApp::Model::Dummy;

   use Moo;

   extends 'Web::Components::Model';
   with    'Web::Components::Role';

   has '+moniker' => default => 'dummy';

   sub get_index {
      my ($self, $context) = @_;

      my $response = [ 200, [ 'Content-Type', 'text/plain' ], [ '42' ] ];

      $context->stash(response => $response);
      return;
   }

   sub get_other {
      my ($self, $context) = @_;

      my $response = [ 200, [ 'Content-Type', 'text/plain' ], [ '43' ] ];

      $context->stash(response => $response);
      return;
   }

   sub is_authorised {
      return 1;
   }

   $INC{ 'TestApp/Model/Dummy.pm' } = __FILE__;
}

{  package TestApp::Role::Bar;

   use Moo::Role;

   with 'Web::Components::Role';

   $INC{ 'TestApp/Role/Bar.pm' } = __FILE__;
}

{  package TestApp::Config;

   use Moo;

   has 'appclass' => is => 'ro', default => 'TestApp';

   has 'config_comps' => is => 'ro', default => sub {
      return { Model  => { 'foo' => [ 'Role::Bar' ] } };
   };

   has 'components' => is => 'ro', default => sub {
      return { 'Model::Foo' => { moniker => 'bar' } };
   };

   $INC{ 'TestApp/Config.pm' } = __FILE__;
}

{  package TestApp::Server;

   use Web::Simple;
   use Moo;

   has 'config' => is => 'ro', default => sub { TestApp::Config->new };

   has 'log' => is => 'ro', default => sub { Class::Null->new };

   has 'foo' => is => 'ro';

   with 'Web::Components::Loader';

   $INC{ 'TestApp/Server.pm' } = __FILE__;
}

my $env = {
   CONTENT_TYPE         => 'text/plain',
   HTTP_ACCEPT_LANGUAGE => 'en-gb,en;q=0.7,de;q=0.3',
   HTTP_HOST            => 'localhost:5000',
   PATH_INFO            => '/',
   QUERY_STRING         => 'key=124-4',
   REMOTE_ADDR          => '127.0.0.1',
   REQUEST_METHOD       => 'GET',
   SERVER_PROTOCOL      => 'HTTP/1.1',
   'psgix.logger'       => sub { warn $_[0]->{message}."\n" },
   'psgix.session'      => { authenticated => 1 },
};

my $server = TestApp::Server->new;

is $server->dispatch_request, 4, 'Default dispatch';
is $server->models->{dummy}->encoding, 'UTF-8', 'Sets encoding';
is $server->to_psgi_app->( $env )->[2]->[0], 42, 'Routes to method';
is $server->_action_suffix, '_action','Action suffix';

$env->{PATH_INFO} = '/other';
is $server->to_psgi_app->( $env )->[2]->[0], 43, 'Other route to method';

use Web::Components::Util qw( deref exception is_arrayref
                              load_components throw );

eval { throw 'Error' };

like exception(), qr{ Error }mx, 'Throws and catches';
is is_arrayref( [] ), 1, 'Is arrayref true';
is is_arrayref( ' ' ), 0, 'Is arrayref false';
is is_arrayref( 0 ), 0, 'Is arrayref false with false arg';
is deref( { test => 'dummy' }, 'test' ), 'dummy', 'Deref a hash with key';
is deref( {}, 'test', 'dummy' ), 'dummy', 'Deref a hash without key';
is deref( {}, 'test', '' ), '', 'Deref a hash without key false default';
is deref( $server, 'foo', 'bar' ), 'bar', 'Deref object with default';
is deref( $server, 'foo', '' ), '', 'Deref object with false default';

use Class::Null;

my $comps = load_components '+TestApp::Model', {
   components => {},
   config     => { appclass => 'TestApp' },
   log        => Class::Null->new,
};

is $comps->{dummy}->moniker, 'dummy', 'Loads components from minimal config';

eval { load_components '' };

like exception(), qr{ \Qcomponent base\E }mx, 'Throw without base';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
