use charnames qw(:full);
no warnings;
$|=1;
print "1..6\n";
sub is {
    my ($foo, $bar, $baz) = @_;
    print +($foo eq $bar ? "ok" : "not ok"), " ", ++$i, " # $baz\n";
    warn "Expected [$bar], got [$foo]\n" if $foo ne $bar;
}

is(require Unicode::Semantics, 1, "Loaded");

Unicode::Semantics->import();
is(\&us, \&Unicode::Semantics::us, "Import (us) works");

Unicode::Semantics->import(qw(up));
is(\&up, \&Unicode::Semantics::us, "Import (up) works");

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $foo = "\xf6";

is(uc($foo), "\N{LATIN SMALL LETTER O WITH DIAERESIS}", "Doesn't work without upgrading (not OK, but this test will fail once this module is no longer needed");
is(uc(us($foo)), "\N{LATIN CAPITAL LETTER O WITH DIAERESIS}", "Yay, works now");
is(uc($foo), "\N{LATIN CAPITAL LETTER O WITH DIAERESIS}", "Stays upgraded");
