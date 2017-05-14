#!/usr/local/bin/perl -w
use strict;
use lib '../.', 
	'/Homes/xpix/projekts/Tk-Moduls';

use Tk;
use Tk::DBIx::Tree;
use DBI;
use Data::Dumper;
use IO::File;

my $host = shift || &use_this_so;
my $db   = shift || &use_this_so;
my $user = shift || &use_this_so;
my $pass = shift || &use_this_so;

# DB Handle
my $dbh = DBI->connect(	
	"DBI:mysql:database=${db};host=${host}", 
	$user, $pass)
		or die ("Can't connect to database:", $! );

END{
	if(defined $dbh) {
		$dbh->do('DROP TABLE food');
		$dbh->disconnect; 
	}
}

while(<DATA>)
{
   $dbh->do($_)
   	if($_);
}

my $top = MainWindow->new;


my $tkdbi = $top->DBITree(
                        -dbh            => $dbh,
                        -table          => 'food',
                        -textcolumn     => 'food',
                        -idx            => 'food_id',
                        -fields         => [qw(descript)],
                        -parent_id      => 'parent_id',
                        -start_id       => 1,
                )->pack(
                        -expand => 1,
                        -fill => 'both'
		);
$tkdbi->refresh();
my $entrytext = '$tkdbi->select_entrys([qw/3 4 5 6/])';
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
$tkdbi->Subwidget('tree')->configure(
	-command => sub{ printf "This is id: %s\n", $_[0] },
);

$top->bind('<Escape>', sub{ 
		exit 
	}
);
MainLoop;


sub use_this_so {
	print "\nplease use $0 host db user password\n";
	exit;
}

__DATA__
CREATE TABLE food ( food char (25), food_id char (3), parent_id char (3) NULL, descript char (128)) 
DELETE FROM food
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Food', '001', NULL, 'The stuff you eat.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Beans and Nuts', '002', '001', 'These are a protein rich variety of food.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Beans', '003', '002', 'Beans have many great properties. When served with rice, they often can supply a complete protein.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Nuts', '004', '002', 'Nuts are chewey and fattening.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Black Beans', '005', '003', 'A small, black bean. It is used in Chinese, Mexican, and Southwestern cooking.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Pecans', '006', '004', 'Pecans are yummy nuts.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Kidney Beans', '007', '003', 'A medium sized bean. It is used in Mexican, Cuban, Dominican and lots of other cooking styles.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Red Kidney Beans', '008', '007', 'A red variety of kidney beans.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Black Kidney Beans', '009', '007', 'A black variety of kidney beans.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Dairy', '010', '001', 'Food that comes from cows.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Beverages', '011', '010', 'Things you can drink.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Whole Milk', '012', '011', 'High in fat and protein, this is the milk without the cream removed.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Skim Milk', '013', '011', 'Low in fat, high in protein, this milk has had the cream removed.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Cheeses', '014', '010', 'Dairy products made by allowing milk and enzymes to culture.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Cheddar', '015', '014', 'A hard, mild to sharp cheese. Good with apples.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Stilton', '016', '014', 'A hard cheese with blue veins. I hate it.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Swiss', '017', '014', 'A mild, tangy hard cheese.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Gouda', '018', '014', 'A creamy, sweet cheese. I love it.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Muenster', '019', '014', 'A creamy cheese, often used in sandwiches.')
INSERT INTO food (food, food_id, parent_id, descript) VALUES ('Coffee Milk', '020', '011', 'Usually made with skim milk, this is a delicacy among Rhode Islanders.')