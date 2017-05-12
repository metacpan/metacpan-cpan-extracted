package Web::Scaffold;

#use diagnostics;
use strict;
use POSIX;
use Fcntl qw(:flock);
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.15 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my @defaults = (

# directory path for 'html pages' relative to the html root
# i.e. public_html/        defaults to:
#
	pagedir		=> '../pages',

# directory path for 'javascript libraries' relative to html root
# defaults to:

	javascript	=> 'lib',

# no search conditions for building the site map. Each
# element is evaluated as a perl match condition in the
# context of m/element/. Include page names, extensions, etc...
#
# [OPTIONAL]
#

	nosearch	=> [ 'pdf' ],

# Directory path for 'sitemap' page generation relative to the 
# html root. This directory must be WRITABLE by the web server.
#
# NOTE: link the file 'sitemapdir'/sitemaplxml to the 
# appropriate location in your web directory.
# 
# The sitemap.xml file will be generated and updated ONLY if 
# the 'sitemapdir' key is present in this configuration file.
#
# The sitemap page will auto update if you modify pages in
# 'pagedir' or in the 'autocheck' list below. If you modify 
# static pages elsewhere in the web directory tree that are
# not listed in 'autocheck', you must DELETE the sitemap.xml 
# file to force an update.
#
# [OPTIONAL]
#
#	sitemapdir	=> '../ws_sitemap',

# Directories to autocheck for sitemap update.
# you can list BOTH directories and individual files
# here relative to the web root. The 'sitemapdir' and
# 'pagedir' are always checked and do not need to be
# listed here.
#
#	autocheck	=> ['docs'],

# site map <changefreq> hint
#
# defaults to:
#
	changefreq	=> 'monthly',

# font family used throughout the document
#
	face		=> 'VERANDA,ARIAL,HELVETICA,SAN-SERIF',

# background color of the web page
# this can be a web color like 'white' or number '#ffffff'
#
	backcolor	=> 'white',

# Menu specifications
#
	barcolor	=> 'red',
	menudrop	=> '55',	# drop down position
	menuwidth	=> '100px',	# width of menu item
	pagewidth	=> '620px',	# recommended
# menu font specifications
	menucolor	=> 'black',
	menuhot		=> 'yellow',	# mouse over
	menucold	=> 'white',	# page selected
	menustyle	=> 'normal',	# bold, italic
	menusize	=> '13px',	# font points or pixels
	sepcolor	=> 'black',	# separator color

# Page link font specifications
#
	linkcolor	=> 'blue',
	linkhot		=> 'green',
	linkstyle	=> 'normal',	# bold, italic
	linksize	=> '13px',	# font points or pixels

# Page Text font specifications
#
 	fontcolor	=> 'black',
	fontstyle	=> 'normal',
	fontsize	=> '13px',

# Heading font specifications
#
	headcolor	=> 'black',
	headstyle	=> 'bold',	# normal, italic
	headsize	=> '16px',
);

# set default values where specs are missing
#
# return most recent mtime from pagedir or autocheck list if sitemap is enabled
#
sub checkspecs {
  my $specs = shift;
# set defaults
  for (my $i=0; $i < @defaults; $i+=2) {
    $specs->{$defaults[$i]} = $defaults[$i+1]
	unless exists $specs->{$defaults[$i]};
  }
  foreach('pagedir', 'javascript', 'sitemapdir') {
    if (exists $specs->{$_}) {
      $specs->{$_} = $' if $specs->{$_} =~ m|^/|;
      $specs->{$_} .= '/' unless $specs->{$_} =~ m|/$|;
    }
  }
  if (exists $specs->{sitemapdir}) {
    my $mtime = (stat($specs->{pagedir}))[9];
    if (exists $specs->{autocheck} && ref $specs->{autocheck}) {
      foreach (@{$specs->{autocheck}}) {
	$_ = $' if $_ =~ m|^/|;
	my $t = (stat($_))[9];
	$mtime = $t if $t > $mtime;
      }
    }
    return $mtime;
  }
}

# generate the style library
#
# input:	pointer to %specs
#		number of columns
sub stylegen {
  my($specs,$cols) = @_;
  $cols = 1 unless $cols;
#
#	.mhs		menuHeadStyle
#	.dropdown	drop down style
#	#mh		menuHead
#	A.B		Basic link
#	A.B:hover	Basic link mouseOVER
#	A.NU		meNU link
#	A.NU:hover	meNU link mouseOVER
#	A.CP		menu link Current Page
#
#	FONT.NU		meNU font
#	TD.NU		meNU font
#	TD.S		Separator font
#	.PT		Page Text
#	.HT		Heading Text
#
  my $styles = q|<style type="text/css">
.mhs {
  background-color: |. $specs->{barcolor} .q|;
}
.dropdown {
  background-color: |. $specs->{barcolor} .q|;
  padding: 2px;
  border: solid 1px |. $specs->{sepcolor} .q|;
}
#mh {
  position: relative;
  z-index: 50;
}
A.B {
  color: |. $specs->{linkcolor} .q|;
  background: transparent;
  font-family: |. $specs->{face} .q|;
  font-weight: |. $specs->{linkstyle} .q|;
  font-size: |. $specs->{linksize} .q|;
  text-decoration: underline;
}
A.B:hover {
  color: |. $specs->{linkhot} .q|;
}|;

  my $tmp = q|
  background: transparent;
  font-family: |. $specs->{face} .q|;
  font-weight: |. $specs->{menustyle} .q|;
  font-size: |. $specs->{menusize} .q|;|;

  $styles .= q|
