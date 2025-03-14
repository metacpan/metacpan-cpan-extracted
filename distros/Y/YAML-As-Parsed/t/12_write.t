use utf8;
use strict;
use warnings;
use lib 't/lib/';
use Test::More 0.88;
use SubtestCompat;
use TestBridge;
use TestUtils;

use YAML::As::Parsed;
use File::Basename qw/basename/;
use File::Spec::Functions 'catfile';
use File::Temp 0.19; # newdir

#--------------------------------------------------------------------------#
# Error conditions
#--------------------------------------------------------------------------#

subtest 'no filename for write()' => sub {
    my $obj = YAML::As::Parsed->new();
    eval { $obj->write(); };
    error_like( qr/You did not specify a file name/,
        "No filename provided to write()"
    );
};

#--------------------------------------------------------------------------#
# Test that write uses correct encoding and can round-trip
#--------------------------------------------------------------------------#

my @cases = (
    { label => "ascii",  name => "Mengue" },
    { label => "latin1", name => "Mengué" },
    { label => "wide",   name => "あ"     },
);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

# YAML::As::Parsed doesn't preserve order in the file, so we can't actually check
# file equivalence.  We have to see if we can round-trip a data structure
# from Perl to YAML and back.
for my $c ( @cases ) {
    subtest "write $c->{label} characters" => sub {
        my $data;
        @warnings = ();

        # get a tempfile name to write to
        my $tempdir = File::Temp->newdir("YTXXXXXX", TMPDIR => 1 );
        my $short_tempfile = 'output';
        my $tempfile = catfile($tempdir, $short_tempfile);

        # YAML::As::Parsed->write
        ok( YAML::As::Parsed->new($c)->write($tempfile),
            "case $c->{label}: write $short_tempfile" )
            or diag "ERROR: " . YAML::As::Parsed->errstr;

        # YAML::As::Parsed->read
        ok( $data = eval { YAML::As::Parsed->read( $tempfile ) },
            "case $c->{label}: read $short_tempfile" )
            or diag "ERROR: " . YAML::As::Parsed->errstr;
        is( $@, '', "no error caught" );
        SKIP : {
            skip "no data read", 1 unless $data;
            cmp_deeply( $data, [ $c ],
                "case $c->{label}: Perl -> File -> Perl roundtrip" );
        }

        # YAML::As::Parsed->read_string on UTF-8 decoded data
        ok( $data = eval { YAML::As::Parsed->read_string( slurp($tempfile, ":utf8") ) },
            "case $c->{label}: read_string on UTF-8 decoded $short_tempfile" );
        is( $@, '', "no error caught" );
        SKIP : {
            skip "no data read", 1 unless $data;
            cmp_deeply( $data, [ $c ],
                "case $c->{label}: Perl -> File -> Decoded -> Perl roundtrip" );
        }

        is( scalar @warnings, 0, "case $c->{label}: no warnings caught" )
            or diag @warnings;
    }
}

done_testing;
