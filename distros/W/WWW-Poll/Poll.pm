package WWW::Poll;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';


# Preloaded methods go here.

my $deBug=1;

# define constant variables
use constant QID => 'qid.dat';
use constant QUEST => 'questions.dat';
use constant ANS => '_ans.dat';
use constant VOTES => '_poll.dat';
use constant MAXWIDTH => '300';
# make a constant for fonts & the bar image location
use constant FONT => '<FONT FACE="arial,helvetica" SIZE=2>';
my $imagepath = $ENV{SCRIPT_NAME}; # same as calling script
$imagepath =~ s|^(.*/).*?$|$1|;
use constant IMAGE => $imagepath.'bar.jpg';
undef $imagepath;

# new initializes with latest poll
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto; 
	my $self = {};
	$self->{POLL_ID} = undef;
	$self->{POLL_PATH} = undef;
	$self->{POLL_QUESTION} = undef;
	$self->{POLL_ANSWERS} = ();
	$self->{POLL_VOTES} = ();
	$self->{POLL_LIST} = ();
	$self->{DATE} = ();
	bless ($self, $class);
	return $self;
}

#------ BEGIN poll object methods ------#

sub id {
	my $self = shift;
	if (@_) { $self->{POLL_ID} = shift; }
	if ( !$self->{POLL_ID} ) { $self->_get_qid; }
	return $self->{POLL_ID};
}

sub question {
	my $self = shift;
	if (@_) { $self->{POLL_QUESTION} = shift; }
	if ( !$self->{POLL_QUESTION} ) { $self->_get_question; }
	return $self->{POLL_QUESTION};
}

sub answers {
	my $self = shift;
	if (@_) {  %{ $self->{POLL_ANSWERS} } = @_; }
	if ( !$self->{POLL_ANSWERS} ) { $self->_get_answers; }
	return $self->{POLL_ANSWERS};
	#return %{ $self->{POLL_ANSWERS} };
}

sub votes {
	my $self = shift;
	if (@_) {  %{ $self->{POLL_VOTES} } = @_; }
	if ( !$self->{POLL_VOTES} ) { $self->_get_votes; }
	return $self->{POLL_VOTES};
	#return %{ $self->{POLL_VOTES} };
}

sub path {
	my $self = shift;
	if (@_) { $self->{POLL_PATH} = shift; }
	return $self->{POLL_PATH};
}

sub list {
	my $self = shift;
	if (!$self->{POLL_LIST}) { $self->_get_question("all"); }
	return %{ $self->{POLL_LIST} };
}

sub date {
	my $self = shift;
	if (@_) { $self->{POLL_DATE} = shift; }
	if (!$self->{POLL_DATE}) { $self->{POLL_DATE} = &_create_date; }
	return $self->{POLL_DATE};
}

#------ END poll object methods ------#

#-------------------------------------------#

#------ BEGIN public methods ------#

# read poll returning poll id
sub get {
	my $self = shift;
	# $self->get($n) will return a specified poll 
	# or the latest poll if no params or valid files
	if (@_ && ($_[0] =~ /\d/)) { $self->{POLL_ID} = shift;  } else { $self->id; }
	# retrieve poll question 
	$self->_get_question;
	# retrieve poll answers file
	$self->_get_answers;
	# retrieve poll results file
	$self->_get_votes;
	# send them html
	#return $self->_create_poll_html;
	return $self->id;
}

# read poll returning html
sub get_html {
	my $self = shift;
	# $self->get($n) will return a specified poll 
	# or the latest poll if no params or valid files
	if (@_ && ($_[0] =~ /\d/)) { $self->{POLL_ID} = shift;  } else { $self->id; }
	# retrieve poll question 
	$self->_get_question;
	# retrieve poll answers file
	$self->_get_answers;
	# retrieve poll results file
	$self->_get_votes;
	# send them html
	return $self->_create_poll_html;
}

# vote on a poll
sub vote {
	my $self = shift;
	my $vote = shift;
	
	# get poll content
	$self->_get_votes;
	# increment proper poll result
	foreach ($self->rkeys) {
		( $_ == $vote ) ? ++$self->votes->{$_} : next ;
	}
	# write new poll back to file 
	$self->_write_votes;
	undef $vote;	# cleanliness is next to godliness
	return 1;
}

