#!/usr/bin/perl -wT

use strict;

# where do we connect to the Similarity server? 
# note I put in my local host information just to give you an idea.
# you should add your own though if you are using another server
# you need to change the $remote_host and the $doc_base
my $remote_host = 'atlas.ahc.umn.edu';
my $remote_port = '31135';
my $doc_base = '/umls_similarity/';

use CGI;
use Socket;

BEGIN {
    # Our University's webserver uses an ancient version of CGI::Carp
    # so we can't do fatalsToBrowser.
    # The carpout() function lets us modify the format of messages sent to
    # a filehandle (in this case STDERR) to include timestamps
    use CGI::Carp 'carpout';
    carpout(*STDOUT);
}

# subroutine prototypes
sub showForm ($$$$$$$$$);
sub round ($);

my $cgi = CGI->new;

# These are the colors of the text when we alternate text colors (when
# showing errors, for example).
my $text_color1 = 'black';
my $text_color2 = '#d03000';

# print the HTTP header
print $cgi->header;

# if the showform parameter is no, then don't show the form--this is how
# we avoid showing the form in popups
my $showform = $cgi->param ('showform') || 'yes';

# show the start of the page (all the usual HTML that goes at the top
# of a page, etc.)
showPageStart ();

# check if we want to show the version information (version of UMLS, etc.)
my $showversion = $cgi->param ('version');
if ($showversion) {
    socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	goto SHOW_END;
    }

    select ((select (Server), $|=1)[0]);

    print Server "v\015\012\015\012";
    print "<h2>Version information</h2>\n";
    while (my $line = <Server>) {
	last if $line eq "\015\012";
	if ($line =~ /^v (\S+) (\S+)/) {
	    print "<p>$1 version $2</p>\n";
	}
	elsif ($line =~ m/^! (.*)/) {
	    print "<p>$1</p>\n";
	}
	else {
	    print "<p>Strange message from server: $line\n";
	}
    }

    local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/sbin";
    my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
    # $t_osinfo is tainted.  Use it in a pattern match and $1 will
    # be untainted.
    $t_osinfo =~ /(.*)/;
    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
    print "<p>Similarity server: $remote_host</p>\n";
    goto SHOW_END;
}

# check if we're generating this page as the result of a query; if so, then
# we need to show the results.
my $word1 = $cgi->param ('word1');
my $word2 = $cgi->param ('word2');

