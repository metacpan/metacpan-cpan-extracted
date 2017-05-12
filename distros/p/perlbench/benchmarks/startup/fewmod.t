#!perl

# Name: Start perl with a few modules
# Require: 5
# Desc:
#


require 'benchlib.pl';

&runtest(0.0015, <<'ENDTEST');

    my $path = $^X;
    (my $pdir = $path) =~ s,[/\\][^/\\]+$,/,;
    my @inc;
    if (-d "$pdir/lib") {
        # uninstalled perl
	@inc = ("-I", "$pdir/lib");
    }

    system $^X, @inc, "-e", "use Getopt::Std; use Text::ParseWords; use File::Find; 1";

ENDTEST
