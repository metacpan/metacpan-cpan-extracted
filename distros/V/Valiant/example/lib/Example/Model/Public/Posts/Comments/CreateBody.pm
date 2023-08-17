package Example::Model::Public::Posts::Comments::CreateBody;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

namespace 'comment';
content_type 'application/x-www-form-urlencoded';

has content => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
