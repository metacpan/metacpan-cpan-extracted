#! /usr/bin/perl -w

print "1..6\n";
use strict;
use W3C::XHTML::HTMLCompatChecker;
print "ok 1\n";
my $checker = W3C::XHTML::HTMLCompatChecker->new();
print "ok 2\n";

# test 3 - document served as application/xhtml+xml
# any_xhtml option is OFF (default) and checker should abort

my @messages = $checker->check_uri("http://qa-dev.w3.org/wmvs/HEAD/dev/tests/xhtml-basic11.xhtml");
if (defined $messages[0]){
    if ($messages[0]{severity} eq "Abort") {
        print "ok 3\n";
    }
    else {print "not ok 3\n";}
}
else {print "not ok 3\n";}

# test 4 - document served as application/xhtml+xml
# any_xhtml option is ON and checker should NOT abort
# but should report an issue
@messages = $checker->check_uri("http://qa-dev.w3.org/wmvs/HEAD/dev/tests/xhtml-basic11.xhtml", any_xhtml=>1);
if (defined $messages[0]) {
    if ($messages[0]{severity} eq "Abort"){print "not ok 4\n";}
    else {print "ok 4\n";}
    }
else {print "not ok 4\n";}

#test 5 : this is not HTML - should abort
@messages = $checker->check_content('<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" 
  "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg width="5cm" height="4cm">
<desc>Four separate rectangles
  </desc>
<rect x="0.5cm" y="0.5cm" width="2cm" height="1cm"/>
<rect x="0.5cm" y="2cm" width="1cm" height="1.5cm"/>
<rect x="3cm" y="0.5cm" width="1.5cm" height="2cm"/>
<rect x="3.5cm" y="3cm" width="1cm" height="0.5cm"/>
<rect x=".01cm" y=".01cm" width="4.98cm" height="3.98cm"
        fill="none" stroke="blue" stroke-width=".02cm" />

</svg>');
if (defined $messages[0]){
    if ($messages[0]{severity} eq "Abort") {
        print "ok 5\n";
    }
    else {print "not ok 5\n";}
}
else {print "not ok 5\n";}

#test 6 : XHTML but not well-formed. The checker should abort
@messages = $checker->check_content('
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head><title>foo</title></head><body></body></html>');
if (defined $messages[0]){
    if ($messages[0]{severity} eq "Abort") {
        print "ok 6\n";
    }
    else {print "not ok 6\n";}
}
else {print "not ok 6\n";}