A.NU {
  color: |. $specs->{menucolor} .q|;|. $tmp .q|
  text-decoration: none;
}
A.NU:hover {
  color: |. $specs->{menuhot} .q|;
}
A.CP {
  color: |. $specs->{menucold} .q|;|. $tmp .q|
  text-decoration: none;
}
FONT.NU {
  color: |. $specs->{menucolor} .q|;|. $tmp .q|
}
TD.NU {
  color: |. $specs->{menucolor} .q|;|. $tmp .q|
}
TD.S {
  color: |. $specs->{sepcolor} .q|;|. $tmp .q|
}
.PT {
  color: |. $specs->{fontcolor} .q|;
  background: transparent;
  font-family: |. $specs->{face} .q|;
  font-weight: |. $specs->{fontstyle} .q|;
  font-size: |. $specs->{fontsize} .q|;
}
.HT {
  color: |. $specs->{headcolor} .q|;
  background: transparent;
  font-family: |. $specs->{face} .q|;
  font-weight: |. $specs->{headstyle} .q|;
  font-size: |. $specs->{headsize} .q|;
}
|;
    
  my $Ls = '';
  my $Mus = '';
  foreach (1..$cols) {
    $Ls .= '#L'. $_;
    $Mus .= '#menu'. $_;
    unless ($_ == $cols) {
      $Ls .= ',';
      $Mus .= ',';
    }
  }

  $styles .= $Ls .q| {
  position: relative;
}
|. $Mus .q| {
  position: absolute;
  z-index: 100;
  visibility: hidden;
  width: |. $specs->{menuwidth} .q|;
}
</style>
|;
}

# find the number of drop down menus
#
# input:	pointer to pages hash
#		page name
#
sub get_cols {
  my($pp,$page) = @_;
  return 0 unless exists $pp->{$page};
  my $cols = 0;
# check for sub-menu's on menu items
  foreach (@{$pp->{$page}->{menu}}) {
#	count if there are sub menu's
    ++$cols if exists $pp->{$_} && exists $pp->{$_}->{submenu} && @{$pp->{$_}->{submenu}};
  }
  return $cols;
}

# generate values for 'name', 'href', 'onClick', 'link text', and 'status text'
#
# input:	pointer to page hash,
#		item
# returns:	name, href, click, link text, status text
#
sub menuitem {
  my($pp,$item) = @_;
  return ($item, '#',
	  qq|onClick="return(npg('$item'));"|,
	  $item, $item
	) if exists $pp->{$item};
  $item =~ m{(.)(.+)};	# skim off the first character
  my $s = quotemeta $1;	# the seperator character
  my($name,$text,$status) = split(m{$s},$2);
  $text = $name unless $text;
  $status = $text unless $status;
  return ($name, '#',
	  qq|onClick="return(npg('$name'));"|,
	  $text, $status
	) if exists $pp->{$name};
  return ($name, $name,'',$text,$status);
}

# generate menu bar
#
# input:	pointer to page hash,
#		page name
#		page width
#		debug page name
# return:	html for menu,
#		div html for dropdowns
#
# call this to fill a table row
# i.e. $pagehtml = '<tr><td>'
# ($html,$div) = menugen(\%pages,$pagename);
# $pagehtml .= $html . $bodytext . $div;
# etc...
#
sub menugen {
  my($pp,$page,$pw,$debug) = @_;
  my @selectbar;
  return ('&nbsp;','') unless
	exists $pp->{$page} && exists $pp->{$page}->{menu} &&
	(@selectbar = @{$pp->{$page}->{menu}});
   my $linkCount = 1;
  my $menustripe = ( exists $pp->{$page}->{menustripe} )
	? qq|  <tr align=top><td width=100%>$pp->{$page}->{menustripe}</td></tr>
|	: '';
  my $div = '';
  my $html = q|<div id="mh" class="mhs"><table cellspacing=0 cellpadding=0 border=0 width="|. $pw .q|">
  <tr|;
  $html .= $#selectbar
	? ' align=center>'
	: '>';
  $html .= "<td>&nbsp;</td>\n";
  my $bar = 0;
  foreach(@selectbar) {
    my($name,$href,$click,$text,$status) = menuitem($pp,$_);
    if ($bar) {
      $html .= q#<td class="S">&nbsp;|&nbsp;</td>#;
    } else {
      $bar = 1;
    }
    my $class = ($name eq $page)
	? 'CP' : 'NU';
    $html .= qq|  <td NOWRAP><a class="$class" |;
    if (exists $pp->{$name} &&
	exists $pp->{$name}->{submenu} &&
	@{$pp->{$name}->{submenu}}) {	# build menu links
      $html .= qq|id="L${linkCount}" href="$href" title="$status" onMouseout="return(headOut());" onMouseover="return(headOver('$status',$linkCount));" $click>$text</a></td>
|;
      $div .= qq|<div id="menu${linkCount}" class="dropdown">
|;
      foreach my $sublink (@{$pp->{$name}->{submenu}}) {
        ($name,$href,$click,$text,$status) = menuitem($pp,$sublink);
	$click = qq|onClick="return(linkClick('$name'));"| if $click;	# fix up click return
	$class = ($name eq $page || $name eq $debug)
		? 'CP' : 'NU';
        $div .= qq|<a class="$class" href="$href" title="$status" onMouseout="return(linkOut());" onMouseover="return(linkOver('$status'));" $click>$text</a><br>
|;
      }
      $div .= q|</div>
|;
      ++$linkCount;
    } else {
      $html .= qq|href="$href" title="$status" onMouseover="return(oneOver('$status'));" onMouseout="return(linkOut());" $click>$text</a></td>
|;
    }
  }  
  $html .= qq|<td width=100%>&nbsp;</td></tr></table>
$menustripe</div>
|;
  return($html,$div);
}

# generate the trailer
#
# input:	pointer to specs hash,
#		pointer to page hash,
#		page name,
#
# call this to fill a table row in the same manner as 'menugen'
# i.e. $pagehtml = '<tr><td>'

