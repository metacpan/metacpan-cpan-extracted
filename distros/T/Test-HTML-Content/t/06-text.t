use strict;
use lib 't';
use testlib;

my $HTML = <<'HTML';
<HTML><BODY>
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very long text.This is a very long text.This is a very long text.
This is a very long text.This is a very long text.This is a very lang text.This is a very long text.This is a very long text.
</BODY></HTML>
HTML
my $HTML2 = "<html>This is some text.<!-- and a comment --> And some more text. <p>And some other stuff</p></html>";

# use Test::HTML::Content;

sub run {
  text_ok($HTML,qr"This is a very lang text."ism,"REs for text work");
  text_count($HTML,qr"This is a very lang text.",1,"Counting text elements works");
  no_text($HTML, "This is a very long test","Negation works as well");
  no_text($HTML, qr"This is a very long test","Negation also works with REs");

  text_ok($HTML2,"This is some text.","Complete elements are matched");
  text_ok($HTML2,"And some more text.","Complete elements are matched with whitespace at the ends");
  text_count($HTML2,qr"text",2,"Counting elements works with REs");
  text_count($HTML2,qr"[aA]nd",2,"Counting elements works with REs");

  # Now guard against inadverent stringification of REs :
    #$text =~ s/^\s*(.*?)\s*$/$1/;
  no_text("[A] simple test",qr"[A] simple test","No stringification of REs in no_text()");
  text_count("[A] simple test",qr"[A] simple test",0,"No stringification of REs in text_count()");
  text_ok("A simple test",qr"A simple test","Text is not broken up");
};

runtests( 11, \&run );