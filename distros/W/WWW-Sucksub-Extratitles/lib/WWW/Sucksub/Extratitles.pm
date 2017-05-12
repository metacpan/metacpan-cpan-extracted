package WWW::Sucksub::Extratitles;


=head1 NAME

WWW::Sucksub::Extratitles - automated access to Extratitles.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

SuckSub::Extratitles is a web automat based on the WWW::Mechanize Module
This module search and collect distant result on the Extratitles.com database.
Subtitles Files are very little files, Sucksub::Divstation store all results
in a dbm file that you can exploit to retrieve any subtitles information.



    use WWW::Sucksub::Extratitles;
    my $foo = WWW::Sucksub::Extratitles->new(
    					dbfile=> '/where/your/DBM/file is.db',
					html =>'/where/your/html/repport/is.html',
					motif=> 'the word(s) you search',
					debug=> 1, 
					language=>'English'
					logout => '/where/your/debug/info/are/written.log',	  						);
    $foo->update(); 	# collect all link corresponding to the $foo->motif()
    $foo->motif('x'); 	# modify the search criteria 
    $foo->search();	# launch a search on the local database 

  

=head1 CONSTRUCTOR AND STARTUP

=head2 Extratitles Constructor 

The new() constructor, is associated to default values :
you can modify these one as shown in the synopsis example.

	my $foo = WWW::Sucksub::Extratitles->new(
		html=> "$ENV{HOME}"."/sksb_Extratitles_report.html",
		dbfile=> "$ENV{HOME}"."/sksb_Extratitles_db.db",
		motif=> undef,
		debug=> 0,
		language => 'English'
		logout => undef, # i.e. *STDOUT	  					
		useragent=> "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007"
    		);

=head3 new() constructor attributes and associated methods

Few attributes can be set thru new() contructor's attributes.
All attributes can be modified by corresponding methods:

	$foo->WWW::Sucksub::Extratitles->new()
	$foo->useragent() # get the useragent attribute value
	$foo->useragent('tructruc') # set the useragent attribute value to 'tructruc'


=head4 cookies_file()

arg must be a file, this default value can be modified by calling the 

  	$foo->cookies_file('/where/my/cookies/are.txt')

modify the default value positionned by the new constructor.

	$foo->cookies_file() 
	
return the actual value of the cookies file path.

=head4 useragent()

arg should be a valid useragent. There's no reason to change this default value.

	$foo->useragent()
	
return the value of the current useragent.

=head4 motif()

you should here give a real value to this function :
if $foo->motif is undef, the package execution will be aborted

	$foo->motif('xxx')

allows to precise that you're searching a word that contains 'xxx'

	$foo->motif()
	
return the current value of the string you search.

=head4 language()

Allows to set the langage for the subtitle search.

Default value is 0 : it means that all langages will be returned

	$foo->langage('french')

allows to precise that you're searching a french subtitles
Common langages string values are :

Albanian
Argentino
Bosnian
Brazilian_portuguese
Bulgarian
Bulgarian_English
Chines GB code
Chinese
Croatian
Czech
Danish
Dutch/English
English
English - Hearing Impaired
English_German
Estonian
Finnish
French
German - Hearing Impaired
Germany
Greek
Hebrew
Hungarian/English
Hungary
Icelandic
Italy
Japanese
Kalle
Korean


=head4 debug()

WWW-Sucksub-Extratitles can produce a lot of interresting informations
The default value is "0" : that means that any debug informations will be written
on the output ( see the logout() method too.)

	$foo->debug(0) # stop the product of debbugging informations
	$foo->debug(1) # debug info will be written to the log file ( see logout() method)

=head4 logout()
  			
if you want some debug information : args is 1, else 0 or undef

		logout => undef; 

output and optional debugging info will be produced on STDOUT
or any other descriptor if you give filename as arg.

=head4 dbfile()

define dbm file for store and retrieving extracted informations
you must provide a full path to the db file to store results.
the search() method can not be used without defined dbm file.

 	dbfile('/where/your/db/is.db')

The file will should be readable/writable.

=head4 html()

