
use lib qw(../lib);
use lib qw(lib);



use strict;
use Test::More 0.98;
use Test::Exception;
use WebService::Mailgun;

my $mime_str = q{Content-Type: text/plain
Content-Disposition: inline
Content-Transfer-Encoding: binary
MIME-Version: 1.0
From: test@perl.example.com
To: kan.fushihara@gmail.com
Subject: Message Subject

Message Body}; 


my $mailgun = WebService::Mailgun->new(
    api_key => 'key-389807c554fdfe0a7757adf0650f7768',
    domain  => 'sandbox56435abd76e84fa6b03de82540e11271.mailgun.org',
);

ok my $res = $mailgun->mime({
	to           => 'kan.fushihara@gmail.com',
	message      => $mime_str, 
	'o:testmode' => 'true',
});

is $res->{message}, 'Queued. Thank you.';
note $res->{id};


ok my $res2 = $mailgun->mime({
	to           => 'kan.fushihara@gmail.com',
	message      => \$mime_str, 
	'o:testmode' => 'true',
});

is $res2->{message}, 'Queued. Thank you.';
note $res2->{id};



ok my $res2 = $mailgun->mime({
	to           => 'kan.fushihara@gmail.com',
	file         => './t/corpus/msg1.mime', 
	'o:testmode' => 'true',
});

is $res2->{message}, 'Queued. Thank you.';
note $res2->{id};

dies_ok { my $res3 = $mailgun->message('scalar'); }, 'unsupport', 'mime() needs a hash ref.';


done_testing;

