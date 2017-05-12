use strict;

die "The evironment vairable OLLEDBTEST is not defined.\n" if not $ENV{OLLEDBTEST};

opendir(D, '.') or die "opendir D failed: $!";
my @files = grep(/\.t$/, readdir(D));
closedir D;

foreach my $file (@files) {
    warn "Running $file.\n";
    my $output = `perl -w $file`;
    my @output = grep(/^[^#]/, split(/\n/, $output));
    my @ok = grep(/^ok\s+\d+/, @output);
    my $expect = shift @output;
    $expect =~ s/^1\.\.//g;
    my $actual = $#ok + 1;
    if ($expect != $actual) {
       warn "For file '$file', the plan was to run $expect tests, but $actual passed.\n";
    }

    my @notok = grep(/^not\s+ok/, @output);
    if (@notok) {
       my $fails = $#notok + 1;
       warn "For file '$file', $fails test(s) of $expect failed.\n";
       warn join("\n", @notok), "\n";
    }

    my @others = grep($_ !~ /^(ok|not|#)/, @output);
    if (@others) {
       warn "Extraneous output from '$file':\n";
       warn join("\n", @others), "\n";
    }
}

