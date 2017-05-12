#!/usr/bin/perl -w
use strict;
BEGIN {$ENV{'PATH'} = ''}
BEGIN { if ($ENV{'AUTOCLEAR'}) { system('/usr/bin/clear') } }
# use lib '/home/miko/projects/IdocsLib/dev/trunk';
# use lib '/home/miko/projects/ShareLib/dev/trunk/lib';
use Test::Toolbox;

# for debugging only
# only loading CWD to debug a failure with go_script_dir() and|or rtfile().
use Cwd;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;
# println '[begin]';


#------------------------------------------------------------------------------
# purpose
#

=head1 Purpose

Test Process::Results.

d go_script_dir
d rtplan
d rtcounts
d rtok
d rtcomp
d rtarr
d rtelcount
d rthash
d rtisa
d rtbool
d rtdef
d rtrx
d rtfile
d rtid
d rteval

=cut

#
# purpose
#------------------------------------------------------------------------------


# prepare for tests
rtplan 23, autodie => $ENV{'IDOCSDEV'};
my $name = 'Test::Toolbox';

## go to script directory
go_script_dir();

## trying to figure out what directory we're in
rtdiag('cwd: ', cwd());
rtdiag('have ./tests.pl: ', -e('./tests.pl'));

##= rtok
rtok "$name: rtok", 1;
rtok "$name: rtok should not", 0, should=>0;

##= rtfile, rtcomp, rtcounts
rtfile "$name: rtfile", './myfile.txt';
rtcomp "$name: rtcomp, rtcounts", rtcounts->{'sofar'}, 3;

##= rtarr, rtelcount
rtarr "$name: rtarr", [qw{a b c}], [qw{a b c}];
rtarr "$name: rtarr order_insensitive", [qw{a b c}], [qw{c b a}], order_insensitive=>1;
rtarr "$name: rtarr order_insensitive", [qw{a b c}], [qw{A B C}], case_insensitive=>1;
rtelcount "$name: rtelcount", [qw{a b c}], 3;

##= rthash
rthash "$name: rthash", {a=>1, b=>2, c=>3}, {a=>1, c=>3, b=>2};

##= rtisa
rtisa "$name: rtisa", {}, 'HASH';
rtisa "$name: rtisa, class empty string", 'hello', '';
rtisa "$name: rtisa, class undef", 'hello', undef;

##= rtbool
rtbool "$name: rtbool, true", 'hello', 'world';
rtbool "$name: rtbool, false", '', undef;

##= rtdef
rtdef "$name: rtdef, true", 1, 1;
rtdef "$name: rtdef, false", undef, 0;

##= rtrx
rtrx "$name: rtrx", 'yo, dude', qr/dude/i;

##= rtid
rtid "$name: rtid, error", 'my-error: whatever dude', 'my-error';
rtid "$name: rtid, no error, empty string", '', undef;
rtid "$name: rtid, no error, undef", undef, '';

##= rteval
rteval "$name: rteval, error", sub {die 'my-error: whatever dude'}, 'my-error';
rteval "$name: rteval, no error, empty string", sub {my $val=1}, '';
rteval "$name: rteval, no error, undef", sub {my $val=1}, undef;


#------------------------------------------------------------------------------
# done
# The following code is purely for a home grown testing system. It has no
# purpose outside of my own system. -Miko
#
if ($ENV{'IDOCSDEV'}) {
	require FileHandle;
	FileHandle->new('> /tmp/test-done.txt') or die "unable to open check file: $!";
	print "[done]\n";
}
#
# done
#------------------------------------------------------------------------------