sub trailgen {
  my($specs,$pp,$page) = @_;      
  my @selectbar;
  return '&nbsp' unless exists $pp->{$page}->{trailer};
  my $html;
  my $cols = 1;
  if (	exists $pp->{$page}->{trailer}->{links} &&
	($cols = @selectbar = @{$pp->{$page}->{trailer}->{links}})) {
#    $html = q|<div class="mhs"><table cellspacing=0 cellpadding=0 border=0 width="|. $specs->{pagewidth} .q|">
    $html = q|<div class="mhs"><table cellspacing=0 cellpadding=0 border=0 width="100%">
|;
    $cols *= 2;
    $cols += 1 if exists $pp->{$page}->{trailer}->{text} && $pp->{$page}->{trailer}->{text};
    if ( exists $pp->{$page}->{trailer}->{top} ) {
      $html .= qq|<tr align=bottom><td colspan=$cols>$pp->{$page}->{trailer}->{top}</td></tr>
|
    }
    $html .= q|<tr align=center><td>&nbsp;</td>
|;
    my $bar = 0;
    foreach (@selectbar) {
      my($name,$href,$click,$text,$status) = menuitem($pp,$_);
      if ($bar) {
        $html .= q#<td class='S'>&nbsp;|&nbsp;</td>#;
      } else {
        $bar = 1;
      }
      my $class = $name eq $page ? 'CP' : 'NU';
      $html .= qq|  <td NOWRAP><a class="$class" |;
      $html .= qq|href="$href" title="$status" onMouseover="return(oneOver('$status'));" onMouseout="return(linkOut());" $click>$text</a></td>
|;
   }
  }
  my $ttop = ( exists $pp->{$page}->{trailer}->{top} )
	? qq|<tr align=bottom><td colspan=$cols>$pp->{$page}->{trailer}->{top}</td></tr>
|	: '';

  if (exists $pp->{$page}->{trailer}->{text} && $pp->{$page}->{trailer}->{text}) {
    if ($html) {
      $html .= q|<td class="NU" align=right width="100%">|;
    } else {
      $html = qq|<div class="mhs"><table cellspacing=0 cellpadding=0 border=0 width="100%">
  $ttop
  <tr><td class="NU">|;
    }
    $html .= $pp->{$page}->{trailer}->{text} .q|&nbsp;</td>|;
  }
  if ( $html && exists $pp->{$page}->{trailer}->{bottom} ) {
    $html .= qq|</tr>
<tr align=top><td colspan=$cols>$pp->{$page}->{trailer}->{bottom}</td>|;
  }
  return '&nbsp;' unless $html;
  return $html .q|</tr></table></div>
|;
}

# parse link text
#
# input:	seperator,
#		link string
# returns:	page, text, status
#
sub parseLINK {
  my($sep,$link) = @_;
  $sep = quotemeta($sep);
  my ($page,$text,$status) = split(m{$sep},$link);
  $text = $page unless $text;
  $status = $text unless $status;
  return ($page,$text,$status);
}

# replace LINK text
#
# input:	pointer to page hash,
#		html text
# returns:	updated html
#
sub fixLINKs {
  my($pp,$html) = @_;
  while ($html =~ m{LINK([C-Z]?)\<(.)([^>]+)>}) {
    my $class = $1 || "B";
    my $match = quotemeta $&;
    my($page,$link,$status) = parseLINK($2,$3);
    my $replacement = q|<a class="|. $class .q|" title="|. $status .q|" onMouseOver="self.status='|. $status . q|';return true;" onMouseOut="self.status='';return true;" |;
    if (exists $pp->{$page}) {
      $replacement .= q|onClick="return(npg('|. $page .q|'));" href="./">|;
    } else {
      $replacement .= q|href="|. $page .q|">|;
    }
    $replacement .= $link .q|</a>|;
    $html =~ s/$match/$replacement/;
  }
  return $html;
}

# generate text from file
#
# input:	pointer to page hash,
#		file name
# returns:	html text
#
sub file2text {
  my($pp,$file) = @_;
  my $html;
  local *F;
  if (-e $file && open F, $file) {
    local $/ = undef;
    $html = fixLINKs($pp,<F>);
    close F;
  } else {
    $html = '&nbsp;';
  }
  return $html;
}

# similar to above

sub fileLoad {
  my($file) = @_;
  my $html;
  local *F;
  if (-e $file && open F, $file) {
    local $/ = undef;
    $html = <F>;
    close F;
  } else {
    $html = '';
  }
  return $html;
}

# return column array
#
# input:	pointer to page hash,
#		page name
#		page width
# returns:	column array
#
sub getColArray {
  my($pp,$page,$pw) = @_;
  return (exists $pp->{$page}->{column} &&		# column array
	  ref $pp->{$page}->{column} eq 'ARRAY')
	? @{$pp->{$page}->{column}}
	: ($pw);
}

# generate main body text
#
# input:	pointer to specs hash,
#		pointer to page hash,
#		page name
#		page width
#		pages directory path
# returns:	html
#
# call this to fill a table row in the same manner as 'menugen'
# i.e. $pagehtml = '<tr><td>'
#

sub bodygen {
  my($specs,$pp,$page,$pw,$pd) = @_;
  return '' unless exists $pp->{$page};
  my @ca = getColArray($pp,$page,$pw);
  my($smp,$smn);			# sitemap path and position number
  if ($page eq 'Sitemap' && exists $specs->{sitemapdir}) {
    $smp = $specs->{sitemapdir} . 'sitemap.htxt';
    $smn = $pp->{Sitemap}->{autocol} || 1;
  }
  my $phead = $pp->{$page}->{heading} || '';
  my $html = q|<table cellspacing=5 cellpadding=0 border=0 width="|. $pw .q|">|."\n  <tr>";
  foreach (@ca) {
    $html .= q|<td width=|. $_ .q|>&nbsp;</td>|;
  }
  $html .= "</tr>\n";

  $_ = @ca;			# number of columns
  if ($phead) {
    $html .= q|  <tr><td colspan=|. $_ .q|><font class=HT>|. $phead .q|</font></td></tr>
|;
  }
  $html .= q|  <tr><td colspan=|. $_ .q|>&nbsp;</td></tr>
  <tr>|;

  foreach (1..@ca) {
    $html .= q|<td valign=top class=PT>|;
    if ($smn && $smn == $_) {
      $html .= file2text($pp,$smp);
    } else {
      my $file = $pd . $page .'.c'. $_;
      $html .= file2text($pp,$file);
    }
    $html .= '</td>';
  }
  return $html .q|</tr></table>|;
}

