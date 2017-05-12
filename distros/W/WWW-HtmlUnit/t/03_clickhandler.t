#!/usr/bin/perl

use Test::More tests => 8;
use Data::Dumper;

use WWW::HtmlUnit;

my $webClient = WWW::HtmlUnit->new;

my $confirm = WWW::HtmlUnit::com::gargoylesoftware::htmlunit::ClickConfirmHandler->new(1);
isa_ok $confirm,
  'WWW::HtmlUnit::com::gargoylesoftware::htmlunit::ClickConfirmHandler',
  'ClickConfirmHandler created';
$webClient->setConfirmHandler($confirm);

my $alert_handler = WWW::HtmlUnit::com::gargoylesoftware::htmlunit::CollectingAlertHandler->new();
isa_ok $alert_handler,
  'WWW::HtmlUnit::com::gargoylesoftware::htmlunit::CollectingAlertHandler',
  'CollectingAlertHandler created';
$webClient->setAlertHandler($alert_handler);

my $page = $webClient->getPage("file:t/03_clickhandler.html");

# Check to see if the onload alert was triggered
is $alert_handler->getCollectedAlerts->toArray->[0], 'load alert', 'Got onload alert';

# For the confirm callback, first we'll try OK, which is the default
$page->getElementById('submit')->click();
is $confirm->getCollectedConfirms->toArray->[0], 'clicked', 'Clicked confirm';
like $page->getElementById('content')->asXml,
  qr/I am confirmed/,
  'Callback did confirm';

# Then we'll try Cancel
$confirm->make_click_cancel();
$page->getElementById('submit')->click();
is $confirm->getCollectedConfirms->toArray->[0], 'clicked', 'Clicked confirm';
like $page->getElementById('content')->asXml,
  qr/I was denied/,
  'Callback did deny';

is $confirm->get_last_confirm_msg(), 'clicked', 'Last message was "clicked"';