if ($word1 and !$word2) {
    print "<p>Term 2 was not specified.</p>";
}
elsif (!$word1 and $word2) {
    print "<p>Term 1 was not specified.</p>";
}
elsif ($word1 and $word2) {
    print "<hr />\n";

    socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	goto SHOW_END;
    }

    select ((select (Server), $|=1)[0]);

    # value of the parameters can be 'all', 'gloss', or 'synset'
    my $w1option = $cgi->param ('senses1');
    my $w2option = $cgi->param ('senses2');
    my $button = $cgi->param('button');

    my %measurehash = ();
    $measurehash{'path'}   = "Path Length";
    $measurehash{'lch'}    = "Leacock &amp; Chodorow";
    $measurehash{'wup'}    = "Wu &amp; Palmer"; 
    $measurehash{'res'}    = "Resnik";
    $measurehash{'lin'}    = "Lin";
    $measurehash{'jcn'}    = "Jiang &amp Conrath";
    $measurehash{'cdist'}  = "Conceptual Distance";
    $measurehash{'nam'}    = "Nguyen &amp Al-Mubaid";
    $measurehash{'random'} = "Random Measure";
    $measurehash{'vector'} = "Vector Measure";
    $measurehash{'lesk'}   = "Adapted Lesk";

    
    my $query_type = 2;

    my $measure = "";
    my $sab     = "";
    my $rel     = "";

    if($button eq "Compute Relatedness") { 
	$measure = $cgi->param('relatedness');
	$sab     = $cgi->param('sabdef');
	$rel     = $cgi->param('reldef');
    }
    else {
	$measure    = $cgi->param ('similarity');
	$sab        = $cgi->param ('sab');
	$rel        = $cgi->param ('rel');
    }

    my $gloss      = $cgi->param ('gloss') ? 'yes' : 'no';
    my $path       = $cgi->param ('path') ? 'yes' : 'no';
    my $all_senses = $cgi->param ('sense') ? 1 : 0;

    # terminate all messages with CRLF (best to avoid \r\n because the
    # meaning of \r and \n varies from platform to platform

    #  if the word is a CUI get its preferred term
    if($word1=~/C[0-9]+/) { 
	print Server "t|$word1|\015\012";
    }
    if($word2=~/C[0-9]+/) { 
	print Server "t|$word2|\015\012";
    }
    
    #  now get their similarity
    if ($measure eq 'all' && $button eq "Compute Similarity") {
	foreach my $m (qw/path wup lch res lin jcn random cdist nam/) { 
	    print Server +("r|$word1|$word2|$button|$m|$sab|$rel|", 
			   "\015\012");
	}
	print Server "\015\012";
    }
    elsif ($measure eq 'all' && $button eq "Compute Relatedness") {
	foreach my $m (qw/vector lesk/) { 
	    print Server +("r|$word1|$word2|$button|$m|$sab|$rel|", 
			   "\015\012");
	}

    }
    else {
	print Server ("r|$word1|$word2|$button|$measure|$sab|$rel|",
		      "\015\012");
    }

    #  get the path information if the similarity button is clicked
    if($button eq "Compute Similarity") { 
	print Server "p|$word1|$word2|\015\012";
    }

    #  get the definitions of the possible CUIs of the words or the CUIs 
    #  themselves depending on what was entered
    print Server "g|$button|$word1|\015\012";
    print Server "g|$button|$word2|\015\012";

    print Server "\015\012";
    
    my %terms    = ();
    my %cuis     = ();
    my %scores   = ();
    my %paths    = ();
    my @glosses  = ();
    my @errors   = ();

    my $pathflag = 0;

    my @version_info;
    my $lines = 0;
    my $last_measure = '';
    while (my $response = <Server>) {
	last if $response eq "\015\012";
	$lines++;
	my $beginning = substr $response, 0, 1;
	my $end = substr $response, 2;
	if ($beginning eq '!') {
	    $end =~ s/\s+$//;
	    push @errors, $end;
	}
	elsif ($beginning eq 'r') {
	    my ($measure, $wps1, $wps2, $score) = split /\s+/, $end;
	    $score = round ($score);
	    $last_measure = $measure;
	    push @{$scores{$measure}}, [$score, $wps1, $wps2];
	    $cuis{$wps1} = $word1;
	    $cuis{$wps2} = $word2;
	}
	elsif($beginning eq 't') { 
	    my ($cui, $word) = split/\s+/, $end;
	    $word=~s/_/ /g;
	    $terms{$cui} = $word;
	}
	elsif ($beginning eq 'g') {
	    my ($wps, @gloss_words) = split /\s+/, $end;
	    push @glosses, [$wps, substr ($end, length ($wps))];
	}
	elsif($beginning eq 'p') { 
	    my @array = split/\|/, $end;
	    my $i = 0;
	    while($i <= $#array) {
		
		my $c1 = $array[$i]; $i++;
		my $c2 = $array[$i]; $i++;
		my $p  = $array[$i]; $i++;
		if($c1=~/^\s*$/) { next; }
		if($c2=~/^\s*$/) { next; }
		push @{$paths{"$c1|$c2"}}, $p;
		$pathflag = 1; 
	    }
	    
	}
	elsif ($beginning eq 'v') {
	    my ($package, $version) = split /\s+/, $end;
	    push @version_info, [$package, $version];
	}
	else {
	    push @errors,
	    "Error: received strange message from server `$response'";
	}
    }
    
    my $query_string = $ENV{QUERY_STRING} || "";
    # replace literal ampersands with their XML entity equivalents
    $query_string =~ s/&/&amp;/g;

    if (scalar @version_info) {
	foreach my $item (@version_info) {
	    print "<p>$item->[0] version $item->[1]</p>\n";
	}
	goto SHOW_END;
    }
    
    # show errors, if any
    if (scalar @errors) {
	unless ($cgi->param ('errors') eq 'show') {
	    my $query = $query_string . '&amp;errors=show';
	    my $url = "umls_similarity.cgi?${query}";
	    
	    # Having onclick return false should keep the browser from
	    # loading the page specified by href, but IE loads it
	    # anyways.  That's why we set href to # instead of the
	    # URL (setting it to the URL would let non-JavaScript
	    # browsers see the page in the main window, but such
	    # browsers are rare)
	    print +("<p>",
		    "<a href=\"#\" ",
		    "onclick=\"showWindow ('$url', 'Errors'); return false;\">View errors</a>",
		    '</p>',
		    "\n");
	}
	else {
	    print '<h2>Warnings/Errors:</h2>';
	    
	    print '<p class="errors">';
	    my $parity = 0;
	    foreach (0..$#errors) {
		my $color = $parity ? $text_color1 : $text_color2;
		print "<div style=\"color: $color\">$errors[$_]</div>";
		$parity = !$parity;
	    }
	    print "</p>\n";
	    
	    goto SHOW_END;
	}
    }
    
    # show glosses, if any
    if ($gloss eq 'yes') {
	my $parity = 0;
	if (scalar @glosses) {
	    print '<h2>Definitions:</h2>';
	    print '<p class="gloss">';
	    
	    print "<dl>";
	    foreach my $ref (@glosses) {
		my $cui = $ref->[0];
		my $word = $cuis{$cui};
		my @defs = split/\|/, $ref->[1];
		if($word=~/C[0-9]/) { 
		    $word = $terms{$word};
		}
		print "<dt>$word ($cui) </dt>";
		foreach my $def (@defs) { 
		    print "<dd>$def</dd>";
		}
	    }
	    print "</dl>\n";
	}
	else {
	    print "<p>Sorry, no definitions were found.</p>\n";
	    }
	goto SHOW_END;
    }
    else {
	my $query = $query_string . '&amp;gloss=yes';
	my $url = "umls_similarity.cgi?${query}";
	
	print +('<p>',
		    "<a href=\"#\" ",
		"onclick=\"showWindow ('$url', 'Glosses'); return false;\">",
		"View Definitions</a>",
		'</p>',
		"\n");
    }
    
    
    # show path information if similarity is desired, if any
    if($button eq "Compute Similarity") {
	if ($path eq 'yes') {
	    my $parity = 0;
	    if($pathflag > 0) { 
	    	print '<h2>Shortest Path Information</h2>';
	    	print '<p class="path">';
		
	    	print "<dl>";
		foreach my $item (sort keys %paths) { 
		    if($item=~/^\s*$/) { next; }
		    my ($c1, $c2) = split/\|/, $item;
		    print "The shortest path between $c1 and $c2 is:<br>";
		    foreach my $p (@{$paths{$item}}) { 
			print "  <dd>$p</dd><br>";
		    }
		 
		}
		
	    	print "</dl>\n";
	    }
	    else {
		print "<p>Sorry, no path information was found.</p>\n";
	    }
	    goto SHOW_END;
	}
	else {
	    my $query = $query_string . '&amp;path=yes';
	    my $url = "umls_similarity.cgi?${query}";
	    
	    print +('<p>',
		    "<a href=\"#\" ",
		    "onclick=\"showWindow ('$url', 'Shortest Path'); return false;\">",
                    "View Shortest Path</a>",
		    '</p>',
		    "\n");
	}
    }
    
    if ($all_senses) {
	print '<h2>Results:</h2>' if scalar keys %scores;
	print '<table class="results" border="1">';
	print '<tr><th>Measure</th><th>Term 1</th><th>Term 2</th><th>Score</th>';
	print "</tr>\n";
	foreach my $m (keys %scores) {
	    my @scrs = sort {$b->[0] <=> $a->[0]} @{$scores{$m}};
	    foreach (@scrs) {
		my $wps1 = $_->[1];
		$wps1 =~ s/\#/%23/g;
		my $wps2 = $_->[2];
		$wps2 =~ s/\#/%23/g;
		
		print "<tr><td>$m</td>";
		print "<td><a href=\"#\" onclick=\"showWindow ('umls_wps.cgi?wps=$wps1', ''); return false;\">$_->[1]</a></td>";
		print "<td><a href=\"#\" onclick=\"showWindow ('umls_wps.cgi?wps=$wps2', ''); return false;\">$_->[2]</a></td>";
		print "<td>$_->[0]</td>";
		print "</tr>\n";
	    }
	}
	
	print "</table>\n";
    }
    else {
	my $query = $query_string;
	
	# remove from the query string options that we don't want
	$query =~ s/(?:&amp;)sense=yes//;
	$query =~ s/(?:&amp;)?trace=yes//;
	# now add the option we do want
	$query .= '&amp;sense=yes';
	
	# prepare two query strings--one without traces and one with
	my $url_nt = "umls_similarity.cgi?${query}"; # 'nt' means 'no trace'
	my $url_trace = $url_nt . '&amp;trace=yes';
	
	goto SHOW_END unless scalar keys %scores;
	
	print '<h2>Results:</h2>';
	
	foreach my $m (keys %scores) {
	    my $good = $scores{$m}->[0];
	    foreach my $i (1..$#{$scores{$m}}) {
		if ($scores{$m}->[$i]->[0] > $good->[0]) {
		    $good = $scores{$m}->[$i];
		}
	    }
	    my $wps1 = $good->[1];
	    $wps1 =~ s/\#/%23/g;
	    my $wps2 = $good->[2];
	    $wps2 =~ s/\#/%23/g;
	    
	    my $term1 = $word1;
	    my $term2 = $word2;
	    if($word1=~/C[0-9]+/) { $term1 = $terms{$word1}; }
	    if($word2=~/C[0-9]+/) { $term2 = $terms{$word2}; }
	    
	    if($m=~/lesk|vector/) { 
		print +("\n<p class=\"results\">",
			"The relatedness of $term1 (",
			"<a href=\"#\" onclick=\"showWindow ('umls_wps.cgi?wps=$wps1', ''); return false;\">$good->[1]</a> ",
			") and $term2 (<a href=\"#\" onclick=\"showWindow ('umls_wps.cgi?wps=$wps2', ''); return false;\">$good->[2]</a> ",
			") using $measurehash{$m} ($m) is $good->[0].",
			"</p>\nUsing:",
			"<p>&nbsp&nbsp&nbsp SABDEF :: include $sab</p>",
			"<p>&nbsp&nbsp&nbsp RELDEF :: include $rel</p>");
	    }
	    else {
		print +("\n<p class=\"results\">",
			"The similarity of $term1 (",
			"<a href=\"#\" onclick=\"showWindow ('umls_wps.cgi?wps=$wps1|$button', ''); return false;\">$good->[1]</a> ",
			") and $term2 (<a href=\"#\" onclick=\"showWindow ('umls_wps.cgi?wps=$wps2|$button', ''); return false;\">$good->[2]</a> ",
			") using $measurehash{$m} ($m) is $good->[0].",
			"</p>\nUsing:",
			"<p>&nbsp&nbsp&nbsp SAB :: include $sab</p>",
			"<p>&nbsp&nbsp&nbsp REL :: include $rel</p>");
	    }
	}
	
	print +("<p><a href=\"#\" ",
		"onclick=\"showWindow ('$url_nt', 'All senses'); return false\">",
		"View relatedness of all possible senses</a></p>\n");
    }
    
  SHOW_END:
    print "<hr />";
    close Server;
    
}

