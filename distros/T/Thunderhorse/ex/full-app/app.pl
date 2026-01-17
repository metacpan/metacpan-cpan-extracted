use v5.40;

use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/lib';

use FullApp;

FullApp->new(initial_config => 'conf')->run;

