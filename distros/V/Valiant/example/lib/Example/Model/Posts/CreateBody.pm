package Example::Model::Posts::CreateBody;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

namespace 'post';
content_type 'application/x-www-form-urlencoded';

has title => (is=>'ro', property=>1);   
has content => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
