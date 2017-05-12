#!/usr/local/bin/perl

# NOTE! I think this doesn't work anymore because of some google javascript
# funny business :(

use strict;
use WWW::HtmlUnit;

# Put in your username and password, and then pass this script an .ics file.
# It'll upload it into your default google calendar

my $google_username = 'XXXXXXX';
my $google_password = 'XXXXXXX';

sub wait_for(&@) {
  my ($subref, $timeout) = @_;
  $timeout ||= 30;
  while($timeout) {
    return if eval { $subref->() };
    sleep 1;
    $timeout--;
  }
  die "Timeout!\n";
}

my $ics_filename = shift @ARGV;
if($ics_filename !~ /\.ics$/i) {
  print "Expected: google_calendar_upload.pl <filename.ics>\n";
  exit;
}

eval {
my $webClient = WWW::HtmlUnit->new('FIREFOX_3');
my $page = $webClient->getPage("http://google.com/calendar/");

my $login_form = $page->getElementById('gaia_loginform');
my $email = $login_form->getInputByName('Email');
my $passwd = $login_form->getInputByName('Passwd');
my $sign_in_button = $login_form->getInputByName('signIn');

$email->type($google_username);
$passwd->type($google_password);
$page = $sign_in_button->click;

wait_for { $page->getElementById('add_cals_link') };

$page->getElementById('add_cals_link')->click;

wait_for { $page->getElementById('addP') };

$page->getElementById('addP')->getLastChild->click;

wait_for { defined $page->getFrames->toArray->[1] };

my $p3 = $page->getFrames->toArray->[1]->getEnclosedPage;
my $f = $p3->getForms->toArray->[0];
# Had issues with the path of the form action
$f->setActionAttribute("http://www.google.com/calendar/" . $f->getActionAttribute);
my $filename = $f->getInputByName('filename');
$filename->setValueAttribute($ics_filename);
my $import_button = $p3->getByXPath('//*[@value="Import"]')->toArray->[0];
my $p4 = $import_button->click;
print $p4->asText;
print "\n";

};

if($@ && ref($@) =~ /Exception/) {
  print "Exception: " . $@->getMessage . "\n";
} elsif($@) {
  print "Err... $@\n";
}



