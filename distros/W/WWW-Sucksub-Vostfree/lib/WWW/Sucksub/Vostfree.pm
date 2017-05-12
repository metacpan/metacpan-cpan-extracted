package WWW::Sucksub::Vostfree;
=head1 NAME

WWW::Sucksub::Vostfree - automated access to vost.free.fr

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

SuckSub::Vostfree is  a web robot based on the WWW::Mechanize Module
This module search and collect distant result on the vostfree.fr web database.
Subtitles Files urls and associated titles are stored in a dbm file.
Distant and local subtitles search are possible. you can use local database thru simple html generated report.



	use WWW::Sucksub::Vostfree;
	my $foo = WWW::Sucksub::Vostfree->new(
    					dbfile=> '/where/your/DBM/file is.db',
					html =>'/where/your/html/report/is.html',
					motif=> 'the word(s) you search',
					debug=> 1, 
					logout => '/where/your/debug/info/are/written.log',
					);	  						);
	$foo->search(); 	# collect all link corresponding to the $foo->motif()	
	$foo->motif('x'); 	# modify the search criteria 
	$foo->searchdbm();	# launch a search on the local database 
	
Html report should be generated at the end of search() and searchdbm().

=head1 CONSTRUCTOR AND STARTUP

=head2 Vostfree Constructor 

The new() constructor, is associated to default values :
you can modify these one as shown in the synopsis example.
initial values you can modify are these :

	my $foo = WWW::Sucksub::Vostfree->new(
		html=> "$ENV{HOME}"."/extratitle_report.html",
		dbfile => "$ENV{HOME}"."/extratitle_db.db",
		motif=> undef,
		tmpfile_vost = > "$ENV{HOME}"."/.vostfree_tmp.html",
		debug=> 0, 
		logout => \*STDOUT	  					
		useragent=> "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007"
    		);

=head3 new() constructor attributes and associated methods

Few attributes can be set thru new() attributes.
All attributes can be modified by corresponding methods:

	$foo->WWW::Sucksub::Vostfree->new()
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

=head4 tmpfile_vost()

Vostfree.pm needs to write temporary file.
the tmpfile_vost() method allows you to change path of this temporary file :

	$foo=WWW::Sucksub::Vostfree->new(
							...
							tmp_vostfile => '/where/tmp/file/is/written.html',
							...
						);

To retrieve temporary file path :

	my $tmp=$foo->tmpfile_vost();
	
To change temporary file path:

	$foo->tmpfile_vost('/where/my/new/tmp/file/is/written.html');


=head4 motif()

you should here give a real value to this function :
if $foo->motif stays undef, the package execution will be aborted

	$foo->motif('xxx')

allows to precise that you're searching a word that contains 'xxx'

	$foo->motif()

return the current value of the string you search.

=head4 debug()

WWW-Sucksub-Vostfree can produce a lot of interresting informations
The default value is "0" : that means that any debug informations will be written
on the output ( see the logout() method too.)

	$foo->debug(0) # stop the product of debbugging informations
	$foo->debug(1) # debug info will be written to the log file ( see logout() method)

=head4 logout()
  			
if you want some debug informations, you should set the debug attribute to 1
See debug() method. 
logout() method is associated to the debug() attribute value. 
It indicates path where debug info will be written.
Default value is :

		$foo=WWW::Sucksub::Vostfree->new(
							...
							logout => \*STDOUT, 
							...,
							);

output and optional debugging info will be produced ont STDOUT
or any other descriptor if you give filename as arg, by example :

	$foo=WWW::Sucksub::Vostfree->new(
						...
						logout => '/where/my/log/is/written.txt', 
						...,
						);

=head4 dbfile()

define dbm file for store and retrieving extracted informations
you must provide a full path to the db file to store results.
the search() method can not be used without defined dbm file.

 	$foo->dbfile('/where/your/db/is.db')

The file will should be readable/writable.

=head4 html()

Define simple html output where to write search report.
you must provide au full path to the html file if you want to get an html output.

 	$foo->html('/where/the html/report/is/written.html')

If $foo->html() is defined. you can get the value of this attribute like this :

	my $html_page = $foo->html()

html file will be used for report with search and searchdbm() methods.


=head1 METHODS and FUNCTIONS

these functions use the precedent attributes value.

=head2 search() 

this function takes no argument.
it alows to launch a local dbm search.

	$foo-> search()

the dbm file is read to give you every couple  (title,link) which corresponds to
the motif() pattern.

