#!/usr/bin/perl

# the subroutine write_latest() writes the latest poll into
# latest.inc inside the ~/data directory so it can be included 
# in SSI, PHP, or even (gasp!) ASP pages.
 
use WWW::Poll;
use CGI;
use CGI::Carp qw( fatalsToBrowser );

my $poll = new WWW::Poll;
$poll->path('/home/mgammon/public_html/poll_test/demo/data');

&main();

sub main {
	my $query=new CGI;
	my $html;
	if ( $query->param(-name=>'newPoll') ) {
		$html = &create_poll($query);
		die unless &write_latest;
	} else {
		$html = &create_form($query);
	}
	print $query->header;
	print &admin_header;
	print $html;
	print &admin_footer;
	exit;
}

sub create_poll {
	local($query) = shift;
	
	
	# insert question
	$poll->question( $query->param( -name=>'question') );
	
	# parse answers
	$poll->add_answers(
		$query->param( -name=>'answer_1'),
		$query->param( -name=>'answer_2'),
		$query->param( -name=>'answer_3'),
		$query->param( -name=>'answer_4'),
		$query->param( -name=>'answer_5'),
		$query->param( -name=>'answer_6')
		);

	my $html = "<H2>Poll Added!</H2>";
	$html .= $poll->create;
	return $html;
}

sub create_form {
	local($query)=shift;
	
	my $html = qq|

<FORM NAME=addPoll ACTION="$ENV{SCRIPT_NAME}" METHOD=post>
<INPUT TYPE=hidden NAME="newPoll" VALUE="1">

Enter Poll Question: (125 chars)<BR>
<INPUT TYPE=text NAME="question" VALUE="" MAXLENGTH=125 SIZE=50>
<P>
Answer 1:&nbsp;
<INPUT TYPE=text NAME="answer_1" VALUE="" MAXLENGTH=30 SIZE=30>
<BR>
Answer 2:&nbsp;
<INPUT TYPE=text NAME="answer_2" VALUE="" MAXLENGTH=30 SIZE=30>
<BR>
Answer 3:&nbsp;
<INPUT TYPE=text NAME="answer_3" VALUE="" MAXLENGTH=30 SIZE=30>
<BR>
Answer 4:&nbsp;
<INPUT TYPE=text NAME="answer_4" VALUE="" MAXLENGTH=30 SIZE=30>
<BR>
Answer 5:&nbsp;
<INPUT TYPE=text NAME="answer_5" VALUE="" MAXLENGTH=30 SIZE=30>
<BR>
Answer 6:&nbsp;
<INPUT TYPE=text NAME="answer_6" VALUE="" MAXLENGTH=30 SIZE=30>

<P>
<INPUT TYPE=submit VALUE="Add Poll">
</FORM>

|;
	return $html;
}

sub write_latest {
	my $font = qq|<FONT FACE="arial,helvetica" SIZE=1>|;
	my $scriptname = $ENV{SCRIPT_NAME};
	$scriptname =~ s|^(.*/).*?$|$1|;
	$scriptname .= "poll.pl";

	my $html = "
			<FORM ACTION=\"$scriptname\" METHOD=post>
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
					".$font."&nbsp;<A HREF=".$ENV{SCRIPT_NAME}."?action=view>View Results</A>&nbsp;&nbsp;&nbsp;&nbsp;
					<INPUT TYPE=submit VALUE=\" vote \"></FONT> </TD>
			</TR>
			<TR><TD COLSPAN=2 VALIGN=top BGCOLOR=#cccccc><SPACER TYPE=block WIDTH=100 HEIGHT=1></TD></TR>
			</TABLE>
			
			</TD></TABLE>
			</FORM>";

	open(LATEST,">".$poll->path."/latest.inc") || die "$!";
	print LATEST $html;
	close(LATEST);
	return 1;
}

sub admin_header {
	my $html = qq|

<HTML>
<HEAD>
<TITLE>Poll Administration</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF">

|;
	return $html;
}

sub admin_footer {
	my $html = qq|

<BR><BR>
</BODY>
</HTML>

|;
	return $html;
}