# display the source for a page
#
#	input:	pointer to page hash,
#		page name
#		page width
#		pages directory path
#		returns html
#
# call this to fill a table row in the same manner as 'menugen'
# i.e. $pagehtml = '<tr><td>'
#
sub srcgen {
  my($pp,$page,$pw,$pd) = @_;
  return '' unless exists $pp->{$page};
  my $html = q|<table cellspacing=0 cellpadding=0 border=0 width="|. $pw .q|">
  <tr><td ><font class=HT>|. $page .q|</font></td></tr>
  <tr><td valign=top class=PT><hr>
<pre>|;
  my $tmp = (exists $pp->{$page}->{location})
	? $pp->{$page}->{location}
	: $pd . $page;
  $tmp = fileLoad($tmp);
  $tmp =~ s|<|&lt;|g;
  $tmp =~ s|>|&gt;|g;
  chop $tmp if $tmp =~ /\n$/;
  return $html . $tmp .q|
</pre>
<hr>
</td></tr></table>|;
}

# convert query string to hash
#
sub _cto { die "child query read timeout" }

sub query2hash () {
  return () unless defined $ENV{REQUEST_METHOD};
  my $tmp = uc $ENV{REQUEST_METHOD};
  my $buff = '';
  if ('GET' eq $tmp && defined $ENV{QUERY_STRING}) {
    $buff = $ENV{QUERY_STRING};
  }
  elsif ('POST' eq $tmp && defined $ENV{CONTENT_LENGTH} && $ENV{CONTENT_LENGTH}) {
    eval {
	local $SIG{ALRM} = \&_cto;
	alarm 5;
	$tmp = read(STDIN,$buff,$ENV{CONTENT_LENGTH});
	alarm 0;
    };
    return () if $@;
  }
  else {
    return ();
  }
  my %qhash = ();
  my @content = split(/&/,$buff);
  foreach (@content) {
    $_ =~ s/\+/ /g;	# convert +'s to spaces
    my($key,$val) = split(/=/,$_,2);
# convert hex characters back to ascii
    $key =~ s/%(..)/pack("c",hex($1))/ge;
    $val =~ s/%(..)/pack("c",hex($1))/ge;
    if (exists $qhash{$key}) {
      $qhash{$key} .= "\0" . $val;
    } else {
      $qhash{$key} = $val;
    }
  }
  return %qhash;
}

# build a web page
#
# input:	pointer to specs,
#		pointer to pages
# prints:	to STDOUT
#
sub build {
  my($specs,$pp) = @_;
  my %query = &query2hash;
  my $page = $query{page} || 'Home';
  $page = 'Home' unless exists $pp->{$page};
  my $tmp = $pp->{$page}->{debug} || '';
  my $debug = '';
  if ($tmp) {
    $debug = $page;
    $page = $tmp;
  }
  my $mtime = checkspecs($specs);			# set defaults for missing specs

# update the site map if needed
  updsitemap($specs,$pp,$mtime);

# build the head
#
  my $pagedir = $specs->{pagedir};
  my $title = (exists $pp->{$page}->{title})
	? $pp->{$page}->{title}
	: (exists $pp->{$page}->{heading})
		? $pp->{$page}->{heading} : '';

  my $html = q|<!-- page built by Web::Scaffold version |. $Web::Scaffold::VERSION .q| -->
<head><title>| . $title .q|</title>
|;
  $tmp = fileLoad($pagedir . $page .'.meta');
  $tmp = fileLoad($pagedir .'Default.meta')
	unless $tmp;
  $html .= $tmp;
  $tmp = get_cols($pp,$page);
  $html .= stylegen($specs,$tmp);
  $html .= q|<script language="javascript1.2" src="|. $specs->{javascript} .q|winUtils.js">
</script>
<script language="javascript1.2" src="|. $specs->{javascript} .q|winMenus.js">
</script>
<script language="javascript1.2" src="|. $specs->{javascript} .q|scaffold.js">
</script>
|;
  $tmp = fileLoad($pagedir . $page . '.head');
  $tmp = fileLoad($pagedir .'Default.head')
	unless $tmp;
  $html .= $tmp;
  $html .= q|
</head>
<body bgcolor="|. $specs->{backcolor} .q|">
<noscript>
<font size=4 color=red>You must enable Javascript1.2 or better<br>to view
all the features on this page</font>
</noscript>

<form id="silent" name="silent" action=index.shtml method=get>
<input type=hidden name=page value="">
</form>
<table cellspacing=0 cellpadding=0 border=0 width="|. $specs->{pagewidth} .q|">
<tr><td>|;

  $tmp = fileLoad($pagedir . $page .'.top');
  $tmp = fileLoad($pagedir .'Default.top')
	unless $tmp;
  $html .= $tmp;
  $html .= q|</td></tr>
<tr><td>|;

  my $divtxt = '';
  if (	exists $pp->{$page}->{menu} &&
	ref $pp->{$page}->{menu} eq 'ARRAY' &&
	@{$pp->{$page}->{menu}} ) {
    (my $mnutxt,$divtxt) = menugen($pp,$page,$specs->{pagewidth},$debug);
    $html .= $mnutxt . q|</td></tr>
<tr><td>|;
  }
  if ($debug) {
    $html .=  srcgen($pp,$debug,$specs->{pagewidth},$pagedir);
  } else {
    $html .= bodygen($specs,$pp,$page,$specs->{pagewidth},$pagedir);
  }
  $html .= "\n". $divtxt .q|<font size=1>&nbsp;<p></font>
</td></tr>
|;
  if (	exists $pp->{$page}->{trailer} &&
	ref $pp->{$page}->{trailer} eq 'HASH' ) {
    $html .= q|<tr align=bottom><td>|. trailgen($specs,$pp,$page) . q|</td></tr>
|;
  }
  $html .= q|</table>
|;
  print $html;
}

###################################
# sitemap code
###################################

