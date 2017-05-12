#!/usr/bin/perl -w
use strict;
use Test::More;
use lib 't';
use testlib;

# This test file tests the internal routines of Test::HTML.
# The internal routines aren't really intended for public
# consumption, but the tests you'll find in here should
# document the behaviour enough ...

my (%cases_2,%cases_3);
my $count;
BEGIN {
    $cases_2{__dwim_compare} = [
      "foo" => "bar" => 0,
      "foo" => "..." => 0,
      "bar" => "foo" => 0,
      "bar" => "barra" => 0,
      "barra" => "bar" => 0,

      "foo" => qr"bar" => 0,
      "foo" => qr"..." => 1,
      "bar" => qr"foo" => 0,
      "bar" => qr"barra" => 0,
      "barra" => qr"bar" => 1,

      "foo" => qr"^oo" => 0,
      "foo" => qr"oo$" => 1,
      "FOO" => qr"foo$" => 0,
      "FOO" => qr"foo$"i => 1,
    ];

    $cases_2{__match_comment} = [
      "hidden  message" => qr"hidden\s+message" => 1,
      "FOO" => qr"foo$"i => 1,
      "  FOO" => qr"foo$"i => 1,
      "FOO  " => qr"foo$"i => 0,
      "FOO  " => qr"^foo$"i => 0,
      "  hidden message  " => "hidden message" => 1,
      "  hidden message  " => "hidden  message" => 0,
    ];

    $cases_2{__match_text} = [
      "hidden  message" => qr"hidden\s+message" => 1,
      "FOO" => qr"foo$"i => 1,
      "  FOO" => qr"foo$"i => 1,
      "FOO  " => qr"foo$"i => 0,
      "FOO  " => qr"^foo$"i => 0,
      "  hidden message  " => "hidden message" => 1,
      "  hidden message  " => "hidden  message" => 0,
    ];

    $cases_2{__match_declaration} = [
      "hidden  message" => qr"hidden\s+message" => 1,
      "FOO" => qr"foo$"i => 1,
      "  FOO" => qr"foo$"i => 1,
      "FOO  " => qr"foo$"i => 0,
      "FOO  " => qr"^foo$"i => 0,
      "  hidden message  " => "hidden message" => 1,
      "  hidden message  " => "hidden  message" => 0,
    ];

    $cases_3{__match} = [
      {href => 'http://www.perl.com', alt =>"foo"},{}, "href" => 0,
      {href => 'http://www.perl.com', alt =>"foo"},{}, "alt" => 0,
      {href => 'http://www.perl.com', alt =>undef},{alt => "boo"}, "alt" => 0,
      {href => undef, alt =>"foo"},{href => 'http://www.perl.com'}, "href" => 0,
      {href => 'http://www.perl.com', alt =>"foo"},{href => 'www.perl.com'}, "href" => 0,
      {href => 'http://www.perl.com', alt =>"foo"},{href => '.', alt => "foo"}, "href" => 0,

      {href => 'http://www.perl.com', alt =>"foo"},{href => 'http://www.perl.com'}, "href" => 1,
      {href => qr'www\.perl\.com'},{href => 'http://www.perl.com', alt =>"foo"}, "href" => 1,
      {href => qr'.', alt => "foo"},{href => 'http://www.perl.com', alt =>"foo"}, "href" => 1,

    ];

  $count = (18 + 24 + 12);
  $count += (@{$cases_2{$_}} / 3) for (keys %cases_2);
  $count += (@{$cases_3{$_}} / 4) for (keys %cases_3);
};

sub run_case {
  my ($count,$methods) = @_;
  my $method;
  for $method (sort keys %$methods) {
    my @cases = @{$methods->{$method}};
    while (@cases) {
      my (@params) = splice @cases, 0, $count;
      my $outcome = pop @params;
      my ($visual);
      ($visual = $method) =~ tr/_/ /;
      $visual =~ s/^\s*(.*?)\s*$/$1/;
      no strict 'refs';
      cmp_ok("Test::HTML::Content::$method"->(@params), '==',$outcome,"$visual(". join( "=~",@params ).")");
    };
  };
};

