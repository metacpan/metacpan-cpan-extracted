package WWW::Sucksub::Frigo;
=head1 NAME

WWW::Sucksub::Frigo - Automated access to frigorifix subtibles database

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

WWW::SuckSub::Frigo is a web robot based on the WWW::Mechanize Module
This module search and collect distant result on the frigorifix.com web database.
Subtitles Files urls and associated titles are stored in a dbm file.
Distant and local subtitles search are possible. Accessing to the local database thru simple html generated repport.



	use WWW::Sucksub::Frigo;
	my $foo = WWW::Sucksub::Frigo->new(
    					dbfile=> '/where/your/DBM/file is.db',
					html =>'/where/your/html/repport/is.html',
					motif=> 'the word(s) you search',
					debug=> 1, 
					logout => '/where/your/debug/info/are/written.log',
					);	  						);
	$foo->search(); 	# collect all link corresponding to the $foo->motif()	
	$foo->motif('x'); 	# modify the search criteria 
	$foo->searchdbm();	# launch a search only on the local database 
	
Html report should be generated at the end of search() and searchdbm().

=head1 CONSTRUCTOR AND STARTUP

=head2 Frigo Constructor 

The new() constructor, is associated to default values :
you can modify these one as shown in the synopsis example.
initial values you can modify are these :

	my $foo = WWW::Sucksub::Frigo->new(
		html=> "$ENV{HOME}"."/frigorifix_report.html",
		dbfile => "$ENV{HOME}"."/frigorifix_db.db",
		motif=> undef,
		tmpfile_frigo = > "$ENV{HOME}"."/tmp_frigo.html",
		debug=> 0,
		usedbm=>0,
		username_frigo=>"",
		password_frigo=>"", 
		logout => \*STDOUT	  					
		useragent=> "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007"
    		);
See _init() internal function for more details.

=head3 new() constructor attributes and associated methods

Few attributes can be set thru new() attributes.
All attributes can be modified by corresponding methods:

	$foo->WWW::Sucksub::Frigo->new()
	$foo->useragent() # get the useragent attribute value
	$foo->useragent('tructruc') # set the useragent attribute value to 'tructruc'


=head4 cookies_file()

arg must be a file, this default value can be modified by calling the 

	$foo->cookies_file('/where/my/cookies/are.txt')

modify the default value positionned by the new constructor.

	$foo->cookies_file() 
	
return the actual value of the cookies file path.


=head4 usedbm(0/1)

Default value is 0. In this case, calling search() method won't affect the dbm file.
You need to set the value 1 to activate dbm update

	$foo->usedbm(1)

This method will fails if no dbm file ( see dbfile() ) has been defined.


=head4 useragent()

arg should be a valid useragent. There's no reason to change this default value.

	$foo->useragent()
	
return the value of the current useragent.

=head4 tmpfile_frigo()

Frigo.pm needs to write temporary file.
the tmpfile_frigo() method allows you to change path of this temporary file :

	$foo=WWW::Sucksub::Frigo->new(
							...
							tmpfile_frigo => '/where/tmp/file/is/written.html',
							...
						);

To retrieve temporary file path :

	my $tmp=$foo->tmpfile_frigo();
	
To change temporary file path:

	$foo->tmpfile_frigo('/where/my/new/tmp/file/is/written.html');


=head4 motif()

you should here give a real value to this function :
if $foo->motif stays undef, the package execution will be aborted

	$foo->motif('xxx')

allows to precise that you're searching a word that contains 'xxx'

	$foo->motif()

return the current value of the string you search.

=head4 debug()

WWW-Sucksub-Frigo can produce a lot of interresting informations
The default value is "0" : that means that any debug informations will be written
on the output ( see the logout() method too.)

	$foo->debug(0) # stop the product of debbugging informations
	$foo->debug(1) # debug info will be written to the log file ( see logout() method)

=head4 logout()
  			
if you want some debug informations, you should set the debug attribute to 1
See debug() method for more precisions. 
logout() method is associated to the debug() attribute value. 
It indicates path where debug info will be written.
Default value is :

		$foo=WWW::Sucksub::Frigo->new(
							...
							logout => \*STDOUT, 
							...,
							)

output and optional debugging info will be produced ont STDOUT
or any other descriptor if you give filename as arg, by example :

