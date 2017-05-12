# -*- perl -*-

BEGIN { $| = 1; print "1..11\n";}
END {print "not ok 1\n" unless $loaded;}

use Tk::Getopt;

$loaded = 1;

@ARGV = qw(--nodebug --foo bar --bla=4711 --notinhash);

%optctl =
  ('debug' => \$debug,
   'foo'   => \$string,
   'bla'   => \$integer);

$opt = new Tk::Getopt(-getopt => [\%optctl, "debug!", "foo=s",
				   "bla=i", "notinhash"]);

if (!$opt->get_options) {
    die $opt->usage;
}

print( ($debug != 0 ? "not " : "") . "ok 1\n");
print( ($string ne 'bar' ? "not " : "") . "ok 2\n");
print( ($integer != 4711 ? "not " : "") . "ok 3\n");
print( ($optctl{'notinhash'} != 1 ? "not " : "") . "ok 4\n");

@ARGV = qw(--link=link --xxx);

$opt2 = new Tk::Getopt(-getopt => [\%optctl, "link=s", \$link, "xxx"]);
if (!$opt2->get_options) {
    die $opt2->usage;
}

print( ($link ne 'link' ? "not " : "") . "ok 5\n");
print( ($optctl{'xxx'} != 1 ? "not " : "") . "ok 6\n");

@ARGV = qw(--s=srt --i=314);

$opt_s = $opt_s; # to satisfy -w
$opt3 = new Tk::Getopt(-getopt => ["s=s", "i=i", \$i]);
if (!$opt3->get_options) {
    die $opt3->usage;
}

print( ($opt_s ne 'srt' ? "not " : "") . "ok 7\n");
print( ($i != 314 ? "not " : "") . "ok 8\n");

@ARGV = qw(--ttt=srt --iii=314);

$opt4 = new Tk::Getopt(-getopt => {"sss|ttt=s" => \$sss, "iii=i", \$iii});
if (!$opt4->get_options) {
    die $opt4->usage;
}

print( ($sss ne 'srt' ? "not " : "") . "ok 9\n");
print( ($iii != 314 ? "not " : "") . "ok 10\n");

@ARGV = qw(--ttt=srt);

$sss = undef;
$opt5 = new Tk::Getopt(-opttable => [["ttt", "=s", undef, {'var' => \$sss}]]);
if (!$opt5->get_options) {
    die $opt5->usage;
}

print( ($sss ne 'srt' ? "not " : "") . "ok 11\n");
