use utf8;

use Test2::V0;

use File::Spec;
use File::Temp qw( tempdir );
use IO::Socket::INET;
use Socket qw( SOL_SOCKET SO_REUSEADDR );

use Zuzu::Parser;
use Zuzu::Runtime;

my $repo_root = File::Spec->rel2abs( File::Spec->curdir );
my $tmp = tempdir( CLEANUP => 1 );
my $record_file = File::Spec->catfile( $tmp, 'smtp-record.txt' );

my $listen = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Proto => 'tcp',
	Listen => 5,
	ReuseAddr => 1,
) or die "Could not start local SMTP listener: $!";
setsockopt( $listen, SOL_SOCKET, SO_REUSEADDR, 1 );
my $port = $listen->sockport;

my $pid = fork();
defined $pid or die "fork failed: $!";
if ( $pid == 0 ) {
	local $SIG{TERM} = sub { exit 0 };
	my $client = $listen->accept();
	open my $record, '>:raw', $record_file
		or die "Could not write SMTP record: $!";
	print {$client} "220 fake.example.test ESMTP\r\n";
	while ( my $line = <$client> ) {
		print {$record} "C $line";
		$line =~ s/\r?\n\z//;
		if ( $line =~ /^EHLO / ) {
			print {$client} "250-fake.example.test\r\n";
			print {$client} "250 PIPELINING\r\n";
		}
		elsif ( $line =~ /^MAIL FROM:/ ) {
			print {$client} "250 sender ok\r\n";
		}
		elsif ( $line =~ /^RCPT TO:<ok\@example\.test>/ ) {
			print {$client} "250 recipient ok\r\n";
		}
		elsif ( $line =~ /^RCPT TO:<bad\@example\.test>/ ) {
			print {$client} "550 recipient rejected\r\n";
		}
		elsif ( $line eq 'DATA' ) {
			print {$client} "354 continue\r\n";
			while ( my $data = <$client> ) {
				print {$record} "D $data";
				last if $data eq ".\r\n";
			}
			print {$client} "250 queued as fake-1\r\n";
		}
		elsif ( $line eq 'QUIT' ) {
			print {$client} "221 bye\r\n";
			last;
		}
		else {
			print {$client} "250 ok\r\n";
		}
	}
	close $record;
	close $client;
	exit 0;
}

my $runtime = Zuzu::Runtime->new(
	lib => [
		File::Spec->catdir( $repo_root, 'stdlib', 'test-modules' ),
		File::Spec->catdir( $repo_root, 'stdlib', 'modules' ),
	],
);
my $parser = Zuzu::Parser->new;

my $output = '';
my $stderr = '';
my $ok = eval {
	local *STDOUT;
	local *STDERR;
	open STDOUT, '>:encoding(UTF-8)', \$output or die $!;
	open STDERR, '>:encoding(UTF-8)', \$stderr or die $!;
	my $ast = $parser->parse(
		qq{
from std/net/smtp import Mailer;

let headers := new PairList();
headers.add( "From", "sender\@example.test" );
headers.add( "X-Dup", "one" );
headers.add( "X-Dup", "two" );
headers.add( "Message-ID", "<smtp-integration\@example.test>" );
let body := to_binary(".dot\r\nfinal\r\n");
let mailer := new Mailer(
	transport: "smtp",
	host: "127.0.0.1",
	port: $port,
	timeout: 5,
);
let result := mailer.send(
	"sender\@example.test",
	[ "ok\@example.test", "bad\@example.test" ],
	headers,
	body,
);
say result{transport};
say result{accepted}[0];
say result{rejected}[0];
say result{message_id};
}
		,
		'std-net-smtp-integration.zzs',
	);
	$runtime->evaluate($ast);
	1;
};

kill 'TERM', $pid;
waitpid( $pid, 0 );

ok $ok, 'SMTP workflow completes against fake server'
	or diag $@;
is $stderr, '', 'no stderr';
is $output,
	"smtp\nok\@example.test\nbad\@example.test\n<smtp-integration\@example.test>\n",
	'SMTP MailResult reports partial recipient outcome';

open my $record, '<:raw', $record_file
	or die "Could not read SMTP record: $!";
my $record_text = do { local $/; <$record> };
close $record;

like $record_text, qr/C MAIL FROM:<sender\@example\.test>\r\n/,
	'MAIL FROM uses envelope sender';
like $record_text, qr/C RCPT TO:<ok\@example\.test>\r\n/,
	'first RCPT TO uses envelope recipient';
like $record_text, qr/C RCPT TO:<bad\@example\.test>\r\n/,
	'second RCPT TO uses envelope recipient';
like $record_text, qr/D From: sender\@example\.test\r\n/,
	'DATA includes serialized headers';
like $record_text, qr/D X-Dup: one\r\nD X-Dup: two\r\n/,
	'DATA preserves duplicate header order';
like $record_text, qr/D \.\.dot\r\n/,
	'SMTP DATA dot-stuffs on the wire';

done_testing;
