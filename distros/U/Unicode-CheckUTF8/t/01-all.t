use Test::More tests => 96;
use Unicode::CheckUTF8 qw(isLegalUTF8String is_utf8);

my @tests = (  # array of arrayrefs of form [filename, good_or_bad, contents]
               ["1-simple", 1, "a"],
               ["2-simple", 1, "Some string!"],
               ["3-german", 1, "Stra\xc3\x9fe"],
               ["4-german-cut", 0, "Stra\xc3"],
               ["5-null", 0, "\0"],
               ["5-null2", 0, "this has a \0 null"],
               ["6-outrange", 0, "\xff"],
               ["7-overlong-1", 0, "\xc0\xaf"],
               ["8-overlong-2", 0, "\xe0\x80\xaf"],
               ["9-overlong-3", 0, "\xf0\x80\x80\xaf"],
               ["10-overlong-4", 0, "\xf8\x80\x80\x80\xaf"],
               );

# append all on-disk tests:

my $data_dir = "t/data";
opendir(D, $data_dir) or die "Couldn't open data directory: $!\n";
foreach my $f (readdir(D)) {
    next unless -f "$data_dir/$f";
    next if $f =~ /~$/;
    next unless $f =~ /^(GOOD|BAD)-/;
    my $good = ($f =~ /^GOOD/) ? 1 : 0;
    open (F, "$data_dir/$f") or die;
    my $contents = do { local $/; <F>; };
    push @tests, [ $f, $good, $contents ];
}
closedir(D);

my @subs = (
            ["with-len",    sub { return isLegalUTF8String($_[0], length $_[0]); }],
            ["without-len", sub { return is_utf8($_[0]); }],
            );


foreach my $s (@subs) {
    my $sb = $s->[1];
    foreach my $t (@tests) {
        my $rv = $sb->($t->[2]);
        is($rv, $t->[1], "name: $t->[0], func: $s->[0]");
    }
}
