package WWW::CheckGzip;
use warnings;
use strict;
our $VERSION = '0.03';
use Carp;
use Gzip::Faster;
use LWP::UserAgent;

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
    $o->{ua} = LWP::UserAgent->new (agent => __PACKAGE__);
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
    $ua->default_header ('Accept-Encoding' => 'gzip');
    my $r = $ua->get ($url);
    return $r;
}

sub get_uncompressed
{
    my ($o, $url) = @_;
    my $ua = $o->{ua};
    $ua->default_header ('Accept-Encoding' => '');
    my $r = $ua->get ($url);
    return $r;
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
    my $get_ok = $r->is_success ();
    & {$o->{test}} (!! $get_ok, "successfully got compressed $url");
    if (! $get_ok) {
	return;
    }
    my $content_encoding = $r->header ('Content-Encoding');
    & {$o->{test}} (!! $content_encoding, "got content encoding");
    & {$o->{test}} ($content_encoding eq 'gzip', "content encoding is gzip");
    my $text = $r->content ();
    my $unc;
    eval {
	$unc = gunzip ($text);
    };
    & {$o->{test}} (! $@, "$url correctly gzipped");
    & {$o->{test}} (length ($unc) > length ($text),
		     "compression made it smaller");

    # Test with uncompressed.

    my $runc = $o->get_uncompressed ($url);
    my $get_ok_unc = $runc->is_success ();
    & {$o->{test}} (!! $get_ok, "successfully got uncompressed $url");
    my $content_encoding_unc = $runc->header ('Content-Encoding');
    & {$o->{test}} (! $content_encoding_unc, "Did not get content encoding");
    my $unctext = $runc->content ();
    eval {
	gunzip ($unctext);
    };
    & {$o->{test}} ($@, "$url not gzipped when requesting ungzipped");
}

1;
