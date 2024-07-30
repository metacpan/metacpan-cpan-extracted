package Example::Model::Times;

use Moose;
extends 'Catalyst::Model';

package Example::Model::Times::StartTime;

use Moose;
use DateTime;
extends 'Catalyst::Model';

sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);
  return DateTime->now;
}

package Example::Model::Times::NowTime;

use Moose;
use DateTime;
extends 'Catalyst::Model';

sub ACCEPT_CONTEXT {
  my ($class_instance, $c, @args) = @_;
  return DateTime->now;  
}

1;
