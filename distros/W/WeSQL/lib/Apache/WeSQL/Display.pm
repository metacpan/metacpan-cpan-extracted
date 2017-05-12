package Apache::WeSQL::Display;

use 5.006;
use strict;
use warnings;
use lib(".");
use lib("../");

use POSIX qw(strftime);		# Could be useful in 'perl;' style replace lines in the views file!

use CGI;

use Apache::WeSQL;
use Apache::WeSQL::SqlFunc qw(:all);
use Apache::WeSQL::Journalled qw(:all);
use Apache::WeSQL::Session qw(:all);

use Apache::Constants qw(:common);
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::WeSQL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	jForm jDetails jList
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.53';

# Preloaded methods go here.

############################################################
# jCheckParams
# Makes sure that CGI parameters exist with the names as passed
# via arguments to this sub. If not, displays an error message,
# logs the event, and exits.
############################################################
sub jCheckParams {
	my $ok = 1;
	my $dd = localtime();
 	my $error .= <<"EOF";
HTTP/1.1 200 OK
Date: $dd
Server: Apache
Connection: close
Content-type: text/html

<html>
<body bgcolor=#FFFFFF>
<h1>Error</h1>
Some parameters are missing
EOF
	$error .= ":<p><ul>\n" if ($Apache::WeSQL::DEBUG);
	foreach (@_) {
		if (!defined($Apache::WeSQL::params{$_})) {
			$ok = 0;
			$error .= "<li>$_ not provided</li>\n" if ($Apache::WeSQL::DEBUG);
		}
	}
	if (!$ok) {
		$error .= "</ul>" if ($Apache::WeSQL::DEBUG);
		$error .= <<EOF;
Please contact the webmaster.
</body>
</html>
EOF
		print $error;
		exit;
  }
}

############################################################
# jForm
# This sub can read the 'form.cf' file (for the syntax, see the man page of this module, 
# or the online docs at http://wesql.org), and produce a dynamic edit/add form
# based on the information from the 'form.cf' file, with the layout specified in the 'layout.cf' file.
############################################################
sub jForm {
	my $dbh = shift;
	my $cookieheader = shift;
	my $body;
	my %layout = &Apache::WeSQL::readLayoutFile("layout.cf");
	&jCheckParams(('view'));	# First check that we have a view parameter!
	my %data = &readConfigFile("form.cf",$Apache::WeSQL::params{view});

  $data{layoutlistheader} = 'listheader' if (!defined($data{layoutlistheader}));
  $data{layoutlistbody} = 'listbody' if (!defined($data{layoutlistbody}));
  $data{layoutliststarttable1} = 'liststarttable1' if (!defined($data{layoutliststarttable1}));
  $data{layoutliststarttable2} = 'liststarttable2' if (!defined($data{layoutliststarttable2}));
  $data{layoutliststoptable} = 'liststoptable' if (!defined($data{layoutliststoptable}));
  $data{layoutlistfooter} = 'listfooter' if (!defined($data{layoutlistfooter}));

  $data{layoutformrowstart} = 'formrowstart' if (!defined($data{layoutformrowstart}));
  $data{layoutformrowstop} = 'formrowstop' if (!defined($data{layoutformrowstop}));
  $data{layoutformkeycolumnstart} = 'formkeycolumnstart' if (!defined($data{layoutformkeycolumnstart}));
  $data{layoutformvalcolumnstart} = 'formvalcolumnstart' if (!defined($data{layoutformvalcolumnstart}));
  $data{layoutformcolumnstop} = 'formcolumnstop' if (!defined($data{layoutformcolumnstop}));
  $data{layoutformboldstart} = 'formboldstart' if (!defined($data{layoutformboldstart}));
  $data{layoutformboldstop} = 'formboldstop' if (!defined($data{layoutformboldstop}));
  $data{layoutformnoresults} = 'formnoresults' if (!defined($data{layoutformnoresults}));
  $data{layoutformupdatebutton} = 'formupdatebutton' if (!defined($data{layoutformupdatebutton}));
  $data{layoutformaddbutton} = 'formaddbutton' if (!defined($data{layoutformaddbutton}));
  $data{layoutformappendcolumnstart} = 'formappendcolumnstart' if (!defined($data{layoutformappendcolumnstart}));

  $data{layoutformtablestop} = 'formtablestop' if (!defined($data{formtablestop}));

	$data{recordsperpage} ||= 10;
	my $new = ($Apache::WeSQL::params{$data{key}} ne "new"?0:1);
	# editdest passed through URL has precedence over 'fallback' editdest in 'form.cf'
	if (defined($data{editdest}) && (!defined($Apache::WeSQL::params{editdest}))) {
		$Apache::WeSQL::params{editdest} = $data{editdest};
		&Apache::WeSQL::log_error("$$: Display.pm: jForm: setting editdest to value from .cf file: " . $Apache::WeSQL::params{editdest}) if ($Apache::WeSQL::DEBUG);
	} elsif (!defined($Apache::WeSQL::params{editdest})) {	# Ultimate fallback is HTTP_REFERER when nothing is specified in the url nor .cf file
		$Apache::WeSQL::params{editdest} = $ENV{HTTP_REFERER};
		&Apache::WeSQL::log_error("$$: Display.pm: jForm: setting editdest to HTTP_REFERER: " . $Apache::WeSQL::params{editdest}) if ($Apache::WeSQL::DEBUG);
	} else {
		&Apache::WeSQL::log_error("$$: Display.pm: jForm: setting editdest to value passed as parameter: " . $Apache::WeSQL::params{editdest}) if ($Apache::WeSQL::DEBUG);
	}
	# Store the editdest in the session
	&Apache::WeSQL::Session::sOverWrite($dbh,"editdest$Apache::WeSQL::params{view}",&operaBugDecode($Apache::WeSQL::params{editdest})); 
	&jCheckParams(("$data{key}","editdest"));	# Now check the other prerequisites!
	my $dd = localtime();
	$body = <<EOF;
HTTP/1.1 200 OK
Date: $dd
Server: Apache
EOF
	$body .= "$cookieheader\r\n" if (defined($cookieheader) && ($cookieheader ne ''));
	$body .= <<EOF;
Connection: close
Content-type: text/html

EOF
	$body .= $layout{listheader};
	$data{title} = $data{titlenew} if ($new and defined($data{titlenew}));
	$body .= "<title>$data{title}</title>" if (defined($data{title}));
	$body .= $layout{listbody};
	$body .= $data{pageheader} if (defined($data{pageheader}));

	# Start the actual table with data!
	$body .= $layout{$data{layoutliststarttable1}};
	$body .= $data{title} if (defined($data{title}));
	$body .= $layout{$data{layoutliststarttable2}};
	$body .= "$data{tableheader}" if (defined($data{tableheader}));

	my $dbtype = 0; #MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	# See if the query needs to be built!
	if (defined($data{buildquery})) {
		$data{query} = eval($data{buildquery});
		&Apache::WeSQL::log_error("$$: Display.pm: jForm: eval error (buildquery): " . $@) if $@;
	}

	my $query = $data{query} . " limit 1";

	# If this is a 'new' form, just make the query 'legal' by replacing 'key=new' by 'key='0''
	# We're only using this query to get the names of the columns anyway, if this is a 'new' form!
	$query =~ s/$data{key}\s*=\s*'*new'*/$data{key}='0'/g if ($new); 
	my $c = &sqlSelectMany($dbh,$query);

	my $action = "jupdate.wsql";
	$action = "jadd.wsql" if ($new);
	$body .= "<form action=$action method=GET>\n";
	$body .= "<input type=hidden name=view value=\"$Apache::WeSQL::params{view}\">\n";

	# Count how much content we have so far, to detect empty result-sets!
	my $prebodylength = length($body);

	my $colnameref = $c->{NAME_lc};
	my @row = ('') x ($#{$colnameref}+1);
	@row  = $c->fetchrow_array if (!$new);

	# Now replace the $columnname occurrences in the %data hash with their proper value
	# And, in the process, override the (empty!) value of a column if $new and something has been passed through GET or POST
	for (my $cnt=0;$cnt<=$#row;$cnt++) {
		$row[$cnt] = $Apache::WeSQL::params{${$colnameref}[$cnt]} if ($new && defined($Apache::WeSQL::params{${$colnameref}[$cnt]}));
		foreach (keys %data) {
			$data{$_} =~ s/\$${$colnameref}[$cnt]/$row[$cnt]/g;
		}
	}

	my $alignkey = "";
	my $alignval = "";
	$alignkey = " align=$data{aligncol}" if (defined($data{aligncol}));
	$alignval = " align=$data{alignval}" if (defined($data{alignval}));

	for (my $cnt=0;$cnt<=$#row;$cnt++) {
		my $colname = ${$colnameref}[$cnt];
		# We can not send the unique key to jAdd, but obviously must send it to jUpdate!
		next if ($new && ($colname eq $data{key}));	
		my $origcolname = $colname;
		$alignkey = ' align=' . $data{"align.$colname"} if (defined($data{"align.$colname"}));
		$alignval = ' align=' . $data{"align.$colname"} if (defined($data{"align.$colname"}));
		my $value = $row[$cnt];
		# See if we need to insert a replacement!
		if (defined($data{"replace.$colname"})) {
			my $tmp = $data{"replace.$colname"};
			# Check if this is a 'perl;'-style replacement, if so, eval it!
			$tmp = eval($tmp) if ($tmp =~ s/^\n*perl;(.*)/$1/s);
			&Apache::WeSQL::log_error("$$: Display.pm: jForm: eval error: " . $@) if $@;  
			$value = $tmp;
		}
		# Now see which form element to use
		$colname = $data{"captions.$colname"} if (defined($data{"captions.$colname"}));
		my $formel = <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformkeycolumnstart}}$layout{$data{layoutformboldstart}}$colname$layout{$data{layoutformboldstop}}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformvalcolumnstart}}<input name="$origcolname" type=textbox size=40 value="$value">$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
		if (defined($data{"form.$origcolname"})) {
			if ($data{"form.$origcolname"} eq 'hidden') {
				$formel = qq/<input name="$origcolname" type=hidden value="$value">/;
			} elsif ($data{"form.$origcolname"} eq 'onlyshow') {
				$formel = <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformkeycolumnstart}}$layout{$data{layoutformboldstart}}$colname$layout{$data{layoutformboldstop}}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformvalcolumnstart}}$value$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
			} elsif ($data{"form.$origcolname"} eq 'showandhidden') {
				$formel = qq/<input name="$origcolname" type=hidden value="$value">\n/;
				$formel .= <<"EOF"
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformkeycolumnstart}}$layout{$data{layoutformboldstart}}$colname$layout{$data{layoutformboldstop}}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformvalcolumnstart}}$value$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
			} elsif ($data{"form.$origcolname"} eq 'password') {
				$formel = <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformkeycolumnstart}}$layout{$data{layoutformboldstart}}$colname$layout{$data{layoutformboldstop}}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformvalcolumnstart}}<input name="$origcolname" type=password size=40 value="$value">$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
			} elsif ($data{"form.$origcolname"} =~ /^textarea\((.*?)\)/i) {
				$formel = <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformkeycolumnstart}}$layout{$data{layoutformboldstart}}$colname$layout{$data{layoutformboldstop}}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformvalcolumnstart}}<textarea name="$origcolname" $1>$value</textarea>$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
			} elsif ($data{"form.$origcolname"} =~ /^select/i) {
				$formel = <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformkeycolumnstart}}$layout{$data{layoutformboldstart}}$colname$layout{$data{layoutformboldstop}}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformvalcolumnstart}}<select name="$origcolname">
