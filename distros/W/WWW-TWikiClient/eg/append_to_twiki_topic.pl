#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use WWW::TWikiClient;

my $client = new WWW::TWikiClient;

$client->auth_user           ("TWikiClientBot");
$client->auth_passwd         ("secretpassword");
$client->override_locks      (1);

$client->bin_url             ('http://twiki.yourhost.de/twiki/bin/');
$client->current_default_web ('Ourweb');
$client->current_topic       ('TestZentrumFuerSammlerUndJaeger');

my $topic_content = $client->read_topic;
print STDERR "$topic_content\n";
my $success = 0;
$success = $client->save_topic ($topic_content . "\n\n*The TWikiClient bot was here.*\n\n") if $topic_content;
if ($success) {
  print "OK\n";
} else {
  print "NOT OK\n";
}

__END__

=head1 NAME

append_to_twiki_topic.pl - Append an "I was here" graffiti to a twiki
topic.

=head1 SYNOPSIS

 perl append_to_twiki_topic.pl

=head1 DESCRIPTION

Example script that demonstrates the usage
L<WWW::TWikiClient|WWW::TWikiClient>.

=head1 AUTHOR

Steffen Schwigon <schwigon@cpan.org>

=head1 LICENSE

 Copyright (c) 2006. Steffen Schwigon
 All rights reserved. You can redistribute and/or modify
 this bundle under the same terms as Perl itself.