Define simple html output where to write search report.
you must provide au full path to the html file if you want to get an html output.

 	html('/where/the html/repport/is/written.html')

If $foo->html() is defined. you can get the value of this attribute like this :

	my $html_page = $foo->html

html file will be used for repport with update() and search() methods.
The html page IS NOT a W3C conform html. It only allows to have a direct access to http links. 

=head1 METHODS and FUNCTIONS

these functions use the precedent attributes value.

=head2 search() 

this function takes no arguments.
it alows to launch a local dbm search.

	$foo-> search()

the dbm file is read to give you every couple  (title,link) which corresponds to
the motif() pattern.

=head2 update() 

this function takes no arguments.
it allows to initiate the distant search on the web site Extratitles.com
the local dbm file is automatically written. Results are accumulated to the dbm file
you define with the .

=head2 get_all_result() 

return a hash of every couple ( title, http link of subtitle file ) the search or update method returned.

	my %hash=$foo->get_all_result()


=head1 SEE ALSO

=over 4

=item * L<WWW::Mechanize>

=item * L<DB_FILE>	

=item * L<HTTP::Cookies>

=item * L<WWW::Sucksub::Frigo>

=item * L<WWW::Sucksub::Attila>

=item * L<WWW::Sucksub::Divxstation>

=item * L<WWW::Sucksub::Vostfree>

=back

=head1 AUTHOR

Timothée foucart, C<< <timothee.foucart@apinc.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sucksub-Extratitles@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Sucksub-Extratitles>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Timothée foucart, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use warnings;
use strict;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT=qw(  cookies_file debug dbfile  
		 get_all_result html logout 
		 motif search update useragent language );
		 
use utf8;
use Carp;
use HTTP::Cookies;
use WWW::Mechanize;
#	 
#
# --
#		 
use Alias qw(attr);
use vars qw( $base  $site $cookies_file $useragent  $motif  $debug  $logout $html $dbfile $okdbfile $nbres $totalres %sstsav $fh $language %langhash);
#
# global var
my $fh;
my %sstsav;
my %langhash;
$langhash{'all'}='0';
$langhash{'Albanian'}='42';
$langhash{'Argentino'}='43';
$langhash{'Bosnian'}='44';
$langhash{'Brazilian_portuguese'}='13';
$langhash{'Bulgarian' }='14';
$langhash{'Bulgarian_English' }='15';
$langhash{'Chines GB code' }='32';
$langhash{'Chinese' }='16';
$langhash{'Croatian' }='17';
$langhash{'Czech' }='2';
$langhash{'Danish' } ='12';
$langhash{'Dutch/English' }='33';
$langhash{'English' }='1';
$langhash{'English - Hearing Impaired' }='34';
$langhash{'English_German' }='18';
$langhash{'Estonian'}='35';
$langhash{'Finnish'}='5';
$langhash{'French'}='6';
$langhash{'German - Hearing Impaired' }='36';
$langhash{'Germany' }='7';
$langhash{'Greek' }='19';
$langhash{'Hebrew' }='37';
$langhash{'Hungarian/English'}='38';
$langhash{'Hungary' }='8';
$langhash{'Icelandic' }='20';
$langhash{'Italy'}='3';
$langhash{'Japanese'}='39';
$langhash{'Kalle'}='21';
$langhash{'Korean'}='22';
$langhash{'Latvian'}='40';
$langhash{'Lithuanian'}='45';
$langhash{'Macedonian'}='41';
$langhash{'Netherlands'}='10';
$langhash{'Norwegian'}='23';
$langhash{'Polish'}='4';
$langhash{'Portuguese'}='24';
$langhash{'Romanian'}='30';
$langhash{'Russian'}='25';
$langhash{'Serbian'}='29';
$langhash{'Slovak'}='31';
$langhash{'Slovenian'}='28';
$langhash{'Spanish'}='9';
$langhash{'Swedish'}='11';
$langhash{'Turkish'}='26';
$langhash{'other' }='27';
#
#
sub new{
	 	my $Extratitles=shift;
		my $classe= ref($Extratitles) || $Extratitles;
	 	my $self={	};
	 	bless($self,$classe);
	 	$self->_init(@_);
	 	logout($self->{logout});
	 	#language($self->{language});
	 	return $self;
};
 sub _init{
 	my $self= attr shift;
 	#
 	# -- init default values
 	#
 	$self->{base} = "http://titles.box.sk/";
	$self->{site} = "http://titles.box.sk/index.php";
	$self->{cookies_file} = "$ENV{HOME}"."/.cookies_sksb";
	$self->{useragent} = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007";
	$self->{motif}  = undef;
	$self->{debug}  = 1;
	$self->{logout} = undef; 
	$self->{html} = "$ENV{HOME}"."/Extratitles_report.html";
	$self->{dbfile} = "$ENV{HOME}"."/Extratitles_db.db";
	$self->{okdbfile} = 0;
	$self->{sstsav} ={};
	$self->{language} ='all';
 	#
 	# -- replace forced values
 	#
 	if (@_)
 		{
 		my %param=@_;
 		while (my($x,$y) =each(%param)){$self->{$x}=$y;};
 		}
 	return $self;
};

