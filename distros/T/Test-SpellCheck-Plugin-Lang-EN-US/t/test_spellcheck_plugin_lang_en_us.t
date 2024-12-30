use 5.020;
use Test2::V0 -no_srand => 1;
use Test::SpellCheck::Plugin::Lang::EN::US;
use Path::Tiny qw( path );

my $plugin = Test::SpellCheck::Plugin::Lang::EN::US->new;
isa_ok $plugin, 'Test::SpellCheck::Plugin::Lang::EN::US';

my @files = $plugin->primary_dictionary;

note "files[]=$_" for @files;

is ref $files[0], '';
is ref $files[1], '';

@files = map { path($_) } @files;

is
  \@files,
  array {
    item object {
      call sub { -f $_[0] } => T();
    };
    item object {
      call sub { -f $_[0] } => T();
    };
    end;
  },
;

done_testing;


