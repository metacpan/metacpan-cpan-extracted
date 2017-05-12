if ($ENV{'PATH_INFO'}) {
    exit if (fork);
    close(STDOUT);
    close(STDERR);
}

$filename = $ARGV[0];
$bindir = $ARGV[1];

@tokens = split(/\//, $filename);
$src = pop @tokens;

$dir = join("/", @tokens);

$src =~ s/\..*?$//;

chdir $dir;


system "h2xs -A -n $src";
open(I, "$src.htxs");
open(O, ">>$src/$src.xs");
while (<I>) {
    print O;
}

close(I);
close(O);

chdir $src;


system "$^X Makefile.PL";
system "make";


@methods = ();

chdir "blib/arch/auto/$src";

system "/bin/mv $src.so ../../../..";
chdir "../../../..";

&export;

system "/bin/mv $src.{o,so,bs,pm} ..";

chdir "..";

system "/bin/rm -rf $src";

sub export {
    @lines = ();
    open(I, "$src.pm");
    while (<I>) {
        last if ($_ eq "1;\n");
        push(@lines, $_);
    }
    close(I);
    open(I, "$bindir/htpl-pm.code");
    while (<I>) {
        push(@lines, $_);
    }

#    shift @lines;

    open(O,">$src.pm");
    print O join("", @lines);
    close(O);
}
