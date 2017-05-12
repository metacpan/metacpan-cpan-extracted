use Test::Simple 'no_plan';

ok( opendir( DIR, './t') );
map { unlink "./t/$_" } grep { /^medium|thumbnails/ } readdir DIR;
closedir(DIR);
ok(1,'cleaned');


