use warnings;
use strict;

package Example::Server;

use Plack::Runner;
use Module::Runtime 'use_module';

sub run { Plack::Runner->run(@_, use_module('Example')->to_app) }

return caller(1) ? 1 : run(@ARGV);
