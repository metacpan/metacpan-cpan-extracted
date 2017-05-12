package WWW::Sucksub::Divxstation;


=head1 NAME

WWW::Sucksub::Divxstation - automated access to divxstation.com

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

SuckSub::Divxstation is  a wab robot based on the WWW::Mechanize Module
This module search and collect distant result on the divxstation.com base
Subtitles Files are very little files, Sucksub::Divstation store all results
of any search in a dbm file. You can retrieve it through an html file.



    use WWW::Sucksub::Divxstation;
    my $foo = WWW::Sucksub::Divxstation->new(
    					dbfile=> '/where/your/DBM/file is.db',
					html =>'/where/your/html/repport/is.html',
					motif=> 'the word(s) you search',
					debug=> 1, 
					logout => '/where/your/debug/info/are/written.log',	  						);
    $foo->update(); 	# collect all link corresponding to the $foo->motif()
    $foo->motif('x'); 	# modify the search criteria 
    $foo->search();	# launch a search on the local database 

  

=head1 CONSTRUCTOR AND STARTUP

=head2 Divxstation Constructor 

The new() constructor, is associated to default values :
you can modify these one as shown in the synopsis example.

	my $foo = WWW::Sucksub::Divxstation->new(
		html=> "$ENV{HOME}"."/sksb_divxstation_report.html",
		dbfile=> "$ENV{HOME}"."/sksb_divxstation_db.db",
		motif=> undef,
		debug=> 0, 
		logout => undef, # i.e. *STDOUT	  					
		useragent=> "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007"
    		);

=head3 new() constructor attributes and associated methods

Few attributes can be set thru new() attributes.
All attributes can be modified by corresponding methods:

	$foo->WWW::Sucksub::Divxstation->new()
	$foo->useragent() # get the useragent attribute value
	$foo->useragent('tructruc') # set the useragent attribute value to 'tructruc'


=head4 cookies_files()

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

=head4 debug()

WWW-Sucksub-Divxstation can produce a lot of interresting informations
The default value is "0" : that means that any debug informations will be written
on the output ( see the logout() method too.)

	$foo->debug(0) # stop the product of debbugging informations
	$foo->debug(1) # debug info will be written to the log file ( see logout() method)

=head4 logout()
  			
if you want some debug information : args is 1, else 0 or undef

		logout => undef; 

output and optional debugging info will be produced ont STDOUT
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

 	html('/where/the/html/repport/is/written.html')

If $foo->html() is defined. you can get the value of this attribute like this :

	my $html_page = $foo->html

html file will be used for repport with update() and search() methods.


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
it alows to initiate the distant search on the web site divxstation.com
the local dbm file is automatically written. Results are accumulated to the dbm file
you define.

=head2 get_all_result() 

return a hash of every couple ( title, http link of subtitle file ) the search or update method returned.

	my %hash=$foo->get_all_result()


=head1 SEE ALSO

=over 4

=item * L<WWW::Mechanize>

=item * L<DB_FILE>	

=item * L<HTTP::Cookies>

=item * L<WWW::Sucksub::Attila>

=item * L<WWW::Sucksub::Vostfree>

=item * L<Alias>

=back

=head1 AUTHOR

Timothée foucart, C<< <timothee.foucart@apinc.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sucksub-divxstation@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Sucksub-Divxstation>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Timothée foucart, all rights reserved.

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
		 motif search update useragent );
		 
use utf8;
use strict;
use Carp;
use HTTP::Cookies;
use WWW::Mechanize;
#	 
#
# --
#		 
use Alias qw(attr);
use vars qw( $base  $site $cookies_file $useragent  $motif  $debug  $logout $html $dbfile $okdbfile $nbres $totalres %sstsav $fh);

