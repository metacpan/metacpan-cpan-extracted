#!/usr/bin/perl

# example polling program
# use the below in place of use WWW::Poll to test local 
#use lib qw( ../ );
#use Poll;

use strict;
use WWW::Poll;
use CGI;
use constant POLLPATH=>'/home/mgammon/public_html/poll_test/demo/data'; 

my $deBug = 1;

my $poll=new WWW::Poll;
$poll->path(POLLPATH);

&main();

sub main {
	my $query = new CGI;
	my $action = $query->param(-name=>'action');
	if ( $action eq 'vote') {
		&vote_poll( $query->param(-name=>'vote') );
	} elsif ( $action eq 'view' ) {
		&get_results;
	} elsif ( $query->param(-name=>'poll_id') ) {
		&get_results( $query->param(-name=>'poll_id') );
	} elsif ( $action eq 'list' ) {
		&list_polls;
	} else {
		&display_poll;
	}
}

sub vote_poll {
	my $vote = shift;
	$poll->vote($vote); # votes on latest poll
	&get_results;
}

sub display_poll {
	my $pollid = $poll->get;

	my $font = qq|<FONT FACE="arial,helvetica" SIZE=1>|;
	my $html = "
			<FORM ACTION=\"$ENV{SCRIPT_NAME}\" METHOD=post>
			<INPUT TYPE=hidden NAME=action VALUE=vote>
			<TABLE CELLPADDING=3 CELLSPACING=0 BORDER=0>
			<TD BGCOLOR=#333333>
			
			<TABLE CELLPADDING=1 CELLSPACING=0 BORDER=0>
			<TR><TD COLSPAN=2 VALIGN=top BGCOLOR=#99CCFF><strong>&nbsp;".$font.$poll->question."&nbsp;</strong></TD></TR>
			<TR><TD COLSPAN=2 VALIGN=top BGCOLOR=#333333><SPACER TYPE=block WIDTH=100 HEIGHT=1></TD></TR>
			<TR><TD COLSPAN=2 VALIGN=top BGCOLOR=#cccccc><SPACER TYPE=block WIDTH=100 HEIGHT=1></TD></TR>";
	foreach ($poll->akeys) {
		$html .= "
			<TR>
				<TD VALIGN=top BGCOLOR=#cccccc><INPUT TYPE=radio NAME=vote VALUE=".$_."></TD>
				<TD BGCOLOR=#cccccc>".$font.$poll->answers->{$_}."</TD>
			</TR>";
	}
	$html .= "
			<TR><TD COLSPAN=2 VALIGN=top BGCOLOR=#cccccc><SPACER TYPE=block WIDTH=100 HEIGHT=1></TD></TR>
			<TR>
				<TD VALIGN=top ALIGN=right BGCOLOR=#ccccccc COLSPAN=2>
					".$font."
					&nbsp;<A HREF=".$ENV{SCRIPT_NAME}."?action=list>Past Polls</A>&nbsp;&nbsp;&nbsp;<A HREF=".$ENV{SCRIPT_NAME}."?action=view>Results</A>&nbsp;&nbsp;&nbsp;
					<INPUT TYPE=submit VALUE=\" vote \">
				</TD>
			</TR>
			<TR><TD COLSPAN=2 VALIGN=top BGCOLOR=#cccccc><SPACER TYPE=block WIDTH=100 HEIGHT=1></TD></TR>
			</TABLE>
			
			</TD></TABLE>
			</FORM>";

	&print_poll($html);
}

sub list_polls {
	my %polls = $poll->list;
	my $html = "<UL>";
	foreach (sort keys %polls) {
		$html .= qq|<LI><A HREF="$ENV{SCRIPT_NAME}?poll_id=$_">$polls{$_}</A>|;
	}
	$html .= </UL>
	&print_poll($html);
}

sub get_results {
	my $poll_id = shift;
	my $html = $poll->get_html($poll_id);
	&print_poll($html);
}

sub print_poll {
	my $html = shift;
	print "Content-type:  text/html\n\n";
	print $html;
}
