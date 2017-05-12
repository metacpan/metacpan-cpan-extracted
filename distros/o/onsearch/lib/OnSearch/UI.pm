package OnSearch::UI; 

#$Id: UI.pm,v 1.26 2005/08/16 05:34:03 kiesling Exp $

use strict;
use warnings;
use Carp;
use Socket;
use Storable qw/fd_retrieve/;
use Fcntl qw(:DEFAULT :flock);

use OnSearch;
use OnSearch::Utils;
use PerlIO::OnSearchIO;

my $VERSION='$Revision: 1.26 $';

require Exporter;
require DynaLoader;
my (@ISA, @EXPORT_OK);
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = (qw/DESTROY/);

###
### Some character entity constants.
###
my $GT_ent = '&gt;';
my $LT_ent = '&lt;';

=head1 NAME

OnSearch::UI.pm - User interface library for OnSearch.

=head1 DESCRIPTION

OnSearch::UI provides an object oriented user interface for the
OnSearch search engine and page templates for the application's
dynamic HTML content.

=head1 EXPORTS

=head2 DESTROY (I<objectref>)

Perl calls DESTROY when deleting unused OnSearch::UI objects.

=head1 METHODS

The UI.pm methods are listed and described below.

=cut

###
### These are the three basic types of matches.  See the comments 
### in Search.pm.
###
my @matchtypes = (qw/any all exact/);

=head2 $ui -> parbreak ();

Template for a paragraph break.

  $ui -> parbreak -> wprint;

=cut

sub parbreak {
    my $self = shift;
    $self -> {text} = '<p>';
    return $self;
}

=head2 $ui -> input_form (I<search_preferences>, I<volume_preferences>);

OnSearch search page template.  The arguments are hash references 
of user preferences.

=cut

sub input_form {
    my $self = shift;
    my $prefs = $_[0];
    my $vol_prefs = $_[1];

    my ($case_opt, $nocase_opt, $matchany_opt, $matchall_opt, 
	$partword_opt,$matchexact_opt, $completeword_opt, $pagesize_opt,
	%dfmatch, $nresults_opt, %volumes, $OnSearchDir);

    $case_opt = $nocase_opt = '';
    $matchany_opt = $matchall_opt = $matchexact_opt = '';
    $partword_opt = $completeword_opt = '';

    my $c = OnSearch::AppConfig -> new;

    %volumes = $c -> Volumes;
    $OnSearchDir = $c -> str (qw/OnSearchDir/);
    $self -> volume_info (\%volumes, $vol_prefs);
    my $volinfo = $self -> {text};

    if ($prefs !~ /defaults|none/) {
	my %prefs = $c->parse_prefs ($prefs);

	(($prefs{matchcase} =~ /yes/) ? $case_opt = 'checked' :
	 $nocase_opt = 'checked');

	$partword_opt = ($prefs{partword} =~ /yes/) ? 'checked' : '';
	$completeword_opt = ($prefs{partword} =~ /no/) ? 'checked' : '';

	foreach (@matchtypes) {
	    $dfmatch{$_} = (m"$prefs{matchtype}" ? 'checked' : ''); 
	}

	$pagesize_opt = $prefs{pagesize};
	$nresults_opt = $prefs{nresults};

    } else {
	###
	### These are the default search options.
	###
	$case_opt = 'checked';
	$dfmatch{$_} = '' foreach (@matchtypes);
	$dfmatch{any} = 'checked';
	$completeword_opt = 'checked';
	$pagesize_opt = $c->str ('PageSize');
	$nresults_opt = $c->str ('ResultsPerFile');
    }

$self -> {text} =<<END_OF_INPUT_FORM;
<form name="inputform" action="search.cgi">
<table width="100%">
  <tr align="center">
    <td>
          <table>
            <tr>
              <td valign="top">
	      <b>Enter a word or phrase to search for.</b><br>
                <label>
                    A search phrase can be any word or<br>combination of words.
                </label><br>
                <input type="text" name="searchterm" size="40"><br>
                <input type="image" name="submit" src="/$OnSearchDir/images/searchbutton.jpg">
		<p>
		$volinfo
              </td>
              <td rowspan="3" valign="top">
                <table>

                  <tr>
                    <td colspan="3">
                      <label><b>Search Options</b></label><br>
                    </td>
                  </td>
                  </tr>
                  <tr>
                    <td>
                      <input type="radio" name="matchcase" value="no" $nocase_opt>
                    </td>
                    <td>
                      <label>Match upper or lower case.</label>
                    </td>
		    <td rowspan="8">
                      <div>
                        <label>
                        <a href="doc/userguide.html#searchingtext" target="_blank">
                        Information about search<br>terms and options.</a>
                        </label>
                     </div>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <input type="radio" name="matchcase" value="yes" $case_opt>
                    </td>
                    <td>
                      <label>Match upper and lower case exactly.</label>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <input type="radio" name="partword" value="yes" $partword_opt>
                    </td>
                    <td>
                      <label>Match text within words.</label>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <input type="radio" name="partword" value="no" $completeword_opt>
                    </td>
                    <td>
                      <label>Match complete words only.</label>
                    </td>
                  </tr>

                  <tr>
                    <td colspan="2">
                      <label><b>Match documents that contain:</b></label>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <input type="radio" name="matchtype" value="all" $dfmatch{all}>
                    </td>
                    <td>
                      <label>All words.</label>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <input type="radio" name="matchtype" value="any" $dfmatch{any}>
                    </td>
                    <td>
                      <label>Any word.</label>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <input type="radio" name="matchtype" value="exact" $dfmatch{exact}>
                    </td>
                    <td>
                      <label>The exact word or phrase.</label>
                    </td>
                  </tr>
                  <tr>
                    <td colspan="2">
                      <label><b>Display Options</b></label>
                    </td>
		  </tr>
		  <tr>
		    <td colspan="2">
		        <label>Display&nbsp;</label>
			<input type="text" name="pagesize" size="3" value="$pagesize_opt">
                        <label>&nbsp;results on each page.</label>
                    </td>
		  </tr>
		  <tr>
		    <td colspan="2">
		        <label>Display&nbsp;</label>
			<input type="text" name="nresults" size="3" value="$nresults_opt">
                        <label>&nbsp;results for each matching file.</label>
                    </td>
		  </tr>
              </table>
            </td>
          </tr>
        </table>
    </div>
  </td>
</tr>
</table>
</form>
END_OF_INPUT_FORM
return $self;
}

