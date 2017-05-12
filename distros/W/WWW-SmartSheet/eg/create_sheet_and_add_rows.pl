#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use WWW::SmartSheet;
use IO::Prompt qw(prompt);
use List::Util qw(min);
use Data::Dumper qw(Dumper);

my $token   = prompt "Enter Smartsheet API access token: ";
my $w = WWW::SmartSheet->new(token => $token);

my $sheet_name = 'test_' . time;
my $s = $w->create_sheet(
    name    => $sheet_name,
	columns =>  [
        { title => "First Col",  type => 'TEXT_NUMBER', primary => JSON::true },
    	{ title => "Second Col", type => 'CONTACT_LIST' },
        { title => 'Third Col',  type => 'TEXT_NUMBER' },
        { title => "Fourth Col", type => 'CHECKBOX', symbol => 'FLAG' },
        { title => 'Status',     type => 'PICKLIST', options => ['Started', 'Finished' , 'Delivered'] }
	],
);
print Dumper $s;

my $c = $w->add_column($s->{result}{id}, { title => 'Delivered', type => 'DATE', index => 5 });

print Dumper $c;



