use 5.026;
use utf8;
use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use lib 't/lib';
use Path::Tiny qw( path );
use Test::SourceFile;
use Test::SpellCheck::Plugin::PerlComment;

subtest 'basic' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlComment->new;
  isa_ok 'Test::SpellCheck::Plugin::PerlComment';

  my $file = file( 'Foo.pm' => <<~'PERL' );
    #!/usr/bin/perl

    say "Hello World"; # one
    exit;              # two
    PERL

  my %words;

  $plugin->stream("$file", splitter(), sub ($type, $fn, $ln, $word) {
    return unless $type eq 'word';
    push $words{$word}->@*, [path($fn)->basename,$ln];
  });

  is
    \%words,
    {
      one => [['Foo.pm', 3]],
      two => [['Foo.pm', 4]],
    },
  ;

};

subtest 'ignore POD' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlComment->new;

  my $file = file( 'Foo.pm' => <<~'PERL' );
    #!/usr/bin/perl

    say "Hello World"; # one

    =head1 DESCRIPTION

    foo baar baz

     say "Hello World!";  #  three
     exit                 # four

    and some more

    =cut

    exit;              # two
    PERL

  my %words;

  $plugin->stream("$file", splitter(), sub ($type, $fn, $ln, $word) {
    return unless $type eq 'word';
    push $words{$word}->@*, [path($fn)->basename,$ln];
  });

  is
    \%words,
    {
      one => [['Foo.pm', 3]],
      two => [['Foo.pm', 16]],
    },
  ;

};

subtest 'urls' => sub {

  my $plugin = Test::SpellCheck::Plugin::PerlComment->new;

  my $file = file( 'Foo.pm' => <<~'PERL' );
    #!/usr/bin/perl

    # https://foo.test#fragment
    # https://bar.test
    # mailto:plicease@cpan.org
    PERL

  my @urls;

  $plugin->stream("$file", splitter(), sub ($type, $fn, $ln, $word) {
    return unless $type eq 'url_link';
    push @urls, [$ln,$word];
  });

  is
    \@urls,
    [
      [ 3, 'https://foo.test#fragment' ],
      [ 4, 'https://bar.test',         ],
      [ 5, 'mailto:plicease@cpan.org'  ],
    ],
  ;
};

done_testing;