# check for LINKs and HREFs in a scaffold page
#
# input:	specs ptr,
#		sitemap ptr,
#		pages ptr,
#		page name
# returns:	last modified time for page
#
sub chk4links {
  my($specs,$sm,$pages,$pg) = @_;
#print "CHK4LINKS $pg\n";
# load page text
  local *H;
  my $html = '';
  opendir(H,$specs->{pagedir}) or die "could not open $specs->{pagedir}\n";
  my @files = grep($_ =~ /${pg}\.[^~]+$/,readdir(H));
  my $mtime = 0;
  
  foreach my $f (qw(meta head top)) {	# include defaults
    unless (grep(/$f$/,@files)) {
      push @files, 'Default.'. $f;
    }
  }
  {
#print "FILES = @files\n";
    undef local $/;
    foreach (@files) {
      my $file = $specs->{pagedir} . $_;
      next unless -e $file;		# skip non-existent defaults
      my $m = (stat($file))[9];
      $mtime = $m if $mtime < $m;
      next if $_ =~ /(?:meta|head)$/;
      next unless open(H,$file);
      $html .= <H>;
      close H;
    }
  }
# check for LINKS
  my @links;
  while ($html =~ m{LINK\<(.)([^>]+)>}) {
    $html = $` . $';			# reconstitute HTML with string removed
    my $sep = $1;
    my($plink,$text,$status) = parseLINK($1,$2);
    next if exists $sm->{$plink};
    if (exists $pages->{$plink}) {
      $sm->{$plink} = [$sep,$plink,$status];
      push @links, [$plink,1];
    } elsif ($plink !~ m|\://| && $plink !~ /\@/) {
      $sm->{$plink} = [$sep,$plink,$status];
      push @links, [$plink,0];
    }
  }
# all links collected and marked, recurse links
  foreach (@links) {
    my($plink,$isLINK) = @{$_};
    my $tab = $specs->{'_tab'};
    push @{$specs->{'_sm'}}, [$tab,$plink];
    if ($isLINK) {
      rcursite($specs,$sm,$pages,$plink);	# recurse if a menu page
    } else {
      chkLocalPage($specs,$sm,$plink);
    }
  }
# check for HREF's
  return $mtime if nosearch($specs,$pg);	# don't check links if no search
  chk4hrefs($specs,$sm,\$html);
  $mtime;
}

# check for HREFs in an string
#
# input:	specs ptr,
#		sitemap ptr,
#		string ptr,
#
sub chk4hrefs {
  my($specs,$sm,$hp) =@_;
#  while ($$hp =~ m{href=\"?([^?" \r\n]+)}) {
  my @links;
  while ($$hp =~ m{<a\s+href=\"?([^?" >\r\n]+)(.*?<)/a>}si) {
    my $match = $&;
    my $link = $1;
    $$hp = $` . $';			# reconstitute HTML with string removed
    $2 =~ />(.*?)</s;
    my $text = $1;
    next unless $text;
    unless (exists $sm->{$link} || $link =~ m|\://|s || $link =~ /\@/s) {
      my $sep;		# scoping error in perl foreach 5.6.1
      foreach ('#', '!', '%', '&',('0'..'9'),('A'..'Z'),('a'..'z')) {
	next if $match =~ /$_/s;
	$sep = $_;
	last;
      }
      $sm->{$link} = [$sep,$link,$text];
      push @links, $link;
    }
  }
# all links collected and marked, recurse them
  my $tab = $specs->{'_tab'};
  foreach my $link (@links) {
    push @{$specs->{'_sm'}}, [$tab,$link];
#print "ck4............. $link to LCL\n";
    chkLocalPage($specs,$sm,$link);
  }
}

# check for no search
#
# input:	pointer to specs
#		page name
# returns:	true = no search
#		else false
#
sub nosearch {
  my($specs,$pg) = @_;
  if (exists $specs->{nosearch}) {
    foreach(@{$specs->{nosearch}}) {
      return 1 if $pg =~ /$_/i;
    }
  }
  return 0;
}

# check an HTML page for HREF's
#
# input:	specs ptr,
#		sitemap ptr,
#		string ptr
#
sub chkLocalPage {
  my($specs,$sm,$pg) = @_;
  $pg =~ s|/||
	if $pg =~ m|^/|;
  return unless -e $pg;
  ${$sm->{$pg}}[3] = (stat($pg))[9];
  return if nosearch($specs,$pg);
#  ++$specs->{'_tab'};
  local *F;
#print "LOCLPG $pg\n";
  return unless open(F,$pg);
  undef local $/;
  my $html = <F>;
  close F;
  chk4hrefs($specs,$sm,\$html);
#  --$specs->{'_tab'};
}

# recurse through scaffold pages beginning with 'page' to build sitemap
#
# input:	specs ptr,
#		sitemap ptr,
#		pages ptr,
#		page name
#
sub rcursite {
  my($specs,$sm,$pages,$pg) = @_;
  return unless exists $pages->{$pg} && exists $pages->{$pg}->{menu};   # skip debug pages
  my $tab = ++$specs->{'_tab'};
#print "RPAGE = ........ $pg\n";
  my $count = 0;
# check menu's
  my @pages = @{$pages->{$pg}->{menu}};
  if (exists $pages->{$pg}->{submenu}) {
    push @pages, @{$pages->{$pg}->{submenu}};
  }
  if (exists $pages->{$pg}->{trailer} && exists $pages->{$pg}->{trailer}->{links}) {
    push @pages, @{$pages->{$pg}->{trailer}->{links}};
  }
  my @lclks;				# local links this page
  foreach (0..$#pages) {
    my $pgname = $pages[$_];
    next if exists $sm->{$pgname};		# pick off most of the page names early
#print "PROCESS $pgname\n";
    my $text = my $status = $pgname;
    my $sep = '#';
    unless (exists $pages->{$pgname}) {
      $pgname =~ m{(.)(.+)};		# skim off the first character
      $sep = $1;
      ($pgname,$text,$status) = parseLINK($1,$2);
      $text = $pgname unless $text;
      $status = $text unless $status;
      $pages[$_] = $pgname;
    }
    next if exists $sm->{$pgname};		# pick off all processed page names
    if (exists $pages->{$pgname}) {			# if this is a scaffold page
      $sm->{$pgname} = [$sep,$pgname,$status];
      push @lclks, [$pgname,1];
    }
    elsif ($pgname !~ m|\://| && $pgname !~ /\@/) {	# or a link but not absolute or mail
      $sm->{$pgname} = [$sep,$pgname,$status];
      push @lclks, [$pgname,0];
    }
  }
#  chk4links($specs,$sm,$pages,$pg)
#	unless exists $sm->{$pg};
# page level is established, recurse each link
  foreach (@lclks) {
    my($pgname,$isLINK) = @{$_};
    push @{$specs->{'_sm'}}, [$tab,$pgname];
#print "RECURSING $pgname\n";
    if ($isLINK) {
      rcursite($specs,$sm,$pages,$pgname);
    }
    else {
#print "rcur........... $pgname to LCL\n";
      chkLocalPage($specs,$sm,$pgname);
    }
  }
  ${$sm->{$pg}}[3] = chk4links($specs,$sm,$pages,$pg);
  --$specs->{'_tab'};  
}

