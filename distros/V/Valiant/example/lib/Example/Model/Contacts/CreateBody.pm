package Example::Model::Contacts::CreateBody;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

namespace 'contact';
content_type 'application/x-www-form-urlencoded';

has first_name => (is=>'ro', property=>1);   
has last_name => (is=>'ro', property=>1);
has notes => (is=>'ro', property=>1);
has emails => (is=>'ro', property=>+{ indexed=>1, model=>'::Email' });
has phones => (is=>'ro', property=>+{ indexed=>1, model=>'::Phone' });

__PACKAGE__->meta->make_immutable();

package Example::Model::Contacts::CreateBody::Email;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

has id => (is=>'ro', property=>1);
has address => (is=>'ro', property=>1);
has _delete => (is=>'ro', property=>1);
has _add => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();

package Example::Model::Contacts::CreateBody::Phone;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

has id => (is=>'ro', property=>1);
has phone_number => (is=>'ro', property=>1);
has _delete => (is=>'ro', property=>1);
has _add => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
