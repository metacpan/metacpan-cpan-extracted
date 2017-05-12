# $Id: test.pl,v 1.5 2004/01/06 07:40:30 cvspub Exp $
use Test::More qw(no_plan);
ok(1);

BEGIN { use_ok( 'WWW::FindConcept' ); }

use Data::Dumper;
use DB_File;

$query = 'perl';

*cachepath = \$WWW::FindConcept::cachepath;
$cachepath = './.find-concept';

%concept = map{$_=>1} find_concept($query);
ok($concept{$_}) foreach q/Perl 5/, q/Perl Mongers/, q/Open Source/;

tie %cache, 'DB_File', $cachepath, O_RDONLY, 0644, $DB_BTREE or die;
ok(defined $cache{$query});
untie %cache;

delete_concept($query);

tie %cache, 'DB_File', $cachepath, O_RDONLY, 0644, $DB_BTREE or die;
ok(!defined $cache{$query});
untie %cache;

ok(update_concept($query));
ok((dump_cache())[0] eq $query);

delete_concept($query);
tie %cache, 'DB_File', $cachepath, O_RDONLY, 0644, $DB_BTREE or die;
ok(!defined $cache{$query});
untie %cache;

remove_cache();
ok(1) unless -e $WWW::FindConcept::cachepath;
