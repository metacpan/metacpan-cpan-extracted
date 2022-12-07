package Example::Model::LoginRequest;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

content_type 'application/x-www-form-urlencoded';

has person => (is=>'ro', property=>+{model=>'LoginRequest::Person' });

__PACKAGE__->meta->make_immutable();

package Example::Model::LoginRequest::Person;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

has username => (is=>'ro', property=>1);   
has password => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
