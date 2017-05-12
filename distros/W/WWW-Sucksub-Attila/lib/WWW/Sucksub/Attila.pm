package WWW::Sucksub::Attila;

=head1 NAME

WWW::Sucksub::Attila - automated access to attila french subtitles database

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

WWW::SuckSub::Attila is a web robot based on the WWW::Mechanize Module.
it parses distant web database specialised on french subtitles and build a dbm file
to store result ( film title - http link for subtitle file ).
The dbm file is used like a dictionnary you can update and use to do quick search.

	use WWW::Sucksub::Attila;
	my $test=WWW::Sucksub::Attila>new(
			motif => $mot,
			debug =>1,
			logout => '/where/debug/file/is/written.txt',
			dbfile=>'/where/dbm/file/is.db',
			html=>'/where/html/report/will/be/written.html'
						);
	$test->update(); #parse all site and collect subtitles http link 
	$test->search(); #search on local dbm file and produce html report

=head1 CONSTRUCTOR AND STARTUP

=head2 Attila Constructor 

The new() constructor, is associated to default values :
you can modify these one as shown in the synopsis example.
Default value are these :

	my $foo = WWW::Sucksub::Divxstation->new(
    		dbfile => "$ENV{HOME}"."/attila.db";
		html => "$ENV{HOME}"."/attila_repport.html";
		motif=> undef,
		tempfile=> "$ENV{HOME}"."/.attila_tmp.html";
		debug=> 0, 
		logout => \*STDOUT	  					
    		useragent=> "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007"
    		);
   		
The environnement variable $ENV{HOME} must exist unless you redefine the constructor value which need it.


=head3 new() constructor attributes and associated methods

All listed attributes can be modified by corresponding methods :
 - set the attributes value when calling equivalent method whith args.
 - get the attribute value when calling equivalent method whithout args.

	$foo->WWW::Sucksub::Attila->new()
	$foo->useragent() # get the useragent attribute value
	$foo->useragent('tructruc') # set the useragent attribute value to 'tructruc'

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
	$foo->debug(1) # debug info will be written to the log file ( see logout() method) .

=head4 logout()

A log file can be defined to keep a trace of website parsing
You have to set $obj->debug(1) to get more detailled informations. 

		$foo->logout(); 				#get the current logout() value
		$foo->logout('/home/xxx/log.txt') 	#set logout() value.

Note that default value is STDOUT
the logout() value can only be set in the new constructor.

=head4 dbfile()

define dbm file for store and retrieving extracted informations
you must provide au full path to the db file to store results

 	dbfile('/where/your/db/is.db')

The file will should be readable/writable.

=head4 html()

Define simple html output where to write search report.
you must provide au full path to the html file if you want to get an html output.

 	html('/where/the html/repport/is/written.html')

If $foo->html() is defined. you can get the value of this attribute like this :

	my $html_page = $foo->html

Default value is automatically defined on the new() call.

	html => "$ENV{HOME}"."/attila_report.html";

html file will be used for reporting with search() methods

=head4 useragent()

arg should be a valid useragent. There's no reason to change this default value.

	$foo->useragent()

return the value of the current useragent

	$foo->useragent('xxxxxxxx')

set the useragent() value to ''xxxxxxxx'.	

=head1 FUNCTIONS

these functions use the precedent attributes value.

=head2 search() 

this function takes no arguments.
it allows to launch a local dbm search.

	$foo-> search()

the dbm file is read to give you every couple  (title,link) which corresponds to
the motif() pattern you defined before.

=head2 update() 
 
this function takes no arguments.
it allows to initiate the distant search on the web site http://davidbillemont5.free.fr/ ( attila website)
the local dbm file is automatically written. Results are accumulated to the dbm file
you define on new() call .
Note that the update can take a while.

=head1 AUTHOR

Timothée Foucart, C<< <timothee.foucart@apinc.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-sucksub-attila@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Sucksub-Attila>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * L<WWW::Sucksub::Divxstation>

=item * L<WWW::Sucksub::Vostfree>

=item * L<WWW::Mechanize>

=item * L<HTML::Parser>

=item * L<Alias>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2005 Timothée Foucart, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT=qw(  debug dbfile  
		 get_all_result html logout 
		 motif search update useragent );
		 