=head2 $ui -> process_error (I<message>);

User warning template. When called from OnSearch::browser_warn(), also
logs the message.

    $ui -> process_error ($message) -> wprint;

=cut

sub process_error {
    my $self = $_[0];
    my $msg = $_[1];
    $self -> {text} = qq{
<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>OnSearch Error</title>
<LINK rel="stylesheet" href="styles.css" type="text/css">
</head>
<body>
<hr noshade size="1">
<h2><font class="onsearch">OnSearch Error</font></h2>
<font size="3">
OnSearch encountered the following error:
<p>
<tt>$msg</tt>
<p>
<font size="2">
For help with this error, contact <i>$ENV{SERVER_ADMIN}</i>.<br>
$ENV{SERVER_SIGNATURE}
<hr noshade size="1">
<p>
</font>
</div>
</body>
};
return $self;
}

=head2 $ui -> brief_warning (I<message>);

Template that formats a warning about a user errror.  To print the
warning to the browser, use the following method calls.

    $ui -> brief_warning ($message) -> wprint;

=cut

sub brief_warning {
    my $self = $_[0];
    my $msg = $_[1];
    $self -> {text} = qq{
<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>OnSearch Warning</title>
<LINK rel="stylesheet" href="styles.css" type="text/css">
</head>
<body>
<hr noshade size="1">
<font size="3">
<strong>Warning</strong><p>
<tt>$msg</tt>
<hr noshade size="1">
<p>
</font>
</div>
</body>
};
return $self;
}


=head2 $ui -> header_css (I<title>);

HTTP header template that includes a link for an external style sheet
named, "styles.css."

=cut

sub header_css {
    my $self = $_[0];
    my $title = $_[1];
    $self -> {text} =<<END_OF_TEMPLATE;
Content-Type: text/html

<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>$title</title>
<LINK rel="stylesheet" href="styles.css" type="text/css">
</head>
<body>
END_OF_TEMPLATE
return $self;
}

=head2 $ui -> navbar_map ();

Graphical navbar image map template.

=cut


sub navbar_map {
    my $self = shift;

    my $c = OnSearch::AppConfig -> new;
    my $OnSearchDir = $c -> str (qw/OnSearchDir/);

$self -> {text} =<<END_OF_MAP;
<map name="navbar">
  <area shape="rect" coords=223,9,281,23 href="/$OnSearchDir/index.shtml">
  <area shape="rect" coords=307,9,367,23 href="/$OnSearchDir/archive.shtml">
  <area shape="rect" coords=392,9,439,23 href="/$OnSearchDir/filters.shtml">
  <area shape="rect" coords=465,9,516,23 href="/$OnSearchDir/admin/admin.shtml">
  <area shape="rect" coords=543,9,590,23 href="/$OnSearchDir/about.html">
</map>
END_OF_MAP
    return $self;
}

=head2 $ui -> header_back ();

