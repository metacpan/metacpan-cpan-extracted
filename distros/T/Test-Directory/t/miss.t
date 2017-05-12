use Test::More tests=>4;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td-miss';
my $td = MODULE->new($d);

$td->touch('past', 'present');
$td->mkdir('old-dir');
$td->mkdir('sub-dir');
$td->mkdir('rm-dir');

is ($td->remove_directories('rm-dir'), 1);

unlink( $td->path('past') );
rmdir( $td->path('old-dir') );

open my($tmpfh), '>', $td->path('future');
mkdir($td->path('new-dir'));

is( $td->count_missing, 2, '2 missing file');
is( $td->count_unknown, 2, '2 unknown file');

$td->check_file('future');
$td->check_directory('new-dir');
