package # hide from PAUSE
  EventBroker;
use Moose;

use ZMQ::Declare;

my $Spec = ZMQ::Declare::ZDCF->new( tree => {
  version => 1.0,
  apps => {

    broker => { devices => { broker => {
      sockets => {
        event_listener => {
          type => 'sub',
          bind => 'tcp://*:5999',
          option => {subscribe => ''}
        },
        work_distributor => {
          type => 'push',
          bind => 'tcp://*:5998',
          option => {hwm => 500000},
        },
      }
    } } },

    worker => { devices => { worker => {
      sockets => {
        work_queue => {
          type => 'pull',
          connect => 'tcp://localhost:5998',
        },
      }
    } } },

    client => { devices => { client => {
      sockets => {
        event_dispatch => {
          type => 'pub',
          connect => 'tcp://localhost:5999',
          option => {hwm => 10000}
        }
      }
    } } },

  } # end of apps
});

has '_client_runtime' => (
  is => 'rw',
);

# instance method for caching (don't want to reconnect all the time)
sub client_socket {
  my $self = shift;
  my $rt = $self->_client_runtime;
  if (not $rt) {
    $rt = $Spec->application("client")->device->make_runtime;
    $self->_client_runtime($rt);
  }
  return $rt->get_socket_by_name("event_dispatch");
}

# static and/or instance methods
sub broker { $Spec->application("broker")->device }
sub worker { $Spec->application("worker")->device }

no Moose;
__PACKAGE__->meta->make_immutable;