$word1 = defined $word1 ? $word1 : "";
$word2 = defined $word2 ? $word2 : "";
my $measure = 'path';
my $sab = 'MSH';
my $rel = 'PAR/CHD';
my $sabdef = 'UMLS_ALL';
my $reldef = 'CUI/PAR/CHD/RB/RN';
my $relatedness = 'vector';

showForm (2, $word1, $word2, $measure, $sab, $rel, $sabdef, $reldef, $relatedness) unless $showform eq 'no';
showPageEnd ();




exit;

# ========= subroutines =========

sub round ($)
{
    my $num = shift;
    my $str = sprintf ("%.4f", $num);
    $str =~ s/\.?0+$//;

    return $str;
}

sub showPageStart
{
    print <<"EOINTRO";
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>Similarity</title>
  <link rel="stylesheet" href="$doc_base/sim-style.css" type="text/css" />
  <script type="text/javascript">
    <!-- hide script from old browsers
    function measureChanged ()
    {
        /* get the form that we want */
        var myform = document.getElementById ("queryform");
        /* get the currently selected measure, put it in mm */
        var mm = myform.measure.options[myform.measure.selectedIndex];

        if (   mm.value == "path" || mm.value == "wup"    || mm.value == "lch"
            || mm.value == "res"  || mm.value == "lin"    || mm.value == "jcn"
            || mm.value == "all"  || mm.value == "vector" || mm.value == "lesk" 
	    || mm.value == "nam"  || mm.value == "cdist") {
           myform.rootnode.disabled = "";
        }
        else {
            myform.rootnode.disabled = "disabled";
        }
    }

    function formReset ()
    {
        window.location = "umls_similarity.cgi";
    }

    function showWindow (url, title)
    {
        url += '&showform=no';
        var nw = window.open (url, "", "width=625, height=625, scrollbars=yes, resizeable=yes, location=no, toolbar=no");
        nw.document.title = title;
    }

    // -->
  </script>

</head>
<body>

   <div id="umdlogo" style="float: left">
     <a href="http://www.d.umn.edu/"><img style="border: 0px"
        src="$doc_base/logo_black.gif"
       alt="" /></a>
   </div>

  <h1>UMLS::Similarity Web Interface</h1>
  <p><a href="http://search.cpan.org/dist/UMLS-Similarity/">UMLS::Similarity</a> 
  is a freely available open source software package that can be used to obtain the 
  similarity or relatedness between two biomedical terms from the 
  <a href="http://www.nlm.nih.gov/research/umls/">Unified Medical Language System</a>
  (UMLS). 
  </p>


EOINTRO
}


