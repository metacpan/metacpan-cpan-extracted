# -*- perl -*-

BEGIN { $| = 1; print "1..2\n";}
END {print "not ok 1\n" unless $loaded;}

use Tk::Getopt;
use vars qw($opt_debug $opt_foo $opt_with_special_symbols);

$loaded = 1;

@ARGV = qw(--nodebug --foo bar --with-special_symbols=4711);

@opttable =
  (['debug', '!', undef, alias => ['d', 'dbg'], label => 'a label'],
   ['foo', '=s'],
   ['with-special_symbols', '=i']);

$opt = new Tk::Getopt(-opttable => \@opttable);

if (!$opt->get_options) {
    die $opt->usage;
}

print( (ref $opttable[0]->[3] ne 'HASH' ? "not " : "") . "ok 1\n");
print( ($opttable[0]->[3]{'label'} ne 'a label' ? "not " : "") . "ok 2\n");
