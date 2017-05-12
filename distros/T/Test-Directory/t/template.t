use Test::More tests => 5;
use Test::Exception;
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $explicit = MODULE->new('explicit');
is ($explicit->path, 'explicit', 'got explicit path');
ok ( -d 'explicit', 'Explicit dir exists' );

my $implicit = MODULE->new;
like($implicit->path, qr/^test-directory-/, 'got implicit path');
ok ( -d $implicit->path, 'Implicit dir exists');

