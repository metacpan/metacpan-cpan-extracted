package Text::Repository::Test04;
# vim: ft=perl:

use strict;
use vars qw(@test_text);

BEGIN {
    @test_text = (
        "skjfio jodj akel jnasdlnflajf ",
        "klkwo kld 093iklk fa- askl;q'wll",
        "jkjpo0 0-0i wek w ie -0i etk ;awfo [",
        "0ifldk po[ -- 30 ikok fkd s'pl ;lwaf'",
        "okf podjk fowekj lqkjlwj lkm3  ",
    );
}

use Test::More tests => scalar @test_text;
use Text::Repository;
use IO::File;


(my $tmpdir = __PACKAGE__) =~ tr/:/-/s;
unless (-d "/tmp/$tmpdir") {
    mkdir "/tmp/$tmpdir", 0700 or die "Can't make temp directory /tmp/$tmpdir";
}

for (0..$#test_text) {
    my $fh;
    unless ($fh = IO::File->new(">/tmp/$tmpdir/test$_")) {
        warn "Couldn't open /tmp/$tmpdir/test$_: $!";
        next;
    }
    $fh->print($test_text[$_]);
    $fh->close;
}

my $rep = Text::Repository->new("/tmp/$tmpdir");

# Test 1 .. 5 -- Does the text match?
for (0 .. $#test_text) {
    is ($rep->fetch("test$_"), $test_text[$_], "Fetch works!");
}
