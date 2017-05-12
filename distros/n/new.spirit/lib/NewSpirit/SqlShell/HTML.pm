# $Id: HTML.pm,v 1.2 2000/11/24 09:57:07 joern Exp $

package NewSpirit::SqlShell::HTML;

@ISA = qw( NewSpirit::SqlShell );

use strict;
use NewSpirit::SqlShell;

sub print_current_command {
	my $self = shift;
	
	my $print_command = $self->{current_command};
	
	$print_command = "<b>&gt;</b> $print_command";
	
	$print_command =~ s!\n!\n<b>&gt;</b> !g;
	
	print qq{<p><a name="cmd_$self->{command_cnt}"></a>\n};
	print qq{<pre>$print_command</pre>\n};

	1;
}

sub print_query_result_start {
	my $self = shift;
	
	my %par = @_;
	
	my $title_lref = $par{title_lref};
	
	print qq{<table border=1><tr>};
	foreach my $col ( @{$title_lref} ) {
		print "<td><tt><b>$col</b></tt></td>\n";
	}
	print qq{</tr>\n};
	
	1;
}

sub print_query_result_row {
	my $self = shift;
	
	my %par = @_;
	
	my $row_lref = $par{row_lref};
	
	print "<tr>\n";
	foreach my $val (@{$row_lref}) {
		print "<td><tt>$val</tt></td>\n";
	}
	print "</tr>\n";
	
	1;
}

sub print_query_result_end {
	my $self = shift;
	
	print "</table><p>\n";
	
	1;
}

sub print_error {
	my $self = shift;

	my ($msg, $comment) = @_;

	print qq{<b><tt><a href="#err_$self->{command_cnt}">}.
	      qq{<font color=red>$msg</a></tt></font></b>\n};
	
	if ($comment) {
		print "<p>$CFG::FONT$comment</FONT>\n";
	}
	
	print "<SCRIPT>self.window.scroll(0,5000000)</SCRIPT>\n";
	print "<SCRIPT>self.window.scroll(0,5000000)</SCRIPT>\n";
}

sub error_summary {
	my $self = shift;
	
	print "<hr><p>$CFG::FONT<b>Error summary:</b> ",
	      scalar(@{$self->{errors}}),
	      " error(s)!</FONT><p>\n";
	
	my $num = 0;
	foreach my $err ( @{$self->{errors}} ) {
		++$num;
		print <<__HTML;
<a name="err_$err->{command_cnt}">
<table border=1>
<tr><td><tt>$err->{command}</tt></td></tr>
<tr><td><tt><a href="#cmd_$err->{command_cnt}"><font color="red">$err->{msg}</a></font></tt></td></tr>
</table>
<br>
__HTML
	}

	print "<SCRIPT>self.window.scroll(0,5000000)</SCRIPT>\n";
	print "<SCRIPT>self.window.scroll(0,5000000)</SCRIPT>\n";
}

sub info {
	my $self = shift;
	
	my ($msg) = @_;
	
	print "<tt><font color=green>$msg</font></tt><br>\n";

	print "<SCRIPT>self.window.scroll(0,5000000)</SCRIPT>\n";
	print "<SCRIPT>self.window.scroll(0,5000000)</SCRIPT>\n";
}

sub print_help_header {
	my $self = shift;
	
	print '<b><font face="Helvetica,Arial,Geneva">Help Page:</font></b><p><pre>';
}

sub print_help_footer {
	my $self = shift;
	
	print "</pre><p>\n";
}