EOF
				while ($data{"form.$origcolname"} =~ /select\((.*?)\)(;|$)/ig) {
					my $parameters = $1;
					if ($parameters =~ /^select /i) {
						my @info = split(/\;/,$parameters,4);
						my ($value) = ($info[2] =~ /value=(.*)/);
						my ($show) = ($info[3] =~ /show=(.*)/);
						my ($selectleft,$selectright) = split(/=/,$info[1]);
						my $c = &sqlSelectMany($dbh,$info[0]);
						while(my $selectrow=$c->fetchrow_hashref()) {
							my $checkedstr = ""; 
							$checkedstr = " SELECTED CHECKED" if ((${$selectrow}{$selectleft} eq $row[$cnt]) && !$new);
							$checkedstr = " SELECTED CHECKED" if (defined($Apache::WeSQL::params{$origcolname}) && ($Apache::WeSQL::params{$origcolname} eq ${$selectrow}{$selectleft}) && $new);
							my $tmp = "<option value=\"$value\"$checkedstr>$show</option>\n";
							foreach (keys %{$selectrow}) {
								# Deal with things like show=[#hname.|]#dname
								$tmp =~ s/\[(.*?)#([a-zA-Z()\[\]0-9_]*)(.*?)(?<!\\)\|(.*?)(?<!\\)\]/&showsubst_inline($1,$2,$3,$4,%{$selectrow})/eg;
								$tmp =~ s/\#$_/${$selectrow}{$_}/g;
							}
							$formel .= $tmp;
						}
					} else {
						my @parameters = split(/\,/,$parameters);
						foreach (@parameters) {
							my @tmp = split(/\=/,$_);
							my $checkedstr = "";
							if (($value eq $tmp[1]) ||
									(defined($Apache::WeSQL::params{$origcolname}) && ($Apache::WeSQL::params{$origcolname} eq $tmp[1]))) {
								$checkedstr = " SELECTED CHECKED";
							}
							$formel .= "<option value=\"$tmp[1]\"$checkedstr>$tmp[0]</option>\n";
						}   
					}
				}
				$formel .= "</select>$layout{$data{layoutformcolumnstop}}\n$layout{$data{layoutformrowstop}}";
			}
		}
		# Replace the $alignkey/$alignval parameters!
		$formel =~ s/\$alignval/$alignval/g;
		$formel =~ s/\$alignkey/$alignkey/g;
		# And finally add the correct line to the output!
		$body .= $formel;
	}
	$c->finish();
	# Check if we found some results!
	if (length($body) == $prebodylength) {
		$body .= $layout{$data{layoutformnoresults}};
	} else {
		# Deal with the 'appendnew' and 'appendedit' tags
		if ($new) {	# This is a form for a new page
			if (defined($data{appendnew})) {
				# First check for 'perl;'-style appends, if so, eval them!
				$data{appendresults} = eval($data{appendresults}) if ($data{appendresults} =~ s/^\n*perl;(.*)/$1/s);
				&Apache::WeSQL::log_error("$$: Display.pm: jList: eval error: " . $@) if $@;  
				$body .= <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformappendcolumnstart}}$data{appendnew}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
			}
		} else {
			if (defined($data{appendedit})) {
				$body .= <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformappendcolumnstart}}$data{appendedit}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
			}
		}
		my $buttontitle = $layout{$data{layoutformupdatebutton}};
		$buttontitle = $layout{$data{layoutformaddbutton}} if ($new);
		$body .= <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformappendcolumnstart}}<input type=Submit value="$buttontitle">$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
	}
	$body .= "</form>";

	# Deal with the 'append'
	if (defined($data{append})) {
		$body .= <<"EOF";
$layout{$data{layoutformrowstart}}
$layout{$data{layoutformappendcolumnstart}}$data{append}$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
EOF
	}
	$body .= <<"EOF";