sub new{
	 	my $divxstation=shift;
		my $classe= ref($divxstation) || $divxstation;
	 	my $self={	};
	 	bless($self,$classe);
	 	$self->_init(@_);
	 	logout($self->{logout});
	 	return $self;
};
 sub _init{
 	my $self= attr shift;
 	#
 	# -- init default values
 	#
 	$self->{base} = "http://divxstation.com";
	$self->{site} = "http://divxstation.com/subtitles.asp";
	$self->{cookies_file} = "$ENV{HOME}"."/.cookies_sksb";
	$self->{useragent} = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007";
	$self->{motif}  = undef;
	$self->{debug}  = 0;
	$self->{logout} = \*STDOUT; 
	$self->{html} = "$ENV{HOME}"."/sksb_divxstation_report.html";
	$self->{dbfile} = "$ENV{HOME}"."/sksb_divxstation_db.db";
	$self->{okdbfile} = 0;
	$self->{sstsav} ={};
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
sub sstsav { 
	my $self =attr shift;
	if (@_) {%sstsav=shift;}
	return %sstsav;
	}
sub get_all_result { 
	my $self =attr shift;
	%sstsav=$self->sstsav();
	return %sstsav;
	}
sub cookies_file { 
	my $self =attr shift;
	if (@_) {$cookies_file=shift;}
	return $cookies_file;
	}
sub motif { 
	my $self = attr shift;
	if (@_) {$motif=shift;return $motif ;}
	else {return $motif ;};
	}	
sub logout { 
	if (@_){$logout=shift; }
      	if ($logout)
		{ open(FH , ">>", $logout) or croak " can not open $logout : $!\n"; 
		   $fh=(\*FH);} 
	else 
		{ $fh=(\*STDOUT);};
	return $logout;
	}	
sub html { 
	my $self =attr shift;
	if (@_) {$html=shift;}
	else {$html=$self;};
	unless (-e ($html))
		{print $fh "[DEBUG] html report file doesn't exists \n";}
	return $html;
	}
sub open_html{
	open(HTMLFILE,">>",$html)
			or croak "can not create $html : $! \n";
	print HTMLFILE "<hr> <small>report generated by suckSub perl module<br>\n";
	print HTMLFILE "searching : ".motif()." on ".$site."<br>\n";
	print HTMLFILE " ".localtime()."</small><br>\n";
	return;
}
sub update {
	my $self =attr shift;
	unless ($motif){print "no motif : please give he words you search....exit\n";return;};
	my $mech = WWW::Mechanize->new(agent=>$useragent,
							cookie_jar => HTTP::Cookies->new(
								file => $cookies_file,
								autosave => 1,
								ignore_discard => 0,
							),
							stack_depth => 1,
					);
if ($html){open_html();};
print $fh  "------------------------------------------------------------------------------------------------\n" if ($debug);
print $fh  "[DEBUG] begin scan on $site  at : ".localtime()."\n" if ($debug);
print $fh  "[DEBUG] searching : ".$motif." on $site  \n" if ($debug);
my $page = 1; #   pagination
if ($debug) {print $fh   "\n[DEBUG \t DIVXSTATION PAGE $page]\n";}; 
$mech->get($site.'?le='.$motif.'&l=18&f=&page=&Submit=search+subtitles') or warn "[WARNING] http get problem on : $site !! \n";
$mech->form_name('theform');
$mech->set_fields( le => $motif  );
$mech->set_fields( l  => 18 ); #i.e. langage = french
$mech->click('Submit');
if ($debug) { print $fh  "[DEBUG \t GET URL \t : \t  ".$mech->uri()."]\n" if ($debug);}; 
$nbres = parse_divxstation($mech);
$totalres=$nbres;
#
#  verify if we need to change page to get next search results
#
while ($totalres eq (20*$page))
	{ 	print $fh "[DEBUG][COUNT RESULTS] page num : ".$page." number result : ".$nbres."\n" if ($debug);
		$page = $page+1;
	  	$mech->get( "http://divxstation.com/searchSubtitles.asp?l=18&f=&le=".$motif."&page=".$page)
	  		or warn "get problem sur page  : $page : $! \n";
	  	if ($debug) { print $fh  "[DEBUG \t PAGE : $page]\n";print $fh    "[DEBUG \t GET URL \t : \t ".$mech->uri() ."]\n";}; 
		$nbres = parse_divxstation($mech,$page);
		$totalres=$totalres+$nbres;
	};
	
#
print $fh   "[DEBUG \t :  $totalres trouves sur $base]\n" if ($debug);
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
	unless ($dbfile) { print $fh " no DB file defined : exit ... \n";};
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
	search_dbm($dbfile);
return;
	
};		
#	
#--- this function = to parse only one result page
#

sub parse_divxstation{
	my $mech=$_[0];my $page =$_[1];
	my $jnd=0; my $jnd2=0;
	my $lnk=$mech->find_all_links(); 
	my $nbl = $#{$lnk}; my $ind=0;
	print $fh "[DEBUG] searching links on : ".$mech->uri()." ]\n" if ($debug);

# =4= rechercher les liens des reponses de la recherche
	my @sstlist=[];my @ssturl=[];# memo array
	for ( my $ind=0; $ind <= $#{$lnk} ; $ind++)
	{
	# search and memorize the subtitle label
      	if 	( 	($lnk->[$ind]->url() =~ m/(subtitle)(\.asp)(\?sId=)([0-9]+$)/g ) 
	   		and ( $lnk->[$ind]->url() !~ m/userinfo/ ) )
	  		{  	
				push @sstlist,$lnk->[$ind]->text();
				push @ssturl,$lnk->[$ind]->url_abs();
		   		print $fh   "[FOUND]". $lnk->[$ind]->text() ."\n\t". $lnk->[$ind]->url_abs()."\n" if $debug;
				$jnd++ ; 
			};
	};
# verify we get any result for the search request 
	if ( $jnd < 1)	{ print $fh      " PAS DE RESULTAT pour $motif sur divxstation\n";return 0;};  
	print $fh   "[DEBUG] nombre de lien premier niveau ". $jnd ."\n" if ($debug);
# from the main result page, we need to follow link to found the sub http adress
# to get the uri of the subtitle file	
	for ( my $n=0; $n <= $jnd ; $n++)
		{ 
		my $result2 = $mech->get( $ssturl[$n] );
		print $fh    "[DEBUG] GET ". $mech->uri()."\n" if ($debug);
	   	my $lnk2=$mech->find_all_links();
		print $fh    "[DEBUG]  link number :  ". $n."\n" if ($debug);
			#
		for ( my $ind2=0; $ind2 <= $#{$lnk2} ; $ind2++)
 			{ 
			if ( $lnk2->[$ind2]->text() =~ m/Download subtitle/ )
					{    
					print $fh   "[FOUND LINK] link : ". $lnk2->[$ind2]->url_abs() ."\n" if ($debug);
					$sstsav{$lnk2->[$ind2]->url_abs()}=$sstlist[$n];
					};
			$jnd2++ ; # next sub in every cases
			};							
		}; # end loop
$nbres=$jnd; 
save_dbm();
return $nbres;	
};
sub save_dbm{
my %xstsav;
use DB_File;
tie (%xstsav,'DB_File',$dbfile )
	or croak "can not use $dbfile : $!\n";
	 while (my ($k, $v) = each %sstsav)
      { $xstsav{$k}=$v; print $fh "[DEBUG][DBM] saving $v [$k] into db \n" if ($debug);};
untie(%xstsav);
return;	
};
sub search_dbm{
use DB_File;
my %hashread;
my $nb_local_res;
	unless (-e ($dbfile))
		{croak "[DEBUG SEARCH] db file ".$dbfile." not found  ! \n";};
	tie(%hashread,'DB_File',$dbfile)
		or croak "can not access : $dbfile : $!\n";
	if ($html)
		 		{ print HTMLFILE "<br><b>Searching  : ".$motif." on local database : </b><br>\n";
		 		  print HTMLFILE "<br><b>DBM file is :".$dbfile."  </b><br>\n";
		 		}
	while (my ($k,$v)=each(%hashread))
		{ 
		 if ($v =~ m/$motif/i)
		 	{
		 	print $fh "[FOUND Libelle ] $v \n[FOUND LINK]". $base.$k ."\n";
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
	close FH;
	close HTMLFILE;
};		 
		 
1; # End of WWW-Sucksub::Divxstation