HTTP header template the Web browser to the previous page.  

=cut

###
### TO DO - Try to make this work with internet explorer.
###

sub header_back {
    my $self = shift;

$self -> {text} =<<END_OF_TEMPLATE;
Content-Type: text/html

<!DOCTYPE html
   PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>OnSearch</title>
<LINK rel="stylesheet" href="styles.css"
  type="text/css">
</head>
<body onload="window.back ()">
</body>
$ENV{HTTP_REFERER}
END_OF_TEMPLATE
    return $self;
}

=head2 $ui -> navbar ();

Template for graphical and text-mode navigation bars.

=cut

sub navbar {
    my $self = shift;

    my $c = OnSearch::AppConfig -> new;
    my $OnSearchDir = $c -> str (qw/OnSearchDir/);

    if ($ENV{HTTP_USER_AGENT} =~ /lynx/i) {
	$self -> {text} =<<END_OF_TEMPLATE;
<p>
<table width="100%">
<tr align="center">
<td>[<a href="/$OnSearchDir/index.shtml">Search</a>]</td>
<td>[<a href="/$OnSearchDir/archive.shtml">Archive</a>]</td>
<td>[<a href="/$OnSearchDir/filters.shtml">Filters</a>]</td>
<td>[<a href="/$OnSearchDir/admin/admin.shtml">Admin</a>]</td>
<td>[<a href="/$OnSearchDir/about.html">About</a>]</td>
</tr>
</table>
END_OF_TEMPLATE
    return $self;
    }

$self -> {text} =<<END_OF_TEMPLATE;
<div><center>
<img src="/$OnSearchDir/images/navbar.jpg" alt="NavBar" usemap="#navbar">
</center></div>
END_OF_TEMPLATE
    return $self;
 }

=head2 $ui -> javascripts ();

Javascript function HTML template.

=cut

sub javascripts {
    my $self = shift;

$self -> {text} =<<END_OF_TEMPLATE;
<script language="javascript" type="text/javascript">
  function validate () {
	if (document.inputform.searchterm.value == '') {
		document.inputform.action = document.URL;
		ErrorWindow ('searchterm');
	}
  }
  function ErrorWindow (p) {
	window.open ('error.cgi?'+p,
		     'Error',
		     'scrollbars=no,menubar=no,width=300,height=180')
  }
  function CloseErrorWindow () {
	window.close ()
  }
</script>	
END_OF_TEMPLATE
return $self;
}

=head2 $ui -> error_dialog (I<message>);

Template for a HTTP header that uses Javascript to pop up an error
dialog box.

=cut

sub error_dialog {
    my $self = shift;
    my $error = $_[0];

    $self->{text} = <<END_OF_TEXT;
Content-Type: text/html

<!DOCTYPE html
   PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>OnSearch</title>
<LINK rel="stylesheet" href="styles.css"
  type="text/css">
</head>
<body onload="window.back () || window.alert('$error')">
</body>
END_OF_TEXT
return $self;
}

=head2 $ui -> critical_error_form (I<message>);

Template for a critical error form that is compatible with all 
Web browsers.

=cut

sub critical_error_form {
    my $self = shift;
    my $text = $_[0];

    $self -> {text} =<<END_OF_TEMPLATE;
<center>
  <table width="100%">
    <tr>
      <td rowspan="2" align="center">
        <img src="/onsearch/images/exclam-icon.jpg">
      </td>
      <td align="center">
        <label class="errortitle"><b>Error</b></label>
      </td>
    </tr>
    <tr>
      <td align="center">
        <label class="errortext">$text</label>
      </td>
    </tr>
    <tr>
      <td colspan="2" align="center">
        <p>
        <input type="image" src="/onsearch/images/close.jpg"
        onclick="CloseErrorWindow()">
      </td>
    </tr>
  </table>
</center>
END_OF_TEMPLATE
return $self;
}

=head2 $ui -> results_form (I<results_list>, I<searchterm>, I<matchcase>)

Template to format the results of a matching document.

=cut

