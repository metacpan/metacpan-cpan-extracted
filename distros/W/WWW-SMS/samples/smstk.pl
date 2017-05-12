#!/usr/bin/perl

#
# Copyright (c) 2001 Giulio Motta. All rights reserved.
# http://www-sms.sourceforge.net/
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

######################################################################
### This is a simple Tk front-end to easily send SMSs and have a   ###
### personal phonebook too. I know it's really crap written, but   ###
### it's anyway a good point to start coding your own applications ###
######################################################################

use Tk;
use WWW::SMS;

open(IN, "< phonebook.txt");
while (<IN>) {
	chomp;
	push @phonebook, [split /\|/];
}
close(IN);

my @gateways = WWW::SMS->gateways();

my %maxlengths;

for my $gate (@gateways) {
	eval 'use WWW::SMS::' . $gate ;
	$maxlengths{$gate} = &{'WWW::SMS::' . $gate . '::MAXLENGTH'};
}

my $maxlength = $maxlengths{$gateways[0]};

$main = MainWindow->new();

$main->configure(-title => 'SMS Sender');

$frmlf = $main->Frame()->pack(-side => 'left', -fill => 'y');
$frmrg = $main->Frame()->pack(-side => 'right', -fill => 'y');

$frmlft = $frmlf->Frame()->pack( -fill=> 'x');
$frmlfb = $frmlf->Frame()->pack(-fill=> 'x');

$frmlfl = $frmlft->Frame()->pack(-side => 'left', -fill=> 'y');
$frmlfr = $frmlft->Frame()->pack(-side => 'right', -fill=> 'y');

$namelabel = $frmlfl->Label(-text => 'Name')->pack();
$intlabel = $frmlfl->Label(-text => 'Int. Prefix')->pack();
$preflabel = $frmlfl->Label(-text => 'Prefix')->pack();
$numlabel = $frmlfl->Label(-text => 'Number')->pack();

$nametext = $frmlfr->Entry(-width => '10', -background => 'white',
						 -textvariable => \$name)->pack();
$inttext = $frmlfr->Entry(-width => '10', -background => 'white',
						 -textvariable => \$intpref)->pack();
$preftext = $frmlfr->Entry(-width => '10', -background => 'white',
						 -textvariable => \$pref)->pack();
$numtext = $frmlfr->Entry(-width => '10', -background => 'white',
						 -textvariable => \$num)->pack();

$msglabel = $frmlfb->Label(-text => "Short Message")->pack(-side => 'top');
$msgtext = $frmlfb->Text(-height => '3', -width => '40', -background => 'white')->pack();

$msgtext->bind('<KeyPress>' => \&count_chars);

$sendButton = $frmlfb->Button(-text => "Send SMS", -command => \&send_sms)->pack( -fill => 'x');

my $opt = $frmlfb->Optionmenu(
                -options => [@gateways],
				-command => sub {
								my $temp = shift;
								$maxlength = $maxlengths{$temp};
								},
                -variable => \$gateway,
                )->pack;

my $error_msg;
my $errortext = $frmlfb->Entry(-width => '40', -background => 'white',
						 -textvariable => \$error_msg)->pack();

$listFrame = $frmrg->Frame()->pack(-side => 'top');
$list = $listFrame->Listbox(-background => 'white')->pack(-side => 'left',
							-fill => 'both', -expand => 'yes');
$listScroll = $listFrame->Scrollbar(-command => ['yview', $list])->pack(-side => 'right',
								 -fill => 'y');
$list->configure(-yscrollcommand => ['set', $listScroll]);
for ($i = 0; $i <= $#phonebook; $i++) {
	$list->insert($i, $phonebook[$i][0]);
}
$list->bind('<ButtonPress>' => \&update_texts);


$addButton = $frmrg->Button(-text => "Add", -command => \&add_user)->pack( -fill => 'x');
$removeButton = $frmrg->Button(-text => "Remove", -command => \&remove_user)->pack( -fill => 'x');
$newButton = $frmrg->Button(-text => "New", -command => \&clear_fields)->pack( -fill => 'x');

###MAINLOOP###
MainLoop;
###MAINLOOP###

open(OUT, "> phonebook.txt");
for ($i =0; $i <= $#phonebook; $i++) {
	print OUT join ('|', @{$phonebook[$i]})."\n";
}
close(OUT);

###ENDMAIN###

sub add_user {
	if (($nametext->get) && ($inttext->get) && ($preftext->get) && ($numtext->get)) {
		push @phonebook, [$nametext->get,$inttext->get,$preftext->get,$numtext->get];
		$list->insert(end, $nametext->get);
	}
}

sub update_texts {
	($name, $intpref, $pref, $num) = @{ $phonebook[$list->curselection] };
}

sub remove_user {
	for ($list->curselection) {
		splice @phonebook, $_, 1;
		$list->delete($_);
		&clear_fields;
	}
}

sub clear_fields {
	($name, $intpref, $pref, $num) = ('', '', '', '');
}

sub count_chars {
	if (length($msgtext->get("1.0", end)) > $maxlength) {
		$smstext = $msgtext->get("1.0", end);
		$msgtext->delete("1.0", end);
		$msgtext->insert("1.0", substr($smstext,0, $maxlength - 1));
	}
}

sub send_sms {

	my $sms = WWW::SMS->new(
			$inttext->get,
			$preftext->get,
			$numtext->get,
			$msgtext->get("1.0", end)
		);

	if ($sms->send($gateway)) {
		$error_msg = 'Message sent!';
	} else {
		$error_msg = "Error: $WWW::SMS::Error";
	}
}