sub showForm ($$$$$$$$$)
{
    my ($type, $arg1, $arg2, $arg3, $arg4, $arg5, $arg6, $arg7, $arg8) = @_;


    # the 'action' attribute for the HTML form below--should be the script
    # name
    my $action = 'umls_similarity.cgi';

    print <<"EOFORM1";
  <p>DIRECTIONS: You may enter any two terms or 
      <a href="$doc_base/faq.html">Concept Unique Identifiers</a> (CUIs) below. 
      If terms are entered, then the relatedness or similarity of the possible 
      CUIs will be computed and the pair with the highest score returned. 
      <a href="$doc_base/faq.html">The difference between similarity and 
      relatedness is ....</a>
  <p>
     <a href="$doc_base/instructions.html">Detailed instructions.</a>
     <br>
     <a href="$doc_base/similarity_measures.html">About the Similarity Measures.</a>
     <br>
     <a href="$doc_base/relatedness_measures.html">About the Relatedness Measures.</a>
     <br>

     </p>
  <form action="$action" method="get" id="queryform" onreset="formReset()">
  <p>
EOFORM1

    # check if we are trying to get the user to type in a pair of words or
    # if the user needs to select senses from a option menu.
    if ($type == 2) {
	# the user needs to type in two words

	print <<"EOT";
	<fieldset >
      <label for="word1in" class="leftlabel"  style="width: 1.2in">Term 1:</label>
      <input type="text" name="word1" id="word1in" value=\"$arg1\" />
      <br>
      <label for="word2in" class="leftlabel"  style="width: 1.2in">Term 2:</label>
      <input type="text" name="word2" id="word2in" value=\"$arg2\" />
      </fieldset>
      <br /><br />
EOT
    }
    else {
	# the user needs to select word senses from a menu

	print "<label for=\"word1in\" class=\"leftlabel\">Word 1:</label>\n";
	print "<select name=\"word1\" id=\"word1in\" style=\"width: 15in\">\n";
	foreach my $ref (@$arg1) {
	    my ($sense, $gloss) = @$ref;
	    print "<option value=\"$sense\">$sense: $gloss</option>\n";
	}
	print "</select><br />\n";
	print "<label for=\"word2in\" class=\"leftlabel\">Word 2:</label>\n";
	print "<select name=\"word2\" id=\"word2in\" style=\"width: 15in\">\n";
	foreach my $ref (@$arg2) {
	    my ($sense, $gloss) = @$ref;
	    print "<option value=\"$sense\">$sense: $gloss</option>\n";
	}
	print "</select><br /><br />\n";
    }


    print '<fieldset>';
    print '<legend>Semantic Similarity</legend>';

    print '<label for="sabpull" class="leftlabel"  style="width: 1.2in">SAB:</label>', "\n";
    print '<select name="sab" id="sabpull" ',
      'onchange="sabChanged();">', "\n";
    my @sabs = (['MSH', 'MSH'],
		['FMA', 'FMA'],
		['OMIM', 'OMIM'],
	  	['SNOMEDCT_US', 'SNOMEDCT']);

    foreach (@sabs) {
	my $selected = $_->[0] eq $arg4 ? 'selected="selected"' : '';
	print "<option value=\"$_->[0]\" $selected>$_->[1]</option>\n";
    }
    print "</select>  <br />\n";

    print '<label for="relpull" class="leftlabel" style="width: 1.2in">REL:</label>', "\n";
    print '<select name="rel" id="relpull" ',
      'onchange="relChanged();">', "\n";
    my @rels = (['PAR/CHD', 'PAR/CHD'],
		['RB/RN', 'RB/RN']);

    foreach (@rels) {
	my $selected = $_->[0] eq $arg5 ? 'selected="selected"' : '';
	print "<option value=\"$_->[0]\" $selected>$_->[1]</option>\n";
    }
    print "</select><br /><br />\n";


    print '<label for="similaritypull" class="leftlabel"  style="width: 1.2in">Similarity:</label>', "\n";
    print '<select name="similarity" id="similaritypull" ',
    'onchange="similarityChanged();">', "\n";
    my @similarity = (['all', 'Use All Similarity Measures'],
		      ['cdist','Conceptual Distance (cdist)'],
		      ['jcn', 'Jiang &amp Conrath (jcn)'],
		      ['lch', 'Leacock &amp; Chodorow (lch)'],
		      ['lin', 'Lin (lin)'],
		      ['nam', 'Nguyen &amp Al-Mubaid (nam)'],
		      ['path', 'Path Length (path)'],
		      ['random', 'Random Measure (random)'],
		      ['res', 'Resnik (res)'],
		      ['wup', 'Wu &amp; Palmer (wup)']
	);
    
    foreach (@similarity) {
	my $selected = $_->[0] eq $arg3 ? 'selected="selected"' : '';
	
	print "<option value=\"$_->[0]\" $selected>$_->[1]</option>\n";
    }
    print "</select><br ><br  > \n";
    
    print <<"EOFORM";	
	<input type="submit" name="button" value="Compute Similarity" />
	</fieldset>
	<br><br>
EOFORM

    print '<fieldset>';
    print '<legend>Semantic Relatedness</legend>';

    print '<label for="sabdefpull" class="leftlabel"  style="width: 1.2in">SABDEF:</label>', "\n";
    print '<select name="sabdef" id="sabdefpull" ',
      'onchange="sabdefChanged();">', "\n";
    my @sabdefs = (['UMLS_ALL', 'UMLS_ALL'],
		   ['MSH', 'MSH'],
		   ['SNOMEDCT_US', 'SNOMEDCT']);

    foreach (@sabdefs) {
	my $selected = $_->[0] eq $arg6 ? 'selected="selected"' : '';
	print "<option value=\"$_->[0]\" $selected>$_->[1]</option>\n";
    }
    print "</select>  <br />\n";

    print '<label for="reldefpull" class="leftlabel" style="width: 1.2in">RELDEF:</label>', "\n";
    print '<select name="reldef" id="reldefpull" ',
      'onchange="reldefChanged();">', "\n";
    my @reldefs = (['CUI/PAR/CHD/RB/RN', 'CUI/PAR/CHD/RB/RN'],
		   ['CUI', 'CUI']);

    foreach (@reldefs) {
	my $selected = $_->[0] eq $arg7 ? 'selected="selected"' : '';
	print "<option value=\"$_->[0]\" $selected>$_->[1]</option>\n";
    }
    print "</select><br /><br />\n";


    print '<label for="relatednesspull" class="leftlabel" style="width: 1.2in">Relatedness:</label>', "\n";
    print '<select name="relatedness" id="relatednesspull" ',
      'onchange="relatednessChanged();">', "\n";
    my @relatednesss = (['all', 'Use All Relatedness Measures'],
			['lesk', 'Adapted Lesk (lesk)'],
			['vector', 'Vector Measure (vector)']);
    
    foreach (@relatednesss) {
	my $selected = $_->[0] eq $arg8 ? 'selected="selected"' : '';

	print "<option value=\"$_->[0]\" $selected>$_->[1]</option>\n";
    }
    print "</select><br ><br  > \n";
    
    print <<"EOFORM2";	
	<input type="submit" name="button" value="Compute Relatedness" />
	</fieldset>

	<input type="reset" value="Clear" />
    </p>
  </form>
  <br>
  <p><a href="umls_similarity.cgi?version=yes">Show version info</a></p>

<hr />

EOFORM2

}

