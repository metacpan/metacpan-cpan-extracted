# -*- perl -*-

BEGIN { $| = 1; print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}

use Tk::Getopt;
use vars qw($opt_debug $opt_foo $opt_with_special_symbols);

$loaded = 1;

@ARGV = qw(--nodebug --foo bar --with-special_symbols=4711);

@opttable =
  (['debug', '!'],
   ['foo', '=s'],
   ['with-special_symbols', '=i']);

$opt = new Tk::Getopt(-opttable => \@opttable);

if (!$opt->get_options) {
    die $opt->usage;
}

print( ($opt_debug != 0 ? "not " : "") . "ok 1\n");
print( ($opt_foo ne 'bar' ? "not " : "") . "ok 2\n");
print( ($opt_with_special_symbols != 4711 ? "not " : "") . "ok 3\n");

