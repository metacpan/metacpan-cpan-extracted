use strict;
use warnings;

use Test::More tests => 15;

use_ok('MMM::Config');
use_ok('MMM::Host');
use_ok('MMM::Mirror');
use_ok('MMM::Report');
use_ok('MMM::Report::Html');
use_ok('MMM::Report::Console');
use_ok('MMM::Report::Mail');
use_ok('MMM::Daemon');
use_ok('MMM::Batch');
use_ok('MMM::MirrorTask');
use_ok('MMM::Sync');
use_ok('MMM::Sync::Rsync');
use_ok('MMM::Sync::Ftp');
use_ok('MMM::Sync::Dummy');
use_ok('MMM');