# build a sitemap structure
#
# input:	specs ptr,
#		pages ptr
#
# returns:	sitemap hash pointer
#
# REMEMBER to DELETE $specs->{_tab} {_sm} when done
#
sub sitestruct {
  my($specs,$pages) = @_;
  $specs->{'_tab'} = 0;
  $specs->{_sm} = [];
  my $sitemap = {
	Home	=> ['#','Home','Home'],
	Default	=> ['#','Default','Default'],
  };
  push @{$specs->{_sm}}, [0,'Home'];
#  chk4links($specs,$sitemap,$pages,'Home');
  chk4links($specs,$sitemap,$pages,'Default');	# include Default contents
  delete $sitemap->{Default};			# page name does not belong in sitemap
  rcursite($specs,$sitemap,$pages,'Home');
  chkLocalPage($specs,$sitemap,'index.shtml');
  return $sitemap;
}

# return xml time for sitemap xml files
#
# input:	time since the epoch
# returns:	yyyy-mm-dd
#
sub xmltime {
  my $time = shift;
  my($mday,$mon,$year) = (localtime($time))[3,4,5];
  ++$mon;
  $year += 1900;
  return sprintf("%04d-%02d-%02d",$year,$mon,$mday);
}

# build html and xml sitemap pages
#
# input:	specs ptr,
#		pages ptr,
#		sitemap ptr
#
# returns:	html string, xml string
#
sub sitemap {
  my($specs,$pp,$sm) = @_;
  my $html = '';
  my $port = $ENV{SERVER_PORT} || 80;
  $port = ($port == 80)
	? '' : ':'. $port;
  my $srvr = $ENV{SERVER_NAME} || 'WebScaffoldText';
  my $xml = q|<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
|;

  my $now = xmltime(time);
  my $mtime = (stat($specs->{pagedir}))[9];
  $mtime = xmltime($mtime);
  my $cf = $specs->{changefreq};

  foreach (@{$specs->{'_sm'}}) {
    my($tab,$page) = @{$_};
    while (0 < $tab--) {
      $html .= '&nbsp;&nbsp;&nbsp;&nbsp;';
    }
    my($sep,$pg,$txt,$m) = @{$sm->{$page}};
    $m = 0 unless $m;
    my $ftime = xmltime($m);
#print "SEP='$sep' PG='$pg' TXT='$txt'\n";

# generate html
    $html .= 'LINK<'. $sep . $pg . $sep . $txt . $sep . $txt ."><br>\n";
# generate xml
    $xml .= q|<url>
  <loc>http://|. $srvr . $port;
    if (exists $pp->{$pg}) {		# if this is a scaffold page
      $xml .= q|/index.shtml?page=|. $pg .q|</loc>|;
    } else {
      if ($pg =~ m|^/|) {
	$pg = $';
      }
      $xml .= '/'. $pg . q|</loc>|;
    }
    $xml .= q|
  <lastmod>|. $ftime .q|</lastmod>
  <changefreq>|. $cf .q|</changefreq>
</url>
|;
  }
  $xml .= q|</urlset>
|;
  $html = fixLINKs($pp,$html);
  return ($html,$xml);  
}

# check and update the sitemap
#
# input:	specs ptr,
#		page ptr,
# returns:	sitemap structure pointer
#		else false
#
# writes htxt and xml pages if needed
#
sub updsitemap {
  my($specs,$pages,$pgt) = @_;
  return undef unless exists $specs->{sitemapdir} &&	# no update required, no sitemap
	 -e $specs->{sitemapdir} &&
	 -w $specs->{sitemapdir};
  my $smt = 0;						# trial sitemap timestamp
  my $smf = $specs->{sitemapdir} .'sitemap.xml';
  if (-e $smf) {
    $smt = (stat($smf))[9];
  }
  return undef if $pgt <= $smt;

  local(*LOCK, *F);
  my $perms = 0644;
  my $oldmask = umask 022;
  unless (sysopen LOCK, $smf .'.lock', O_RDWR|O_CREAT|O_TRUNC, $perms) {
    umask $oldmask;
    $! = 11;		# 11 Resource temporarily unavailable
    return undef;
  }
  umask $oldmask;
  unless (flock(LOCK, LOCK_EX())) {
    close LOCK;
    return 0;
  }

# build the sitemap structure
  my $sm = sitestruct($specs,$pages);

# build the html and xml text
  my($htext,$xtext) = sitemap($specs,$pages,$sm);

# write the files
  if (open(F,'>'. $smf .'.tmp')) {
    print F $xtext;
    close F;
    rename $smf .'.tmp', $smf;				# atomic update
  }
  $smf = $specs->{sitemapdir} .'sitemap.htxt';
  if (open(F,'>'. $smf .'.tmp')) {
    print F $htext;
    close F;
    rename $smf .'.tmp', $smf;
  }
  flock(LOCK,LOCK_UN());
  close LOCK;
}

# generate the structure of the site map, human readable
# 
# input:	specs ptr,
#		sitemap ptr
#
# returns:	text
#
sub debugstruct {
  my($specs,$sm) = @_;
  my $txt = '';
  foreach (@{$specs->{'_sm'}}) {
    my($tab,$page) = @{$_};
    while (0 < $tab--) {
      $txt .= '    ';
    }
    $txt .= "@{$sm->{$page}}\n"
  }
  return $txt;
}

# generate the sitemap contents, not ordered, human readable
#
# input:	sitemap ptr
#
# returns:	text
#
sub debugsmap {
  my $sitemap = shift;  
  my $txt = '';
  foreach (sort keys %$sitemap) {
    my @ary = @{$sitemap->{$_}};
    $txt .= "$_\t => @ary\n";
  }
}


## generate sitemap hash
#my $sm = sitestruct(\%specs,\%pages);


