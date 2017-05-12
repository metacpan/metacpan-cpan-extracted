#!/usr/bin/perl -w
use strict;
use lib 'blib/lib';
use lib 'blib/arch';
use Text::Scws;
use Time::HiRes qw/time/;
use Devel::Peek;
use Data::Dumper;

my $t = time();
my $scws = Text::Scws->new;
#Dump($scws);

my $res1 = $scws->set_dict('/root/Text-Scws-0.01/dict.xdb');
#Dump($res1);

my $res2 = $scws->set_rule('/root/Text-Scws-0.01/rules.ini');
#Dump($res2);

$scws->set_ignore(1);
#my $text = "这里是中文环境下的一段文字";
#my $res3 = $scws->send_text($text);
#Dump($res3);

my $res4 = $scws->get_result();
#Dump($res4);
#print Dumper($res4);
foreach (@$res4) {
    print $_->{word}, " ";
}

print "\n\n";
my $l = 0;
my $s = '';
open FD, "< 110.txt";
while (<FD>) {
    last if ++ $l > 20;
    $s .= $_;
}
close FD;

print "INOUT:\n";
print $s;

print "\n\n";
print "OUTPUT:\n";
$scws->send_text($s);
while (my $r = $scws->get_result()) {
    foreach (@$r) {
        print $_->{word}, " ";
    }
}
print "\n\n";
print "Time used: " . (time() - $t) . "\n";;
