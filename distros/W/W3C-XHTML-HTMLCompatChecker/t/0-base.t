#! /usr/bin/perl -w

print "1..3\n";
use strict;
use W3C::XHTML::HTMLCompatChecker;
print "ok 1\n";
my $checker = W3C::XHTML::HTMLCompatChecker->new();
print "ok 2\n";
my @messages = $checker->check_content('
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head><title>foo</title></head><body></body></html>');
print "ok 3\n";
