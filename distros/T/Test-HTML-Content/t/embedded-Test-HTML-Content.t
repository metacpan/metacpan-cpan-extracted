#!D:\perl\5.8.2\bin\perl.exe -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}

my $Original_File = 'lib\Test\HTML\Content.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 598 lib/Test/HTML/Content.pm

  $HTML = "<html><title>A test page</title><body><p>Home page</p>
           <img src='http://www.perl.com/camel.png' alt='camel'>
           <a href='http://www.perl.com'>Perl</a>
           <img src='http://www.perl.com/camel.png' alt='more camel'>
           <!--Hidden message--></body></html>";

  link_ok($HTML,"http://www.perl.com","We link to Perl");
  no_link($HTML,"http://www.pearl.com","We have no embarassing typos");
  link_ok($HTML,qr"http://[a-z]+\.perl.com","We have a link to perl.com");

  title_count($HTML,1,"We have one title tag");
  title_ok($HTML,qr/test/);

  tag_ok($HTML,"img", {src => "http://www.perl.com/camel.png"},
                        "We have an image of a camel on the page");
  tag_count($HTML,"img", {src => "http://www.perl.com/camel.png"}, 2,
                        "In fact, we have exactly two camel images on the page");
  no_tag($HTML,"blink",{}, "No annoying blink tags ..." );

  # We can check the textual contents
  text_ok($HTML,"Perl");

  # We can also check the contents of comments
  comment_ok($HTML,"Hidden message");

  # Advanced stuff

  # Using a regular expression to match against
  # tag attributes - here checking there are no ugly styles
  no_tag($HTML,"p",{ style => qr'ugly$' }, "No ugly styles" );

  # REs also can be used for substrings in comments
  comment_ok($HTML,qr"[hH]idden\s+mess");

  # and if you have XML::LibXML or XML::XPath, you can
  # even do XPath queries yourself:
  xpath_ok($HTML,'/html/body/p','HTML is somewhat wellformed');
  no_xpath($HTML,'/html/head/p','HTML is somewhat wellformed');

;

  }
};
is($@, '', "example from line 598");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

