#!/usr/bin/perl -w
use strict;
use lib 't';
use testlib;

sub run {
  # Tests for tags
  tag_ok('<html><A href="http://www.perl.com">Title</A></html>',
      "a",{href => "http://www.perl.com" }, "Single attribute");
  tag_ok('<html><a href="http://www.perl.com">Title</a></html>',
      "A",{href => "http://www.perl.com" }, "Uppercase query finds lowercase tag");
  tag_ok('<html><A href="http://www.perl.com">Title</A></html>',
      "a",{href => "http://www.perl.com" }, "Lowercase query finds uppercase tag");
  tag_ok('<html><A href="http://www.perl.com">Title</A></html>',
      "A",{href => "http://www.perl.com" }, "Uppercase query finds uppercase tag");
  tag_ok('<html><a href="http://www.perl.com">Title</a></html>',
      "a",{href => "http://www.perl.com" }, "Lowercase query finds lowercase tag");
  tag_ok('<html><A href="http://www.perl.com">Title</A></html>',
      "a",{}, "No attributes");
  tag_ok('<html><A href="http://www.perl.com">Title</A></html>',
      "a",undef, "Undef attributes");
  tag_ok('<html><A href="http://www.perl.com">Title</A></html>',
      "a", "Forgotten attributes");
  tag_count('<html><A href="http://www.perl.com">Title</A></html>',
      "a",{href => "http://www.perl.com" },1, "Single attribute gets counted once");
  tag_ok('<html><A href="http://www.perl.com" alt=\'click here!\'>Title</A></html>',
      "a",{href => "http://www.perl.com" }, "Superfluous attributes are ignored");
  tag_count('<html><A href="http://www.perl.com" alt=\'click here!\'>Title</A></html>',
      "a",{href => "http://www.perl.com" }, 1, "Superfluous attributes are ignored and still the matchcount stays");
  tag_ok('<html><A href="http://www.perl.com">Title</A><A href="http://www.perl.com">Icon</A></html>',
      "a",{href => "http://www.perl.com" }, "Tags that appear twice get reported");
  tag_count('<html><A href="http://www.perl.com">Title</A><A href="http://www.perl.com">Icon</A></html>',
      "a",{href => "http://www.perl.com" },2, "Tags that appear twice get reported twice");

  no_tag('<html><A href="http://www.perl.com.example.com">Title</A></html>',
      "a",{href => "http://www.perl.com" }, "Plain strings get matched exactly");
  tag_ok('<html><A href="http://www.perl.com">Title</A></html>',
      "a",{href => qr"^http://.*$" }, "Regular expressions for attributes");
  tag_ok('<html><A href="http://www.perl.com" name="Perl">Title</A></html>',
      "a",{href => qr"^http://.*$", name => "Perl" }, "Mixing regular expressions with strings");
  tag_ok('<html><A href="http://www.perl.com" name="Perl">Title</A></html>',
      "a",{href => qr"^http://.*$", name => qr"^P.*l$" }, "Specifying more than one RE");
  tag_ok('<html><A href="http://www.perl.com" name="Perl">Title</A></html>',
      "a",{href => qr"http://www.pea?rl.com", name => qr"^Pea?rl$" }, "Optional RE");

  tag_count('<html><A href="http://www.perl.com" name="Perl">Title</A><A href="http://www.perl.com">Another link</A></html>',
      "a",{href => "http://www.perl.com" },2, "Ignored tags");
  tag_count('<html><a href="http://www.perl.com" name="Perl">Title</a><a href="http://www.perl.com">Another link</a></html>',
      "a",{href => "http://www.perl.com", name => undef },1, "Absent tags");

  no_tag('<html><A hrf="http://www.perl.com">Title</A></html>',
      "a",{href => "http://www.perl.com" }, "Misspelled attribute is not found");
  tag_count('<html><A hrf="http://www.perl.com">Title</A></html>',
      "a",{href => "http://www.perl.com" },0, "Misspelled attribute is reported zero times");

  no_tag('<html><B href="http://www.perl.com">Title</B></html>',
      "a",{href => "http://www.perl.com" }, "Tag with same attribute but different tag is not found");
  tag_count('<html><B href="http://www.perl.com">Title</B></html>',
      "a",{href => "http://www.perl.com" }, 0,"Tag with same attribute but different tag is reported zero times");

  no_tag('<html><A href="http://www.purl.com">Title</A></html>',
      "a",{href => "http://www.perl.com" },"Tag with different attribute value is not found");
  tag_count('<html><A href="http://www.purl.com">Title</A></html>',
      "a",{href => "http://www.perl.com" },0,"Tag with different attribute value is reported zero times");

  no_tag('<html><!-- <A href="http://www.purl.com">Title</A></html> -->',
      "a",{href => "http://www.perl.com" }, "Tag within a comment is not found");
  tag_count('<html><!-- <A href="http://www.purl.com">Title</A></html> -->',
      "a",{href => "http://www.perl.com" }, 0, "Tag within a comment is reported zero times");

  no_tag('<html><!-- <A href="http://www.perl.com"> -->Title</A></html>',
      "a",{href => "http://www.perl.com" }, "Tag within a (different) comment is not found");
  tag_count('<html><!-- <A href="http://www.perl.com"> -->Title</A></html>',
      "a",{href => "http://www.perl.com" }, 0, "Tag within a (different) comment is reported zero times");

  # RE parameters
  no_tag('<html><A href="http://www.perl.com" name="Perl">Title</A></html>',
      "a",{href => "http://www.perl.com", name => qr"^Pearl$" }, "Nonmatching via RE");
  tag_count('<html>
               <p style="nice">Nice style</p>
               <p style="ugly">Ugly style</p>
               <p style="super-ugly">Super-ugly style</p>
             </html>',
      "p",{style => qr"ugly$" }, 2, "Tag attribute counting");
};

runtests(32,\&run);