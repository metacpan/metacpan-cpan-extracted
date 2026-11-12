#!/usr/bin/perl
use strict;
use warnings;

use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);

use Web::VWF::Mail;

# The module runs sendmail(1) with -t and -f, so the stand-in has to be a
# program rather than a Perl subroutine.  A shell script is the shortest way
# to get one; Windows has no such thing to point at, so the file is skipped
# there rather than pretended to pass.
plan skip_all => 'needs a Unix-like executable to stand in for sendmail' if($^O eq 'MSWin32');

my $have_dkim = eval { require Mail::DKIM::Signer; 1 };
my $have_crypto = eval { require Crypt::OpenSSL::RSA; 1 };

my $dir = tempdir(CLEANUP => 1);

# Write a stand-in sendmail that keeps a copy of what it is given, and return
# its path with the path of the copy.  It has to accept -t -f FROM and ignore
# them, because that is how the module calls it.
sub capture
{
	my $name = shift;

	my $program = File::Spec->catfile($dir, $name);
	my $output = "$program.out";

	open(my $fh, '>', $program) or die "Cannot write $program: $!";
	print $fh "#!/bin/sh\ncat > '$output'\n";
	close($fh) or die "Cannot close $program: $!";
	chmod(0755, $program) or die "Cannot chmod $program: $!";

	return ($program, $output);
}

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return undef;
	return <$fh>;
}

subtest 'new' => sub {
	throws_ok { Web::VWF::Mail->new() } qr/\Afrom is required/, 'a sender is required';

	my $mail = Web::VWF::Mail->new({ from => 'no-reply@example.com' });
	isa_ok($mail, 'Web::VWF::Mail');
	is($mail->print("one\n"), 1, 'print returns true');
};

subtest 'unsigned without a key' => sub {
	my ($program, $output) = capture('plain');

	my $mail = Web::VWF::Mail->new(from => 'no-reply@example.com', sendmail => $program);
	$mail->print("To: someone\@example.com\n",
		"From: no-reply\@example.com\n",
		"Subject: hello\n\n",
		"Body line\n");
	ok($mail->close(), 'sendmail reported success');

	my $sent = slurp($output);
	ok(defined($sent), 'the stand-in received something');
	unlike($sent, qr/^DKIM-Signature:/m, 'no signature was invented');
	like($sent, qr/\ATo: someone\@example\.com\r\nFrom: no-reply\@example\.com\r\nSubject: hello\r\n\r\nBody line\r\n\z/,
		'The message is passed through unchanged apart from CRLF');

	my $length = length($sent);
	ok($mail->close(), 'a second close still reports the first result');
	is(length(slurp($output)), $length, 'a second close does not send again');
};

subtest 'signed when configured' => sub {
	plan skip_all => 'Mail::DKIM and Crypt::OpenSSL::RSA are needed to sign' unless($have_dkim && $have_crypto);

	# A key per run: no private key belongs in the distribution, not even a
	# throwaway one, because the next reader cannot tell that it is throwaway.
	my $keyfile = File::Spec->catfile($dir, 'test.private');
	open(my $fh, '>', $keyfile) or die "Cannot write $keyfile: $!";
	print $fh Crypt::OpenSSL::RSA->generate_key(1024)->get_private_key_string();
	close($fh) or die "Cannot close $keyfile: $!";

	my ($program, $output) = capture('signed');

	my $mail = Web::VWF::Mail->new(
		from => 'no-reply@example.com',
		domain => 'example.com',
		selector => '202611',
		keyfile => $keyfile,
		sendmail => $program,
	);
	$mail->print("To: someone\@example.com\n",
		"From: no-reply\@example.com\n",
		"Subject: hello\n\n",
		"Body line\n");
	ok($mail->close(), 'sendmail reported success');

	my $sent = slurp($output);
	my ($signature) = $sent =~ /^(DKIM-Signature:.*)$/m;
	ok(defined($signature), 'a signature was added');

	like($signature, qr/\bv=1\b/, 'DKIM version');
	like($signature, qr/\ba=rsa-sha256\b/, 'signed with SHA-256');
	# Both header and body relaxed: a body signed with simple canonicalisation
	# fails as soon as anything touches its trailing newline.
	like($signature, qr/\bc=relaxed\/relaxed\b/, 'relaxed canonicalisation');
	like($signature, qr/\bd=example\.com\b/, 'signed for the configured domain');
	like($signature, qr/\bs=202611\b/, 'signed with the configured selector');
	like($sent, qr/\r\n\r\nBody line\r\n\z/, 'the body follows the signature untouched');
};

subtest 'an unreadable key sends unsigned' => sub {
	my ($program, $output) = capture('nokey');

	my $mail = Web::VWF::Mail->new(
		from => 'no-reply@example.com',
		domain => 'example.com',
		selector => '202611',
		keyfile => File::Spec->catfile($dir, 'missing.private'),
		sendmail => $program,
	);
	$mail->print("To: someone\@example.com\nSubject: hello\n\nBody\n");

	my @warnings;
	{
		local $SIG{'__WARN__'} = sub { push @warnings, @_ };
		ok($mail->close(), 'the message is still sent');
	}
	ok(scalar(grep { /is not readable/ } @warnings), 'the unreadable key is reported');
	unlike(slurp($output), qr/^DKIM-Signature:/m, 'nothing claimed to be signed');
};

subtest 'sendmail that cannot be run' => sub {
	my $mail = Web::VWF::Mail->new(
		from => 'no-reply@example.com',
		sendmail => File::Spec->catfile($dir, 'no-such-sendmail'),
	);
	$mail->print("To: someone\@example.com\n\nBody\n");

	my @warnings;
	{
		local $SIG{'__WARN__'} = sub { push @warnings, @_ };
		ok(!$mail->close(), 'close reports the failure');
	}
	ok(scalar(grep { /Cannot run/ } @warnings), 'the failure is explained');
};

subtest 'an envelope sender that could be an option or a header is refused' => sub {
	foreach my $from ('-X/etc/passwd', "a\@example.com\nBcc: x\@example.com", 'a b@example.com', "a\@example.com\0") {
		(my $label = $from) =~ s/[^\x20-\x7e]/?/g;
		throws_ok { Web::VWF::Mail->new(from => $from) } qr/from is not a valid envelope sender/, "refuses '$label'";
	}
	throws_ok { Web::VWF::Mail->new() } qr/from is required/, 'from is required';
	lives_ok { Web::VWF::Mail->new(from => 'no-reply@example.com') } 'an ordinary sender is accepted';
};

done_testing();
