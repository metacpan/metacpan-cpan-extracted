#Test progamme for GridEntry using a database table
#This is a sample programme for fetching and updating rows from a 
# table.
#The table 'item' has structure
# itemno int,itemdesc char(30),itemunit char(7), itemrate float
# The data fetched and displayed. The itemrate can be edited and updated.

use Tk;
use strict;
use DBI;
use Tk::GridEntry;

#DBI parameters
my $hostname=`hostname`;
my $dsn="DBI:mysql:dbname:$hostname"; #put connection parameters here
my $username="";   #put user name here
my $password=""; # put Password here. Remember to clear it.
my $dbh=DBI->connect($dsn,$username,$password);
die "could not connect " if (! $dbh);

#Create the structure
my $itemrec= {  
 		columns=>["itemno","itemdesc","itemunit","itemrate"],
		itemno =>{ 
			'widgettype'=>'Entry',
			'label'=>'CODE',
			'col'=>'0',
			-width=>'6',
			-state=>'disabled'
			},
		itemdesc =>{ 
			'widgettype'=>'Entry',
			'label'=>'Desc',
			'col'=>'1',
			-width=>'30',
			-state=>'disabled'
			},
		itemunit =>{ 
			'widgettype'=>'Entry',
			'label'=>'Unit',
			'col'=>'2',
			-width=>'7',
			-state=>'disabled'
			},
		itemrate =>{ 
			'widgettype'=>'Entry',
			'label'=>'SP',
			'col'=>'3',
			-width=>'7'
			}
		};

#Define a hash for storing records
my $datahash={};

#create main window
my $mw=MainWindow->new();

my $fetch=$mw->Button( -text=>'Fetch Data',
			-command=>\&getItems
			)->pack();


my $itemrecW=$mw->GridEntry(-structure=>$itemrec, 
			-rows=>10,
			-datahash=>$datahash,
			-extend=>0,
			-scroll=>'1'
			)->pack();

my $ub=$mw->Button(-text=>'Update Data',
			-command=>\&saveItems
			)->pack();
my $cb=$mw->Button(-text=>'Clear Data',
			-command=>\&clearItems
			)->pack();


#Sub to get data from database
sub getItems
{
#Now let us run sql to get data
	my $query="select itemno,itemdesc,itemunit,itemrate ";
	$query.=sprintf "from item ";
	$query.=sprintf " order by  itemno ";
	my $sth=$dbh->prepare($query);
	$sth->execute();
#First let us clear data hash of any old contents
my $key;
foreach $key (keys (%{$datahash})) {delete $datahash->{$key};}

my $hashref;
#read data using hashref.

	while($hashref=$sth->fetchrow_hashref()) {
	
		foreach $key (keys (%{$hashref})){
		 push @{$datahash->{$key}},$hashref->{$key}; 
		}
	}
#set page index to start
$itemrecW->configure(-pageindex=>0);
$itemrecW->moverectoscreen();
$itemrecW->update();
}


#sub to save details in database table

sub saveItems
{
my ($query);
		#go into loop read each record
	for (my $i=0;$i<=scalar(@{$datahash->{itemno}});$i++)
		{
				$query="update item ";
				$query.=sprintf " set itemrate= %11.2f",$datahash->{itemrate}[$i];
				$query.=sprintf " where itemno=%d",$datahash->{itemno}[$i];
				$dbh->do($query);
	
		}
}

#sub to clear data from screen and datahash
#first move null to screen. Then delete contents of datahash.

sub clearItems{
$itemrecW->movenulltoscreen();
$itemrecW->update();
for my $key(keys %{$datahash}){
	delete $datahash->{$key};
	}
}
MainLoop;