sub run {
  run_case( 3, \%cases_2 );
  run_case( 4, \%cases_3 );

  my ($count,$seen);
  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><body>foo</body></html>","a",{href => "http://www.perl.com"});
  is($count, 0,"Counting tags 1");
  is(@$seen, 0,"Checking possible candidates");
  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><a href='http://www.python.org'>Perl</a></html>","a",{href => "http://www.perl.com"});
  is($count, 0,"Counting tags 2");
  is(@$seen, 1,"Checking possible candidates");
  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><b href='http://www.python.org'>Perl</b></html>","a",{href => "http://www.perl.com"});
  is($count, 0,"Counting tags 3");
  is(@$seen, 0,"Checking possible candidates");
  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><b href='http://www.perl.com'>Perl</b></html>","a",{href => "http://www.perl.com"});
  is($count, 0,"Counting tags 4");
  is(@$seen, 0,"Checking possible candidates");

  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><a href='http://www.perl.com'>Perl</a></html>","a",{href => "http://www.perl.com"});
  is($count, 1,"Counting tags 6");
  is(@$seen, 1,"Checking possible candidates");
  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><a href='http://www.perl.com' alt='click here'>Perl</a></html>","a",{href => "http://www.perl.com"});
  is($count, 1,"Counting tags 7");
  is(@$seen, 1,"Checking possible candidates");
  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><a href='http://www.perl.com' alt=\"don't click here\">Perl</a><a href='http://www.perl.com'>Perl</a></html>","a",{href => "http://www.perl.com", alt => undef});
  is($count, 1,"Counting tags 8");
  is(@$seen, 2,"Checking possible candidates");
  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><a href='http://www.perl.com' alt=\"don't click here\">Perl</a><a href='http://www.perl.com'>Perl</a></html>","a",{href => "http://www.perl.com"});
  is($count, 2,"Counting tags 9");
  is(@$seen, 2,"Checking possible candidates");

  ($count,$seen) = Test::HTML::Content::__count_tags->("<html><a href='http://www.perl.com' alt=\"don't click here\">Perl</a><p><b><a href='http://www.perl.com'>Perl</a></b></p></html>","a",{href => "http://www.perl.com"});
  is($count, 2,"Counting tags 10");
  is(@$seen, 2,"Checking possible candidates");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html></html>" => "foo" );
  is($count,0,"Counting comments 0");
  is(@$seen,0,"Counting possible candidates 0");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html>foo</html>" => "foo" );
  is($count,0,"Counting comments 1");
  is(@$seen,0,"Counting possible candidates 1");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!-- foo --></html>" => "foo" );
  is($count,1,"Counting comments 2");
  is(@$seen,1,"Counting possible candidates 2");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!-- foo bar --></html>" => "foo" );
  is($count,0,"Counting comments 3");
  is(@$seen,1,"Counting possible candidates 3");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!-- bar foo --></html>" => "foo" );
  is($count,0,"Counting comments 4");
  is(@$seen,1,"Counting possible candidates 4");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!-- bar foo --></html>" => "foo" );
  is($count,0,"Counting comments 5");
  is(@$seen,1,"Counting possible candidates 5");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!-- foo --></html>" => "foo " );
  is($count,1,"Counting comments 6");
  is(@$seen,1,"Counting possible candidates 6");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!-- bar foo --></html>" => qr"foo" );
  is($count,1,"Counting comments 7");
  is(@$seen,1,"Counting possible candidates 7");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!--foo--></html>" => "foo" );
  is($count,1,"Counting comments 8");
  is(@$seen,1,"Counting possible candidates 8");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!--foo--><!--foo--></html>" => "foo" );
  is($count,2,"Counting comments 9");
  is(@$seen,2,"Counting possible candidates 9");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!--foo--><!--foo--><!--foo--></html>" => "foo" );
  is($count,3,"Counting comments 10");
  is(@$seen,3,"Counting possible candidates 10");

  ($count,$seen) = Test::HTML::Content::__count_comments( "<html><!--foo--><!--bar--><!--foo--></html>" => "foo" );
  is($count,2,"Counting comments 11");
  is(@$seen,3,"Counting possible candidates 11");

  ($count,$seen) = Test::HTML::Content::__count_text( "<html></html>" => "foo" );
  is($count,0,"Counting text occurrences 0");
  is(@$seen,0,"Counting possible candidates 0");

  ($count,$seen) = Test::HTML::Content::__count_text( "<html>foo</html>" => "foo" );
  is($count,1,"counting text occurrences 1");
  is(@$seen,1,"Counting possible candidates 1");

  ($count,$seen) = Test::HTML::Content::__count_text( "<html><!-- foo --></html>" => "foo" );
  is($count,0,"counting text occurrences 2");
  is(@$seen,0,"Counting possible candidates 2");

  # This test disabled, as it is not consistent between XPath and NoXPath...
  #($count,$seen) = Test::HTML::Content::__count_text( "<html><head></head><body><p> <!-- foo bar --> </p></body></html>" => "foo" );
  #is($count,0,"counting text occurrences 3");
  #is(@$seen,2,"Counting possible candidates 3");

  ($count,$seen) = Test::HTML::Content::__count_text( "<html>foo<!-- bar foo --> bar</html>" => "foo" );
  is($count,1,"counting text occurrences 4");
  is(@$seen,2,"Counting possible candidates 4");

  ($count,$seen) = Test::HTML::Content::__count_text( "<html>f<!-- bar foo -->o<!-- bar -->o</html>" => "foo" );
  is($count,0,"counting text occurrences 5");
  is(@$seen,3,"Counting possible candidates 5");

  ($count,$seen) = Test::HTML::Content::__count_text( "<html>Hello foo World</html>" => qr"foo" );
  is($count,1,"Checking RE for text 6");
  is(@$seen,1,"Counting possible candidates 6");
};

runtests( $count, \&run );

