#!/usr/bin/perl -w
############################################################
#
#   $Id: example.pl 941 2007-02-06 18:48:19Z nicolaw $
#   example.pl - WWW::FleXtel example script
#
#   Copyright 2007 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

use 5.6.1;
use strict;
use warnings;
use WWW::FleXtel qw();
use Data::Dumper qw(Dumper);

my %acct = (
		#account   => 'A999999',
		#password  => 'password',
		number    => '07010000000',
		pin       => '1234',
		cache_ttl => 15,
		timeout   => 15,
	);

my $flextel = WWW::FleXtel->new(%acct);

my $destination = $flextel->set_destination(destination => "0800883322");

printf("Email: %s\nDestination: %s\nICD: %s\n",
		$flextel->get_email,
		$flextel->get_destination,
		$flextel->get_icd,
	);

print "Sleeping 10 seconds ...\n";
sleep 10;

print Dumper($flextel->get_phonebook);

print "Sleeping 10 seconds ...\n";
sleep 10;

printf("Email: %s\nDestination: %s\nICD: %s\n",
		$flextel->get_email,
		$flextel->get_destination,
		$flextel->get_icd,
	);


exit;

__END__

