print "1..2\n";
sub layers {
    join "\0", map { defined($_) ? $_ : 'UNDEF' } (
        PerlIO::get_layers(STDIN),
        PerlIO::get_layers(STDOUT),
    );
}

BEGIN {
    $before = layers();
}
use encoding::stdio 'utf8';
print 'not ' if layers() eq $before;
print "ok 1\n";
print 'not ' if layers() !~ /utf8/;
print "ok 2\n";
#warn "\nBefore: $before\n___Now: ", layers;
