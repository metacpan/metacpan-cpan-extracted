package WWW::CheckGzip;
use warnings;
use strict;
our $VERSION = '0.05';
use Carp;
use Gzip::Faster;
use HTTP::Tiny;

sub builtin_test
{
    my ($ok, $message) = @_;
    if ($ok) {
	print "OK - $message.\n";
    }
    else {
	print "Not OK - $message.\n";
    }
}

sub new
{
    my ($class, $test) = @_;
    my $o = bless {};
    $o->{ua} = HTTP::Tiny->new (agent => __PACKAGE__);
    if (! $test) {
	$test = \& builtin_test;
    }
    $o->{test} = $test;
    return $o;
}

sub get_compressed
{
    my ($o, $url) = @_;
    my $ua = $o->{ua};
    my $r = $ua->get ($url, {headers => {'Accept-Encoding' => 'gzip'}});
    return $r;
}

sub get_uncompressed
{
    my ($o, $url) = @_;
    my $ua = $o->{ua};
    my $r = $ua->get ($url, {headers => {'Accept-Encoding' => ''}});
    return $r;
}

# Private

sub getce
{
    my ($r) = @_;
    return $r->{headers}{'content-encoding'};
}

sub check
{
    my ($o, $url) = @_;

    if (! $url) {
	carp "No URL supplied";
	return;
    }

    # Test with compressed.

    my $r = $o->get_compressed ($url);
    my $get_ok = $r->{success};
    & {$o->{test}} (!! $get_ok, "successfully got compressed $url");
    if (! $get_ok) {
	return;
    }

    my $content_encoding = getce ($r);
    & {$o->{test}} (!! $content_encoding, "got content encoding");
    & {$o->{test}} ($content_encoding eq 'gzip', "content encoding is gzip");
    my $text = $r->{content};
    my $unc;
    eval {
	$unc = gunzip ($text);
    };
    & {$o->{test}} (! $@, "$url correctly gzipped");
    & {$o->{test}} (length ($unc) > length ($text),
		     "compression made it smaller");

    # Test with uncompressed.

    my $runc = $o->get_uncompressed ($url);
    my $get_ok_unc = $runc->{success};
    & {$o->{test}} ($get_ok_unc, "successfully got uncompressed $url");
    my $content_encoding_unc = getce ($runc);
    & {$o->{test}} (! $content_encoding_unc, "Did not get content encoding");
    my $unctext = $runc->{content};
    eval {
	gunzip ($unctext);
    };
    & {$o->{test}} ($@, "$url not gzipped when requesting ungzipped");
}

1;
