use strict;
use warnings;
use Test::More tests => 1;
use App::SmokeBox::Mini;
use Cwd;

$ENV{PERL5_SMOKEBOX_DIR} = cwd();

my $smokebox_dir = App::SmokeBox::Mini::_smokebox_dir();

diag("SmokeBox directory is in '$smokebox_dir'\n");

ok( $smokebox_dir eq cwd(), 'PERL5_SMOKEBOX_DIR' );
