# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-VCardFast.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Encode qw(encode_utf8);
use FindBin qw($Bin);
use Test::More;
use JSON::XS;

BEGIN { use_ok('Text::VCardFast') };

my @tests;
if (opendir(DH, "$Bin/cases")) {
    while (my $item = readdir(DH)) {
	next unless $item =~ m/^(.*)\.vcf$/;
	push @tests, $1;
    }
    closedir(DH);
}

my $numtests = @tests;

ok($numtests, "we have $numtests cards to test");

my @parseargs = (
  multival => ['adr','org','n'],
  multiparam => ['type'],
);

foreach my $test (@tests) {
    my $vdata = getfile("$Bin/cases/$test.vcf");
    ok($vdata, "data in $test.vcf");

    my $phash = eval { Text::VCardFast::vcard2hash_pp($vdata, @parseargs) };
    ok($phash, "parsed VCARD in $test.vcf with pureperl ($@)");
    my $chash = eval { Text::VCardFast::vcard2hash_c($vdata, @parseargs) };
    ok($chash, "parsed VCARD in $test.vcf with C ($@)");

    unless (is_deeply($phash, $chash, "contents of $test.vcf match from pureperl and C")) {
	use Data::Dumper;
	die Dumper($phash, $chash);
    }

    my $jdata = getfile("$Bin/cases/$test.json");
    unless (ok($jdata, "data in $test.json")) {
	open(FH, ">$Bin/cases/$test.json");
	my $coder = JSON::XS->new->utf8->pretty;
	print FH $coder->encode($chash);
	close(FH);
	print "CREATED JSON FILE $test.json\n";
	next;
    }

    my $jhash = eval { decode_json(encode_utf8($jdata)) };
    unless (ok($jhash, "valid JSON in $test.json ($@)")) {
	die $jdata;
    }

    unless (is_deeply($jhash, $chash, "contents of $test.vcf match $test.json")) {
	my $coder = JSON::XS->new->utf8->pretty;
	die "$jdata\n\n\n" . $coder->encode($chash);
    }

    my $data = Text::VCardFast::hash2vcard($chash);
    my $rehash = Text::VCardFast::vcard2hash_c($data, @parseargs);

    unless (is_deeply($rehash, $chash, "generated and reparsed data matches for $test")) {
	use Data::Dumper;
	die Dumper($rehash, $chash, $data, $vdata);
    }
}

plan tests => ($numtests * 8) + 2;

sub getfile {
    my $file = shift;
    open(FH, "<:encoding(UTF-8)", $file) or return;
    local $/ = undef;
    my $res = <FH>;
    close(FH);
    return $res;
}

