use Test::More tests=>16;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td';
{
    my $td = MODULE->new($d);
    $td->touch(1,2);
    ok(-d $d, 'Dir was created');
    ok(-f "$d/2", 'file was created');
    ok($td->check_file(1), 'object finds file');
    $td->has(1);
    ok($td->check_file(2), 'object finds file');
    ok(!$td->check_file(3), "object doesn't find file");
    $td->hasnt(3);

    $td->remove_files(2);
    $td->hasnt(2);

    $td->create('c');
    $td->has('c');

    $td->create('text', content=>'hello world');
    is ( -s($td->path('text')), length('hello world'), "got length");
    $td->create('old', time=>time-3600);
    cmp_ok( -M($td->path('old')), '>', -M($td->path('text')), 
	    'old is older than text');
    

    is($td->count_missing, 0, "no missing files");
    is($td->count_unknown, 0, "no unknown files");
    $td->is_ok("No missing or unknown files");


}

ok (!-d $d, 'Dir was removed');