# seed answers for poll creation
sub add_answers {
	my $self = shift;
	my $i=1;
	foreach (@_) {
		next unless (/\w/);
		$self->{POLL_ANSWERS}->{$i} = $_;
		$i++;
	}
}

# create a new poll
sub create {
	my $self = shift;
	# check to be sure all params have been set
	$self->_check_params;
	# clean out tabs & newlines from data
	$self->_clean_input;
	# get last qid number 
	$self->_get_qid;
	# increment poll id
	$self->id($self->id+1);
	# append the question to the question file
	$self->_insert_question;
	# create answers file for new poll
	$self->_write_answers;
	# seed the votes object
	foreach ($self->akeys) { $self->{POLL_VOTES}->{$_} = '1'; }
	# create votes file for new poll
	$self->_write_votes;
	# update the qid file
	$self->_set_qid;
	# return some output html
	return $self->_create_admin_html;
}										

# return keys for votes
sub rkeys {
	my $self = shift;
	if ( !$self->{POLL_VOTES} ) { $self->_get_votes; }
	return (keys %{ $self->votes });
}

# return keys for answers
sub akeys {
	my $self = shift;
	if ( !$self->{POLL_ANSWERS} ) { $self->_get_answers; }
	return (keys %{ $self->answers });
}

#------ END public methods ------#

#-------------------------------------------#

#------ BEGIN private methods ------#
# All private methods are accessing the hashes (except $self->id) directly
# rather than the proper object methods (just for the hell of it)

#- BEGIN reading from files METHODS
sub _get_qid {
	my $self = shift;
	# get qid of latest poll 
	open(QFILE,$self->{POLL_PATH}."/".QID) || croak "$!, Perhaps \$poll->path() wasn't set?\n".$self->{POLL_PATH}."/".QID if $deBug;
	my @qid = <QFILE>;
	close(QFILE);
	$self->{POLL_ID} = $qid[0];
}

sub _get_question {
	my $self = shift;
	# open & retrieve question
	open(QFILE,$self->{POLL_PATH}."/".QUEST) || croak "$!, Perhaps \$poll->path() wasn't set?\n".$self->{POLL_PATH}."/".QUEST if $deBug;
	if ( @_ && $_[0] eq 'all') {
		while(<QFILE>) {
			/^(\d+)\t.*?\t(.*?)$/o;
			$self->{POLL_LIST}->{$1}=$2;
		}
	} else {
		while(<QFILE>) {
			if (/^$self->{POLL_ID}\t(.*?)\t(.*?)$/o) {
				$self->{POLL_QUESTION}=($2);
				$self->date($1);
			}
		}
	}
	close(QFILE);
}

sub _get_answers {
	my $self = shift;
	open(AFILE,$self->{POLL_PATH}."/".$self->id.ANS) || croak "$!, Perhaps \$poll->path() wasn't set?\n".$self->{POLL_PATH}."/".$self->id.ANS if $deBug;
	while (<AFILE>) {
		/^(\d+)\t(.*?)$/o;
		$self->{POLL_ANSWERS}->{$1}=$2 
	}
	close(AFILE);
}

sub _get_votes {
	my $self = shift;
	# open & retrieve poll results file
	open(PFILE,$self->{POLL_PATH}."/".$self->id.VOTES) || croak "$!, Perhaps \$poll->path() wasn't set?\n".$self->{POLL_PATH}."/".$self->id.VOTES if $deBug;
	while (<PFILE>) {
		/^(\d+)\t(\d+)$/o;
		$self->{POLL_VOTES}->{$1}=$2; 
	}
	close(PFILE);
}