=head2 searchdbm() 

this function takes no argument.
it alows to initiate the distant search on the web site vost.free.fr
the local dbm file is automatically written. Results are accumulated to the dbm file
you defined.
a search pattern must be define thru motif() method before launching search.

=head2 get_all_result() 

return a hash of every couple ( title, absolute http link of subtitle file ) the search or update method returned.

	my %hash=$foo->get_all_result()


=head1 SEE ALSO

=over 4

=item * L<WWW::Mechanize>

=item * L<DB_FILE>	

=item * L<HTTP::Cookies>

=item * L<WWW::Sucksub::Attila>

=item * L<WWW::Sucksub::Divxstation>

=item * L<WWW::Sucksub::Frigo>

=item * L<Alias>

=back

=head1 AUTHOR

Timothée foucart, C<< <timothee.foucart@apinc.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sucksub-divxstation@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Sucksub-Vostfree>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

		 
=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Timothée foucart, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT=qw(  debug dbfile  tmp_file_vost
		 get_all_result html logout 
		 motif search searchdbm useragent );

use strict;
use warnings;
use Carp;
use utf8;
use HTTP::Cookies;
use WWW::Mechanize;
use Alias qw(attr);
use vars qw( $cookies_file $site $nbres 
		$base $dlbase $debug $useragent
		$motif  $dbfile $dbsearch %sstsav 
		$logout $fh $tmpfile_vost $html
		);
#
sub new{
	 	my $vostfree=shift;
		my $classe= ref($vostfree) || $vostfree;
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
 	$self->{base} = "http://vo.st.fr.free.fr/";
 	$self->{dlbase} = "http://vo.st.fr.free.fr/sts/";
	$self->{site} = "http://vo.st.fr.free.fr/search.php";
	$self->{tmpfile_vost} = "$ENV{HOME}"."/.vostfree_tmp.html";
	$self->{cookies_file} = "$ENV{HOME}"."/.cookies_sksb";
	$self->{useragent} = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007";
	$self->{motif}  = undef;
	$self->{debug}  = 0;
	$self->{logout} = \*STDOUT; 
	$self->{html} = "$ENV{HOME}"."/extratitle_report.html";
	$self->{dbfile} = "$ENV{HOME}"."/extratitle_db.db";
	$self->{dbsearch} = 0;
	$self->{sstsav} ={};
 	$self->{nbres} = 0;
 	#
 	# -- replace forced values
 	#
 	if (@_)
 		{
 		my %param=@_;
 		while (my($x,$y) =each(%param)){$self->{$x}=$y;};
 		}
 	return $self;
}
sub useragent { 
	my $self =attr shift;
	if (@_) {$useragent=shift;}
	return $useragent;
	}
sub dlbase { #internal 
	my $self =attr shift;
	if (@_) {$dlbase=shift;}
	return $dlbase;
	}
sub logout { 
	if (@_){$logout=shift; }
      if ($logout)
		{ open(FH , ">>", $logout) or die "$logout : $!\n"; 
		   $fh=(\*FH);} 
	else 
		{ $fh=(\*STDOUT);};
	return $logout;
	}	
sub debug { 
	my $self =attr shift;
	if (@_) {$debug=shift;}
	return $debug;
	}
sub cookies_file { 
	my $self =attr shift;
	if (@_) {$cookies_file=shift;}
	return $cookies_file;
	}
sub tmpfile_vost { 
	my $self =attr shift;
	if (@_) {$tmpfile_vost=shift;}
	return  $tmpfile_vost;
	}
sub sstsav { 
	my $self =attr shift;
	if (@_) {%sstsav=shift;}
	return %sstsav;
	}
sub dbfile { 
	my $self =attr shift;
	if (@_) {$dbfile=shift;};
	return $dbfile;
	}
sub dbsearch { 
	my $self =attr shift;
	if (@_) {$dbsearch=shift;}
	croak " can not do a local search without motif !!\n you must provide  a string thru motif() method before \n"
			unless $motif;
	if ($dbsearch>0){searchdbm();};
	return $dbfile;
	}