$layout{$data{layoutformtablestop}}
$layout{$data{layoutformcolumnstop}}
$layout{$data{layoutformrowstop}}
$layout{$data{layoutliststoptable}}
EOF

	# And a page footer!
	$body .= $data{pagefooter} if (defined($data{pagefooter}));
	$body .= $layout{listfooter};
	my $r = Apache->request;
	&Apache::WeSQL::log_error("$$: Display.pm: jForm: success with view '$Apache::WeSQL::params{view}' in " . $r->document_root) if ($Apache::WeSQL::DEBUG);
	return ($body,0);
}

############################################################
# showsubst_inline
# Deals with [something here #column something there|alternate value] style code (used in the 'show' part of the form:select() tag (.cf files).
# Note that this works slightly different than the code in WeSQL::dosubst_inline, which deals with the same syntax,
# but for PR_ and COOKIE_ style parameters.
#
# This code will use the alternate value when the column is not defined or equals the empty string, whereas dosubst_inline
# will only use the alternate value when the PR_ or COOKIE_ style parameter is not defined.
#
# This sub is called from the subs form_select (called from jDetails and jList) and jForm
############################################################
sub showsubst_inline {
	my ($pre, $value, $post, $alt,%uchash) = @_;
  if (defined($uchash{$value}) && ($uchash{$value} ne '')) {
    $post =~ s/\\\|/\|/g;
    return "$pre$uchash{$value}$post";
  } else {
    $alt =~ s/\\\]/\]/g;
    return "$pre$alt";
  }
}