#my ($htext,$xtext) = sitemap(\%specs,\%pages,$sm);

#print $htext,"\n\n",$xtext;
#print debugstruct(\%specs,$sm);

#  checkspecs(\%specs);

#if (updsitemap(\%specs,\%pages)) {
#  print "DONE\n";
#} else {
#  print "NOTHING\n";
#}
#delete $specs{_sm};
#delete $specs{_tab};

1;
__END__

=head1 NAME

  Web::Scaffold -- build minimalist fancy web sites

=head1 SYNOPSIS

  use Web::Scaffold;

  Web::Scaffold::build(\%specs,\%pages);

=head1 DESCRIPTION

B<Web::Scaffold> is a module that allows you to easily and quickly build a
fancy web site with drop down menus an a variable number of columns. This is
accomplished with a simple specification and a series of minimal html page
includes that are written in very basic html. 

In its simplest form, your web will have the following structure:

  pages/	contains minimalist html pages
  ws_sitemap/	[optional] contains sitemap in google xml format
		NOTE: link this into public_html
  public_html/	contains the index page and
		any non Web::Scaffold pages
	images/	contains web site images
	lib/	contains javascript library(s)

The index pages requires Server Side Includes (SSI) and is as follows:

  <html>
  <!-- page name "index.shtml"
  place your comments, revision number, etc... here
  -->
  <!--#exec cmd="./pages.cgi" -->
  </body>
  </html>

Alternatively, you can use the included B<pages.cgi> script as an example to
build your own more sophisticated cgi or mod_perl application.

An illustrated sample web site can be viewed here:

=head1 SAMPLE WEBSITE

=head2 L<http://www.bizsystems.net/downloads/webscaffold/>

=head1 CONFIGURATION

=head2 build(%specs,%pages)

A web site with drop down menus can be complete configured with two hash
arrays. The B<%specs> array configures the style and form of the site and
the B<%pages> array configures the menus and column layout.

=over 4

=item %specs

The specifications for fonts, menu, links, colors

  %specs = (

  # directory path for 'html pages' relative to the html root
  # i.e. public_html/        defaults to:
  #
	pagedir		=> '../pages',

  # directory path for 'javascript libraries' relative to html root
  # defaults to:

	javascript	=> 'lib',

  # no search conditions for building the site map. Each
  # element is evaluated as a perl match condition in the
  # context of m/element/. Include page names, extensions, etc...
  #
  # [OPTIONAL]
  #

	nosearch	=> [ 'pdf' ],

  # Directory path for 'sitemap' page generation relative to the 
  # html root. This directory must be WRITABLE by the web server.
  #
  # NOTE: link the file 'sitemapdir'/sitemaplxml to the 
  # appropriate location in your web directory.
  # 
  # The sitemap.xml file will be generated and updated ONLY if 
  # the 'sitemapdir' key is present in this configuration file.
  #
  # The sitemap page will auto update if you modify pages in
  # 'pagedir' or in the 'autocheck' list below. If you modify 
  # static pages elsewhere in the web directory tree that are
  # not listed in 'autocheck', you must DELETE the sitemap.xml 
  # file to force an update.
  #
  # [OPTIONAL]
  #
  #	sitemapdir	=> '../ws_sitemap',

  # Directories to autocheck for sitemap update.
  # you can list BOTH directories and individual files
  # here relative to the web root. The 'sitemapdir' and
  # 'pagedir' are always checked and do not need to be
  # listed here.
  #
	autocheck	=> ['docs'],

  # site map <changefreq> hint
  #
  # defaults to:
  #
	changefreq	=> 'monthly',

  # font family used throughout the document
  #
	face		=> 'VERANDA,ARIAL,HELVETICA,SAN-SERIF',

  # background color of the web page
  # this can be a web color like 'white' or number '#ffffff'
  #
	backcolor	=> 'white',

  # Menu specifications
  #
	barcolor	=> 'red',
	menudrop	=> '55',	# drop down position
	menuwidth	=> '100px',	# width of menu item
	pagewidth	=> '620px',	# recommended
  # menu font specifications
	menucolor	=> 'black',
	menuhot		=> 'yellow',	# mouse over
	menucold	=> 'white',	# page selected
	menustyle	=> 'normal',	# bold, italic
	menusize	=> '13px',	# font points or pixels
	sepcolor	=> 'black',	# separator color

  # Page link font specifications
  #
	linkcolor	=> 'blue',
	linkhot		=> 'green',
	linkstyle	=> 'normal',	# bold, italic
	linksize	=> '13px',	# font points or pixels

  # Page Text font specifications
  #
 	fontcolor	=> 'black',
	fontstyle	=> 'normal',
	fontsize	=> '13px',

  # Heading font specifications
  #
	headcolor	=> 'black',
	headstyle	=> 'bold',	# normal, italic
	headsize	=> '16px',
  );

=item %pages

The specifications for menus and pages. Menus can be single link or a series
of drop down menu depending on how you specifiy the page. The page names are
the keys to the hash and are used as the menu-bar link text. All page files
are placed in the 'pages' directory. 

FILE NAME SYNTAX:

