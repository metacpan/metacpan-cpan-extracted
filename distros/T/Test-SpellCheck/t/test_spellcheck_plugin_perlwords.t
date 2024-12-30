use Test2::V0 -no_srand => 1;
use 5.026;
use Test::SpellCheck::Plugin::PerlWords;
use Path::Tiny qw( path );
use List::Util 1.29 qw( pairs );

subtest 'dictionary' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlWords->new;
  isa_ok $plugin, 'Test::SpellCheck::Plugin::PerlWords';

  my @files = $plugin->dictionary;

  note "files[]=$_" for @files;

  is ref $files[0], '';

  @files = map { path($_) } @files;

  is
    \@files,
    array {
      item object {
        call sub { -f $_[0] } => T();
      };
      end;
    },
  ;

};

subtest 'splitter' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlWords->new;

  is
    [pairs( $plugin->splitter )],
    array {
      # has at least one element
      item D();

      # none of the types are path_name,
      # since we do not support that in core
      all_items array {
        item !string('path_name');
        item D();
      };
      etc;
    },
  ;

};


done_testing;