#------------------------------------------------------------------------------------------------------------------------
#             alias method for ->sstsav
#------------------------------------------------------------------------------------------------------------------------
sub get_all_result { 
	my $self =attr shift;
	if ($self->sstsav() ==undef){ return undef}
	else {return %sstsav;};
};
sub html { 
	my $self =attr shift;
	if (@_) {$html=shift;}
	else {$html=$self;};
	unless (-e ($html))
		{
		print $fh "[DEBUG] html report file doesn't exists \n";
		print $fh "[DEBUG] Sucksub will create one ... \n";
		}
	return $html;
}
sub motif { 
	my $self =attr shift;
	if (@_) {$motif=shift;};
	if ((length($motif))<2)
		{ 	print $fh "[INFO] motif is : ".$motif." [length = ".length($motif)." ]\n" if $debug;
			croak "[FATAL WARNING] your search motif should be longer than 2 characters ! \n It's only ".length($motif)." long !\n";
		};
	return $motif;
}		
sub search{
	my $self =attr shift; 
	croak "can not search without motif!\n" unless $motif;
	motif($motif);#obtain warn eventually
	our $mech = WWW::Mechanize->new(agent=>$useragent,
			cookie_jar => HTTP::Cookies->new(
    			file => $cookies_file,
    			autosave => 1,
			ignore_discard => 0,
						   ),								   
  					);
  	$mech->stack_depth(1);
	if ($html)
		{ 
		open (HTMLFILE,">>",$html) or warn "can not access $html : $! \n";
		print HTMLFILE "<hr><small><b>Generated by suckSub perl module</b>\n";
		print HTMLFILE "searching : ".$motif." on ".$site."<br>\n";
		print HTMLFILE " ".localtime()."</small><br>\n";
		};		 
	print $fh  "--------------------------------------------------------------------------------\n" if ($debug);
	print $fh  "[DEBUG] begin scan on $site  at : ".localtime()."\n" if ($debug);
	print $fh  "[DEBUG] searching : ".$motif." on $site  \n" if ($debug);
	print $fh  "--------------------------------------------------------------------------------\n" if ($debug);
	if ($debug) {print $fh   "\n[DEBUG \t VO.ST.FREE.FR  ][BEGIN SCAN]\n";};
	# we're obliged to get the entry page to avoid a redirection (because of no  cookies )
	$mech->get($base) or die  "[WARNING] can not get  $base ! : $!  \n";
	$mech->get($site) or die  "[WARNING] can not get  $site ! : $!  \n";
	$mech->form_number(1);
	$mech->set_fields( search => $motif );
	$mech->click();
	if ($debug) { print $fh  "[DEBUG \t GET URL \t : \t  ".$mech->uri()."]\n" if ($debug);}; 
	$nbres = parse_vostfree($mech);
	if (!$nbres){$nbres=0};
	print $fh   "[DEBUG \t :  $nbres trouves sur $base]\n" if ($debug);
	print $fh    "[END]\n" if ($debug);
	print $fh  "--------------------------------------------------------------------------------\n\n" if ($debug);

return;
};			
#	
#--- this function  parses only one result page and return all subtitles url.
#
sub parse_vostfree{ #INTERNAL
	my $mech=$_[0];
	my $jnd=0; my $jnd2=0;
	my $lnk=$mech->find_all_links(); 
	my $nbl = $#{$lnk}; my $ind=0;
# rechercher les liens des reponses de la rechercher
	my @sstlist=[];# memo array
	for ( my $ind=0; $ind <= $#{$lnk} ; $ind++)
	{
# search and memorize the subtitle label
#http://vo.st.fr.free.fr/edit.php?id=142
      	if 	($lnk->[$ind]->url() =~ m/edit\.php\?id/ ) 
	   		{  	
				$sstlist[$jnd] = $lnk->[$ind]->url_abs();
				my $libelle = $lnk->[$ind]->text();
				print $fh	"[FOUND PAGE] ". $lnk->[$ind]->url_abs()."\n" if $debug;
				print $fh   "[FOUND TITLE]". $lnk->[$ind]->text() ."\n" if $debug;
			# get the link file url
				my $result2 = $mech->get( $sstlist[$jnd] );
				print $fh    "[DEBUG] GET ". $mech->uri()."\n" if ($debug);
	   		# parse the result page  : link is in a javascript popup
				unlink ($tmpfile_vost) unless (!(-f $tmpfile_vost));
				open (TAMPON,'>', $tmpfile_vost) or croak "can not open $tmpfile_vost :  $! \n";
				print TAMPON $mech->response->as_string;
				close TAMPON;
			# save one or more subtitles links
				my @lnkdl=vosftree_dlfile($tmpfile_vost);
				for (my $lnd=0;$lnd<=$#lnkdl;$lnd++)
					{ 
					$sstsav{$lnkdl[$lnd]} = $libelle;
					if ($lnd>0){$libelle=$sstsav{$lnkdl[$lnd]}."_(".$lnd.")";};
					if ($html)
						{ 
						print HTMLFILE  "<a href=\"".$lnkdl[$lnd]."\">".$libelle."</a><br>\n";
						};
					if ($debug)
						{
						print $fh "[FOUND LINK ]".$lnkdl[$lnd]."\n" if $debug;
						};
					
					if ($dbfile) 
						{
						savedbm();
						print $fh "[DBM SAVE] ".$lnkdl[$lnd]."\n" if $debug;
						};
					$nbres++;
					};
			};
	$jnd++ ; 
	};
# verify we get any result for the search request 
	if ( $jnd < 1)
		{ 
		print $fh " NO RESULT FOUND for  $motif on http://vostfree.fr \n";
		if ($html)
			{
			print HTMLFILE  " NO RESULT FOUND for  $motif on http://vostfree.fr <br>\n";
			print HTMLFILE  " ending scan on $site  at : ".localtime()."<br><br>\n";
			};
		return;
		}
	else  
		{
		print $fh   "[DEBUG]   :  ". $nbres ." links on distant web search \n" if ($debug);
		print $fh   "[DEBUG] ending scan on $site  at : ".localtime()."\n" if ($debug);
		if ($html)
			{
			print HTMLFILE  "<b>". $nbres ." result(s)<b> for pattern <i>".$motif."</i> on http://vostfree.fr <br>\n";
			print HTMLFILE  " ending scan on $site  at : ".localtime()."<br><hr>\n";
			};
		};
if (-e $tmpfile_vost){unlink $tmpfile_vost};
return $nbres;
}
sub searchdbm{ 
	my $self =attr shift;
	croak " can do a local search without $motif !! \n" unless $motif;
	print HTMLFILE "<hr>\n";
	print HTMLFILE "<b>Searching on local DBM : $dbfile for $site  at : ".localtime()."</b><br>\n";
	print HTMLFILE "<hr>\n";
	tie(%sstsav,'DB_File',$dbfile)
			or die "can not access : $dbfile : $!\n";
	while (my ($k,$v)=each(%sstsav))
		{ 
		 if ($v =~ m/$motif/i)
	 		{
	 		print $fh "[FOUND Libelle ] $v \n[FOUND LINK]".$k ."\n";
	 		if ($html)
	 			{ 
	  			print HTMLFILE "<a href=\"".$k."\">".$v."</a><br>\n";
	  			$nbres++;
	  			};
	 		};
		};
	untie(%sstsav);
	if ($html)
		{
		print HTMLFILE "<br><b>".$nbres." result(s) found</b> <br>\n";
		print HTMLFILE " html finished at ".localtime()."<br>\n";
		};		
}
#-------------------------------------------------------------------------------
# parse javascript link and rebuild url links
#-------------------------------------------------------------------------------
	
sub vosftree_dlfile{ #INTERNAL
use HTML::Parser;  
	my $content_vost = $_[0];
	our @urlfile=();
	my $pf = HTML::Parser->new();
	$pf->handler( start => \&start_vostf, "tagname,attr" );
	$pf->parse_file($content_vost);
	$pf->eof;
#
     sub start_vostf{
     	  my ( $tag, $args ) = @_;
     	  return unless ($tag eq 'input');
     	  return unless ($args->{value});
     	  return unless ($args->{value} =~ m/T?l?charger/ );
     	  return unless ($args->{onclick});
        my $click = $args->{onclick};
	  my @mot=split(/[']/,$click);my $filename=$mot[1];#'<--fucking eclipse!!
	  $filename=~ s/ /%20/g; $filename=$dlbase.$filename; 
	  print $fh "[PARSER FOUND LINK ] ".$filename."\n" if $debug;
	  push @urlfile,$filename;
	
	};
return @urlfile;
}; 
#---------------------------------------------------------------------------
#-- save updated hash into dbm file
#-- internal use only
#---------------------------------------------------------------------------
sub savedbm{
my $self =attr shift;
my %hashtosave;
use DB_File;
tie (%hashtosave,'DB_File',$dbfile )
	or die "can not use $dbfile : $!\n";
	 while (my ($k, $v) = each %sstsav)
      { $hashtosave{$k}=$v;};
untie(%hashtosave);
return;	
};
#--------------------------------------------------------------
# End code
#--------------------------------------------------------------
sub END{
	close HTMLFILE if $html;
};
#end vostfree
#
1;
