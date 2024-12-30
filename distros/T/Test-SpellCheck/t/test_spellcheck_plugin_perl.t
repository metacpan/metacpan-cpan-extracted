use 5.026;
use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use lib 't/lib';
use Path::Tiny qw( path );
use Test::SourceFile;
use Test::SpellCheck::Plugin::Perl;
use List::Util 1.29 qw( pairs );

subtest 'combo' => sub {

  my $plugin = Test::SpellCheck::Plugin::Perl->new;
  isa_ok 'Test::SpellCheck::Plugin::Perl';

  my $file = file( 'Foo.pm' => <<~'PERL' );
    #!/usr/bin/perl

    say "Hello World"; # one

    =head1 DESCRIPTION

    two

     say "Hello World!";  # three
     exit                 # four

    five

    =cut

    exit;              # six
    PERL

  my %words;

  $plugin->stream("$file", splitter(), sub ($type, $fn, $ln, $word) {
    return unless $type eq 'word';
    push $words{$word}->@*, [path($fn)->basename,$ln];
  });

  is
    \%words,
    {
      description => [['Foo.pm', 5]],
      one         => [['Foo.pm', 3]],
      two         => [['Foo.pm', 7]],
      three       => [['Foo.pm', 9]],
      four        => [['Foo.pm', 10]],
      five        => [['Foo.pm', 12]],
      six         => [['Foo.pm', 16]],
    },
  ;

};

subtest 'skip-section' => sub {

  my $plugin = Test::SpellCheck::Plugin::Perl->new(
    skip_sections => ['skip1'],
  );

  my $file = file( 'Foo.pm' => <<~'PERL' );
    #!/usr/bin/perl

    say "Hello World"; # one

    =head1 DESCRIPTION

    two

     say "Hello World!";  # three
     exit                 # four

    =head1 SKIP1

    foo bar baz

    =head1 DESCRIPTION

    five

    =cut

    exit;              # six
    PERL

  my %words;

  $plugin->stream("$file", splitter(), sub ($type, $fn, $ln, $word) {
    return unless $type eq 'word';
    push $words{$word}->@*, [path($fn)->basename,$ln];
  });

  is
    \%words,
    {
      description => [['Foo.pm', 5],['Foo.pm',16]],
      skip1       => [['Foo.pm', 12]],
      one         => [['Foo.pm', 3]],
      two         => [['Foo.pm', 7]],
      three       => [['Foo.pm', 9]],
      four        => [['Foo.pm', 10]],
      five        => [['Foo.pm', 18]],
      six         => [['Foo.pm', 22]],
    },
  ;

};

subtest 'lang' => sub {

  local $@ = '';
  eval { Test::SpellCheck::Plugin::Perl->new( lang => 'foo-bar' ) };
  like "$@", qr/^bad language: foo-bar/;

  package Test::SpellCheck::Plugin::Lang::AB::CD {

    sub new ($class)
    {
      bless {}, $class;
    }

    sub primary_dictionary ($self)
    {
      return ('x','y');
    }

    $INC{'Test/SpellCheck/Plugin/Lang/AB/CD.pm'} = __FILE__;
  }

  my $plugin = Test::SpellCheck::Plugin::Perl->new( lang => 'Ab-Cd' );
  is
    [$plugin->primary_dictionary],
    ['x','y'],
  ;

  $plugin = Test::SpellCheck::Plugin::Perl->new( lang => [__FILE__,__FILE__] );
  is
    [$plugin->primary_dictionary],
    [__FILE__,__FILE__],
  ;

};

subtest 'do not check comments' => sub {

  my $plugin = Test::SpellCheck::Plugin::Perl->new(
    check_comments => 0,
  );

  my $file = file( 'Foo.pm' => <<~'PERL' );
    say "Hello World"; # foo bar baz

    =head1 DESCRIPTION

    one

    =cut
    PERL

  my %words;

  $plugin->stream("$file", splitter(), sub ($type, $fn, $ln, $word) {
    return unless $type eq 'word';
    push $words{$word}->@*, [path($fn)->basename,$ln];
  });

  is
    \%words,
    {
      description => [['Foo.pm', 3]],
      one         => [['Foo.pm', 5]],
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
