#!/usr/bin/perl -w

use strict;
use warnings;
use WWW::CheckPad;
use WWW::CheckPad::CheckList;
use WWW::CheckPad::CheckItem;


## Connec to check*pad server and login.
my $connection = WWW::CheckPad->connect(
    email => $ARGV[0],
    password => $ARGV[1],
);

print "LOGIN FAILED\n" if not $connection->has_logged_in();

 foreach my $checklist (WWW::CheckPad::CheckList->retrieve_all) {
     foreach my $checkitem ($checklist->checkitems) {
         if ($checkitem->is_finished()) {
             my ($year, $month, $date) =
                 (localtime($checkitem->finished_time()))[5, 4, 3];
             printf " * [%s] %s (%s)\n", $checklist->title, $checkitem->title,
                 sprintf("%s/%s/%s", $year+1900, $month+1, $date);
         }
         else {
             printf "   [%s] %s\n", $checklist->title, $checkitem->title;
         }
     }
     return;
 }
return;


## Add new checklist.
my $new_checklist = WWW::CheckPad::CheckList->insert({
    title => 'New Check List'
});

## Add several checkitems.
my $new_checkitem1 = $new_checklist->add_checkitem('My new todo item 1.');
my $new_checkitem2 = $new_checklist->add_checkitem('My new todo item 2.');
my $new_checkitem3 = $new_checklist->add_checkitem('My new todo item 3.');
my $new_checkitem4 = $new_checklist->add_checkitem('My new todo item 4.');
my $new_checkitem5 = $new_checklist->add_checkitem('My new todo item 5.');


foreach my $checkitem ($new_checklist->checkitems()) {
    printf "[%s] %s\n", $new_checklist->title, $checkitem->title;
}

## Delete all checkitems.
$new_checkitem3->delete();
$new_checkitem1->delete();
$new_checkitem5->delete();
$new_checkitem2->delete();
$new_checkitem4->delete();


## new_checklist shouldn't have any checkitem by now.
printf "now checklist has %d items\n", scalar @{$new_checklist->checkitems()};

$new_checklist->delete();

WWW::CheckPad->disconnect();
