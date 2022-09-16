package Example::Model::ContactsRequest;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

namespace 'person';
content_type 'application/x-www-form-urlencoded';

has contacts => (is=>'ro', property=>+{ indexed=>1, model=>'ContactsRequest::Contact' }); 

__PACKAGE__->meta->make_immutable();

package Example::Model::ContactsRequest::Contact;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

has id => (is=>'ro', property=>1);   
has _delete => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