#use warnings;
use utf8;
use warnings;
use strict;
use Carp;
use WWW::Mechanize;
#
use Alias qw(attr);
use vars qw(  $site $nbres $base $debug $useragent $motif %sstsav $logout $fh $tempfile $dbfile $html );
sub new{
	 	my $attila=shift;
		my $classe= ref($attila) || $attila;
		my $self={	};
	 	bless($self,$classe);
	 	$self=$self->_init(@_);
	 	logout($self->{logout});
	 	return $self;
		};
		
sub _init{
	my $self= attr shift;
 	#
 	# -- init default values
 	#
 	$self->{base} ="http://davidbillemont5.free.fr/";
	$self->{site} = "http://davidbillemont5.free.fr/Sous-Titres%200.htm";
	$self->{tempfile} = "$ENV{HOME}"."/.attila_tmp.html";
	$self->{useragent} ="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.5) Gecko/20031007";
	$self->{motif} = undef;
	$self->{debug} = 0;
	$self->{logout} = \*STDOUT;
	$self->{nbres} = 0;
	$self->{sstsav} = {};
	$self->{dbfile} = "$ENV{HOME}"."/attila.db";
	$self->{html} = "$ENV{HOME}"."/attila_repport.html";
 	#
 	# -- replace "forced" values
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
	if (@_) {$dbfile=shift;}
	return $dbfile;
	}
