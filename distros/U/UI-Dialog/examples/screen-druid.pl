#!/usr/bin/env perl
use strict;
use warnings;
use diagnostics;
use constant { TRUE => 1, FALSE => 0 };

use lib qw(./lib);
use UI::Dialog::Screen::Druid;

#
#: Demonstrate usage of UI::Dialog::Screen::Druid
#

my $druid = new UI::Dialog::Screen::Druid();
$druid->add_yesno_step("yesnotag","Hello world?");
$druid->add_input_step
  ( "inputtag",
    "What's an alternative to the Hello World phrase?"
  );
$druid->add_input_step
  ( "inputtag2",
    "If you were to write a book, what would you name it?",
    "{{inputtag}}, done the right way!"
  );
$druid->add_password_step
  ( "passwordtag",
    "Tell me your secret..."
  );
$druid->add_menu_step
  ( "menutag",
    "Example scripts are...",
    [ "Boring", "Useful", "Necessary Evil",
      "A step towards proper QA/UAT?"
    ]
  );
my (%answers) = $druid->perform();
if ($answers{aborted}) {
  die "User left the druid performance at step: ".$answers{key}."\n";
}
use Data::Dumper;
print "Answers received:\n";
print Dumper(\%answers)."\n";

exit 0;
