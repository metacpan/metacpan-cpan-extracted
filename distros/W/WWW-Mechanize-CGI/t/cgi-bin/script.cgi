#!/usr/bin/perl

print "Content-Type: text/plain\n";
print "Status: 200\n";
print "X-Field: 1\n";
print "X-Field: 2\n";
print "\n";
print "$ENV{DOCUMENT_ROOT}";

die 'exception' if $ENV{DIE};
