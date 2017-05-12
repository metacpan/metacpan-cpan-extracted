=pod

This sample reads an RSS file off of the internet using LWP,
and feeds it to XML::RAX.  The sample then uses a loop to
iterate through the news articles.

=cut

use XML::RAX;
use LWP::Simple;
use Text::Wrap qw(wrap $columns);

$columns = 60;
my $R = new XML::RAX();

$R->open( get('http://www.webreference.com/webreference.rdf') );
$R->setRecord('item');

my $rec = $R->readRecord();

while ( $rec )
	{
	print "============================================================\n";
	print $rec->getField('title')."\n";
	print "============================================================\n";
	print wrap( "   ", "", $rec->getField('description') );
	print "\n";
	print "(".$rec->getField('link').")\n\n";
	
	$rec = $R->readRecord();
	
	if ( $rec )
		{
		print "[ hit ENTER for next article ]";
		my $a = <STDIN>;
		print "\n";
		}
	}

