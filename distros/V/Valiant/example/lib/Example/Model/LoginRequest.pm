package Example::Model::LoginRequest;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

namespace 'person';
content_type 'application/x-www-form-urlencoded';

has username => (is=>'ro', property=>1);   
has password => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
