#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use WWW::SmartSheet;
use IO::Prompt qw(prompt);
use List::Util qw(min);

my $token   = prompt "Enter Smartsheet API access token: ";
my $w = WWW::SmartSheet->new(token => $token);

my $all_sheets = $w->get_sheets;
if (not @$all_sheets) {
    say "You don't have any sheets. Goodbye!";
	exit;
}

my $N = min(5, scalar @$all_sheets);
say "Total sheets:" . scalar @$all_sheets;
say "Showing the first $N sheets...";
for my $i (1 .. $N) {
	say "$i: $all_sheets->[$i-1]{name}   access level: $all_sheets->[$i-1]{accessLevel}";
} 


prompt('Select sheet number');

use Data::Dumper qw(Dumper);
#print Dumper $all_sheets;
my $columns = $w->get_columns(0); # sheet number
print Dumper $columns;


#my $sheet_number = prompt("Enter the number of the sheet you want to share:");
#my $sheet_name  = $all_sheets->[$sheet_number-1]{name};
#my $sheet_id    = $all_sheets->[$sheet_number-1]{id};

#shareURL = API_URL +'/sheet/' + str(sheet_id) + '/shares?sendEmail=true' #URL used to share a sheet


