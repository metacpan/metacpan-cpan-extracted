
use lib qw(../lib);
use lib qw(lib);



use strict;
use Test::More 0.98;
use Test::Exception;
use WebService::Mailgun;

# credentials are embedded into the request URL, so surrounding spaces
# (e.g. a trailing newline in a CI secret) must be stripped here.
sub env ($) {
    my $value = $ENV{$_[0]};
    return unless defined $value;
    $value =~ s/\A\s+|\s+\z//g;
    return $value;
}

my ($api_key, $domain, $to, $region) =
    map { env $_ } qw/MAILGUN_API_KEY MAILGUN_DOMAIN MAILGUN_TO MAILGUN_REGION/;

plan skip_all => 'set MAILGUN_API_KEY, MAILGUN_DOMAIN and MAILGUN_TO to run this test'
    unless $api_key && $domain && $to;

my $mime_str = qq{Content-Type: text/plain
Content-Disposition: inline
Content-Transfer-Encoding: binary
MIME-Version: 1.0
From: test\@perl.example.com
To: $to
Subject: Message Subject

Message Body};


my $mailgun = WebService::Mailgun->new(
    api_key => $api_key,
    domain  => $domain,
    region  => $region,
);

ok my $res = $mailgun->mime({
	to           => $to,
	message      => $mime_str,
	'o:testmode' => 'true',
}) or diag sprintf 'mailgun error: %s (%s)', $mailgun->error // 'unknown', $mailgun->error_status // 'unknown';

is $res->{message}, 'Queued. Thank you.';
note $res->{id};


ok my $res2 = $mailgun->mime({
	to           => $to,
	message      => \$mime_str,
	'o:testmode' => 'true',
});

is $res2->{message}, 'Queued. Thank you.';
note $res2->{id};



ok my $res3 = $mailgun->mime({
	to           => $to,
	file         => './t/corpus/msg1.mime',
	'o:testmode' => 'true',
});

is $res3->{message}, 'Queued. Thank you.';
note $res3->{id};

dies_ok { my $res4 = $mailgun->message('scalar'); }, 'unsupport', 'mime() needs a hash ref.';


done_testing;