sub useragent { 
	my $self =attr shift;
	if (@_) {$useragent=shift;}
	return $useragent;
	}

sub dbfile { 
	my $self =attr shift;
	if (@_) {$dbfile=shift;$okdbfile=1};
	if ($okdbfile==0) {return undef;};
	return $dbfile;
	}
sub debug { 
	my $self =attr shift;
	if (@_) {$debug=shift;}
	return $debug;
	}
sub _sstsav { 
	my $self =attr shift;
	if (@_) {%sstsav=shift;}
	return %sstsav;
	}
sub get_all_result { 
	my $self =attr shift;
	%sstsav=$self->_sstsav();
	return %sstsav;
	}
sub cookies_file { 
	my $self =attr shift;
	if (@_) {$cookies_file=shift;}
	return $cookies_file;
	}
sub motif { 
	my $self = attr shift;
	if (@_) {$motif=shift};
	return $motif;
	}	
sub logout { 
	if (@_){$logout=shift; }
      	if ($logout)
		{ open(FH , ">>", $logout) or croak " can not open $logout : $!\n"; 
		   $fh=(\*FH);} 
	else 
		{  open (FH, ">&STDOUT" )    or croak "Can't dup STDOUT: $!";
			$fh=(\*STDOUT);};
	return $logout;
	}	
sub html { 
	my $self =attr shift;
	if (@_) {$html=shift;}
	else {$html=$self;};
	unless (-e ($html))
		{
		print $fh "[DEBUG] html report file doesn't exists \n";
		print $fh "[DEBUG] default value is now :  ".$self->{html}." \n";
		}
	return $html;
	}
