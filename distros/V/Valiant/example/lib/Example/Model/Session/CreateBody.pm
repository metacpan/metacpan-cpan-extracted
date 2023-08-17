package Example::Model::Session::CreateBody;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

content_type 'application/x-www-form-urlencoded';
namespace 'person';

has username => (is=>'ro', property=>1);   
has password => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
