#!/usr/local/bin/perl
# Time-stamp: "2004-04-24 00:56:51 ADT"

print "I'm supposed to be run as a CGI\n\n" unless $ENV{REQUEST_METHOD};
if( ($ENV{HTTP_IF_NONE_MATCH} || '')  =~ m{"0-de-3d06d040"} ) {
  print "Status: 304 Not Modified\n\n";
} else {
  print qq{Contest-type: text/plain\nEtag: "0-de-3d06d040"\n\n},
        qq{<rss>Hello World</rss>\n};
}