sub html { 
	my $self =attr shift;
	if (@_) {$html=shift;}
	return $html;
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
sub motif { 
	my $self =attr shift;
	if (@_) {$motif=shift;}
	return $motif;
	}	
sub logout { 
	#no update after first init
	if (@_){$logout=shift; }
    	if ($logout)
		{ open(FH , ">>", $logout) or croak "$logout : $!\n"; 
		   $fh=(\*FH);} 
	else 
		{ $fh=(\*STDOUT);};
	return $logout;
	}	
sub update{
	my $self =attr shift; 
	my $mech = WWW::Mechanize->new(agent=>$useragent,
					stack_depth => 1,
					);
print $fh  "------------------------------------------------------------------------------------------------\n" if ($debug);
print $fh  "[DEBUG] begin updating local database from $site  at : ".localtime()."\n" if ($debug);
print $fh  "------------------------------------------------------------------------------------------------\n" if ($debug);

my @update_base;
my $ipage=0;
my $attila_page;
$mech->get($site) or warn "[WARNING] http get problem on : $site !! \n";
my $links=$mech->find_all_links(); 
for ( my $ind=0; $ind <= $#{$links} ; $ind++)
		{
			if ($links->[$ind]->url_abs()=~m/Sous-Titres/m)
				{
				$ipage++;
				print $fh "[DEBUG][SUBTITLE PAGE  : $ipage ]\t".$links->[$ind]->url_abs()."\n" if $debug;
				push @update_base,$links->[$ind]->url_abs();
				};
		};
foreach $attila_page (@update_base)
	{
	if (-e ($tempfile))
		{unlink $tempfile or croak "can not suppress $tempfile : $!\n";};
	print $fh "[DEBUG] parsing : ".$attila_page ."\n"; 
	$mech->get($attila_page);
	open (TAMPON,'>', $tempfile) or croak "can not open $tempfile:$!\n";
	print TAMPON $mech->response->as_string;
	close TAMPON;
	my %x=parse_attila($tempfile);
	while (my ($k, $v) = each %x)
      		{ $sstsav{$k}=$v;};
	save_dbm(%sstsav);
	};
	
print $fh "[DEBUG] update finished\n";
return; 
};
#
# --- recherche du motif dans la db
sub search{
	my $self =attr shift;
	$motif=$self->motif();
	if ($html)
		{ 
		open (HTMLFILE,">>",$html) or warn "can not access $html   : $! \n";
		print HTMLFILE "<hr> <small>html generated by suckSub perl module<br>\n";
		print HTMLFILE "searching : ".$motif." on ".$site."<br>\n";
		print HTMLFILE " ".localtime()."</small><br>\n";
		};
	my %hashread;
	return unless $motif;
	print $fh " file db is : ". $dbfile."\n";
	unless (-e ($dbfile))
		{croak "[DEBUG SEARCH] db file ".$dbfile." not found \n maybe you should use update() method to build it ! \n";};
	use DB_File;
	tie(%hashread,'DB_File',$dbfile)
		or croak "can not access : $dbfile : $!\n";
	while (my ($k,$v)=each(%hashread))
		{ 
		 if ($v =~ m/$motif/i)
		 	{
		 	print $fh "[FOUND Libelle ] $v \n[FOUND LINK]".$k ."\n";
		 	if ($html)
		 		{ 
		  		print HTMLFILE "<a href=\"".$k."\">".$v."</a><br>\n";
		  		$nbres++
		  		};
		 	
		 	};
		};
		untie(%hashread);
		if ($html)
			{
			print HTMLFILE "<br><b>".$nbres." result(s) found</b> <br>\n";
			print HTMLFILE " html finished at ".localtime()."<br>\n";
			close HTMLFILE;
			};
return;	
};
			
#---------------------------------------------------------------------------
#-- save updated hash into dbm file
#-- internal use only
#---------------------------------------------------------------------------
sub save_dbm{
my $self =attr shift;
my %hashtosave;
use DB_File;
tie (%hashtosave,'DB_File',$dbfile )
	or croak "can not use $dbfile : $!\n";
	 while (my ($k, $v) = each %sstsav)
      { $hashtosave{$k}=$v;};
untie(%hashtosave);
return;	
};
#---------------------------------------------------------------------------	
#--- parse one .htm page and extract label + info + link into memo hash
#-- internal use only
#---------------------------------------------------------------------------
sub parse_attila{
	use HTML::Parser;
	use vars qw( %hsav $top_label1 $label $endor );
	my $file=$_[0];
	$label="";
	$top_label1=0; #flag begin label or text to get
	$endor=0;# flag end of row => re-init counters for states analyse
	my $p = HTML::Parser->new();
#
	$p->handler( start => \&start_attila, "tagname,attr" );
	$p->handler( text  => \&text_attila,  "text" );
	$p->unbroken_text( 1 );
	$p->marked_sections( 0 );
	$p->ignore_elements(qw(script style));
#
	$p->parse_file($file);
	$p->eof;
#
#
#
	sub start_attila 	{
         my ( $tag, $args ) = @_;
        #--- searching 'td' tag -> verify width of each column
        if ( $tag eq 'td' )
        	{
        	return unless $args->{width};	
        	# french label and orig title in the array
         	if ( ($args->{width} eq '39%')  && ($top_label1==0) )
        		  { $top_label1++;};
        	if ( ($args->{width} eq '39%')  && ($top_label1==1) )
        		  { $top_label1++;};
        	# possible width variation 
        	if ( ($args->{width} eq '38%')  && ($top_label1==0) )
        		  { $top_label1++;};
        	if ( ($args->{width} eq '38%')  && ($top_label1==1) )
        		  { $top_label1++;};
        	# number of cd width = 10-11%
        	if ( ($args->{width} eq '10%') && ($top_label1>0))
        		{ $top_label1++;$endor=1};
        	if ( ($args->{width} eq '11%') && ($top_label1>0))
        		{ $top_label1++;$endor=1};
        	}
        #---searching sub links in html page 
        if (( $tag eq 'a' ) && ($args->{href}))
        	{
        	if ($args->{href} =~ m/Subs\// )
        		{ 
        		$hsav{$base.$args->{href}}=$label;
        		#DEBUG#print "[DEBUG PARSER]". $args->{href} ." ===>".$label."\n";
        		$label="";$top_label1=0;
        			
        		};
        	};
	};
	sub text_attila {
        my $text= shift;
	  $text =~ tr/&nbsp;//s; # nbsp html
	  $text =~ tr/ /_/s; #
	  $text =~ s/-/_/gi; 
	  $text =~ s/\n//gi; #
	  $text =~ tr/_/_/s; #  
	  if ($top_label1>0)
	  	{ 
		  return if ($text eq "_"); # texte parasite
		  $label=$label."[".$text."]";
		  $top_label1++;
		  if ($endor==1){$top_label1=0;$endor=0};
		  #DEBUG#print "[DEBUG PARSER LABEL] ". $label ."\n";
	  	}; 
	return $label
	};
return %hsav;
}
#



1; # End of WWW::Sucksub::Attila
