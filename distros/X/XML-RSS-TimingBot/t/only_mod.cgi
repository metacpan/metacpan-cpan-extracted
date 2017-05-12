#!/usr/local/bin/perl
# Time-stamp: "2004-04-24 00:56:16 ADT"

print "I'm supposed to be run as a CGI\n\n" unless $ENV{REQUEST_METHOD};
if( ($ENV{HTTP_IF_MODIFIED_SINCE} || '')
 =~ m{Wed, 21 Apr 2004 00:43:11 GMT} ) {
  print "Status: 304 Not Modified\n\n";
} else {
  print qq{Contest-type: text/plain\n},
        qq{Last-Modified: Wed, 21 Apr 2004 00:43:11 GMT\n\n},
        qq{<rss>Hello World</rss>\n};
}
