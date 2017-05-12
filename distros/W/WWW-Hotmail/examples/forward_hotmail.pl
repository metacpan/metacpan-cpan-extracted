#!/usr/bin/perl

$|++;

use lib qw(../blib ../blib/lib);

use WWW::Hotmail;

my @accounts = (
#	{
#		email => 'tester@hotmail.com',
#		pass => 'PASSWORD',
#		forward => 'tester@gmail.com',
#	},
#	{
#		email => 'tester@hotmail.com',
#		pass => 'PASSWORD',
#		forward => 'tester@gmail.com',
#	},
);

unless (@accounts) {
	die "you need to edit this script\n";
}

foreach my $ac (@accounts) {
	my $h = WWW::Hotmail->new();

	print "- logging into account $ac->{email}\n";
	
	die $WWW::Hotmail::errstr unless $h->login($ac->{email},$ac->{pass});

	my @msgs = $h->messages();
	die "$1" if ($WWW::Hotmail::errstr =~ m/^(.+)/);
	
	unless (@msgs) {
		print "no email for $ac->{email}\n\n";
		next;
	}

	print "getting ".scalar(@msgs)." messages for $ac->{email}\n";
	
	for my $i ( 0 .. $#msgs ) {
		print "#".($i+1)." ".$msgs[$i]->from." ";
		print "- retrieving ";
		my $ma = $msgs[$i]->retrieve();
		if ($ac->{forward}) {
			print "- forwarding to $ac->{forward} ";
			$ma->resend($ac->{forward});
		} else {
			print "- delivering locally ";
			$ma->accept();
		}
		print "- deleting original ";
		$msgs[$i]->delete();
		print "- done!\n";
		sleep(3);
	}
	print "\n";
}
