#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Time::HiRes qw(usleep);

# demo helper
sub printerr { print STDERR "\n".'UI::Dialog : '.join( " ", @_ )."\n"; sleep(1); }

use UI::Dialog::Backend::KDialog;
my $d = new UI::Dialog::Backend::KDialog
  ( title => "KDialog  Demo",
    height => 16, width => 65,
    listheight => 5,
    debug => 1,
    test_mode => 0,
  );

# placeholder variable
our $text;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a "yesno" question widget. There should be "YES" and "NO" buttons below this text message. The title of this message box should be "$d->yesno()".};
my $is_yes = $d->yesno( title => '$d->yesno()', text => $text );
if ($d->state() eq "OK" && $is_yes) {
  printerr("The user has answered YES to the yesno widget.");
} else {
  printerr("The user has answered NO or pressed ESC to the yesno widget.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a "yesnocancel" question widget. There should be "YES", "NO" and "CANCEL" buttons below this text message. The title of this message box should be "$d->yesno()".};
$is_yes = $d->yesnocancel( title => '$d->yesnocancel()', text => $text );
if ($d->state() eq "OK" && $is_yes) {
  printerr("The user has answered YES to the yesnocancel widget.");
} else {
  printerr("The user has answered NO or pressed ESC to the yesnocancel widget.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a "warningyesno" question widget. There should be "YES" and "NO" buttons below this text message and a warning icon to the left. The title of this message box should be "$d->warningyesno()".};
$is_yes = $d->warningyesno( title => '$d->warningyesno()', text => $text );
if ($d->state() eq "OK" && $is_yes) {
  printerr("The user has answered YES to the warningyesno widget.");
} else {
  printerr("The user has answered NO or pressed ESC to the warningyesno widget.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a "warningyesnocancel" question widget. There should be "YES", "NO" and "CANCEL" buttons below this text message and a warning icon to the left. The title of this message box should be "$d->warningyesnocancel()".};
$is_yes = $d->warningyesnocancel
  ( title => '$d->warningyesnocancel()',
    text => $text
  );
if ($d->state() eq "OK" && $is_yes) {
  printerr("The user has answered YES to the warningyesnocancel widget.");
} else {
  printerr("The user has answered NO or pressed ESC to the warningyesnocancel widget.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is the msgbox widget. There should be a single "OK" button below this text message and the title of this message box should be "msgbox".};
$d->msgbox( title => 'msgbox', text =>  $text );
if ($d->state() eq "OK") {
  printerr("The user pressed OK.");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is an infobox widget. There should be a single "OK" button below this text message and the title of this message box should be "$d->infobox()". Unlike other implementations, this infobox does not pause for any time and is essentially a messagebox at heart.};
$d->infobox( timeout => 3000, title => '$d->infobox()', text => $text);
if ($d->state() eq "OK") {
  printerr("The user pressed OK.");
} else {
  printerr("The user pressed ESC or CTRL+C.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a password input box. The field below should be pre-populated with the words "insecure password entry" but displayed as asterisks for each character. Providing "entry" text to a password field is inherently insecure.};
my $password = $d->password
  ( title => '$d->password()',
    text => $text,
    entry => 'insecure password entry',
  );
if ($d->state() eq "OK") {
  printerr( "You input: ".($password||'NULL'));
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a text input box. The field below should be pre-populated with the words "preset text entry".};
my $user_input = $d->inputbox
  ( title => '$d->inputbox()', text => $text, entry => 'preset text entry' );
if ($d->state() eq "OK") {
  printerr( "You input: ".($user_input||'NULL') );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$d->textbox( title => '$d->textbox()', path => $0 );
if ($d->state() eq "OK") {
  printerr("The user pressed EXIT.");
} else {
  printerr("The user pressed CTRL+C or ESC instead of EXIT.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This text is in the second column of the first row of a menu list dialog. The title should be "$d->menu()" and there should be two items in the list. "Test" with the label "testing" and "WT" with the label "Whiptail".};
my $menuSelect = $d->menu
  ( title => '$d->menu()',
    text => $text,
    list =>
    [ 'Test', 'testing',
      'WT', 'Whiptail'
    ]
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".($menuSelect||'NULL')."'\n");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This text is in the third column of the first row of a checklist dialog. The title should be "$d->checklist()" and there should be two items in the list. "Test" with the label "testing" (already selected) and "WT" with the label "Whiptail" (not selected).};
my @checkSelect = $d->checklist
  ( title => '$d->checklist()',
    text => $text,
    list =>
    [ 'Test', [ 'testing', 1 ],
      'WT', [ 'Whiptail', '0' ]
    ]
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".(join("' '",@checkSelect))."'");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This text is in the third column of the first row of a radiolist dialog. The title should be "$d->radiolist()" and there should be two items in thbe list. "Test" with the label "testing" (not selected) and "WT" with the label "Whiptail" (already selected).};
my $radioSelect = $d->radiolist
  ( title => '$d->radiolist()',
    text => $text,
    list =>
    [ 'test',[ 'testing', 0 ],
      'WT', [ 'Whiptail', 1 ]
    ]
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".$radioSelect."'");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{The next screen is a file selection widget. The title should be "$d->fselect()" and the starting path should be this script file. Should only let you select files and not directories.};
$d->msgbox(text=>$text);
my $filename = $d->fselect
  ( title => '$d->fselect()',
    height => 10,
    path => $0,
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".$filename."'");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{The next screen is a path selection widget. The title should be "$d->dselect()" and the starting path should be this script file. Should not let you select files, only directories.};
$d->msgbox(text=>$text);
my $dirname = $d->dselect
  ( title => '$d->dselect()',
    height => 10,
    path => $0,
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".$dirname."'");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
exit();
