use 5.026;
use utf8;
use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use lib 't/lib';
use Path::Tiny qw( path );
use Test::SourceFile;
use Test::SpellCheck::Plugin::PerlPOD;

subtest 'basic' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlPOD->new;
  isa_ok 'Test::SpellCheck::Plugin::PerlPOD';

  my $file = file( 'Foo.pod' => <<~'PERL' );
    =head1 DESCRIPTION

    one

     say "Hello World!";  # two
     exit                 # three

    four

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
      description => [['Foo.pod', 1]],
      one         => [['Foo.pod', 3]],
      two         => [['Foo.pod', 5]],
      three       => [['Foo.pod', 6]],
      four        => [['Foo.pod', 8]],
    },
  ;

};

subtest 'ignore Perl' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlPOD->new;

  my $file = file( 'Foo.pm' => <<~'PERL' );
    #!/usr/bin/perl

    say "Hello World"; # foo bar baz

    =head1 DESCRIPTION

    one

     say "Hello World!";  # two
     exit                 # three

    four

    =cut

    exit;              # and some more
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
      one         => [['Foo.pm', 7]],
      two         => [['Foo.pm', 9]],
      three       => [['Foo.pm', 10]],
      four        => [['Foo.pm', 12]],
    },
  ;

};

subtest 'skip-section' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlPOD->new(
    skip_sections => 'skip1',
  );

  my $file = file( 'Foo.pod' => <<~'PERL' );
    =head1 DESCRIPTION

    one

    =head1 SKIP1

    foo bar baz

    =head1 DESCRIPTION

    two

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
      description => [['Foo.pod', 1],['Foo.pod',9]],
      skip1       => [['Foo.pod', 5]],
      one         => [['Foo.pod', 3]],
      two         => [['Foo.pod', 11]],
    },
  or diag Dump(\%words);

};

subtest 'skip-sections' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlPOD->new(
    skip_sections => ['skip1','skip2'],
  );

  my $file = file( 'Foo.pod' => <<~'PERL' );
    =head1 DESCRIPTION

    one

    =head1 SKIP1

    foo bar baz

    =head1 DESCRIPTION

    two

    =head1 SKIP2

    foo bar baz

    =head1 DESCRIPTION

    three

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
      description => [['Foo.pod', 1],['Foo.pod',9],['Foo.pod',17]],
      skip1       => [['Foo.pod', 5]],
      skip2       => [['Foo.pod', 13]],
      one         => [['Foo.pod', 3]],
      two         => [['Foo.pod', 11]],
      three       => [['Foo.pod', 19]],
    },
  or diag Dump(\%words);

};

subtest 'no skip-sections' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlPOD->new(
    skip_sections => [],
  );

  my $file = file( 'Foo.pod' => <<~'PERL' );
    =head1 DESCRIPTION

    one

    =head1 AUTHOR

    two

    =head1 DESCRIPTION

    three

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
      description => [['Foo.pod', 1],['Foo.pod',9]],
      author      => [['Foo.pod', 5]],
      one         => [['Foo.pod', 3]],
      two         => [['Foo.pod', 7]],
      three       => [['Foo.pod', 11]],
    },
  or diag Dump(\%words);

};

subtest 'name' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlPOD->new(
    skip_sections => [],
  );

  my $file = file( 'Foo.pod' => <<~'PERL' );
    # something?
    package Foo::Bar;
    PERL

  my @events;

  $plugin->stream("$file", splitter(), sub ($type, $fn, $ln, $word) {
    return unless $type eq 'name';
    push @events,  [$type, $ln, $word];
  });

  is
    \@events,
    [[ 'name', 2, 'Foo::Bar' ]],
  ;

};

done_testing;
