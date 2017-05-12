#!/usr/bin/perl -w
use strict;
use lib 't';
use testlib;

sub run {
  use_ok('Test::HTML::Content');
  # Tests for comments
  comment_ok('<html>Mail me at <!-- (c) 2002 corion@cpan.org -->some address</html>',
      '(c) 2002 corion@cpan.org', "Comments are found if there");
  comment_ok('<html>Mail me at <!-- (c) 2002 corion@cpan.org -->some address</html>',
      '  (c) 2002 corion@cpan.org', "Whitespace at front");
  comment_ok('<html>Mail me at <!-- (c) 2002 corion@cpan.org -->some address</html>',
      '  (c) 2002 corion@cpan.org  ', "Whitespace at front and end");
  comment_ok('<html>Mail me at <!-- (c) 2002 corion@cpan.org -->some address</html>',
      '(c) 2002 corion@cpan.org  ', "Whitespace at end");
  comment_ok('<html>Mail me at <!--   (c) 2002 corion@cpan.org -->some address</html>',
      '(c) 2002 corion@cpan.org', "Whitespace at HTML front");
  comment_ok('<html>Mail me at <!-- (c) 2002 corion@cpan.org   -->some address</html>',
      '(c) 2002 corion@cpan.org', "Whitespace at HTML end");
  comment_ok('<html>Mail me at <!-- (c) 2002 corion@cpan.org   -->some address</html>',
      qr'corion@cpan.org', "RE over comments");

  comment_ok('<html>Mail me at <a href="corion@cpan.org">foo<!-- corion@cpan.org --></a> some address</html>', 'corion@cpan.org', "Comments are found if there");

  comment_count('<html>Mail me at <a href="corion@cpan.org">foo<!-- corion@cpan.org --></a> some address</html>', 'corion@cpan.org',1, "Comments are found if there");
  comment_count('<html>Mail me at <a href="corion@cpan.org">foo<!-- corion@cpan.org -->
    <!-- corion@cpan.org --></a> some address</html>', 'corion@cpan.org',2, "Comments are counted correctly");
  comment_count('<html>Mail me at <a href="corion@cpan.org">foo<!-- corion@cpan.org --><!-- nospam@cpan.org --></a> some address</html>', qr'\@cpan\.org',2, "RE-Comments are counted correctly");

  no_comment('<html>Mail me at (c) 2002 corion@cpan.org some address</html>',
      '(c) 2002 corion@cpan.org', "Comments are not found if not there");
  no_comment('<html>Mail me at <a href="corion@cpan.org">corion@cpan.org</a> some address</html>',
      'corion@cpan.org', "Comments are not found if not there");
  no_comment('<html>Mail me at <a href="corion@cpan.org">foo<!-- corion@cpan.org --><!-- nospam@cpan.org --></a> some address</html>', qr'\@cpan\.com', "RE-Comments are found correctly");

  no_comment('<html>Mail me at <a href="corion@cpan.org">foo<!-- corion@[c]pan.org --><!-- nospam@cpan.org --></a> some address</html>', qr'corion\@[c]pan\.org', "RE-Comments not stringified");
};

runtests( 1+15, \&run );