sub _open_html{
	open(HTMLFILE,">>",$html)
			or croak "can not create $html : $! \n";
	print HTMLFILE "<hr> <small>report generated by suckSub perl module<br>\n";
	print HTMLFILE "searching : ".motif()." on ".$site."<br>\n";
	print HTMLFILE " ".localtime()."</small><br>\n";
	return;
}
sub language{	
my $self =attr shift;
if (@_){$language=shift;
	  if (defined($langhash{$language}))
		{
		my $lang=$langhash{$language};
		printf "langage is now set to ".$language." [ ".$lang." ]\n" if ($debug);
		return $lang;}
	  else
		{ croak "language $language is not recognized !\n";};
	};
};
sub update {
	my $self =attr shift;
	unless ($motif){croak "You must provide a string value to motif()....exit\n";};
	my $mech = WWW::Mechanize->new(agent=>$useragent,
						cookie_jar => HTTP::Cookies->new(
						file => $cookies_file,
						autosave => 1,
						ignore_discard => 0,
							),
						stack_depth => 1,
					);
	my $next=0;# next page indicator (0/1)
	
if ($html){_open_html();};
print $fh  "------------------------------------------------------------------------------------------------\n" if ($debug);
print $fh  "[DEBUG] begin scan on $site  at : ".localtime()."\n" if ($debug);
print $fh  "[DEBUG] searching : ".$motif." on $site  \n" if ($debug);
my $page = 1; #   pagination
if ($debug) {print $fh   "\n[DEBUG \t Extratitles PAGE $page]\n";}; 
$mech->get('http://titles.box.sk/index.php?p=se&pas=as') or warn "[WARNING] http get problem on : $site !! \n";
# launch advanced search research
$mech->form_name('as_form');
$mech->select( 'jaz' , $langhash{$self->{language}}  );#i.e. langage = french
$mech->field( 'z3' , $motif,1 );
$mech->field( 'p', 'se',1 );
$mech->click();
if ($debug) { print $fh  "[DEBUG \t GET URL \t : \t  ".$mech->uri()."]\n" if ($debug);}; 
# so we parse all result page one by one
($nbres,$next) = _parse_Extratitles($mech,$page);
printf $fh "[DEBUG] next page detected \n" if $debug;
$totalres=$nbres;
#
#  verify if we need to change page to get next search results
#
while ($next>0)
	{ 	
		$page = $page+1;
		#http://titles.box.sk/index.php?pid=subt2&p=se&bp=40&bn=0&z3=e&jaz=6
	  	#								|	|	|    \langage
	  	#								|	|	\z3=search motif								
	  	#								|	\display range begin
	  	#								\number of subtitles to display 
	  	my $nbdisp=$page*20;
	  	$mech->get( "http://titles.box.sk/index.php?pid=subt2&p=se&bp=20&bn=".$nbdisp."&z3=".$motif."&jaz=".$langhash{$self->{language}})
	  		or warn "get problem on page  : $page : $! \n";
	  	if ($debug) { print $fh  "[DEBUG \t PAGE : $page]\n";print $fh    "[DEBUG \t GET URL \t : \t ".$mech->uri() ."]\n";}; 
		($nbres,$next) = _parse_Extratitles($mech,$page);
		$totalres=$totalres+$nbres;
	};
	
#
print $fh   "[DEBUG \t :  $totalres found on $base]\n" if ($debug);
print $fh   "[END]\n" if ($debug);
#print html report
if ($html)
{
	$nbres=0;
	while (my ($k,$v) =each(%sstsav))
		{
		print HTMLFILE "<a href=\"".$k."\">".$v."</a><br>\n";
		$nbres++;
		}
			
}
#finish and close all open file(s)
if ($html)
	{
	print HTMLFILE "<br><b>".$nbres." result(s) found</b> <br>\n";
	print HTMLFILE " report finished at ".localtime()."<br>\n";
	}


close HTMLFILE;
return;
};	

