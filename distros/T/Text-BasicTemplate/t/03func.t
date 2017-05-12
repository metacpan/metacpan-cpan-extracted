#!/usr/bin/perl -w
# $Id: 03func.t,v 1.3 2000/02/22 01:55:52 aqua Exp $

BEGIN {
    $| = 1; print "1..14\n";
}
END {print "not ok 1\n" unless $loaded;}
use Text::BasicTemplate;
$loaded = 1;
print "ok 1\n";

use strict;

my $bt = new Text::BasicTemplate;
$bt or print "not ";
print "ok 2\n";

my ($tf2_count,$tf4_count) = (2,3);

sub argjoin { join('|',@_) }

my %ov = (
	  'foo' => sub { return 'bar' },
	  'tf' => \&tf_func,
	  'tf2' => [ \&tf2_start, \&tf2_list, \&tf2_end ],
	  'tf3' => \&tf3_func,
	  'tf4' => [ \&tf4_start, \&tf4_func, \&tf4_end ],
	  'recipe' => { fee => 'fi',
			fo => 'fum',
			bones => 'bread' },
	  'argjoin' => \&argjoin,
);


my $ss;

# anonymous subroutine
$ss = "%foo%";
print "not " unless $bt->parse(\$ss,\%ov) eq 'bar';
print "ok 3\n";

# named subroutine
$ss = "%tf%";
print "not " unless $bt->parse(\$ss,\%ov) eq 'tf_func running';
print "ok 4\n";

# start-list-end subroutine trio
$ss = "%&tf2%";
print "not " unless $bt->parse(\$ss,\%ov) eq 
  'tf2:begin tf2:1 tf2:0 tf2:end';
print "ok 5\n";

# subroutine taking arguments (various forms)
$ss = '%&tf3%';
print "not " unless $bt->parse(\$ss,\%ov) eq 'tf3<>';
print "ok 6\n";

$ss = '%&tf3()%';
print "not " unless $bt->parse(\$ss,\%ov) eq 'tf3<>';
print "ok 7\n";

$ss = '%&tf3(foo)%';
print "not " unless $bt->parse(\$ss,\%ov) eq 'tf3<foo>';
print "ok 8\n";

$ss = '%&tf3(foo,bar)%';
print "not " unless $bt->parse(\$ss,\%ov) eq 'tf3<foo,bar>';
print "ok 9\n";

$ss = '%&tf3(foo => bar)%';
print "not " unless $bt->parse(\$ss,\%ov) eq 'tf3<foo,bar>';
print "ok 10\n";

$ss = '%&tf3(foo => bar, snaf => u)%';
print "not " unless $bt->parse(\$ss,\%ov) eq 'tf3<foo,bar,snaf,u>';
print "ok 11\n";

# recursing subroutine returning stuff to be parsed
$ss = "%&tf4(bt_template => /tmp/maketest-03func-$$-tf4.tmpl)%";
if (open(TF,">/tmp/maketest-03func-$$-tf4.tmpl")) {
    print TF " %foo%:%bar%";
    close TF;
    print "not " unless $bt->parse(\$ss,\%ov) eq '[ bar:3 bar:3 bar:3 ]';
    print "ok 12\n";
    unlink("/tmp/maketest-03func-$$-tf4.tmpl");
} else {
    print "not ok 12\n";
    warn "/maketest-03func-$$-tf4start.tmpl: $!";
}

$ss = "%&argjoin(foo,bar,foo1=>bar1,foo2=>\"foo bar 2\",foo3,'bar3')%";
print "not " unless $bt->parse(\$ss,\%ov) eq 'foo|bar|foo1|bar1|foo2|foo bar 2|foo3|bar3';
print "ok 13\n";

$ss = "%&argjoin(foo,bar,\"f'oo\",'b\"ar',\"f\\\"oo\",'b\\'ar')%";
print "not " unless $bt->parse(\$ss,\%ov) eq 'foo|bar|f\'oo|b"ar|f"oo|b\'ar';
print "ok 14\n";

sub tf_func {
    "tf_func running";
}

sub tf2_start {
    "tf2:begin";
}

sub tf2_list {
    return " tf2:$tf2_count" if --$tf2_count>=0;
    undef;
}
sub tf2_end {
    return " tf2:end";
}

sub tf3_func {
    return "tf3<".join(',',@_).">";
}

sub tf4_start { '[' };
sub tf4_end { ' ]' };

sub tf4_func {
    return { foo => 2, bar => 3 } if $tf4_count--; 
    undef;
}
