use strict;
use Test::More tests => 4;

use WebService::Backlog;
use Encode;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

my $versions = $backlog->getVersions(20);
ok($versions);
ok( scalar( @{$versions} ) > 0 );
is( $versions->[ $#{$versions} ]->id,   965 );
is( $versions->[ $#{$versions} ]->name, 'R2006-10-02' );
