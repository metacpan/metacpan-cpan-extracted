#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

# demo helper
sub printerr { print STDERR "\n".'UI::Dialog : '.join( " ", @_ )."\n"; sleep(1); }

use UI::Dialog::Backend::CDialog;
my $d = new UI::Dialog::Backend::CDialog
  ( title => "CDialog Demo",
    height => 16, width => 65,
    listheight => 5,
    debug => 1,
    test_mode => 0,
  );

# placeholder variable
our $text;

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
  q{This is a question widget. There should be "YES" and "NO" buttons below this text message. The title of this message box should be "$d->yesno()".};
my $is_yes = $d->yesno( title => '$d->yesno()', text => $text );
if ($d->state() eq "OK" && $is_yes) {
    printerr("The user has answered YES to the yesno widget.");
} else {
    printerr("The user has answered NO or pressed ESC to the yesno widget.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is an infobox widget. There should be no buttons below this message, and the title of this info box should be "$d->infobox()". This will stop blocking after 3 seconds.};
$d->infobox( timeout => 3000, title => '$d->infobox()', text => $text);
if ($d->state() eq "OK") {
  printerr("The user waited the 3 seconds.");
} else {
  printerr("The user pressed ESC or CTRL+C.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a progress indicator. You should see a bar line filling up with intervals of 20 percent.};
$d->gauge_start( title => '$d->gauge_start()', text => $text );
foreach my $i (20,40,60,80,100) {
    last unless $d->gauge_set($i);
    sleep(1);
}
$d->gauge_stop();

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a text input box. The field below should be pre-populated with the words "preset text entry".};
my $user_input = $d->inputbox
  ( title => '$d->inputbox()', text => $text, entry => 'preset text entry' );
if ($d->state() eq "OK") {
    printerr( "You input: ".($user_input||'NULL') );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a password input box. The field below should be pre-populated with the words "insecure password entry" but displayed as asterisks for each character. Providing "entry" text to a password field is inherently insecure. Without the insecure asterisks behavior, users may enter their password without realizing it's appending to the existing "entry" text and never be able to type in the actually stored password.};
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
  q{This is another password input box. Because no "entry" text was given, but the insecure option was specified; the password will be displayed as asterisks for each character and the field below should be empty to begin with.};
$password = $d->password
  ( title => '$d->password()',
    text => $text,
    insecure => 1
  );
if ($d->state() eq "OK") {
  printerr( "You input: ".($password||'NULL'));
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is yet another password input box. Because no "entry" text was given, and the insecure option was not specified; the text entered will not be displayed visually at all. This is the best way to use the password dialog. No "entry" text and without the insecure option.};
$password = $d->password
  ( title => '$d->password()',
    text => $text,
  );
if ($d->state() eq "OK") {
  printerr( "You input: ".($password||'NULL'));
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
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
  q{This is a menu. The title should be "$d->menu()" and there should be two items in the list. "Test" with the label "testing" and "CD" with the label "CDialog".};
my $menuSelect = $d->menu
  ( title => '$d->menu()',
    text => $text,
    list =>
    [ 'Test', 'testing',
      'CD', 'CDialog'
    ]
  );
if ($d->state() eq "OK") {
    printerr( "You selected: '".($menuSelect||'NULL')."'\n");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a checklist. The title should be "$d->checklist()" and there should be two items in thbe list. "Test" with the label "testing" (already selected) and "CD" with the label "CDialog" (not selected).};
my @checkSelect = $d->checklist
  ( title => '$d->checklist()',
    text => $text,
    list =>
    [ 'Test', [ 'testing', 1 ],
      'CD', [ 'CDialog', '0' ]
    ]
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".(join("' '",@checkSelect))."'");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a radiolist. The title should be "$d->radiolist()" and there should be two items in thbe list. "Test" with the label "testing" (not selected) and "CD" with the label "CDialog" (already selected).};
my $radioSelect = $d->radiolist
  ( title => '$d->radiolist()',
    text => $text,
    list =>
    [ 'test',[ 'testing', 0 ],
      'CD', [ 'CDialog', 1 ]
    ]
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".$radioSelect."'");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{The next screen is a directory selection widget. The title should be "$d->dselect()" and the starting path should be the current working directory. Should only let you select directories and not files.};
$d->msgbox(text=>$text);
my $dirname = $d->dselect
  ( title => '$d->dselect()',
    height => 10,
    path => $ENV{'PWD'},
  );
if ($d->state() eq "OK") {
  printerr( "You selected: '".$dirname."'");
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
$d->tailbox
  ( title => '$d->tailbox()',
    filename => $0
  );
if ($d->state() eq "OK") {
  printerr("The user pressed EXIT.");
} else {
  printerr("The user pressed CTRL+C or ESC instead of EXIT.");
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a timebox. The title should be "$d->timebox()" and the current time should be displayed.};
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
my $timeSelect = $d->timebox
  ( title => '$d->timebox()',
    text => $text,
    height => 5,
    second => $sec, minute => $min, hour => $hour
  );
my @time = $d->ra();
if ($d->state() eq "OK") {
  printerr("You selected: '".($timeSelect||'NULL')."' or rather: ".$time[0]." hour, ".$time[1]." minute, ".$time[2]." second.");
} else {
  printerr("The user pressed CTRL+C or ESC instead of OK.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$mon += 1;
$year += 1900;
$text = q{This is a calendar widget. The title should be "$d->calendar()" and the current date should be selected.};
my $dateSelect = $d->calendar
  ( title => '$d->calendar()',
    text => $text,
    day => $mday, month => $mon, year => $year
  );
my @date = $d->ra();
if ($d->state() eq "OK") {
  printerr("You selected: '".($dateSelect||'NULL')."' or rather: ".$date[0]." day, ".$date[1]." month, ".$date[2]." year.");
} else {
  printerr("You pressed ESC or CTRL+c.");
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$text =
  q{This is a form. The title should be "$d->form()". There should be two entries in the form. "Test" with the text of "testing" and "CD" with the text of "CDialog". Both text fields are editable.};
my @formSelection = $d->form
  ( title => '$d->form()',
    text => $text,
    list =>
    [ [ 'Test', 1, 1 ], [ 'testing', 1, 10, 10, 10 ],
      [ 'CD', 2, 1 ], [ 'CDialog', 2, 10, 10, 10 ],
    ]
  );
if ($d->state() eq "OK") {
  printerr("The user supplied ".@formSelection." bits of text: ".join(", ",@formSelection));
} else {
  printerr("The user pressed CTRL+C or ESC instead of EXIT.");
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
exit();
