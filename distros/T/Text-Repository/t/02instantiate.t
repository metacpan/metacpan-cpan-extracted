package Text::Repository::Test02;

use strict;

use Test::More tests => 1;
use Cwd;
use Text::Repository;

my $rep = Text::Repository->new(cwd);

ok(defined $rep, "new returns a defined object");