sub _create_poll_html {
	my $self = shift;
	my ($sum,@votes);
	
	foreach (keys %{$self->{POLL_VOTES}}) { 
		push @votes, $self->{POLL_VOTES}->{$_};
		$sum += $self->{POLL_VOTES}->{$_};
	}
	
	# get highest vote
	my @maxvotes = sort { $b<=>$a } @votes;
	my $maxvote = $maxvotes[0];
	undef (@maxvotes,@votes);
	
	if ( $maxvote<1 ) { $maxvote=1; }
	#my $factor = MAXWIDTH/(MAXWIDTH-$maxvote);
	#croak $factor;
	
	my $format_date = $self->{POLL_DATE};
	$format_date =~ s|(\d{4})(\d{2})(\d{2})|$2/$3/$1|;
	my $html = "
			<TABLE WIDTH=".(MAXWIDTH+200)." CELLPADDING=4 CELLSPACING=0 BORDER=0>"; 
	$html .= "
			<TR><TD WIDTH=".(MAXWIDTH+200)." COLSPAN=2>
					<strong>".FONT."<FONT SIZE=3>".$self->{POLL_QUESTION}."&nbsp;</strong><BR>
					<FONT SIZE=1>( question posted ".$format_date."&nbsp;-&nbsp;".$sum." votes total )</TD></TR>";
	foreach ( sort keys %{$self->{POLL_VOTES}} ) {
		my $vote = ( $self->{POLL_VOTES}->{$_}<1 ) ? 1 : $self->{POLL_VOTES}->{$_} ;
		if ($sum<1 ) { $sum=1; }
		$html .= "
			<TR><TD WIDTH=20><BR></TD>
				<TD WIDTH=".(MAXWIDTH+180)." ALIGN=left VALIGN=top>
					<strong>".FONT.$self->{POLL_ANSWERS}->{$_}."</strong></FONT>
					<BR>
					<IMG SRC=".IMAGE." WIDTH=". int( (MAXWIDTH*($vote/$sum)) ) ." HEIGHT=10 BORDER=0>
					&nbsp;".int(($vote/$sum)*100)."%&nbsp;<FONT SIZE=2>&nbsp;-&nbsp;".$vote."&nbsp;votes</FONT></TD></TR>
			";
	}
	$html .= "
			</TABLE>";
	return $html;
}

sub _create_admin_html {
	# format some html to display to admin
	my $self = shift;
	my $html = "
		<TABLE>
		<TR><TD COLSPAN=2><strong>".FONT."<FONT SIZE=2>".$self->{POLL_QUESTION}."</strong></TD></TR>";
	foreach ( keys %{$self->{POLL_ANSWERS}} ) {
		$html .= "
		<TR><TD>".FONT."Answer ".$_.":</TD><TD><strong>".FONT.$self->{POLL_ANSWERS}->{$_}."</strong></TD></TR>";
	}
	$html .= qq|\n</TABLE>\n|;
	return $html;
}
#- END reading from files METHODS

#- BEGIN writing to files METHODS
sub _set_qid {
	my $self = shift;
	# get qid of latest poll 
	open(QFILE,">".$self->{POLL_PATH}."/".QID) || croak "$!, Perhaps \$poll->path() wasn't set?\n".$self->{POLL_PATH}.QID if $deBug;
	print QFILE $self->id;
	close(QFILE);
}

sub _insert_question {
	my $self = shift;
	# insert question & date(YYYYMMDD) into file
	open(QFILE,">>".$self->{POLL_PATH}."/".QUEST) || croak "$!" if $deBug;
	print QFILE $self->id."\t".$self->date."\t".$self->{POLL_QUESTION}."\n";
	close(QFILE);
}

sub _write_answers {
	my $self = shift;
	open(AFILE,">".$self->{POLL_PATH}."/".$self->id.ANS) || croak "$!" if $deBug;
	foreach ( keys %{$self->{POLL_ANSWERS}} ) {
		print AFILE $_ ."\t".$self->{POLL_ANSWERS}->{$_}."\n";
	}
	close(AFILE);
	return 1;
}

sub _write_votes {
	my $self = shift;	
	open(PFILE,">".$self->{POLL_PATH}."/".$self->id.VOTES) || croak "$!" if $deBug;
	foreach ( keys %{$self->{POLL_VOTES}} ) {
		print PFILE $_ ."\t".$self->{POLL_VOTES}->{$_}."\n";
	}
	close(PFILE);
	return 1;
}
#- END writing to files METHODS

