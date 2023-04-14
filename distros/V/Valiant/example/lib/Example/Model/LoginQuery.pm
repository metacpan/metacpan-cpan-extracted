package Example::Model::LoginQuery;

use Moose;
use CatalystX::QueryModel;

extends 'Catalyst::Model';

has post_login_redirect => (is=>'ro', predicate=>'has_post_login_redirect', property=>1);

__PACKAGE__->meta->make_immutable();
