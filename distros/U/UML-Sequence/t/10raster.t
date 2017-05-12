use strict;
use warnings;

use Test::More tests => 1;

use vars qw($bootfail);

BEGIN {
    eval {
        require GD;
    };
    $bootfail = "no GD"
        if $@;

    unless ($bootfail) {
        eval {
            require GD::Text;
        };
        $bootfail = "no GD::Text"
            if $@;
    }

    unless ($bootfail) {
        eval {
            require MIME::Base64;
        };
        $bootfail = "no MIME::Base64"
            if $@;
    }

    SKIP:
    {
        skip($bootfail, 1) if $bootfail;
    }

    exit 1 if $bootfail;
}

use MIME::Base64 qw(encode_base64);

use UML::Sequence::SimpleSeq;
use UML::Sequence;
use UML::Sequence::Raster;

my $outline     = UML::Sequence::SimpleSeq->grab_outline_text('t/deluxewash.seq');
my $methods     = UML::Sequence::SimpleSeq->grab_methods($outline);

my $tree = UML::Sequence
    ->new($methods, $outline, \&UML::Sequence::SimpleSeq::parse_signature,
         \&UML::Sequence::SimpleSeq::grab_methods);

# run the seq2rast.pl script against washcar.xml from the distribution

UML::Sequence::Raster::seq2raster(
    -a => 'yellow',
    -c => '#E0E0E0',
    -f => 'gd',
    -o => 't/deluxewash.png',
    't/deluxewash.xml')
        or die "Couldn't run seq2rast.pl: $!\n";

open(TESTRAST, 't/deluxewash.png');
binmode TESTRAST;
my $test_rast;
read(TESTRAST, $test_rast, 16384);
close TESTRAST;

$test_rast = encode_base64($test_rast);
my $correct_rast = join('', <DATA>);

is_deeply($test_rast, $correct_rast, "PNG output");

unlink 't/deluxewash.png';

#
#    need to base64 encode the PNG image, and put it here...
#
__DATA__
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
