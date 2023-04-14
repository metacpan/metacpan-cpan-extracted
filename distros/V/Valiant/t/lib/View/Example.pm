package View::Example;

use Catalyst;
use Moose;

__PACKAGE__->setup_plugins([qw//]);
__PACKAGE__->config({
 ## 'View::Hello' => +{from_config=>'now'},
});

__PACKAGE__->setup();
__PACKAGE__->meta->make_immutable();
