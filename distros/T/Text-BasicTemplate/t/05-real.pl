#!/usr/bin/perl -Tw
# $Id: 05-real.pl,v 1.2 2000/01/20 05:01:14 aqua Exp $

my $loaded;

use strict;

BEGIN {
    $| = 1; print "1..12\n";
}
END {print "not ok 1\n" unless $loaded;}
use Text::BasicTemplate;
$loaded = 1;
print "ok 1\n";

$ENV{PATH} = '/bin:/usr/bin';
$ENV{IFS} = ' ';
delete @ENV{'ENV','CDPATH','BASH_ENV'};

# from Programming Perl (blue edition), p.358
sub is_tainted {
    not eval {
	my $foo = join("",@_), kill 0;
	1;
    }
}

print "not " unless &is_tainted($^X);
print "ok 2\n";

my $bt = Text::BasicTemplate->new(compatibility_mode_0x => 0);
$bt or print "not ";
print "ok 3\n";
$bt->{use_lexicon_cache} = $bt->{use_file_cache} = 0;

# did BT notice that taint checking is active?
print "not " unless $bt->{taint_enabled};
print "ok 4\n";

my $ss;

if ($ENV{PATH}) {
    $ss = "path=%\$PATH%";
    print "not " unless $bt->parse(\$ss,{}) =~ /^path=.+/;
}
print "ok 5\n";

# properly pass along tainted data
$ss = "ill at %ease%";
print "not " unless $bt->parse(\$ss,{ ease => $^X }) eq "ill at $^X";
print "ok 6\n";

print "compat=$bt->{compatibility_mode_0x} taint=$bt->{taint_enabled}\n",
      "7out($ss)=[",$bt->parse(\$ss,{ ease => $^X }),"]\n";

print "not " unless &is_tainted($bt->parse(\$ss,{ ease => $^X }));
print "ok 7\n";

$ss = "includes should be off %&bt_include(file,/etc/passwd)%";
print "not " unless $bt->parse(\$ss,{}) eq
  'includes should be off '.$bt->{disabled_pragma_identifier};
print "ok 8\n";

$ss = "exec should be off %&bt_exec(cmd,cat /etc/passwd)%";
print "not " unless $bt->parse(\$ss,{}) eq
  'exec should be off '.$bt->{disabled_pragma_identifier};
print "ok 9\n";

# now force exec/include and check the next level in
$bt->{pragma_enable}->{bt_include} =
  $bt->{pragma_enable}->{bt_exec} = 1;

my $tf = "/tmp/maketest-05taint-$$-it.tmpl";
open(TT,">$tf") || do {
    print "not ok 10\n";
    exit(1);
};
print TT "included %me%";
close TT;
print "ok 10\n";

print "not "
  unless $bt->parse($tf,{me => 'something'}) eq 'included something';
print "ok 11\n";

$ss = "I have %&bt_include(file,$tf)%";
print "not " unless $bt->parse(\$ss,{me => 'something'})
			       eq 'I have included something';
print "ok 12\n";

# perl 5.6.1 broke this test -- disabled until a solution
# can be found.
#open(TT,">$tf") || do {
#    print "not ok 13\n";
#    exit(1);
#};
#print TT "I can't include %&bt_include(file,/tmp/evil)%";
#close TT;
#
#print $bt->parse($tf,{});
#print "not " unless $bt->parse($tf,{}) =~ /is tainted, can\'t include/;
#print "ok 13\n";

#unlink($tf);