############################################################
# form_select
# Deals with a select(key=value,...) and select(select * from xxxxx) style 'form' tags.
# Called from jList and jDetails. 
# Note that the similar behaviour for the select version of the 'form' tag in jForm is dealt with in jForm.
############################################################
sub form_select {
	my ($dbh,$colname,$value,$rowcnt,%data) = @_;
	# Deal with 'form:' style selects
	if (defined($data{"form.$colname"}) && ($data{"form.$colname"} =~ /^select/i)) {
		while ($data{"form.$colname"} =~ /select\((.*?)\)(;|$)/ig) {
			my $parameters = $1;
			if ($parameters =~ /^select /i) {
				my @info = split(/\;/,$parameters,4);
				my ($value1) = ($info[2] =~ /value=(.*)/);
				my ($show) = ($info[3] =~ /show=(.*)/);
				my ($selectleft,$selectright) = split(/=/,$info[1]);
				my $c = &sqlSelectMany($dbh,$info[0]);
				while(my $selectrow=$c->fetchrow_hashref()) {
					$value = $show if (${$selectrow}{$selectleft} eq $rowcnt);
					foreach (keys %{$selectrow}) {
						# Deal with things like show=[#hname.|]#dname
						$value =~ s/\[(.*?)#([a-zA-Z()\[\]0-9_]*)(.*?)(?<!\\)\|(.*?)(?<!\\)\]/&showsubst_inline($1,$2,$3,$4,%{$selectrow})/eg;
						$value =~ s/\#$_/${$selectrow}{$_}/g;
					}
				}
			} else {
				my @parameters = split(/\,/,$parameters);
				foreach (@parameters) {
					my @tmp = split(/\=/,$_);
					if (($rowcnt eq $tmp[1]) ||
							(defined($Apache::WeSQL::params{$colname}) && ($Apache::WeSQL::params{$colname} eq $tmp[1]))) {
						$value = $tmp[0];
					}
				}   
			}
		}
	}
	return $value;
}

############################################################
# jDetails
# This sub can read the 'details.cf' file (for the syntax, see the man page of this module, 
# or the online docs at http://wesql.org), and produce a dynamic list of records
# based on the information from the 'details.cf' file, with the layout specified in the 'layout.cf' file.
############################################################
sub jDetails {
	my $dbh = shift;
	my $cookieheader = shift;
	my $body;
	my %layout = &Apache::WeSQL::readLayoutFile("layout.cf");
	&jCheckParams(('view'));				# First check that we have a 'view' parameter!
	my %data = &readConfigFile("details.cf",$Apache::WeSQL::params{view});

  $data{layoutlistheader} = 'listheader' if (!defined($data{layoutlistheader}));
  $data{layoutlistbody} = 'listbody' if (!defined($data{layoutlistbody}));
  $data{layoutliststarttable1} = 'liststarttable1' if (!defined($data{layoutliststarttable1}));
  $data{layoutliststarttable2} = 'liststarttable2' if (!defined($data{layoutliststarttable2}));
  $data{layoutliststoptable} = 'liststoptable' if (!defined($data{layoutliststoptable}));
  $data{layoutlistfooter} = 'listfooter' if (!defined($data{layoutlistfooter}));

  $data{layoutdetailscenterstart} = 'detailscenterstart' if (!defined($data{layoutdetailscenterstart}));
  $data{layoutdetailscenterstop} = 'detailscenterstop' if (!defined($data{layoutdetailscenterstop}));
  $data{layoutdetailsdeletemessage} = 'detailsdeletemessage' if (!defined($data{layoutdetailsdeletemessage}));
  $data{layoutdetailsrowstart} = 'detailsrowstart' if (!defined($data{layoutdetailsrowstart}));
  $data{layoutdetailsrowstop} = 'detailsrowstop' if (!defined($data{layoutdetailsrowstop}));
  $data{layoutdetailskeycolumnstart} = 'detailskeycolumnstart' if (!defined($data{layoutdetailskeycolumnstart}));
  $data{layoutdetailsvalcolumnstart} = 'detailsvalcolumnstart' if (!defined($data{layoutdetailsvalcolumnstart}));
  $data{layoutdetailscolumnstop} = 'detailscolumnstop' if (!defined($data{layoutdetailscolumnstop}));
  $data{layoutdetailsboldstart} = 'detailsboldstart' if (!defined($data{layoutdetailsboldstart}));
  $data{layoutdetailsboldstop} = 'detailsboldstop' if (!defined($data{layoutdetailsboldstop}));
  $data{layoutdetailsrowstop} = 'detailsrowstop' if (!defined($data{layoutdetailsrowstop}));
  $data{layoutdetailsrowstart} = 'detailsrowstart' if (!defined($data{layoutdetailsrowstart}));
  $data{layoutdetailsappendcolumnstart} = 'detailsappendcolumnstart' if (!defined($data{layoutdetailsappendcolumnstart}));

# In case this is a request for a delete form, deal with it by adding a small 
# 'delete' form at the bottom of the table
	my $r = Apache->request;
	if ($r->uri =~ /\/jdeleteform.wsql$/) {
		# The default canceldest is back to where we came from
		$Apache::WeSQL::params{canceldest} ||= $ENV{HTTP_REFERER};
		&Apache::WeSQL::Session::sOverWrite($dbh,"canceldest$Apache::WeSQL::params{view}",operaBugDecode($Apache::WeSQL::params{canceldest}));	# Store the canceldest in the session
		# The default deldest is less sensible than the default canceldest: 
		# the root of the web server. This should really be set on a case by case basis
		$Apache::WeSQL::params{deldest} ||= '/';
		# Store the deldest in the session, if there is none stored there!
		&Apache::WeSQL::Session::sOverWrite($dbh,"deldest$Apache::WeSQL::params{view}",operaBugDecode($Apache::WeSQL::params{deldest}));
	  $data{append} = <<"EOF" 
$layout{$data{layoutdetailscenterstart}}
$layout{$data{layoutdetailsdeletemessage}}
<form action=jdelete.wsql method=get>
<input type=hidden name=$data{key} value="$Apache::WeSQL::params{$data{key}}">
<input type=hidden name=view value="$Apache::WeSQL::params{view}">
<input type=submit name=delete value=Delete>
<input type=submit name=cancel value=Cancel>
</form>
$layout{$data{layoutdetailscenterstop}}
EOF
	}

	$data{recordsperpage} ||= 10;
	&jCheckParams(("$data{key}"));	# Now check the other prerequisites!
	my $dd = localtime();
	$body = <<EOF;
HTTP/1.1 200 OK
Date: $dd
Server: Apache
EOF
	$body .= "$cookieheader\r\n" if (defined($cookieheader) && ($cookieheader ne ''));
	$body .= <<EOF;
Connection: close
Content-type: text/html

EOF
	$body .= $layout{$data{layoutlistheader}};
	$body .= "<title>$data{title}</title>" if (defined($data{title}));
	$body .= $layout{$data{layoutlistbody}};
	$body .= $data{pageheader} if (defined($data{pageheader}));

	# Start the actual table with data!
	$body .= $layout{$data{layoutliststarttable1}};
	$body .= $data{title} if (defined($data{title}));
	$body .= $layout{$data{layoutliststarttable2}};
	if (defined($data{tableheader})) {
		# Check if this is a 'perl;'-style replacement, if so, eval it!
		$data{tableheader} = eval($data{tableheader}) if ($data{tableheader} =~ s/^\n*perl;(.*)/$1/s);
		&Apache::WeSQL::log_error("$$: Display.pm: jDetails: eval error (tableheader): " . $@) if $@;
		$body .= "$data{tableheader}";
	}
	my $dbtype = 0; #MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	# See if the query needs to be built!
	if (defined($data{buildquery})) {
		$data{query} = eval($data{buildquery});
		&Apache::WeSQL::log_error("$$: Display.pm: jDetails: eval error (buildquery): " . $@) if $@;
	}

	my $query = $data{query} . " limit 1";

	# See which columns we are to hide
	my %hide;
	$data{hide} ||= "";
	my @tmp = split(/\,/,$data{hide});
	foreach (@tmp) {
		$hide{$_} = $_;
	}
	
	my $c = &sqlSelectMany($dbh,$query);
	my $colnameref = $c->{NAME_lc};
	my @row = $c->fetchrow_array;

	# Now replace the $columnname occurrences in the %data hash with their proper value
	for (my $cnt=0;$cnt<=$#row;$cnt++) {
		foreach (keys %data) {
			$data{$_} =~ s/\$${$colnameref}[$cnt]/$row[$cnt]/g;
		}
	}

	my $alignkey = "";
	my $alignval = "";
	$alignkey = " align=$data{aligncol}" if (defined($data{aligncol}));
	$alignval = " align=$data{alignval}" if (defined($data{alignval}));

	for (my $cnt=0;$cnt<=$#row;$cnt++) {
		my $colname = ${$colnameref}[$cnt];
		$alignkey = ' align=' . $data{"align.$colname"} if (defined($data{"align.$colname"}));
		$alignval = ' align=' . $data{"align.$colname"} if (defined($data{"align.$colname"}));
		my $value = $row[$cnt];
		# Set $print to 1 if the 'hideifdefault' condition is not met and we should print the record
		my $print = 0;
		$print = 1 if (!defined($data{"hideifdefault.$colname"}) || ($data{"hideifdefault.$colname"} ne $value));
		# See if we need to insert a replacement!
		if (defined($data{"replace.$colname"})) {
			my $tmp = $data{"replace.$colname"};
			# Fill in the value of the column
			$tmp =~ s/\$$colname/$value/g;
			# Check if this is a 'perl;'-style replacement, if so, eval it!
			$tmp = eval($tmp) if ($tmp =~ s/^\n*perl;(.*)/$1/s);
			&Apache::WeSQL::log_error("$$: Display.pm: jDetails: eval error: " . $@) if $@;
			$value = $tmp;
		}
		# Deal with form:select() style lines
		$value = &form_select($dbh,$colname,$value,$row[$cnt],%data);

		

		# And finally add the correct line to the output - if we may!
		if  (!defined($hide{${$colnameref}[$cnt]}) && $print) {
			$colname = $data{"captions.$colname"} if (defined($data{"captions.$colname"}));
      $layout{$data{layoutdetailskeycolumnstart}} =~ s/\$alignkey/$alignkey/g;
      $layout{$data{layoutdetailsvalcolumnstart}} =~ s/\$alignval/$alignval/g;
			$body .= <<"EOF";
$layout{$data{layoutdetailsrowstart}}
$layout{$data{layoutdetailskeycolumnstart}}$layout{$data{layoutdetailsboldstart}}$colname$layout{$data{layoutdetailsboldstop}}$layout{$data{layoutdetailscolumnstop}}
$layout{$data{layoutdetailsvalcolumnstart}}$value$layout{$data{layoutdetailscolumnstop}}
$layout{$data{layoutdetailsrowstop}}
EOF
		}
	}
	$c->finish();

	# Deal with the 'append'
	$data{append} =~ s/\&list\((.*?)\)/&insertList($dbh,$1)/eg;
	if (defined($data{append})) {
		$body .= <<"EOF";
$layout{$data{layoutdetailsrowstart}}
$layout{$data{layoutdetailsappendcolumnstart}}$data{append}$layout{$data{layoutdetailscolumnstop}}
$layout{$data{layoutdetailsrowstop}}
$layout{$data{layoutliststoptable}}
EOF
	}

	# And a page footer!
	$body .= $data{pagefooter} if (defined($data{pagefooter}));
	$body .= $layout{$data{layoutlistfooter}};
	&Apache::WeSQL::log_error("$$: Display.pm: jDetails: success with view '$Apache::WeSQL::params{view}' in " . $r->document_root) if ($Apache::WeSQL::DEBUG);
	return ($body,0);
}

sub insertList {
	my $dbh = shift;
	my $params = shift;
	&Apache::WeSQL::log_error("$$: Display.pm: insertList called with parameters: $params") if ($Apache::WeSQL::DEBUG);
	my %tmpparams;
	my @pairs = split(/&/,$params);
	foreach (@pairs) {
		my ($key,$val) = split(/\=/,$_);
		$tmpparams{$key} = $val;
	}
	undef %Apache::WeSQL::params;
	foreach (keys %tmpparams) {
		$Apache::WeSQL::params{$_} = $tmpparams{$_};
	}
	# I assume the following line was at some point necessary to keep cookies from the main page 
	# 'infecting' the sub-page. We can't, however, have jList run without id,suid and hash cookies,
	# so I've commented the line out. We'll see if there are problems with this... WVW, 2002-05-08
#	undef %Apache::WeSQL::cookies;
	my ($body,$retval) = &jList($dbh,1);
	&Apache::WeSQL::getparams($dbh);
	return ($body);
}


sub select_replacement {
	my ($tmp,$origvalue) = @_;
	my $selectcontent = $1;
	my %pairhash;
	my @pairs = split(/\,/,$selectcontent);
	foreach (@pairs) {
		my @kv = split(/=/,$_);
		$pairhash{$kv[1]} = $kv[0];
	}
	if (defined($pairhash{$origvalue})) {
		$tmp = $pairhash{$origvalue};
	} else {
		$tmp = $origvalue;
	}
}

############################################################
# jList
# This sub can read the 'list.cf' file (for the syntax, see the man page of this module, 
# or the online docs at http://wesql.org), and produce a dynamic list of records
# based on the information from the 'views' file, with the layout specified in the 'layout.cf' file.
############################################################
sub jList {
	my $dbh = shift;
	my $inline = shift;		# Set to 1 if called 'inline', inserted from another view (typically /jdetails)
	my $cookieheader = shift;
	$inline ||= 0;
	my $body;
	my %layout = &Apache::WeSQL::readLayoutFile("layout.cf");
	&jCheckParams(('view'));	# Check that there is a 'view' parameter
	my %data = &readConfigFile("list.cf",$Apache::WeSQL::params{view});

	$data{recordsperpage} ||= 10;
	my $dd = localtime();

	$data{layoutlistheader} = 'listheader' if (!defined($data{layoutlistheader}));
	$data{layoutlistbody} = 'listbody' if (!defined($data{layoutlistbody}));
	$data{layoutliststarttable1} = 'liststarttable1' if (!defined($data{layoutliststarttable1}));
	$data{layoutliststarttable2} = 'liststarttable2' if (!defined($data{layoutliststarttable2}));
	$data{layoutliststoptable} = 'liststoptable' if (!defined($data{layoutliststoptable}));
	$data{layoutlistfooter} = 'listfooter' if (!defined($data{layoutlistfooter}));
	$data{layoutlistrowstart} = 'listrowstart' if (!defined($data{layoutlistrowstart}));
	$data{layoutlistrowstop} = 'listrowstop' if (!defined($data{layoutlistrowstop}));
	$data{layoutlistcolumnstart} = 'listcolumnstart' if (!defined($data{layoutlistcolumnstart}));
	$data{layoutlistcolumnstop} = 'listcolumnstop' if (!defined($data{layoutlistcolumnstop}));
	$data{layoutlistappendstart} = 'listappendstart' if (!defined($data{layoutlistappendstart}));
	$data{layoutlistappendnoresultsstart} = 'listappendnoresultsstart' if (!defined($data{layoutlistappendnoresultsstart}));

	if (!$inline) {
		$body = <<EOF;
HTTP/1.1 200 OK
Date: $dd
Server: Apache
EOF
		$body .= "$cookieheader\r\n" if (defined($cookieheader) && ($cookieheader ne ''));
		$body .= <<EOF;
Connection: close
Content-type: text/html

EOF
		$body .= $layout{$data{layoutlistheader}};
		$body .= "<title>$data{title}</title>" if (defined($data{title}));
		$body .= $layout{$data{layoutlistbody}};
		$body .= $data{pageheader} if (defined($data{pageheader}));
	}

	# Start the actual table with data!
	$body .= $layout{$data{layoutliststarttable1}};
	$body .= $data{title} if (defined($data{title}));
	$body .= $layout{$data{layoutliststarttable2}};
	$body .= "$data{tableheader}" if (defined($data{tableheader}));

	my $dbtype = 0; #MySQL
	$dbtype = 1 if (${$dbh}->{Driver}->{Name} =~ /^Pg/);

	# See if the query needs to be built!
	if (defined($data{buildquery})) {
		$data{query} = eval($data{buildquery});
		&Apache::WeSQL::log_error("$$: Display.pm: jList: eval error (buildquery): " . $@) if $@;
	}

	# Determine the LIMIT string (number of records to show per page)
	my $limitstr = "";

	# Get the most recent 'from' value from the session data - and store the current one there!
	if (!defined($Apache::WeSQL::params{from})) {
		$Apache::WeSQL::params{from} = &Apache::WeSQL::Session::sRead($dbh,"listfrom$Apache::WeSQL::params{view}");
		$Apache::WeSQL::params{from} = 0 if (!defined($Apache::WeSQL::params{from}));
	}
	&Apache::WeSQL::Session::sOverWrite($dbh,"listfrom$Apache::WeSQL::params{view}",$Apache::WeSQL::params{from});

  if ($dbtype == 0) { #MySQL
    $limitstr = " LIMIT " . $Apache::WeSQL::params{from} . "," . $data{recordsperpage} if (!($data{query} =~ /\s+LIMIT\s+/i));
  } else { #PostgreSQL
    $limitstr = " LIMIT " . $data{recordsperpage} . "," . $Apache::WeSQL::params{from} if (!($data{query} =~ /\s+LIMIT\s+/i));
  }
	# Count how many records would have been returned without the LIMIT
	my $tmp = $data{query};
	$tmp =~ s/\s+LIMIT\s+[\d\,]*//i;		# First get rid of any LIMIT parts in the original query
	$tmp =~ s/\s+ORDER BY\s+[^\s]*//i;	# Also get rid of any ORDER BY parts in the original query
	$tmp =~ s/select (.*?) from/select count(*) from/i;
	my @count = &sqlSelect($dbh,$tmp);

	# See which columns we are to hide
	my %hide;
	$data{hide} ||= "";
	my @tmp = split(/\,/,$data{hide});
	foreach (@tmp) {
		$hide{$_} = $_;
	}

	my $c = &sqlSelectMany($dbh,$data{query} . $limitstr);
	my $colnameref = $c->{NAME_lc};
	my (@align,@replace);
	my $cnt = 0;
	my $visiblecols = 0;
	$body .= $layout{$data{layoutlistrowstart}};
	foreach (@{$colnameref}) {
		my ($colname) = ($_);
		# First do the alignment
		$align[$cnt] = '';
		$align[$cnt] = ' align=' . $data{"align.$colname"} if (defined($data{"align.$colname"}));
		my $layoutlistcolumnstart = $layout{$data{layoutlistcolumnstart}};
		# Initialize replacements
		$replace[$cnt] = '';
		$replace[$cnt] = $data{"replace.$colname"} if (defined($data{"replace.$colname"}));
		# Now see if there is a caption for this column
		my $caption = '';
		$caption = $data{"captions.$colname"} if (defined($data{"captions.$colname"}));
		# Write column headers, but only if there are results!
		$layoutlistcolumnstart =~ s/\$align\[\$cnt\]/$align[$cnt]/;
		if (($count[0] > 0) && !defined($hide{$colname}) && ($caption ne '')) {
			$body .= <<"EOF";
$layoutlistcolumnstart
<b>$caption</b>
$layout{$data{layoutlistcolumnstop}}
EOF
		}
		$cnt++;
		$visiblecols += 1 if (!defined($hide{$colname}));
	}
	$body .= $layout{$data{layoutlistrowstop}} . "\n";
	while(my $rowref=$c->fetchrow_arrayref()) { 
		$body .= $layout{$data{layoutlistrowstart}} . "\n";
		for (my $cnt=0;$cnt<=$#{$rowref};$cnt++) {
			my $layoutlistcolumnstart = $layout{$data{layoutlistcolumnstart}};
			# Deal with form:select() style lines
			${$rowref}[$cnt] = &form_select($dbh,${$colnameref}[$cnt],${$rowref}[$cnt],${$rowref}[$cnt],%data);

			# Deal with replacements
			if ($replace[$cnt] ne "") {
				my $tmp = $replace[$cnt];
				# Fill in the value of the column(s)
				for (my $cnt2=0;$cnt2<=$#{$rowref};$cnt2++) {
					$tmp =~ s/\$${$colnameref}[$cnt2]/${$rowref}[$cnt2]/g;
				}
				# Check if this is a 'perl;'-style replacement, if so, eval it!
				$tmp = eval($tmp) if ($tmp =~ s/^\n*perl;(.*)/$1/s);
				&Apache::WeSQL::log_error("$$: Display.pm: jList: eval error: " . $@) if $@;  
				${$rowref}[$cnt] = $tmp;
			}

			$layoutlistcolumnstart =~ s/\$align\[\$cnt\]/$align[$cnt]/;
			$body .= $layoutlistcolumnstart . ${$rowref}[$cnt] . $layout{$data{layoutlistcolumnstop}} . "\n" if (!defined($hide{${$colnameref}[$cnt]}));
		}
		$body .= $layout{$data{layoutlistrowstop}} . "\n";
	}
	$c->finish();

	# Deal with the 'appendresults' and 'appendnoresults' tags
	if ($count[0] > 0) {	# There were results
		$layout{$data{layoutlistappendstart}} =~ s/\$visiblecols/$visiblecols/;
		if (defined($data{appendresults})) {
			# First check for 'perl;'-style appends, if so, eval them!
			$data{appendresults} = eval($data{appendresults}) if ($data{appendresults} =~ s/^\n*perl;(.*)/$1/s);
			&Apache::WeSQL::log_error("$$: Display.pm: jList: eval error: " . $@) if $@;  
			$body .= $layout{$data{layoutlistappendstart}} . $data{appendresults} . $layout{$data{layoutlistcolumnstop}} . $layout{$data{layoutlistrowstop}};
		}
	} else {
		if (defined($data{appendnoresults})) {
			# First check for 'perl;'-style appends, if so, eval them!
			$data{appendnoresults} = eval($data{appendnoresults}) if ($data{appendnoresults} =~ s/^\n*perl;(.*)/$1/s);
			&Apache::WeSQL::log_error("$$: Display.pm: jList: eval error: " . $@) if $@;  
			$body .= $layout{$data{layoutlistappendnoresultsstart}} . $data{appendnoresults} . $layout{$data{layoutlistcolumnstop}} . $layout{$data{layoutlistrowstop}};
		} else {
			$body .= $layout{$data{layoutlistappendnoresultsstart}} . 'No results!' . $layout{$data{layoutlistcolumnstop}} . $layout{$data{layoutlistrowstop}};
		}
	}
	# Deal with the 'append'
	if (defined($data{append})) {
		$layout{$data{layoutlistappendstart}} =~ s/\$visiblecols/$visiblecols/;
		# First check for 'perl;'-style appends, if so, eval them!
		$data{append} = eval($data{append}) if ($data{append} =~ s/^\n*perl;(.*)/$1/s);
		&Apache::WeSQL::log_error("$$: Display.pm: jList: eval error: " . $@) if $@;  
		$body .= $layout{$data{layoutlistappendstart}} . $data{append} . $layout{$data{layoutlistcolumnstop}} . $layout{$data{layoutlistrowstop}};
	}

	$body .= $layout{$data{layoutliststoptable}};

	# Now write the previous/next links if necessary
	my $r = Apache->request;
	$body .= '<center>';
	my $previousargs = $r->args;
	$previousargs .= "&from=" . ($Apache::WeSQL::params{from} - $data{recordsperpage}) 
		if (!($previousargs =~ s/from=(\d*)/"from=" . ($Apache::WeSQL::params{from} - $data{recordsperpage})/e));
	my $nextargs = $r->args;
	$nextargs .= "&from=" . ($Apache::WeSQL::params{from} + $data{recordsperpage}) 
		if (!($nextargs =~ s/from=(\d*)/"from=" . ($Apache::WeSQL::params{from} + $data{recordsperpage})/e));
	$body .= "| <a href=" . $r->uri . "?$previousargs>Previous</a> |\n" 
		if ($Apache::WeSQL::params{from} > 0);
	# Print a separator, but only if we there are going to be 'previous' and 'next' links
	$body .= "| " if (($Apache::WeSQL::params{from} <= 0) && ($count[0] > $data{recordsperpage}));
	$body .= "<a href=" . $r->uri . "?$nextargs>Next</a> |\n" 
		if ($count[0] > ($Apache::WeSQL::params{from} + $data{recordsperpage}));
	$body .= '</center>';

	if (!$inline) {
		# And a page footer!
		$body .= $data{pagefooter} if (defined($data{pagefooter}));
		$body .= $layout{$data{layoutlistfooter}};
	}
	&Apache::WeSQL::log_error("$$: Display.pm: jList: success with view '$Apache::WeSQL::params{view}' in " . $r->document_root) if ($Apache::WeSQL::DEBUG);
	return ($body,0);
}

1;
__END__

=head1 NAME

Apache::WeSQL::Display - A library of functions to create web-pages based on a 'Journalled' SQL database.

=head1 SYNOPSIS

  use Apache::WeSQL::Display qw( :all );

=head1 DESCRIPTION

This module contains the functions necessary to deal with the jform.wsql, jdetails.wsql, and jlist.wsql web calls.
These calls read their configuration from the form.cf, details.cf, and list.cf files. Also, they use
certain (see LAYOUT.CF below to know which) entries from the layout.cf file for the layout. 
The structure of the .cf files is outlined below.

=head1 .CF FILES

=head2 STRUCTURE

The '.cf' files (except for layout.cf, see below) have the following syntax:

=over 4

 <view-name>
 <key>:<value>
   <value_line2>
 <key>:<value>
   <value_line2>
   <value_line3>
 ...


 <view-name>
 <key>:<value>
 ...

Multi-line values are allowed as long as the extra lines begin with whitespace. Of course they can not be all whitespace, or they would be seen as a view separator!

=head2 PLACEHOLDERS

In all values, several placeholders will be replaced by their respective value:

You can use the %params hash to refer to the cgi parameters passed to the script. For instance:
$params{id} will be replaced by the value of the cgi parameter 'id'.

You can use the %cookies hash to refer to the cookies passed to the script. For instance:
$cookies{id} will be replaced by the value of the cookie 'id'.

For the details.cf and forms.cf files (respectively used by jdetails.wsql and jform.wsql), you can also use
the name of the columns are returned by the 'query' tag, prepended with a dollar sign, to represent
the values of the record. For instance:

=over 4

=item
query:select id,firstname,lastname,birthday,mobile from people where $data{key}=$params{$data{key}} and status='1'

=item
appendedit:<center><a href=jdetails.wsql?id=$id&view=person&redirect=>Details</a></center>

=back

With this query, in the 'appendedit' tag, $id will be replaced by the value of the column id in the table people. Also note the use of the %params and %data replacements in the query. Note that the %data placeholder is replaced first, followed by the %params placeholder, and finally the column placeholders. This means that you can do something like $params{$data{key}} in the query above, but something like $data{$params{key}} will not work.

Please note that it is also possible to provide a 'default' value, for when the parameter/cookie/column is not defined:

query:select id,firstname,lastname,birthday from people where status='1' and id like [$params{id}|'%'] order by lastname

The [$params{id}|'%'] syntax will be evaluated to the cgi parameter id if defined, and if not, to '%'. Consider this example:

query:select id,firstname,lastname,birthday from people where status='1' and firstname like '%[$params{firstname}%|]' order by lastname

The '%[$params{id}%|]' will be evaluated to '%ward%' if there is a parameter firstname with value ward. Otherwise, it will be evaluated to '%'. So you can put other things around the $params{something} in the first part of the condition.

Or consider this:

query:select id,firstname,lastname,birthday from people where status='1' [and id like '$params{id}'|] order by lastname

This query is more efficient because the whole 'and' part will not be displayed if the parameter is not defined! Note the compulsary pipe symbol (|), used for specifying an optional alternative value. It also will reduce the chance of an accidental match of something in right brackets.

Finally, you can have the value of $params{something} url-encoded, by simply replacing it with encode($params{something}) in any of the above examples. This encoding is even safe for use with Opera 5.05 for Linux, which contains an url-decoding bug.

Similarly, you can have the value of $params{something} url-decoded, by simply replacing it with decode($params{something}) in any of the above examples. This decoding is even safe for use with Opera 5.05 for Linux, which contains an url-decoding bug.

=head2 KEYS

Here is a list of possible keys for the .cf files:

=over 4

=head2 title (details.cf, form.cf, list.cf)

The title of the page, as it will appear in the html of the page between the <title> and </title> tags in the header, and also somewhere near the top of the page (depends on the layout). Don't put html tags in 'title', because these will not be rendered within the <title> tags in the header of the document. Use the layout file instead if you want to control how to display the title on the page.

=item
Example:

=item
title:All users

=back

=head2 query (details.cf, form.cf, list.cf)

The sql select query that determines the columns that will be displayed on the page.

=over 4

=item
Example:

=item
query:select * from users where status='1'

=back

=head2 buildquery (details.cf, form.cf, list.cf)

The buildquery key takes a perl expression as its value, that should evaluate to a proper sql query. When specifying this key, the query key (if defined) will be overwritten by the output of the eval of the buildquery key.

=over 4

=item
Example:

=item
buildquery:
  my $query="select p.id,p.title,p.startdate,p.stopdate,p.url,p.private from tbl_projects as p, tbl_projectkeywords as k" .
            " where p.status='1' and k.status='1' and k.projectid=p.id ";
  my @keywords = ();
  @keywords = split(/\|/,'$params{keyword}') if defined('$params{keyword}');
  my $defined = 0;
  foreach (@keywords) {
    if (!$defined) {
      $query .= 'and (';
      $defined = 1;
    }
    $query .= "(k.keywordid = '$_') or "
  }
  if ($defined) {
    chop($query); chop($query); chop($query); chop($query);
    $query .= ')';
  }
  $query .= ' group by p.id order by title';
  return $query;

This block of code will generate a proper query from a form that returns multiple keyword parameters. Note the multiline value for the key (extra lines need to start with whitespace!)

=back

=head2 captions (details.cf, form.cf, list.cf)

Determines the captions of the table columns.

syntax: captions:<colname>=<value>|<colname>=<value>|...

<colname> is the name of a column returned from the sql-select querey, as returned by the database. The value can be anything and may contain any character except a pipe (|). Columns without a 'captions' entry will have the name the database returns for them as caption in the page.

=over 4

=item
Example:

=item
captions:uid=User|epoch=Epoch|status=Status|pid=Pid|login=Login

=back

=head2 align (details.cf, form.cf, list.cf)

Allows aligning columns in a specific way.

syntax: align:<colname>=<value>|<colname>=<value>|...

<colname> is the name of a column returned from the sql-select querey, as returned by the database. The value can be 'left', 'right', or 'center'. By default there is no specific alignment (which in most browsers will show as a left alignment).

=over 4

=item
Example:

=item
align:uid=right|status=center

=back

=head2 alignkey,alignval (details.cf)

Allows aligning the 'name' and the 'value' column in a specific way. 
Note that for setting the alignment of specific lines of the output, you can use the 'align' parameter as described higher.

syntax: alignkey:<value>
syntax: alignval:<value>

<value> can be 'left', 'right', or 'center'. Default there is no specific alignment (which in most browsers will show as a left alignment).

=over 4

=item
Example:

=item
alignkey:center
alignval:right

=back


=head2 replace (details.cf, form.cf, list.cf)

Allows the value of a column in a record with something else, for instance a hyperlink.

syntax: replace:<colname>=<value> OR replace:<colname>=perl;<perlvalue>

<colname> is the name of a column returned from the sql-select querey, as returned by the database.
<value> or <perlvalue> can contain $<colname>, which will be translated into the value of the column. 

The first variant assumes <value> is html, and will insert <value> into the html, after translating $<colname> into it's value.

=over 4

=item
Example:

=item
replace:status=<a href="/?status=$status">A link to somewhere</a>

=back

The second variant recognises the 'perl;', and assumes <perlvalue> is perl code. First, any $<colname> occurences are translated into their value, and then <perlvalue> is eval'd, and the output is appended to the html. This means that you have to 'return' whatever you want to see in the html.

=over 4

=item
Example:

=item
replace:epoch=perl;return(strftime "%Y.%m.%e %H:%M:%S", localtime($epoch));

=back

=head2 pageheader (details.cf, form.cf, list.cf)

Allows a view-specific header. Expects pure html as its value.

=over 4

=item
Example:

=item
pageheader:<center>some view-specific header</center><br>

=back

=head2 pagefooter (details.cf, form.cf, list.cf)

Allows a view-specific footer. Expects pure html as its value.

=over 4

=item
Example:

=item
pagefooter:<center>some view-specific footer</center><br>

=back

=head2 editdest (form.cf)

Provides a default 'editdest' for a view. That is the destination the user will be redirected to after (s)he clicks on the button.

=over 4

=item
Example:

=item
editdest:index.wsql

=back

=head2 recordsperpage (list.cf)

Controls how many records are shown per page (with the rest being accessible through an automatically generated system of 'next' and 'previous' links). Default: 10.

=over 4

=item
Example:

=item
recordsperpage:12

=back

=head2 append (details.cf, form.cf, list.cf)

Some text to add to the page. See also append(no)results (list.cf) and appendedit/appendnew (form.cf)

=over 4

=item
Example:

=item
append:<center>some text to add</center>

=back

=head2 appendnoresults (list.cf)

Some text to add to the page if the query returns no results.

=over 4

=item
Example:

=item
appendnoresults:<center>some text to add if there are NO results</center>

=back

=head2 appendresults (list.cf)

Some text to add to the page if the query returns results.

=over 4

=item
Example:

=item
appendresults:<center>some text to add if there are results</center>

=back

=head2 hideifdefault (details.cf)

Columns to hide in the listing, if they match a default value.

syntax: hideifdefault:<colname>=<defaultvalue>

<colname> is the name of a column returned from the sql-select querey, as returned by the database.
<defaultvalue> is the default value that, if matched, will prevent the column from being printed.

=over 4

=item
Example:

=item
hideifdefault:url=

=item
hideifdefault:publishdate=0

=back

=head2 hide (details.cf, list.cf)

Columns to hide in the listing.

=over 4

=item
Example:

=item
hide:id

=back

=head2 key (details.cf, form.cf)

Determines the name of the column containing the unique identifier for each record in the table.

=over 4

=item
Example:

=item
key:id

=back

=head2 form (form.cf and for form:select also details.cf and list.cf)

Allows to set the form element. The default type for each column is 'textbox'. Other options 
include 'hidden', 'password', 'select', 'textarea', 'onlyshow' and 'showandhidden'. The first four of these
options are standard html form elements. 'onlyshow' will not make a form element but only display
the value of the column in the table. 'showandhidden' is basically a non-editable field in the
table: the value is show, but there is also a hidden form element that will assure that it is
passed to the form action script.

The 'textarea' form element has some extra possible syntax. In it's simplest form, it looks like this:

form:status=textarea()

Which will result in the following html:

<textarea name=status>value_of_status</textarea>

However, between the two brackets you may supply options that will be inserted in the textarea tag, like this:

form:status=textarea(cols=50 rows=10 break=hard)

This would result in:

<textarea name=status cols=50 rows=10 break=hard>value_of_status</textarea>

The 'select' form element is a special one. You can select a limited number of options like this:

form:status=select(Yes=1,No=0)

or rather use an sql query to supply the options, like this:

form:peopleid=select(select id,firstname,lastname from people where status='1';id=peopleid;value=#id;show=#firstname #lastname)

As you can see, there are 4 paramaters between the select brackets. They are separated by semicolons. The first one is the sql-query (which has to start with 'select '!). The second parameter indicates which column from the query corresponds to the value of the form element. This is used to select the correct value in the dropdown list by default. The third parameter is what will be used as the 'value' of the select option tag. Note that you can refer to values of the query by preceding their name with a hash (#). The last parameter is what will be shown on the screen in the dropdown box. In this case, two columns are combined. 

You can put more than one select() statement in such a form: line, like this (new from v0.51):

form:peopleid=select(John Miles=12,Larry Wall=13);select(select id,firstname,lastname from people where status='1';id=peopleid;value=#id;show=#firstname #lastname)

This will result in 2 fixed people in the list, followed by whoever is stored in the database.

Note that since version 0.52, the 'select' form element is also the only form: element that will be recognised in details.cf and list.cf, with identical syntax. Obviously, the output on the web page will not be a form element but rather only the right value from the select statement.

Also since version 0.52, you can now use the [something #firstname|alternate value] syntax in the 'show' part of a select statement. This works very similar to the syntax you're familiar with from the PR_ and COOKIE_ style parameters. The only difference is that 'alternate value' will be displayed if #firstname would be undefined or equal the empty string, unlike for PR_ and COOKIE_ style parameters, where the alternate value will only be displayed if the parameter is not defined.

=back

=head2 tableheader (details.cf, list.cf, form.cf)

Allows a view-specific page header. Expects pure html as its value.

=over 4

=item
Example:

=item
tableheader:<tr><td colspan=2><center>some view-specific table header</center></td></tr>

=back

=head2 appendnew, appendedit (form.cf)

Some text that will be added, depending on whether this is an edit of a record, or rather the
addition of a new record.

=over 4

=item
Example:

=item
appendnew:<center>some text to add if this is a NEW record</center>

=item
appendedit:<center>some text to add if this is an EDIT </center>

=back

=head2 table (permissions.cf)

The table the view applies to.

=over 4

=item
Example:

=item
table:people

=back

=head2 add (permissions.cf)

The 'add' key determines whether journalled adds are allowed. Possible values: 'yes' and 'no'.

=over 4

=item
Example:

=item
add:yes

=back

=head2 delete (permissions.cf)

The 'delete' key determines whether journalled deletes are allowed. Possible values: 'yes' and 'no'.

=over 4

=item
Example:

=item
delete:yes

=back

=head2 update (permissions.cf)

The 'update' key determines whether journalled updates are allowed, on a column by column basis.
The value of the key is a comma-separated list of columns that may be updated. Updates to columns
that are not in this list will simply be ignored (with an appropriate warning in the logs!).

=over 4

=item
Example:

=item
update:firstname,lastname,mobile,birthday,email,im

=back

=head2 validate (permissions.cf)

The 'validate' key has a perl expression that can be evaluated to a 1 or 0 as its value.
If the expression evaluates to 0, the operation (add or update) will be cancelled, and the
matchin 'validatetext' (see below) will be displayed. Note that 'validate' doesn't apply to
delete actions.

=over 4

=item
Example:

=item
validate:'$params{birthday}'=~/^\d{2,4}.\d{1,2}.\d{1,2}$/

=back

=head2 validatetext (permissions.cf)

The 'validatetext' key holds the message corresponding to a validate expression. 
Validatetext and validate should aways be defined in pairs.

=over 4

=item
Example:

=item
validatetext:<font color=#FF0000>A valid date has the format yyyy.mm.dd, for instance 1970.01.01!</font><br>

=back

=head2 validateifcondition (permissions.cf)

The 'validateifcondition' key holds a perl expression that can be evaluated to a 1 or 0 as its value.
If the expression evaluates to 1, the corresponding 'validateif' key will be evaluated. If it is 0,
it will be ignored.

=over 4

=item
Example:

=item
validateifcondition:!('$params{mobile}' =~ /^$/)

=back

=head2 validateif (permissions.cf)

The 'validateif' key holds a perl expression that can be evaluated to a 1 or 0 as its value.
If the expression evaluates to 0, the operation (add or update) will be cancelled, and the
matchin 'validateiftext' (see below) will be displayed. Note that 'validateif' doesn't apply to
delete actions, and that it will only be tested if the corresponding 'validateifcondition' 
evaluates to 1.

=over 4

=item
Example:

=item
validateif:'$params{mobile}' =~ /^\+[\d\s]+/

=back

=head2 validateiftext (permissions.cf)

The 'validateiftext' key holds the message corresponding to a 'validateif' expression. 
This message will be displayed if the 'validateif' condition is not met.
Validateiftext, validateif and validateifcondition should aways be defined in threesomes.

=over 4

=item
Example:

=item
validateiftext:<font color=#FF0000>If the 'mobile' field is not empty, it must start with a '+' sign and consist only of digits and spaces!</font><br>

=back

=head2 sqlcondition (permissions.cf)

The 'sqlcondition' key allows definition of an sql condition. Its value contains 4 parts, separated
by a pipe symbol. The first part defines when the condition is to be met. It can be 'add', 'update',
or a combination of the two, like 'addupdate'. The second part is a standard sql query.
The third part is an operator. Possible values are all perl operators, for instance the numeric 
equality operator '=='. The fourth part is the value of the second part of the condition. Use
quotes for strings.

=over 4

=item
Example:

=item
sqlcondition:add|select count(*) from people where firstname='$params{firstname}' and lastname='$params{lastname}' and status='1'|==|0

=back

=head2 sqlconditiontext (permissions.cf)

The 'sqlconditiontext' key holds the message corresponding to a 'sqlcondition' expression. 
This message will be displayed if the 'sqlcondition' condition is not met.
Sqlconditiontext and sqlcondition should aways be defined in pairs.

=over 4

=item
Example:

=item
sqlconditiontext:<font color=#FF0000>This person ($params{firstname} $params{lastname}) is already defined!</font><br>

=back

=head2 preprocess (permissions.cf)

The 'preprocess' key holds a block of perl that will be executed _before_ the insertion of a record in the database by 
jAdd or jUpdate. It takes three arguments: the name of a database column, a parameter describing when to execute this code
(add, update, or addupdate), and a block of perl. This is the syntax:

preprocess:<colname>=<whentoexecute>|perl;<perlcode>

Of course <perlcode> may occupy multiple lines, as long as these lines start with whitespace and as long as there are no empty
lines in between the perl code.

The perl code needs to return a value that will replace the value for the column specified.

=over 4

Example:

 preprocess:price=add|perl;
   return '$params{price}' if ('$params{price}' ne '');
   my @res = &Apache::WeSQL::sqlSelect($dbh,"select price from tbl_productprices where id='$params{productpriceid}' and status='1'");
   return $res[0];

=head1 LAYOUT.CF

The 'layout.cf' file has the following structure:

=over 4

=item
<key-name>

=item
<some html, multi line>


=item
<key-name>

=item
<more html, multi line>


=item
...

=back

Optionally, the first line looks like: 

  inherit:<path-to-another-layout-file>

This line must be followed by an empty line. It will include all tags 
in the other layout file specified, and then process the ones defined in this
file, possibly overriding already defined tags.

Limitation: 

1. Nesting is limited to 10 levels, to prevent circular references.
2. The specified path is relative to the URI of the request for the original html page!


Example:

=over 4

=item
listheader

=item
<html>

=item
<head>

=item
listbody

=item
</head>

=item
<body bgcolor=#FFFFFF>

=back

jForm, the sub that deals with jform.wsql calls, jList (jlist.wsql), and jDetails (jdetails.wsql) 
uses the following layout keys:
listheader, listbody, liststarttable1, liststarttable2, liststoptable and listfooter

jLoginForm, the sub that displays the jloginform.wsql page, includes a reference to the 'publiclogon' layout key.
By default, this key has the following value:

    publiclogon
    <tr><td><b>Login</b></td><td align=right><b>Password</b></td><td align=right><b>Superuser</b></td></tr>
    <!-- LIST A select login, password, superuser from users where status='1' -->
    <tr><td>A_LOGIN</td><td align=right>A_PASSWORD</td><td align=right><!-- EVAL POST if ('A_SUPERUSER' eq 1) { return "Yes"; } else { return "No"; } --></td></tr>
    <!-- /LIST A -->

It displays a list of all valid login/password combinations for the sample application. I imagine you will
want to change the value of this layout tag if you want to build a real-world system that requires logins!

If you want to do away with this key, just define it in the layout.cf file and give it a value of a single space. You can also remove it from the layout.cf file, but then you will see ugly "Use of uninitialized value in concatenation (.) or string at /usr/local/lib/perl5/site_perl/5.6.1/Apache/WeSQL/Auth.pm line 157." in the log of your webserver.

WeSQL.pm exports a sub called readLayoutFile, which returns a hash with all the layout
elements. Also, you can use <!-- LAYOUT TAG --> style tags in your .wsql files, where
TAG is the name of the key from the layout file that you want to include in a wsql file.

This module is part of the WeSQL package, version 0.53

(c) 2000-2002 by Ward Vandewege

=head1 EXPORT

None by default. Possible: jForm jDetails jList

=head1 AUTHOR

Ward Vandewege, E<lt>ward@pong.beE<gt>

=head1 SEE ALSO

L<Apache::WeSQL::Journalled>, L<Apache::WeSQL>, L<Apache::WeSQL::SqlFunc>, L<Apache::WeSQL::AppHandler>

=cut
