package Example::Model::Todos::CreateBody;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

namespace 'todo';
content_type 'application/x-www-form-urlencoded';

has title => (is=>'ro', property=>1);   
has status => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
