use strict;
use warnings;
use Test::More tests => 6;
use YAML::Syck;

# GH #193 — Dumping blessed scalar refs that alias each other caused the
# type tag to leak onto the next map key.  The emitter's alias early-return
# path skipped the tag-buffer cleanup, so the stale tag attached to whatever
# was emitted next.

{
    my $inner = bless \do { my $o = 1 }, 'JSON::PP::Boolean';
    my $data  = { a => $inner, b => $inner, c => 12143 };
    my $yaml  = Dump($data);

    unlike $yaml, qr/!!perl\/scalar:JSON::PP::Boolean c/,
        'type tag does not leak onto unrelated key';

    like $yaml, qr/^c: 12143$/m,
        'plain key c emits without tag';

    like $yaml, qr/!!perl\/scalar:JSON::PP::Boolean/,
        'blessed value still carries its tag';

    like $yaml, qr/&\d+/,
        'anchor is emitted for first occurrence';

    like $yaml, qr/\*\d+/,
        'alias is emitted for second occurrence';

    my $roundtrip = Load($yaml);
    is $roundtrip->{c}, 12143,
        'roundtrip preserves plain value';
}
