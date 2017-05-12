#!perl -w
use strict;
use Test::More;
use File::Path qw(rmtree);

# preload libs dynamically loaded
use Cwd      ();
use overload ();
use Scalar::Util ();

use lib::xi 'xt-extlib', '-q', '-n';
use constant INSTALL_DIR => $INC[-1]->install_dir;

BEGIN { diag('install_dir: ', INSTALL_DIR) }

BEGIN { rmtree(INSTALL_DIR);  }
END   { rmtree(INSTALL_DIR);  }

use install; # a dummy module
use JSON::XS;

like $INC{'install.pm'}, qr/\Qinstall.pm\E \z/xms, 'collectly installed';

ok( JSON::XS->VERSION, 'XS module');

done_testing;

