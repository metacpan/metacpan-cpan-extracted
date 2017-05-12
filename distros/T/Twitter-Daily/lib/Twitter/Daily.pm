package Twitter::Daily;

use strict;
use warnings;

use Net::Twitter;
use File::MkTemp;
use HTTP::Date 'parse_date';
	
our $VERSION="0.1.3";
our @EXPORT = qw(new);

use constant PASS => 1;
use constant FAIL => 0;

use constant ERR_NO_ERROR => "";
use constant ERR_NO_ERROR_NUM => 0;
use constant ERR_PUBLISH => 3;
use constant ERR_PUBLISH_MSG =>"Can't publish entry : ";
use constant ERR_TW_TIMELINE => 4;
use constant ERR_TW_TIMELINE_MSG =>"Can't retrieve Twitter timeline";
use constant ERR_TEMP_FILE => 5;
use constant ERR_TEMP_FILE_MSG =>"Can't save entry to temporary file";

use constant NEWLINE => "\n";


=pod

=head1 NAME

Twitter::Daily - Publishes a blog entry using the given day Twitter tweets

=head1 SYNOPSIS

	my $twDaily = Twitter::Daily->new( 'TWuser' => $twUser,
									   'twitter' => $twitter,
									   'blog' => $blog,
									   'entry' => $entry,
									   'verbose' => $verbose
									   ) || die("Not all options were passed");
								
	$twDaily->postNews($date,$title) || do {
		my $error =  $twDaily->errMsg();
		$twDaily->close(); 
		die( $error ); 
	};
	
	$twDaily->close();
 
=head1 DESCRIPTION 

This package contains the very Twitter::Daily core and coordinates Twitter
timeline retrieval and blog publishing

=head2 new

Constructor. Accepts the next parameters :

=over 1

=item * TWuser : twitter username

=item * twitter : Net::Twitter created object

=item * blog : blog publishing object based on Twitter::Daily::Blog::Base (e.g Blosxom::Publish)

=item * verbose : more activity related messages than usual :-D

=back

=cut


sub new {
    my $class = shift;
    my %option = @_;
    ## ToDo make 'twitter' use not a Net::Twitter object
    ## but one whose the user can be obtained from it 
	my $mandatory = [ 'twitter', 'TWuser', 'blog', 'entry'];
	my $optional = ['verbose', 'silent'];
	
    my $this;

    
    $this->{'silent'} = 0    if (! defined $this->{'silent'} );
	$this->{'verbose'} = 0   if (! defined $this->{'verbose'} );
    
    
    for my $opt ( @$mandatory ) {
    	_verboseMessage($this, "new: processing option " . $opt );
    	return undef  if ( ! defined $option{$opt} );
    	$this->{$opt} = $option{$opt};
    }
    
    for my $option ( @$optional ) {
    	if ( defined $option{$option} ) {
    		$this->{$option} = $option{$option}
    	} 
    }

    $this->{'errMsg'} = "";
    $this->{'errNumber'} = 0;

    return bless $this, $class;
};

=head2 postNews

Obtains Twitter entries for the day and creates a new entry in the blog.
Returns 1 on success and 0 on fail. The error can be retrieved using errMsg and errNumber

=cut

sub postNews {
    my $this = shift;
    ### ToDo add parameter verification
    my $date = shift;
    my $title = shift;
    
    my ($entryFile,$entries) = $this->_buildEntry($date,$title);
    return FAIL     if (! $entryFile );

	if ( ! $entries ) {
		$this->_normalMessage("No entries to publish");
		$this->_verboseMessage("Deleting file $entryFile");
	    unlink( $entryFile ); 
	    $this->_setError(ERR_NO_ERROR, ERR_NO_ERROR_NUM);
		return PASS;
	}
	
    $this->_verboseMessage("Publishing entry");
    
    $this->{'blog'}->publish( $entryFile ) 
    	|| do {
    			$this->_verboseMessage("Deleting file $entryFile");
    			unlink( $entryFile );
    			return  $this->_setError( ERR_PUBLISH_MSG . $this->{'blog'}->errMsg,
       			  				    	  ERR_PUBLISH );
    	};
	
    $this->_verboseMessage("Deleting file $entryFile");
	unlink( $entryFile );
	$this->_setError(ERR_NO_ERROR, ERR_NO_ERROR_NUM);
	return PASS;    
}

=head2 close

Ends relationship woth Twitter and Blog

=cut

sub close {
    my $this = shift;


    $this->_verboseMessage("Bye, Blog !");
    $this->{'blog'}->quit();
	$this->_setError(ERR_NO_ERROR, ERR_NO_ERROR_NUM);
	return PASS;  
}