sub results_form {
    my $self = shift;
    my $rlist = $_[0];

    my ($ext, $searchterm, $doc_url, $r, $regex, $cfg, $OnSearchDir);

    $cfg = OnSearch::AppConfig -> new;

    $OnSearchDir = $cfg -> str (qw/OnSearchDir/);
    $ext = ++($self -> {ext});
    $searchterm = $self -> {searchterm};
    $doc_url = $rlist->[0];
    $regex = $self->{q}->{displayregex};

$self -> {text} =<<EOM;
<map name="viewbutton_$ext">
  <area shape="rect" coords=0,0,90,15 href="$doc_url" target="_blank">
</map>
EOM

$self -> {text} .= qq|
<table>
  <colgroup>
  <col width="90%">
  <col width="10%">
  <tr>
    <td align="left">
      <label><strong>${$rlist}[0]</strong></label>
    </td>
    <td align="right">
      <img src="/$OnSearchDir/images/sopen.jpg" alt="View"  usemap="#viewbutton_$ext">
    </td>
  </tr>
|;


shift @{$rlist};
foreach $r (@{$rlist}) {
    $r =~ s"\<"&lt;"g;
    $r =~ s"\>"&gt;"g;
    $r =~ s/\n/ /g;
    $r =~ s"($regex)"<strong>$1<\/strong>"g;
    $self -> {text} .= qq|<tr><td colspan="2">$r</td></tr>\n|;
}
$self -> {text} .= qq|
</colgroup>
</table>
|;
	return $self;
}

=head2 $ui -> results_header ();

Template for the page numbers that appear at the top of each page of results.

For page number and results counts, and formatting the results header and
results footer, UI.pm uses _queue_indexes to calculate the
indexes.

=cut

sub results_header {
    my $self = $_[0];

    my $id;

    $id = $self -> {q} -> {id};

    my ($s, $us);
    my ($first, $last, $nextp, $prevp) = $self -> _queue_indexes ();
    my $total = $#{$self->{r}} + 1;

$self -> {text} =<<EOM;
    [HR_TAG]
    <center>
    <font class="body"><p>
    <a href="results.cgi?id=$id&page=$prevp">$LT_ent$LT_ent</a>&nbsp;
EOM
    my $i = ($nextp > 10) ? $nextp - 10 : 1;
    my $max = ($nextp > 10) ? $nextp : 10;
    for (; $i <= $max; $i++) {
	if ($i == $self -> {pageno}) {
	    $s = '<strong>'; $us = '</strong>';
	} else {
	    $s = ''; $us = '';
	}	    
	$self -> {text} .= qq|<a href="results.cgi?id=$id&page=$i">$s$i$us</a>&nbsp\n|;
    }
    $self -> {text} .= qq|<a href="results.cgi?id=$id&page=$nextp">$GT_ent$GT_ent</a>&nbsp;
    </font>
    <p>
    </center>
    |;
return $self;
}

=head2 $ui -> results_footer ();

Format the page numbers and results totals that appear at the bottom 
of each page of results.

=cut

sub results_footer {
    my $self = $_[0];

    my $id = $self -> {q} -> {id};
    my ($s, $us);
    my ($first, $last, $nextp, $prevp) = $self -> _queue_indexes ();
    my $total = $#{$self->{r}} + 1;

$self -> {text} =<<EOM;
    [HR_TAG]
    <p>
    <center>
    <font class="body"><p>
    Results $first to $last of $total documents.<p>
    <a href="results.cgi?id=$id&page=$prevp">$LT_ent$LT_ent</a>&nbsp;
EOM

    my $i = ($nextp > 10) ? $nextp - 10 : 1;
    my $max = ($nextp > 10) ? $nextp : 10;
    for (; $i <= $max; $i++) {
	if ($i == $self -> {pageno}) {
	    $s = '<strong>'; $us = '</strong>';
	} else {
	    $s = ''; $us = '';
	}	    
	$self -> {text} .= qq|<a href="results.cgi?id=$id&page=$i">$s$i$us</a>&nbsp\n|;
    }
    $self -> {text} .= qq|<a href="results.cgi?id=$id&page=$nextp">$GT_ent$GT_ent</a>&nbsp;
    </font>
    <p>
    </center>
    |;
return $self;
}