#- BEGIN miscellany METHODS
sub _chmod_files {
	my $self = shift;
	chmod 0666, $self->{POLL_PATH}."/".$self->id.VOTES,$self->{POLL_PATH}."/".$self->id.ANS;
	return 1;
}

sub _check_params {
	my $self = shift;
	if ( scalar((keys %{$self->{POLL_ANSWERS}}))<1 ) { die "$! Answers weren't set"; }
	if ( $self->{POLL_QUESTION} !~ /\w/ ) { die "$! Question wasn't set"; }
}

sub _clean_input {
	my $self = shift;
	$self->{POLL_QUESTION} =~ s/[\t\r\n]/  /g; 
	foreach ( keys %{ $self->{POLL_ANSWERS} } ) {
		$self->{POLL_ANSWERS}->{$_} =~ s/[\t\r\n]/  /g; 
	}
}

sub _create_date {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$mon = '0'.($mon+1) if ($mon<10);
	$mday = '0'.$mday if ($mday<10);
	return (($year+1900).$mon.$mday);
}
#- END miscellany METHODS

# uncomment this if mod_perl complains in the error log
#sub DESTROY { }

#------ END private methods ------#

#-------------------------------------------#


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Poll - Perl extension to build web polls

=head1 DESCRIPTION

	Perl module to build and run web polls with built-in administrative capabilities.

=head1 SYNOPSIS

	use Poll;
	my $poll = new Poll;
	$poll->path('/system/path/to/data/directory');

# Voting and returning poll results

	$poll->vote($ans_key);
	$html = $poll->get_html();
	print "Content-type: text/html\n\n";
	print $html;

#- Create a new Poll -# 
	
	$poll->question('Should Trent Lott change his barber?');
	$poll->add_answers( "Yes", "No", "Who's Trent Lott?", etc );
	$poll->create();

=head1 USAGE

	$poll->path($directory);

Above system directory must me chmod'ed 666.  Also, it needs to contain the files qid.dat & questions.dat as world writable.   The graphic to create the default percentage graph also goes in this directory. 

#- Retrieving Poll Data -#
	
	$html = $poll->get_html(<pollid>);

Returns default html of specific poll results.  
With no parameter the script returns the latest poll. 
	
-OR-
	
	$poll_id = $poll->get(<pollid>);

This command retrieve the specified poll but returns the poll id rather than html. Using this method the poll objects can be accessed for customized formatting of output.
Example below:

	$poll_id = $poll->get(<pollid>);
	print $poll->question();
	foreach ($poll->rkeys) { 
		print $poll->answers->{$_}." = ".$poll->votes->{$_}."<BR>";
	}

#- Voting on Latest Poll -#

	$poll->vote($ans_key);

Takes hash key for appropriate $poll->answers.  Keys can be gotten via $poll->akeys.
Example below:
	
	foreach ($poll->akeys) {
		print "Answer = ".$poll->answers->{$_}."\n";
		print "Key = ".$_."\n";
	}

#- Create a new Poll -# 

	$poll->question('Should Trent Lott change his barber?');
	$poll->add_answers( "Yes", "No", "Who's Trent Lott?", etc );
	$poll->create();

This is pretty straight-forward.  There can be an infinite amount of answers for any giver question but be aware of how it may look when outputted to html.  The create() command builds the appropriate poll files in the $poll->path() directory.

#- To get a hash array of all polls to date -#

	my %all_polls = $poll->list();
	foreach (keys %polls) {
		print qq|<A HREF="$ENV{SCRIPT_NAME}?poll_id=$_">$all_polls{$_}</A><BR>|;
	}

This would print out a list of polls with links that could be followed to view the results of that poll.

=head1 DOCUMENTATION

Documentation and code examples for Poll.pm can be located at http://www.straphanger.org/~mgammon/poll

The code examples located at the above url handle both administrative and standard polling routines. There are currently no manpages for this module but I will be working on them and post a revision when available.

=head1 PREREQUISITES

Perl 5.004
	
May work with earlier versions but hasn't been tested.   Feel free to email me if you find it does.

=head1 AUTHOR

Mike Gammon <mgammon@straphanger.org>

perl(1).

=cut
