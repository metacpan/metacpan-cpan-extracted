#!/usr/bin/perl -w
use strict;
use lib 't';
use testlib;

sub run {
  # Tests for links
  no_link('<html></html>','http://www.perl.com', "Simple non-existing link");
  no_link('<html>http://www.perl.com</html>',"http://www.perl.com", "Plain text gets not interpreted as link");
  link_ok('<html><a href="http://www.perl.com">Title</a></html>',"http://www.perl.com", "A link is found");
  link_count('<html><A href="http://www.perl.com">Icon</a><a href="http://www.perl.com">Title</a></html>',"http://www.perl.com", 2,"A link that appears twice is reported twice");

  link_ok('<html>Mail me at <!-- href="corion@cpan.org" -->
                    <a href="corion@somewhere.else"></a> some address</html>',
      'corion@somewhere.else', "Links are not found if commented out");
};

runtests(5,\&run);