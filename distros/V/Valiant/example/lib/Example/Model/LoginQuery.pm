package Example::Model::LoginQuery;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';

content_type 'application/x-www-form-urlencoded';
content_in 'query';

has post_login_redirect => (is=>'ro', predicate=>'has_post_login_redirect', property=>1);

__PACKAGE__->meta->make_immutable();
