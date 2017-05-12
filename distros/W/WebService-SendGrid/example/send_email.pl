#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use JSON::XS;
use Perl6::Slurp;

my $list = '/Users/jlloyd/Backup/Constant Contact/Contacts.csv';
my $html = slurp '/Users/jlloyd/Desktop/email/email.html';

use SendGrid::Mail;
use Data::Validate::Email qw(is_email is_email_rfc822);

my @rows;
use Text::CSV_XS;
my $csv = Text::CSV_XS->new ({ binary => 1 }) or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
open my $fh, "<:encoding(utf8)", $list or die "$list: $!";
while (my $row = $csv->getline ($fh)) {
  if (is_email($row->[0])) {
    push @rows, $row->[0]
  }
  else {
    print "Invalid email : " . $row->[0] . "\n";
  }
}
$csv->eof or $csv->error_diag ();
close $fh;

my $data;
$data->{category} = 'An Evening With Musicals - 09/25/11';
$data->{filters}{subscriptiontrack}{settings}{enable} = 1;
$data->{filters}{subscriptiontrack}{settings}{'text/html'} =
  '<p>If you&#39;d like to unsubscribe and stop receiving these emails <% click here %>.</p>';

my $count = 0;
my $total = scalar @rows;
for my $email (@rows) {

  $count++;
  print "($count/$total) Sending email to $email\n";

  my $mail = SendGrid::Mail->new(
    to => $email,
    from => 'info@thetribeproductions.org',
    'x-smtpapi' => encode_json $data,
    subject => 'Spend "An Evening With Musicals" to Benefit theTRIBE\'s 2012 Season!',
    #text => 'This is a test message',
    html => $html
  );

  $mail->send;

}