#
# ---local search if $dbfile exist
#
sub search {
	my $self =attr shift;
	unless ($motif){croak "You must provide a string value to motif() attribute....exit\n";};
	unless ($dbfile) { croak " no DB file defined : exit ... \n";};
	#html report
	if ($html)
		{
		open(HTMLFILE,">>",$html)
				or croak "can not create $html : $! \n";
		print HTMLFILE "<hr> <small>local search on dm file : $dbfile <br>\n";
		print HTMLFILE "searching : ".$motif." on ".$site."<br>\n";
		print HTMLFILE " ".localtime()."</small><br>\n";
		};
	#print html report
	#local search  --> print and finish html report
	_search_dbm($dbfile);
return;
	
};		
#	
#--- this function = to parse only one result page
#
sub _parse_Extratitles{
	my $mech=$_[0];my $page =$_[1];
	my $jnd=0; my $jnd2=0;
	my $oktitle=0;my $okurl=0;
	my $next_page_exists=0;
	my $f_url; my $f_title;
	my $lnk=$mech->find_all_links(); 
	my $nbl = $#{$lnk}; my $ind=0;
	print $fh "[DEBUG] searching links on : ".$mech->uri()." ]\n" if ($debug);

# =4= rechercher les liens des reponses de la recherche
	my @sstlist=[];my @ssturl=[];# memo array
	for ( my $ind=0; $ind < $#{$lnk} ; $ind++)
	{
	# search and memorize the subtitle label
	# can be fixed if site changes
	# --Title links should have these syntax :
	# --http://titles.box.sk/index.php?pid=subt2&p=i&rid=<a number> 207488
	# --Subtitle file must have an url text = "DOWNLOAD"
      	#search lovie name
      	if 	(	($lnk->[$ind]->url() =~ m/(^?pid=subt2\&p=i\&rid=)([0-9]+$)/g ) 
	   			and ($lnk->[$ind]->text()!~m/MORE INFO/)
	   		)
	  		{  	
				push @sstlist,$lnk->[$ind]->text();
	                  print $fh "[FOUND MOVIE NAME]\n\t".$lnk->[$ind]->text()."\n" if $debug; 
				$f_title=scalar($lnk->[$ind]->text());
				$oktitle=1;
			};
		#    search subtitle url to download
		# test if text() is f=defined avoid warning
		# then if found, we can save in sstsav hash
		if (  (defined($lnk->[$ind]->text()) and ($lnk->[$ind]->text() =~m/(\DOWNLOAD)/) )
		   )
		   {
		   	push @ssturl,$lnk->[$ind]->url_abs();
		   	print $fh   "[FOUND SUBTITLE LINK]\n\t". scalar($lnk->[$ind]->url_abs()) ."\n" if $debug;
		   	$f_url=scalar($lnk->[$ind]->url_abs());
			$okurl=1;
			if ($oktitle==1)
				{
				 $sstsav{$f_url}=$f_title;
				 $oktitle=0;$okurl=0;	
				}
		   };
		if (defined($lnk->[$ind]->text()) and ($lnk->[$ind]->text() =~/>/) )
		{$next_page_exists=1;}
	};
      # verify we get any result for the search request 
	if ( $#ssturl < 1)	{ print $fh      " PAS DE RESULTAT pour $motif sur Extratitles\n";return (0,0);};  
     #else save and print if $html
	print $fh "[DEBUG] Found ". $#ssturl ." subtitles on page : ".$page."\n" if ($debug);
	$nbres=$#ssturl; 
	_save_dbm();
     #and reinit sstsav
      %sstsav={};
	return ($nbres,$next_page_exists);	
};
sub _save_dbm{
my %xstsav;
use DB_File;
tie (%xstsav,'DB_File',$dbfile )
	or croak "can not use $dbfile : $!\n";
      while (my ($k, $v) = each %sstsav)
      { $xstsav{$k}=$v; print $fh "[DEBUG][DBM] saving $v [$k] into db \n" if ($debug);};
      untie(%xstsav);
return;	
};
sub _search_dbm{
use DB_File;
my %hashread;
my $nb_local_res;
	unless (-e ($dbfile))
		{croak "[DEBUG SEARCH] db file ".$dbfile." not found  ! \n";};
	tie(%hashread,'DB_File',$dbfile)
		or croak "can not access : $dbfile : $!\n";
	if ($html)
		 		{ 
		 		print HTMLFILE "<br><b>Searching  : ".$motif." on local database : </b><br>\n";
		 		print HTMLFILE "<br><b>DBM file is :".$dbfile."  </b><br>\n";
		 		}
	while (my ($k,$v)=each(%hashread))
		{ 
		 if ($v =~ m/$motif/i)
		 	{
		 	print $fh "[FOUND Libelle ] $v \n[FOUND LINK]". $base.$k ."\n" if $debug;
		 	if ($html)
		 		{
		 		my $url=$k;
		  		if ($k !~ m/http:\/\//im){my $url=$base.$k}
		  		print HTMLFILE "<a href=\"".$url."\">".$v."</a><br>\n";
		  		$nb_local_res++;
		  		};
		 	};
		};
		untie(%hashread);
	if ($html)
	{
	print HTMLFILE "<br><b>[ ".$nb_local_res." result(s) found on local DB ] </b> <br>\n";
	print HTMLFILE " report finished at ".localtime()."<br>\n";
	}
return;
};
sub END{
	my $self =attr shift;
	close HTMLFILE;close FH;
	return;
};		 
		 
1; # End of WWW-Sucksub::Extratitles
