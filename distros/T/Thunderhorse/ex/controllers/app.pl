use v5.40;

use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/lib';

use ControllerApp;

ControllerApp->new->run;