sub _queue_indexes {
    my $self = shift;

    my ($first, $last, $nextp, $prevp);

    $first = (($self -> {pageno} - 1) * $self -> {pagesize}) + 1;  
    ###
    ### If the page is past the end of the results queue, simply print 
    ### the queue head pointer.
    ###
    if ($first <= 0) {
	if ($#{$self->{r}} < 0) {
	    $first = 0;
	} else {
	    $first = 1;
	}
    }
    $last = (($first + $self -> {pagesize}) <= ($#{$self->{r}} + 1)) 
	? (($self->{pageno} - 1) * $self->{pagesize}) + $self->{pagesize} 
    : $#{$self->{r}} + 1;

    $nextp = $self -> {pageno} + 1;
    $prevp = $self -> {pageno} - 1;
    if ($prevp <= 0) { $prevp = 1; }

    return ($first, $last, $nextp, $prevp);
}

=head2 $ui -> admin_page (I<lastindex>, I<indexinterval>,, I<backup_opt>, I<digitsonly_opt>);

Template for the OnSearch administrator page.

=cut

sub admin_page {
    my $self = shift;
    my ($lastindex, $idxsecs, $backup_opt, $digitsonly_opt) = @_;
    my $backups = '';
    my $digitsonly = '';
    my ($cfg, $OnSearchDir);
    
    $cfg = OnSearch::AppConfig -> new;
    $OnSearchDir = $cfg -> str (qw/OnSearchDir/);

    $backups = 'checked' if $backup_opt ne '0'; 
    $digitsonly = 'checked' if $digitsonly_opt ne '0';

$self -> {text} =<<EOP;
<table>
<tr><td>
<form action="../index.cgi">
  <table align="left">
  <colgroup>
  <col width="43%">
  <col width="43%">
  <col width="24%">
    <tr>
      <td colspan="3">
        <label class="admintitle"><b>Indexing</b></label>
      </td>
    </tr>
    <tr>
      <td valign="top">
        <table>
          <tr>
            <td colspan="4">
              <label class="adminsubtitle"><b>Local Files</b></label>
            </td>
          </tr>
          <tr>
	    <td>
              <label class="button">Seconds between<br>background indexes:</label>
            </td>
            <td rowspan="3" valign="center">
              <div class="info">
                <label class="helptext">
                  <a class="info" href="schedule.html" target="_blank">
                  Information about<br>scheduling options.</a>
                </label>
              </div>
            </td>
	  </tr>
          <tr>
            <td>
	      <input type="text" size="10" name="idxinterval" value="$idxsecs">
            </td>
          </tr>
        </table>
      </td>
      <td valign="top">
        <table>
          <tr>
            <td colspan="2">
              <label class="adminsubtitle"><b>Options</label>
            </td>
          </tr>
	  <tr>
	    <td>
	      <input type="checkbox" name="digitsonly" $digitsonly>
	    </td>
	    <td>
	      <label class="buttontext">Index words that contain only digits.</label>
	    </td>
	  </tr>
	  <tr>
	    <td>
	      <input type="checkbox" name="backupindexes" $backups>
	    </td>
	    <td>
	      <label class="buttontext">Back up indexes.</label>
	    </td>
	  </tr>
        </table>
      </td>
      <td valign="top">
        <table>
	  <tr>
	    <td colspan="2">
              <label class="adminsubtitle"><b>Last&nbsp;Indexed:  <i>$lastindex</i></b></label>
            </td>
	  </tr>
	  <tr>
            <td>
	      <input type="checkbox" name="index_now">
            </td>
            <td>
              <label class="buttontext"><b>Index Now</b></label>
            </td>
          </tr>
          <tr>
            <td colspan="3">
              <input type="image" name="submit" class="search" src="/$OnSearchDir/images/update.jpg">
            </td>
          </tr>
       </table>
     </td>
    </tr>
  </colgroup>
  </table>
</form>
</td></tr>
<tr><td>
</td></tr>
</table>
</div>
</html>
EOP
    return $self;
}

=head2 $ui -> fileindex_form ();

Template for the file uploading and indexing form.

=cut

sub fileindex_form {
    my $self = shift;
    my ($cfg, $OnSearchDir);
    
    $cfg = OnSearch::AppConfig -> new;
    $OnSearchDir = $cfg -> str (qw/OnSearchDir/);

    $self -> {text} =<<EOT;
<form method="post" action="archive.cgi" enctype="multipart/form-data">
  <table width="75%" align="center">
    <colgroup>
    <col width="75%">
    <col width="25%">
      <tr>
        <td>
          <label class="adminsubtitle"><b>Files</b></label>
        </td>
	<td>
	&nbsp;
        </td>
      </tr>
      <tr>
        <td>
          <label class="buttontext">Enter a file name to upload and index:</label>
        </td>
        <td valign="bottom" rowspan="2">
          <input type="image" class="search" src="/$OnSearchDir/images/update.jpg">
        </td>  
      </tr>
      <tr>
        <td> 
          <input type="file" name="file">
        </td>
      </tr>
    </colgrou>
  </table>
</form>
EOT

    return $self;
}

=head2 $ui -> archive_title ();

Template for the Archive page title.

=cut

sub archive_title {
    my $self = shift;
    $self -> {text} =<<EOT;
<table width="75%" align="center">
  <tr><td><label class="admintitle"><b>Archive</b></label></td></tr>
  <tr><td><label class="helptext">Add files or URLs to be indexed.</td></tr>
</table>
EOT
return $self;
}

=head2 $ui -> webindex_form (I<preferences>);

Template for the Web index form.

=cut

sub webindex_form {
    my $self = shift;
    my $prefs = $_[0];

    my ($pagescope_opt, $sitescope_opt, %prefs, $cfg, $OnSearchDir);
    
    $cfg = OnSearch::AppConfig -> new;
    $OnSearchDir = $cfg -> str (qw/OnSearchDir/);

    if ($prefs =~ /defaults/) {
	$pagescope_opt = 'checked';
	$sitescope_opt = '';
    } else {
	%prefs = OnSearch::AppConfig->parse_prefs ($prefs);
	$pagescope_opt = ($prefs{targetscope} =~ /page/) ? 'checked' : '';
	$sitescope_opt = ($prefs{targetscope} =~ /site/) ? 'checked' : '';
    }

    $self -> {text} =<<EOT;
<form action="archive.cgi">
  <table width="75%" align="center">
  <colgroup>
  <col width="75%">
  <col width="25%">
    <tr>
      <td valign="top">
        <table>
          <tr>
            <td>
              <label class="adminsubtitle"><b>Web Pages</b></label>
            </td>
          </tr>
	  <tr>
            <td colspan="2">
              <label class="buttontext">Enter a URL to index:</label>
            </td>
          </tr>
          <tr>
	    <td colspan="2">
              <input type="text" size="40" name="targeturl">
            </td>
          </tr>
          <tr>
            <td>
              <input type="radio" name="targetscope" value="page" $pagescope_opt>
              <label class="button">Index this page only.</label>
            </td>
            <td>
              <input type="radio" name="targetscope" value="site" $sitescope_opt>
              <label class="button">Index the pages on this site.</label>
            </td>
          </tr>
        </table>
      </td>
      <td valign="bottom">
        <input type="image" name="submit" class="search" src="/$OnSearchDir/images/update.jpg">
      </td>
    </tr>
  </colgroup>
  </table>
</form>
EOT
return $self;
}

=head2 $ui -> volume_info (I<volume_list>, I<user_prefs>);

Matches site volume information with user preferences.

=cut

sub volume_info {
    my $self = $_[0];
    my $vol_ref = $_[1];
    my $vol_prefs = $_[2];

    my $c = OnSearch::AppConfig -> new;
    my ($vol, $vol_name, $v, $k, @selected);

    @selected = split /,/, $vol_prefs;

    $self -> {text} = qq|<label><strong>Volumes Selected:</strong>\n|;
    $self -> {text} .=  qq|<table>\n|;
    foreach my $k (keys %{$vol_ref}) {
	next unless scalar grep /$k/, @selected;
	$self -> {text} .= qq|<tr><td><label>$k</label></td></tr>\n|;
    }
    $self -> {text} .= qq|</table>\n|;
    return $self;
}

=head2 $ui -> volume_form (I<volume_list>);

Template for the volume list.

=cut

sub volume_form {
    my $self = $_[0];
    my $vols_ref = $_[1];
    my $selected_ref = $_[2];

    my ($c, $OnSearchDir, $vol_list, $vol_name, $v, $checked);
    $c = OnSearch::AppConfig -> new;
    $OnSearchDir = $c -> str (qw/OnSearchDir/);

$self -> {text} =  qq|<form action="filters.cgi">\n|;
$self -> {text} .= qq|<table cellpadding="5">\n|;
$self -> {text} .= qq|<colgroup>\n|;
$self -> {text} .= qq|<col width="10%">\n|;
$self -> {text} .= qq|<col width="20%">\n|;
$self -> {text} .= qq|<col width="45%">\n|;
$self -> {text} .= qq|<col width="25%">\n|;
$self -> {text} .= qq|<tr><td valign="top"><strong>Select</strong></td>\n|;
$self -> {text} .= qq|<td valign="top"><strong>Volume<br>Name</strong></td>\n|;
$self -> {text} .= qq|<td valign="top"><strong>Contents</strong></td>\n|;
$self -> {text} .= qq|<td rowspan="3"><input type="image" name="submit" class="search" src="/$OnSearchDir/images/update.jpg"></td></tr>\n|;

    foreach my $k (keys %{$vols_ref}) {
	$vol_name = $k;
	$v = ${$vols_ref}{$k};
    if (scalar grep /$k/, @$selected_ref) {
	$checked = 'checked';
    } else {
	$checked = '';
    }
$self -> {text} .= qq|<tr><td><input name="$vol_name" type="checkbox" $checked></td>\n|;
$self -> {text} .= qq|<td><label class="errortext">$vol_name</label></td>\n|;

$self -> {text} .= qq|<td><label class="errortext">$v</label></td></tr>\n|;
    }
$self -> {text} .= qq|</table>\n|;
$self -> {text} .= qq|</form>\n|;

    return $self;
}

=head2 $ui -> wprint (I<fh>);

Output text or a page template to the Web browser.

    $ui -> admin_page -> wprint;

Prints to the filehandle given as an argument, or to STDOUT, either
directly or via PerlIO::OnSearchIO, if called without an argument.

=cut

sub wprint {
    my $self = shift;

    my $crlf="\015\012";
    $self -> {text} =~ s"\n"$crlf"gs;
    $self -> m_subs;

    my $fh = shift || \*STDOUT;
    if (fileno ($fh)) {
	syswrite ($fh, $self -> {text});
    } else {
        warn ("Wprint: attempt to print on closed STDOUT");
# elsif ($self -> {id}) {
#	my $id = $self -> {id};
#	my $sockname = "/tmp/.onsearch.io.$id";
#	while (! -S $sockname) { }
#	socket (PCLIENT, PF_UNIX, SOCK_STREAM, 0) || 
#	    die "OnSearch: wprint socket: $!";
#	connect (PCLIENT, sockaddr_un ($sockname));
#	PerlIO::OnSearchIO::_sock_write (fileno (PCLIENT), $self -> {text});
#	close (PCLIENT);
    }
}

=head2 $ui -> m_subs ();

Perform macro substitutions in templates if necessary.

=cut

sub m_subs {
    my $self = $_[0];

    if ($self -> {text} =~ /\[HR_TAG\]/m) {
	my $app_uri = $self -> image_dir_uri;
	$self -> {text} =~ s"\[HR_TAG\]""gm;
    }

}

=head2 $ui -> header_cookie (I<title>, I<key>, I<val>, I<expires>);

Template for a HTTP header to set a cookie.

=cut

sub header_cookie {
    my $self = shift;
    my ($title, $key, $val, $expires) = @_;

    my $server = OnSearch::AppConfig->str('ServerName');

$self -> {text} =<<END_OF_TEMPLATE;
Set-Cookie: $key=$val; expires=$expires; path=/onsearch; domain=$server 
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>$title</title>
<LINK rel="stylesheet" href="/onsearch/styles.css" type="text/css">
</head>
<body>
END_OF_TEMPLATE
    return $self;
}

=head2 $ui -> header_expires (I<title>, I<datestr>);

Template for a HTTP header with, "Expires," field.

=cut

sub header_expires {
    my $self = $_[0];
    my $title = $_[1];
    my $datestr = $_[2];

    my $server = OnSearch::AppConfig->str('ServerName');

$self -> {text} =<<END_OF_TEMPLATE;
Expires: $datestr
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head><title>$title</title>
<LINK rel="stylesheet" href="/onsearch/styles.css" type="text/css">
</head>
<body>
END_OF_TEMPLATE
    return $self;
}

=head2 $ui -> querytitle ();

Template for the query title that appears at the top of each page of
results.

=cut

sub querytitle {
    my $self = shift;
    my ($s, $text);

    no warnings;
    if ($self -> {completed} == 1) {
	use warnings;
	$text = 'Results';
    } else {
	$text = 'Searching';
    }
    if ($self -> {q} -> {matchtype} =~ /any/) {
	$s = join '</i> or <i>', split /\W+/, $self -> {searchterm};
	$s = '<i>' . $s . '.</i>';
    } elsif ($self -> {q} -> {matchtype} =~ /all/) {
	$s = join '</i> and <i>', split /\W+/, $self -> {searchterm};
	$s = '<i>' . $s . '.</i>';
    } elsif ($self -> {q} -> {matchtype} =~ /exact/) {
	$s = '<i>"' . $self -> {q} ->{searchterm} . '."</i>';
    } else {
	$s = $self -> {q} -> {searchterm} . '.';
    }

    $self -> {text} = qq|
<label class="querytitle"><b>$text for: $s</b></label><br>
|;
    return $self;
}

=head2 $ui -> html_footer ();

Template for the HTML tags that end the document.

=cut

sub html_footer {
    my $self = shift;
    $self -> {text} =<<END_OF_TEMPLATE;
</body>
</html>
END_OF_TEMPLATE
return $self;
}

=head2 $ui -> restore_session (I<class>, I<id>);

Retrieve stored results from OnSearch's data directory.

=cut

sub restore_session {
    my $class = shift || __PACKAGE__;
    my $id = shift;
    my ($ui, $DataDir);

    $DataDir = OnSearch::AppConfig->str('DataDir');
    if (!$DataDir || (length ($DataDir) == 0)) {
	warn "UI->restore DataDir $DataDir not found.  Re-reading conf.";
	eval {require OnSearch::AppConfig; };
	if (@!) {
	    error_dialog ("UI->restore: Can't read config!\\n@!");
	    die "UI-restore: Can't read config: @!";
	}
	$DataDir = OnSearch::AppConfig->str('DataDir');
    }

    my $datafn = $DataDir . "/session.$id";
    my $lockfn = $datafn . '.lck';
    my $r;
    my $mode = O_RDONLY;
    my $retries = 3;

    ### Wait if results are being written.
    ###
    ### This is more predictable than flock if one or more
    ### of the processes respawns.
    ###
    while (-f $lockfn) { }

    ###
    ### If connection times out and there is no session file,
    ### recover from calling function.
    ###
    return undef unless -f $datafn;

    sysopen (LOCK, $lockfn, O_WRONLY | O_TRUNC | O_CREAT) || do {
	warn "store_result open $lockfn: $!";
	return undef;
    };
    print LOCK $id;
    close (LOCK);

    sysopen (F, $datafn, $mode) || do {
	OnSearch::WebLog::clf ('error', 
	       "UI -> restore open $datafn: $!");
      };

    undef $!;
    eval { 
	RETRY: for (my $i = $retries; $i; $i--) {
	    $ui = fd_retrieve (\*F);
	    unless ($ui) {
		warn "restore_session PID $$: $!. Retrying.";
	    } else {
		bless $ui, __PACKAGE__;
		last RETRY;
	    }
	}
    };
    close (F);
    unless ($ui) {
	if ($@||$!) { 
	    warn ("UI->retrieve storage error $datafn: $! $@. Creating new UI object.");
	}
	$ui = new ();
    }
    unlink ($lockfn) || do {
	###
	### This should not cause an exception.  A lock
	### can become stale when another process 
	### terminates.  However, we should note it 
	### and then check whether another process was
	### able to overwrite the lock. See store_result ()
	### in Search.pm.
	###
	eval { use OnSearch; };
	warn "restore session unlink $lockfn: $!";
    };
    return $ui;
}

=head2 $ui -> new (I<module>);

This is the OnSearch::UI constructor method.

=cut

sub new {
    my $module = shift || __PACKAGE__;
    my $obj = {
	r => [],                 # Results queue.
        head => 0,               # Queue index of the last result displayed.
	q => undef,              # The query object of these results.
	searchterm => undef,     # Search term from the query object.
	server => '',            # The Internet address of the Web server.
	port => 0,               # The network port of the Web server.
        ext => 0,                # Unique HTML link extension for displaying 
                                 # documents.
	id => 0,                 # Session ID of the search.
        pageno => 0,             # Number of currently displayed page.
    };
    bless $obj, $module;
    return $obj;
}

=head2 $ui -> DESTROY ();

OnSearch::UI object destructor, also called by Perl to delete unused 
objects.

=cut

sub DESTROY {
    my ($self) = @_;
    undef %{$self};
}

# The calling script should have called read_config for either of these.
sub image_dir_uri {
return 'http://'. $ENV{SERVER_NAME} . ':' . $ENV{SERVER_PORT} .
    '/' . OnSearch::AppConfig->str('OnSearchDir'). '/images';
}

sub app_dir_uri {
    my $self = shift;
    no warnings;  # In case the config is not available.
    return 'http://'. $ENV{SERVER_NAME} . ':' . $ENV{SERVER_PORT} .
	'/' . OnSearch::AppConfig->str('OnSearchDir');
    use warnings;
}

sub w_out {
    my $self = $_[0];

    my $addr = gethostbyname ($self -> {server});
    if (! $addr ) {
	OnSearch::WebLog::clf ('notice', 
	       "w_out: ". $self -> {server} . ": $!");
	  return undef;
    }
    socket (SOCKFH, PF_INET, SOCK_STREAM, getprotobyname ('tcp')) || 
	OnSearch::WebLog::clf ('notice', "w_out: socket: $!");
    my $paddr = inet_aton ($self -> {server});
    my $sinput = sockaddr_in ($self -> {port}, $paddr);
    if (!connect (SOCKFH, $sinput)) {
	OnSearch::WebLog::clf ('notice', "w_out: connect: $!");
	  return undef;
      }
    my $deffhprev = select (SOCKFH); $| = 1; select ($deffhprev);
    if (syswrite (SOCKFH, $self -> {text}, length($self -> {text})) 
        != length ($self -> {text})) {
	OnSearch::WebLog::clf ('error', "w_out: syswrite: $!");
        return undef;
    }
    shutdown (SOCKFH, 2);
}


=head1 VERSION AND CREDITS

$Id: UI.pm,v 1.26 2005/08/16 05:34:03 kiesling Exp $

Written by Robert Kiesling <rkies@cpan.org> and licensed under the
same terms a Perl.  Refer to the file, "Artistic," for information.

=head1 SEE ALSO

L<OnSearch(3)>,  L<OnSearch::Base64(3)>, L<OnSearch::AppConfig(3)>

=cut
1;
