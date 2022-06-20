use Test::More 0.96;
use Test::Exception;

use IO qw(File Handle); # Make sure we can run on perl 5.8/5.10
use IO::All;
use Text::Continuation::Parser qw(parse_line);
use File::Spec::Functions qw(catfile);
use autodie;

{
    note "Test line continuation";

    open my $fh, '<', catfile(qw(t inc data text.txt));
    my $line = parse_line($fh);
    is(
        $line,
        "line onecontinues in two without spaces in onecontinues",
        "line one and two are parsed"
    );

    $line = parse_line($fh);
    is($line, 'baz', "line three is parsed");

    $line = parse_line($fh);
    is(
        $line,
        "this line starts with 'this line starts with' and ends with ''s:''s",
        "lines four to nine are parsed"
    );

    $line = parse_line($fh);
    is($line, "0foo''", "line ten to twelve are parsed");

    $line = parse_line($fh);
    is($line, "", "empty line");

    $line = parse_line($fh);
    is($line, "last line", "the last line");

    my $OEF = parse_line($fh);
    is($OEF, undef, "file ends here");

}

sub _io_tmp {
    my $fh = io('?');
    foreach (@_) {
        $fh->print($_, $/);
    }
    $fh->seek(0,0);
    return $fh;
}

{
    # These are not really errors, but probably not what you meant
    # either. Just like Docker we don't want you to do stupid things
    note "Test line continuation errors";

    my $io = _io_tmp("foo\\\r", "  #\r", "\r");
    throws_ok(
        sub {
            parse_line($io);
        },
        qr/Line continuation detected and empty line\. This is invalid/,
        "Line continuation and empty line"
    );

    throws_ok(
        sub {
            parse_line($io, "foo");
        },
        qr/Line continuation detected and reaching end of file\. This is invalid/,
        "Line continuation at end of file"
    );
}


done_testing;
