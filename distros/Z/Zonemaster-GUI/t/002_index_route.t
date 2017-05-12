use Test::More tests => 2;
use strict;
use warnings;
use Cwd;
use File::Spec::Functions;

my $appdir = catfile( getcwd(), 'zm_app');

# the order is important
use Zonemaster::GUI::Dancer::Frontend;
use Dancer::Test;

# Have to do this by hand, since we moved most of the files.
my $conf = Zonemaster::GUI::Dancer::Frontend::config();
$conf->{appdir} = $appdir;
$conf->{confdir} = $appdir;
$conf->{envdir} = catfile($appdir, 'environments');
$conf->{public} = catfile($appdir, 'public');
$conf->{views} = catfile($appdir, 'views');

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';
