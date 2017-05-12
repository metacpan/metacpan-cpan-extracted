use Test::More tests=>4;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $obj = MODULE->new('t/tmp');

is ($obj->path, File::Spec->join('t','tmp'), 'top directory path');
is ($obj->path('f'), File::Spec->join('t','tmp', 'f'), 'file path');

$obj = MODULE->new('t-tmp');
is ($obj->path, 't-tmp', 'top directory');