Files are named with the 'key' name of the page as the lefthand side and 
a suffix designating the file's purpose as the right hand side. For the 
required page 'Home', they are as follows:

 # [optional] page used if there are not individual pages
 # NOTE: neither a Default page or individual page is required
  Default.meta		# meta text loaded after <title>
  Default.head		# optional additional <head> text
			# that is on every page, end of page
  Default.top		# optional body text that appears
			# on every page before menu-bar
			# i.e. logo, etc...
 # for each individual page
  Home.meta		# meta text loaded after <title>
  Home.head		# optional additional <head> text
  Home.top		# body text that appears before
			# menu-bar. i.e. logo, etc...
  Home.c1		# [optional] column 1 content
  Home.c2		# [optional] column 2 content
  Home.cn		# [optional] column 'n' content

  %pages = (

  # REQUIRED page
  #
	Home	=> {
  #			SEE: detailed link format below
	    menu	=> ['Home', 'Page1', 'Page2', 'Page5'],
  # optional title text - if missing, 'heading' text will be used
	    title	=> 'page title',

  # optional table row immediately under menu. This allows a "drop"
  # shadow to be added to the menu bar with a "1" pixel wide image, 'example'
	    menustripe	=> '<img src="images/stripe1.gif" height=4 width=100%>',

  # optional
	    heading	=> 'Text under menu, over body text',

  # number of columns and column width in pixels
	    column	=> [20, 200, 400],    # three columns

  # optional
	    submenu	=> [qw(Page3 Page4)], # drop down menu

  # optional trailer bar
	    trailer	=> {

  # a named page
		links	=> [qw(Page5 Page6)],

  # optional right hand side text. if there are no links then the
  # text will be placed on the left hand side of the trailer bar
		text	=> 'Copyright 2006, yourname',

  # optional table row immediately above trailer bar. this allows a "drop"
  # shadow to be added to trailer bar with a "1" pixel wide image, 'example'
		top	=> '<img src="images/stripe2.gif" height=4 width=100%>',

  # optional table row immediately below trailer bar. This allows a "top" 
  # shadow to be added to trailer bar with a "1" pixel wide image,  'example'
		bottom	=> '<img src="images/stripe1.gif" height=4 width=100%>',
	    },
	},

  # next page
  #
	Page1	=>	... same as above
	},
  #
  #	... and so on

  # for the auto-generated Sitemap page, there is one additional
  # specification element...
  #
	Sitemap	=> {
		...
  # specify the column in which the sitemap should appear
  # defaults to '1'
		autocol	=> 1,
		...
	},


  # and for debug... example
  # load this page segment as source in a single window

	'Home.top' => {

  # copy prototype page from this one page.

	    debug	=> 'Home',

  # optional location if not in the 'pages' directory
  #
	    location	=> 'path/to/filename',
	},
  );

=back

=head1 OPERATION

The sample index.shtml and pages.cgi script may be used together with the
above specification and configuration data to produce a multi-page web site
with with drop down menus. Each of the sub-pages specified in the ./pages
directory may be prepared in a simple text editor with 'basic' html
formating. LINKS WITHIN THE PAGE may be regular html or to take advantage
of the MouseOver and STATUS reporting features of Web::Scaffold, may be 
specified using the special syntax:

=head2 Menu and Trailer link format

There are two acceptable formats for links used in the MENU and TRAILER
sections of a page specification:

=over 4

=item 1 PageName

This is simply the key to the %pages array and its value will be used as the
text for the LINK and the display value in the browser STATUS bar.

=item 2 {separator}key or URL{separator}link text{separator}status text

This syntax allows for either a PageName as above or a file/http URL value
to be used as the link target. The separator may be any printable ASCII
character except B<{}>. The C<link text> and C<status text> values are
optional. C<link text> will be filled from the key/URL value if it is not
present. C<status text> will be filled from the link text or from the
key/URL value if link text is not present.

  Example:
    #http://my.website.com#visit my website#MY WEBSITE#

Note that an optional separator character may terminate the link string.

=back

=head2 Embedded Links Within Page Text

The syntax for embedded page links is similar to above with the addition of
a keyword and enclosing brackets.

  LINK<#page_name#optional link text#optional status text#>
or
  LINK<#URL#optional link text#optional status text#>

  LINK may also be specified with a CLASS designator for CSS
  The default class is "B"

  Alternate class designations may be specified for classes C thru Z
  which you can then define in a CSS STYLE statement in the [page].head
  portion of the give page.

  Example:
A.C {
  color: #6666FF;
  background: transparent;
  font-family: VERANDA,ARIAL,HELVETICA,SAN-SERIF;
  font-weight: bold;
  font-size: 16px;
  text-decoration: underline;
}
A.C:hover {
  color: #00CC00;
}

Exact syntax for LINK is as follows:

  uppercase word	"LINK"
  optional CLASS	C through Z  (default is B)
  less than symbol	<
  delimiter (any char)	#
  page name or url text	./dir/file or http://....
    [optional] link and status fields
  delimiter		#
  link text		optional text for link
  delimiter		#
  status bar text	optional browser status bar text
  delimiter		# [optional] closing delimiter
     required
  greater than symbol	>

Where the first syntax refers to a named page in the %pages array and the
second syntax refers to a real URL optionally followed by the text to 
appear as the "link" text and in the status bar.

Line breaks are not allowed in LINKE<lt>#text>

B<Web::Scaffold> builds the page with menus and incorporates the various
include files (page.head, page.top, page.c1, page.c2, etc...) to produce a
website that can be easily and quickly maintained by simply editing the page
includes.

Each web page assembled by B<Web::Scaffold> as follows:

  <html>
  <head>
  <title> [from page title or heading] </title>
  [optional] Default.meg\ta or Page.meta
  internally generated style statements
  [optional] Default.head or Page.head
  </head>
  <body>
  [optional] Default.top or Page.top
  [optional] menu bar as specified for this Page
  internally generated column specification for this Page
  {    column 1    }{    column 2    }......{    column N    }
   Page.c1 or blank  Page.c2 or blank .etc.. Page.cN or blank
  [optional] trailer
  </body>
  </html>

=head2 Sitemap

B<Web::Scaffold> will automatically write as sitemap.xml sitemap file and a
corresponding scaffold page named B<Sitemap.htxt> the first time the site is
accessed if the specification KEY, 'sitemapdir' for
the sitemap is present. 

If you modify any pages in the scaffold 'pagedir' or pages or directories 
listed in the 'autocheck' list, the sitemap will
auto update. If you modify a static page elsewhere in the web site that are
not listed in 'autocheck', you must DELETE sitemap.xml to force and
update.

You must include a spec for the B<Sitemap> page in the %pages configuration.

If you wish to use your own sitemap, do not activate the specification KEY.

=head1 AUTHOR

Michael Robinton E<lt>michael@bizsystems.comE<gt>

=head1 COPYRIGHT AND LICENSE

This notice does NOT cover the javascript libraries. Those libraries are
freely usable but copyright and licensed all or in part by others and
have their own copyright notices and license requirements. Please read 
the text in the individual libraries to determine their specific licensing
and copyright notice requirements.

Copyright 2006 - 2010, Michael Robinton E<lt>michael@bizsystems.comE<gt>
 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 

=cut

1;
