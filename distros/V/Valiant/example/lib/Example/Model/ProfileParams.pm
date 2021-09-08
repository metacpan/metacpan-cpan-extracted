package Example::Model::ProfileParams;

use Moose;
use Catalyst::InjectableComponent;
extends 'Catalyst::Model';

has 'test1' => (is=>'ro', lazy=>1, tags=>['111', '222'], default=>1);
has 'test2' => (is=>'ro', lazy=>1, tags=>'333', default=>1);

__PACKAGE__->meta->make_immutable();

