#!/usr/local/bin/perl -w
use strict;
use lib '../.', 
	'/Homes/xpix/projekts/Tk-Moduls';

use Tk;
use Tk::ItemStyle;
use Tk::DBIx::Table;
use DBI;

my $host = shift || &use_this_so;
my $db   = shift || &use_this_so;
my $user = shift || &use_this_so;
my $pass = shift || &use_this_so;
my $sql  = shift || &use_this_so;

# DB Handle
my $dbh = DBI->connect(	
	"DBI:mysql:database=${db};host=${host}", 
	$user, $pass)
		or die ("Can't connect to database:", $! );

my $top = MainWindow->new;

# formatting definitions
my %Styles = (
	'selected_head'		=> [ -background => '#fff7E5' 	],
	'unselected_head'	=> [ -background => '#ffffff' 	],
	'sorted_column'		=> [ -background => '#fff7E5' 	],
);
my %SStyles;
foreach my $state (keys %Styles) {
	$SStyles{$state} = $top->ItemStyle('text', @{$Styles{$state}});
}
# ------------

my $tkdbi = $top->DBITable(
		-sql		=> $sql,
		-dbh   		=> $dbh,
		-debug  	=> 1,
		-display_id	=> 0,
		-srtColumnStyle => $SStyles{'sorted_column'},
		-maxchars	=> 25,
		)->pack(expand => 1, -fill => 'both');

$tkdbi->Subwidget('table')->configure(
	-command => sub{ printf "This is id: %s\n", $_[0] },
);

my $entrytext = '$tkdbi->sql(\'select * from Inventory limit 10\')';
my $entry = $top->Entry(
		-text => \$entrytext,
)->pack(-side => 'left', -expand => 1, -fill => 'x');

my $button = $top->Button(
		-text => 'Go!',
		-command => sub{
			eval($entrytext);
			print $@ if($@);
		},
)->pack(-side => 'left');

$top->bind('<Escape>', sub{ $dbh->disconnect; exit });
MainLoop;


sub use_this_so {
	print "\nplease use $0 host db user password 'select * from table'\n";
	exit;
}