sub showPageEnd
{

print <<'ENDOFPAGE';
<div class="footer">
<table width="100%"><tbody><tr><td>
This interface is based on the 
<a href="http://wn-similarity.sourceforge.net">WordNet::Similarity web interface</a>
<br />Created by Ted Pedersen and Jason Michelizzi and Bridget T. McInnes
<br />E-mail: bthomson (at) umn (dot) edu
<br>
<td align="right"
<div id="clustrmaps-widget"></div><script type="text/javascript">var _clustrmaps = {'url' : 'http://atlas.ahc.umn.edu/cgi-bin/umls_similarity.cgi', 'user' : 873181, 'server' : '2', 'id' : 'clustrmaps-widget', 'version' : 1, 'date' : '2011-08-15', 'lang' : 'en', 'corners' : 'square' };(function (){ var s = document.createElement('script'); s.type = 'text/javascript'; s.async = true; s.src = 'http://www2.clustrmaps.com/counter/map.js'; var x = document.getElementsByTagName('script')[0]; x.parentNode.insertBefore(s, x);})();</script><noscript><a href="http://www2.clustrmaps.com/user/d8ed52dd"><img src="http://www2.clustrmaps.com/stats/maps-no_clusters/atlas.ahc.umn.edu-cgi-bin-umls_similarity.cgi-thumb.jpg" alt="Locations of visitors to this page" /></a></noscript>
</td>
</div>
</body>
</html>
ENDOFPAGE
}

__END__

=head1 NAME

umls_similarity.cgi - a CGI script implementing a portion of a web interface for
UMLS::Similarity

=head1 DESCRIPTION

This script works in conjunction with umls_similarity_server.pl and wps.cgi to
provide a web interface for UMLS::Similarity.  The documentation
for umls_similarity_server.pl describes how messages are passed between this
script and that one.

=head1 AUTHORS

 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Jason Michelizzi

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2005-2008, Ted Pedersen and Jason Michelizzi

This program is free software; you may redistribute and/or modify it under
the terms of the GNU General Public License version 2 or, at your option, any
later version.

=cut