$foo=WWW::Sucksub::Frigo->new(
							...
							logout => '/where/my/log/is/written.txt', 
							...,
							)

=head4 dbfile()

define dbm file for store and retrieving extracted informations
you must provide a full path to the db file to store results.
the search() method can not be used without defined dbm file.

 	$foo->dbfile('/where/your/db/is.db')

The file will should be readable/writable.

=head4 html()

Define simple html output where to write search report.
you must provide au full path to the html file if you want to get an html output.

 	$foo->html('/where/the html/repport/is/written.html')

If $foo->html() is defined. you can get the value of this attribute like this :

	my $html_page = $foo->html()

html file will be used for report with search and searchdbm() methods.

=head4 username_frigo()

Allow you to login and obtain cookies from frigorifix web site

	$foo->username_frigo('my_login')

Default value is empty. there's no obligation to fill it.
Otherwise, you should fill password_frigo() too.

=head4 password_frigo()

Allow you to login and obtain cookies from frigorifix web site

	$foo->password_frigo('my_password')

Default value is empty. there's no obligations to fill it.
Otherwise, you should fill username_frigo() too.



=head1 METHODS and FUNCTIONS

these functions use the precedent attributes value.

=head2 search() 

this function takes no arguments.
it alows to launch a local dbm search.

	$foo-> search()

the dbm file is read to give you every couple  (title,link) which corresponds to
the motif() pattern.

=head2 searchdbm() 

this function takes no arguments.
it allows to initiate the distant search on the web site frigorifix
the local dbm file is automatically written. Results are accumulated to the dbm file
you defined.
a search pattern must be define thru motif() method before launching a dbm search.

=head2 get_all_result() 

return a hash of every couple ( title, http link of subtitle file ) the search or update method returned.

	my %hash=$foo->get_all_result()


=head1 SEE ALSO

=over 4

=item * L<WWW::Mechanize>

=item * L<DB_FILE>	

=item * L<HTTP::Cookies>

=item * L<WWW::Sucksub::Attila>

=item * L<WWW::Sucksub::Divxstation>

=item * L<WWW::Sucksub::Vostfree>

=back

=head1 AUTHOR

Timothée foucart, C<< <timothee.foucart@apinc.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sucksub-frigo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Sucksub-Frigo>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=cut

use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT=qw(  debug dbfile tmpfile_frigo
		 get_all_result html logout 
		 motif search searchdbm useragent 
		 usedbm username_frigo password_frigo );


use warnings;
use strict;
use Carp;
use HTML::Form;
use HTTP::Cookies;
use WWW::Mechanize;
#
use Alias qw(attr);
use vars qw($cookies_file $site $nbres 
		$base $debug $useragent $motif 
		%sstsav $username_frigo $password_frigo 
		$logout $srchadr $fh $loginpage $html
		$usedbm $dbfile
		$mech );