## ToDo change error management using Error module

=head2 errMsg

Returns the last error message in English language.
Will return an empty string if the last operation ended successfuly

=cut

sub errMsg {
	return $_[0]->{'errMsg'};
}


## ToDo change error management using Error module

=head2 errNumber

Returns the last error number.
Will return zero if the last operation ended successfuly

=cut

sub errNumber {
	return $_[0]->{'errNumber'};
}

sub _acceptEntry($$) {
    my $this = shift;
	my $date = shift;
	my $line = shift;
	
	my ($year, $month, $day, $hour, $min, $sec, $tz) =
            parse_date($date);
        $month = $this->_getMonthName($month);

	## ToDo use Twitter::Date
	## Quick Twitter date parsing
	## Sample date : Tue May 26 20:25:13 +0000 2009
	my ($Twday, $Tmonth, $Tday, $Ttime, $Ttz, $Tyear) =
            split (/ /, $line->{'created_at'});

       return  ( ($year == $Tyear) && ( $month eq $Tmonth ) && ($Tday == $day) );
}

sub _buildEntry($$$) {
	my $this = shift;
    my $date = shift;
    my $title = shift;
    my $entries = 0;

    $this->_verboseMessage("Obtaining Twitter timeline ($date)" );
	my $timeline = $this->{'twitter'}->user_timeline(
						{  id => $this->{'TWuser'}, since => $date } );

	return  $this->_setError( ERR_TW_TIMELINE_MSG . ' (' . $@ . ')' , ERR_TW_TIMELINE )	
		if (! defined $timeline);

	$this->{'entry'}->setTitle( $this->_getTitle($title, $date) );

    foreach my $line ( @$timeline ) {
    	## Since Apr 12th 2009 (aprox) Net::Twitter retrieves more
    	## entries than expected, then we need to perform a local
    	## filtering based on the entry date :-(
    	if (! $this->_acceptEntry($date, $line)) {
    		$this->_verboseMessage("Entry rejected (" . $line->{'created_at'}.") : "
    		                       . "'" . $line->{'text'} . "'" );
    		next;
    	}

    	$this->_normalMessage("Generating entry '" . $line->{'text'} . "' (" . $line->{'created_at'}.")" );
		$this->{'entry'}->addLine( $line->{'text'}, $line->{'created_at'}  );
    	$entries++;
    }

	my $fname = _saveToTempFile($this, $this->{'entry'} );
	
 	return  $this->_setError( ERR_TEMP_FILE , ERR_TEMP_FILE_MSG )	
		if (! $fname);

	return ($fname,$entries);
};

sub _setError {
	my $this = shift;

	$this->{'errMsg'} = $_[0];
	$this->{'errNumber'} = $_[1];
	return FAIL;
}


sub _normalMessage($$) {
	my $this = shift;
	my $msg = shift;
	
	print "$msg\n"  if ( ! $this->{'silent'} );
}

sub _verboseMessage($$) {
	my $this = shift;
	my $msg = shift;
	
	print "$msg\n"  if ( $this->{'verbose'} != 0 );
}

sub _getTitle {
	my $this  = shift;
	my $title = shift;
	my $date  = shift;

	if ( !$title ) {
		my ($year, $month, $day, $hour, $min, $sec, $tz) = parse_date($date);
		my $m = $this->_getMonthName($month);
		$title = "Twitter timeline for $m $day, $year";
	}
	
	$this->_verboseMessage( "News title : '" . $title . "'");
	return $title;
}

sub _getMonthName($$) {
	my $this  = shift;
	my $month = shift;
	my @m = ('Jan', 'Feb', 'Mar', 'Apr', 
                 'May', 'Jun', 'Jul', 'Aug', 
                 'Sep', 'Oct', 'Nov', 'Dec');
	$month--;
	
	return $m[$month];
}

sub _saveToTempFile {
	my $this = shift;
	my $entryBuilder = shift;

	$this->_verboseMessage("Generating temp file");
	my $fname = mktemp( 'twitterXXXXXX', '.');
    $this->_verboseMessage("Temp filename : $fname");

	$this->_verboseMessage("Opening it");
	my $fh;
	open ($fh, '>', $fname) || return FAIL;
			
	$this->_verboseMessage("Writing entry");
	print $fh $entryBuilder->getEntry();
	
	$this->_verboseMessage("Closing entry temp file");
	CORE::close($fh);
	
    return $fname;
}


=pod

=head1 AUTHOR

Victor A. Rodriguez (Bit-Man)


=cut

1;


