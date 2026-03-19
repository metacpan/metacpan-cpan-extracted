use strict;
use warnings;

use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use Test::More tests => 12;
use YAML::Syck;

# Issue #60: upgraded strings confuse Load()
# Perl strings can be stored internally as bytes or as UTF-8 (upgraded).
# LoadBytes/LoadUTF8 and DumpBytes/DumpUTF8 handle this explicitly.

# --- LoadBytes tests ---

{
    # LoadBytes with byte string (should work like Load)
    my $yaml = "---\n\xe9p\xe9e";  # épée in Latin-1 bytes
    my $result = YAML::Syck::LoadBytes($yaml);
    is( $result, "\xe9p\xe9e", "LoadBytes: byte string parsed correctly" );
}

{
    # LoadBytes with upgraded string (the core bug from issue #60)
    my $yaml = "---\n\xe9p\xe9e";  # épée in Latin-1 bytes
    utf8::upgrade($yaml);
    my $result = YAML::Syck::LoadBytes($yaml);
    is( $result, "\xe9p\xe9e", "LoadBytes: upgraded string downgraded before parsing" );
}

{
    # LoadBytes in list context
    my $yaml = "--- foo\n--- bar";
    my @results = YAML::Syck::LoadBytes($yaml);
    is_deeply( \@results, ['foo', 'bar'], "LoadBytes: list context works" );
}

# --- LoadUTF8 tests ---

{
    # LoadUTF8 with UTF-8 byte string
    my $yaml = "---\n\xc3\xa9p\xc3\xa9e";  # épée in UTF-8 bytes
    my $result = YAML::Syck::LoadUTF8($yaml);
    ok( utf8::is_utf8($result), "LoadUTF8: result has UTF-8 flag set" );
    is( $result, "\xe9p\xe9e", "LoadUTF8: UTF-8 bytes decoded to characters" );
}

{
    # LoadUTF8 with upgraded string (should also work)
    my $yaml = "---\n\xc3\xa9p\xc3\xa9e";  # UTF-8 bytes
    utf8::upgrade($yaml);
    my $result = YAML::Syck::LoadUTF8($yaml);
    ok( utf8::is_utf8($result), "LoadUTF8: upgraded input, result has UTF-8 flag" );
}

{
    # LoadUTF8 in list context
    my $yaml = "--- foo\n--- bar";
    my @results = YAML::Syck::LoadUTF8($yaml);
    is_deeply( \@results, ['foo', 'bar'], "LoadUTF8: list context works" );
}

# --- DumpBytes tests ---

{
    # DumpBytes should return bytes (no UTF-8 flag)
    my $data = "\xe9p\xe9e";
    utf8::upgrade($data);  # force UTF-8 internal representation
    my $yaml = YAML::Syck::DumpBytes($data);
    ok( !utf8::is_utf8($yaml), "DumpBytes: output has no UTF-8 flag" );
}

{
    # DumpBytes with plain ASCII
    my $yaml = YAML::Syck::DumpBytes("hello");
    is( $yaml, "--- hello\n", "DumpBytes: ASCII data dumped correctly" );
    ok( !utf8::is_utf8($yaml), "DumpBytes: ASCII output has no UTF-8 flag" );
}

# --- DumpUTF8 tests ---

{
    # DumpUTF8 should return UTF-8 flagged string
    my $data = "\xe9p\xe9e";
    utf8::upgrade($data);  # ensure it's a character string
    my $yaml = YAML::Syck::DumpUTF8($data);
    ok( utf8::is_utf8($yaml), "DumpUTF8: output has UTF-8 flag" );
    like( $yaml, qr/\xe9p\xe9e/, "DumpUTF8: contains the correct characters" );
}