#
sub new{
	 	my $frigo=shift;
		my $classe= ref($frigo) || $frigo;
		my $self={	};
	 	bless($self,$classe);
	 	$self->_init(@_);
	 	logout($self->{logout});
	 	return $self;
};
#
sub _init{
	 	# init du hachage pour l'objet
	 	my $self= attr shift;
	 				$self->{base} = "http://v2.frigorifix.com/";
					$self->{site}= "http://v2.frigorifix.com/index.php";
					$self->{loginpage}= "http://v2.frigorifix.com/index.php?action=login";
					$self->{cookies_file}="$ENV{HOME}"."/.cookies_frigo";
					$self->{tmpfile_frigo}="$ENV{HOME}"."/.tmp_frigo.html";
					$self->{useragent}= "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007";
					$self->{username_frigo}="";
					$self->{password_frigo}="";
		            	$self->{srchadr}="http://v2.frigorifix.com/index.php?action=static&staticpage=9";
					$self->{motif}= undef;
					$self->{debug}= 0;
					$self->{logout}=\*STDOUT;
					$self->{nbres}= 0;
					$self->{html} = "$ENV{HOME}"."/frigorifix_report.html";
					$self->{dbfile} = "$ENV{HOME}"."/frigorifix_db.db";
					$self->{usedbm} = 0;
					$self->{sstsav}={};
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
#
sub usedbm { 
	my $self =attr shift;
	if (@_) {$usedbm=shift;}
	croak " can not do a local search without motif !!\n you must provide  a string thru motif() method before \n" unless $motif;
	if ($usedbm>0){searchdbm();};
	return $dbfile;
	}
sub dbfile { 
	my $self =attr shift;
	if (@_) {$dbfile=shift;};
	return $dbfile;
	}
sub useragent { 
	my $self =attr shift;
	if (@_) {$useragent=shift;}
	return $useragent;
	}
sub username_frigo { 
	my $self =attr shift;
	if (@_) {$username_frigo=shift;}
	return $username_frigo;
	}
sub password_frigo { 
	my $self =attr shift;
	if (@_) {$password_frigo=shift;}
	return $password_frigo;
	}
sub nbres { 
	my $self =attr shift;
	if (@_) {$nbres=shift;}
	#print $fh   " $nbres : sous-titres touves \n";
	return $nbres;
	}
sub srchadr { 
	my $self =attr shift;
	if (@_) {$srchadr=shift;}
	return $srchadr;
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
sub get_all_result { # alias for sstsav
	my $self =attr shift;
	if (!($self->sstsav())){ return undef}
	else {return %sstsav;};
}
sub sstsav { 
	my $self =attr shift;
	if (%sstsav){return %sstsav;}
	else {return undef;};
	}
sub html { 
	my $self =attr shift;
	@_?$html=shift:$html=$self;
	unless (-e ($html))
		{
		print $fh "[DEBUG] html report file doesn't exists \n";
		print $fh "[DEBUG] Sucksub will create one ... \n";
		}
	return $html;
}
sub cookies_file { 
	my $self =attr shift;
	if (@_) {$cookies_file=shift;}
	return $cookies_file;
	}

sub loginpage { 
	my $self =attr shift;
	if (@_) {$loginpage=shift;}
	return $loginpage;
	}
sub motif { 
	my $self =attr shift;
	if (@_) {$motif=shift;}
	return $motif;
	}	
sub search{
	my $self =attr shift; 
	return unless $motif;
	our $mech = WWW::Mechanize->new(stack_depth => 1,
					agent=>$useragent,
					cookie_jar => HTTP::Cookies->new(
						file => $cookies_file,
						autosave => 1,
						ignore_discard => 0),
			);
	# login to frigorifix v2 and obtain cookie
	unless ( -e ($cookies_file) )
		{	
		$mech->get($loginpage) or croak  "[WARNING] can not get  $base ! : $!  \n";
		$mech->form_number(3);
		$mech->set_fields( 'user' => $username_frigo);
		$mech->set_fields( 'passwrd' => $password_frigo);
		$mech->set_fields( 'cookieneverexp' => 'on' );	
		$mech->click();
		 };
	print $fh  "--------------------------------------------------------------------------------\n" if ($debug);
	print $fh  "[DEBUG] begin scan on $site  at : ".localtime()."\n" if ($debug);
	print $fh  "[DEBUG] searching : ".$motif." on $site  \n" if ($debug);
	print $fh  "--------------------------------------------------------------------------------\n" if ($debug);
	if ($html)
		{ 
		open (HTML,">>",$html) or warn "can not access $html : $! \n";
		print HTML "<hr><small><b>HTML report generated by suckSub perl module<br></b>\n";
		print HTML "searching : ".$motif." on ".$site." at ".localtime()."</small><br><hr>\n";
		};
	#----main search process call-------------------
	$nbres=_search_frigorifix();
	#-----------------------------------------------
	
	print $fh  "[DEBUG]   ".$nbres."  results found \n" if ($debug);
	print $fh  "--------------------------------------------------------------------------------\n" if ($debug);
	if ($html)
		{
		print HTML "<br><b>".$nbres." result(s) found</b> <br>\n";
		print HTML "<i>Html report finished at ".localtime()."</i><hr><br>\n";
		};
	if ($usedbm)
		{
		_savedbm();
		}
	return $nbres;
};			
sub _search_frigorifix{
	my $self =attr shift; 
	my $jnd=0;my @sstlist=();my @sstlib=();
	$mech->get($srchadr) or croak  "[WARNING] can not get  $site ! : $!  \n";
	#collect and links which text is in search phrase
	my $lnk1=$mech->find_all_links(); 
	for ( my $ind=0; $ind <= $#{$lnk1} ; $ind++)
		{
			if 	( ($lnk1->[$ind]->text() =~ m/$motif/i )
						and ( $lnk1->[$ind]->url_abs() =~m/v2\.frigorifix\.com/)  )
				{  	
					push @sstlist,$lnk1->[$ind]->url_abs();
					push @sstlib,$lnk1->[$ind]->text();
					print $fh   "[FOUND]". $lnk1->[$ind]->text() ."\n\t". $lnk1->[$ind]->url_abs()."\n" if $debug;
					$jnd++ ; 
				};
		};

		# verify all collected links one by one to found subtitle filename
		# first we search the image-link which redirect to the download page
		#<img src="http://v2.frigorifix.com/Smileys/kidechirent/RLZFT.gif" alt="Disponible en section releases" border="0">
		#<img src="http://v2.frigorifix.com/Themes/FrigoLand/images/post/xx.gif" alt="" border="0">
	for ( my $ind2=0; $ind2 <= $#sstlist ; $ind2++)
		{
		$mech->get($sstlist[$ind2]);
	# --------------------------------------------------------------------------------------------------------------
	# 1 : search for indirect links
	# 2 : if not , search for direct links ( DISPO + RIP )
	# 3 : else : there's nothing to get 
	# note : we presuppose there's only one indirect link to download page for a page
	# --------------------------------------------------------------------------------------------------------------
		my $lnk2=$mech->find_link(text_regex=>qr/(Disponible en section releases)|(v2\.frigorifix\.com\/Themes\/FrigoLand\/images\/post\/xx.gif)/);
		#is there any indirect link to download page ?
		print $fh "[DEBUG] SEARCH  SUBTITLES LINKS FOR :   [ ".$sstlib[$ind2]." ] ... \n" if ($debug);
		if ($#{$lnk2}>0)
			{
			$mech->get( $lnk2->url() );
			_search_direct_link($sstlib[$ind2],$sstlist[$ind2]);
			}
		else # there's no release link here?
			{
			_search_direct_link($sstlib[$ind2],$sstlist[$ind2]) 
			};
		};
return $nbres;
};
#-------------------------------------------------------------------------------------------------------------------------
sub _search_direct_link{
	my ($alt_lib,$topic_link) =shift;
	my $self =attr shift;
	my $knd=0;
	my $lnk3 = $mech->find_all_links();
	for ( $knd=0; $knd <= $#{$lnk3} ; $knd++)
		{
			if ($lnk3->[$knd]->url()=~ m/action=dlattach;topic/ )
				{ 
				print  $fh "* [ LINK FOUND ] : \t";
				print $fh $lnk3->[$knd]->url_abs() ."\n";
				$mech->get($lnk3->[$knd]->url_abs());
				my $libelle=$mech->res()->headers()->{'content-disposition'}."\n";
				$libelle = substr $libelle , 22, (length($libelle)-24);
				print $fh "[DEBUG] extract title :  ". $libelle ." \n" if ($debug);
				print $fh "[numero : ".$nbres."]\n"if ($debug);
				$sstsav{$lnk3->[$knd]->url_abs()}=$libelle."_".$alt_lib;
				print $fh "\t[Alt libelle Extracted]\t".$alt_lib."\n" if ($debug);
				print $fh "\t[Libelle Extracted]\t".$libelle."\n" if ($debug);
				print $fh "\t[Url Extracted]\t".$lnk3->[$knd]->url_abs()."\n" if ($debug);
				if ($html)
					{
					print HTML "&nbsp&nbsp<a  href=\"". $lnk3->[$knd]->url_abs() ."\">".$libelle."_".$alt_lib."</a><br>\n";
					};
				$nbres++;
			};
		};
return $nbres;
};
sub searchdbm{ 
	my $self =attr shift;
	croak " can do a local search without $motif !! \n" unless $motif;
	if ($html)
	{
	print HTMLFILE "<hr>\n";
	print HTMLFILE "<b>Searching on local DBM : $dbfile for $site  at : ".localtime()."</b><br>\n";
	print HTMLFILE "<hr>\n";
	};
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
};
#---------------------------------------------------------------------------
#-- save updated hash into dbm file
#-- internal use only
#---------------------------------------------------------------------------
sub _savedbm{
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
##
sub END{
	my $self =attr shift;
	close HTML;close FH;
	return;
};
1; # End of WWW::Sucksub::Frigo
