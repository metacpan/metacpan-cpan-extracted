use Test::More tests=>12;
use Test::Exception;
use lib '.';
use constant MODULE => 'Test::Directory';

use_ok(MODULE);

my $d='tmp-td';

{
  my $td = MODULE->new($d);
  
  $td->mkdir('sd');
  $td->touch('sd/f1');
  
  $td->has_dir('sd');
  $td->hasnt_dir('od');
  $td->has('sd/f1');

  $td->is_ok;

  mkdir( $td->path('bogus-dir-1') );
  mkdir( $td->path('bogus-dir-2') );

  is ($td->count_unknown, 2, "2 unknown directory");
  $td->has_dir('bogus-dir-1');
  is($td->remove_directories('bogus-dir-2'),1);
  is($td->remove_directories('bogus-dir-3'),0);

  is ($td->name("a/b/c"), File::Spec->catfile('a','b','c'), "name concats");

  dies_ok { $td->mkdir('sd') } 'Dupe dir dies';
}
ok (!-d($d), "dir was cleaned");

