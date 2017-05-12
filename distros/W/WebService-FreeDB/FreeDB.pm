package WebService::FreeDB; # -*- tab-width:8 -*- 
use Data::Dumper;
use LWP::UserAgent; # Erweiterung jb

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw//;
@EXPORT_OK = qw/getdiscs getdiscinfo ask4discurls outdumper outstd/;
$VERSION = '0.79';

#####
# Description: for getting a instace of this Class
# Params: %hash with keys:
#         HOST : Destination host, if not defined: www.freedb.org
#         PATH : Path on HOST to CGI
#         PROXY: Define Proxy to use
#         DEFAULTVALUES : Default parameters for CGI, will be set always
# Returns: an object of this class
#####
sub new {
	my $class = shift;
	my $self = {};
	$self->{ARG} = {@_};
	if(!defined($self->{ARG}->{HOST})) {
		#Maybe there are other freedb-web-interfaces ?!
		$self->{ARG}->{HOST}='http://www.freedb.org'  
	}
	if(!defined($self->{ARG}->{PATH})) {
		#Path to CGI-script
		$self->{ARG}->{PATH}='/freedb_search.php'} 
	if(!defined($self->{ARG}->{PROXY})) {			  
		#If there's no proxy, define but don't change it		 
		$self->{ARG}->{PROXY}=''  					  
	}												  
	if(!defined($self->{ARG}->{DEFAULTVALUES})) {
		#default Parameters
		$self->{ARG}->{DEFAULTVALUES}='&allfields=NO&grouping=none'
	}
	bless($self, $class);
	$self ? return $self : return undef;
	
}

#####
# Description: out of Keywords it will return a List of entries in FreeDB
# Params: <Keywords as a String>,[Array of fields to search in],
#         [Array of categories to search in]
# Returns: %Hash, where urls are Key and [Array of Artist,Album] is value%
#####
sub getdiscs {
	my $self = shift;
	my @keywords = split(/ /,shift);
	my @fields = @{$_[0]};
	if(defined $_[1]) {@cats = @{$_[1]};}
	my %discs;
	my $url = $self->{ARG}->{HOST}.
	          $self->{ARG}->{PATH}."?".
			  $self->{ARG}->{DEFAULTVALUES};
	
	
	$url .="&words=".shift(@keywords);
	for my $word (@keywords) {
		$url .= "+".$word;
	}
	
	
	for my $field (@fields) {
		if(!($field =~ /^(artist|title|track|rest)$/)) {
			if (defined $self->{ARG}->{DEBUG} &&
			    $self->{ARG}->{DEBUG} >= 1) {
			    print STDERR "*unknown field-type: $field;\n" 
		    }
			next;
		}
		$url .= "&fields=".$field;
	}
	if (@cats) {
		$url .= "&allcats=NO";
		for my $cat (@cats) {
			if(!($cat =~ /^(blues|classical|country|data|folk|jazz|misc|newage|reggae|rock|soundtrack)$/)) {
			    if (defined $self->{ARG}->{DEBUG} && 
				    $self->{ARG}->{DEBUG} >= 1) {
				   print STDERR "*unknown cat-type: $cat;\n" 
		        }
				next;
			}
			$url .= "&cats=".$cat;
		}
	} else {
		$url .= "&allcats=YES";
	}
	
	if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 2) {
		print STDERR "**url-search: $url;\n" ;
	}

	my $ua = LWP::UserAgent->new();
	$ua->proxy('http' => $self->{ARG}->{PROXY});
	my $req = HTTP::Request->new(GET => $url);
	my $response = $ua->request($req);
	if ($response->is_success) {
		my $data = $response->content;
		my ($line) = grep {m|^<a name="fdbsr"></a>|} split(/\n/, $data);
		die "no match" unless $line;
                $discs{$1} = [$2,$3]
		  while $line =~ m|<a href="(.+?)" class=searchResultTopLinkA .+? title=".+? / .+?">(.+?) / (.+?)</a></td>|g;
	}							   
	else {						   
		die $response->status_line;
	} 							   
	return %discs;
}

#####
# Description: out of a URL (you got as key from getdiscs() ) will retrieve 
#              concrete Informations of this CD.
# Params: <URL as String>
# Returns: %Hash of items of the CD%
#####
sub getdiscinfo {
	my $self = shift;
	my $url = shift;
	my %disc;

	if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 2) {
		print STDERR "**url-disc:$url;\n";
	}
	my $ua = LWP::UserAgent->new();
	$ua->proxy('http' => $self->{ARG}->{PROXY});
	my $req = HTTP::Request->new(GET => $url);
	my $response = $ua->request($req);
	if ($response->is_success) {
		my $data = $response->content;
		if (!defined($data)) {
			if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
				print STDERR "*found no disc;\n";
			}
			return ;
		}
		$disc{url} = $url;
		@lines = split(/\n/,$data);
		$line = shift(@lines);
		#ignore until begin of searchResult data
		while (!($line =~ m|^<a name="fdbsr"></a>|)) {
		  $line = shift(@lines);
		  last unless @lines;
		}
		if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 2) {
			print STDERR "**found start of data :$line;\n"; 
		}
		die "found no data. FreeDB template format changed?\n" unless $line;
		if ($line =~ m|/id="searchU11" title="(.+?) / (.+?)">|) {
			$disc{artist} = $1;
			$disc{album} = $2;
		} else {
			if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
				print STDERR "*format error(artist+album):$line;\n";
			}
		}
		if ($line =~ m|<b>Tracks:</b>\s*?(\d+)<br>|) {
			$disc{tracks} = $1;
		} else {
  			if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
				print STDERR "*format error(tracks):$line;\n";
			}
		}
		if ($line =~ m|<b>Total time:</b>\s*(\d+:\d+)<br>|) {
			$disc{totaltime} = $1;
		} else {
			if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
	 			print STDERR "*format error(totaltime):$line;\n";
			}
		}
		if ($line =~ m|<b>Year:</b>\s*(\d*)<br>|) {
			$disc{year} = $1;
		} else {
			 if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
				print STDERR "*format error(year):$line;\n";
			}
		}
		if ($line =~ m|<b>Disc-ID:</b>\s*(.*?) / |) {
			$disc{genre} = $1;
		} else {
  			if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
				print STDERR "*format error(genre):$line;\n";
			}
		}
		if(!defined($disc{artist})) {$disc{artist} = "";}
		if(!defined($disc{album})) {$disc{album} = "";}
		if(!defined($disc{year})) {$disc{year} = "";}
		if(!defined($disc{genre})) {$disc{genre} = "";}

		while (!($line =~ /^<table border=0>$/)) { #ignore until begin of tackinfo
			if ($line =~ /^<br><hr><center><table width="98%"><tr><td bgcolor="#E8E8E8"><pre>$/) {
				$line = shift(@lines);
				while (!($line =~ /<\/pre><\/tr><\/td><\/table><\/center>/)) {
					$disc{rest} .= $line."\n";
					$line = shift(@lines);
					last unless $line;
				}
			}
			$line = shift(@lines);
			if (!defined($line)) {
				$disc{trackinfo} = defined;
				return %disc;  #break if not found beginning (empty entries)
			}
		}
		if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 2) {
			print STDERR "**found start of trackinfo:$line;\n";
		}
		$index = 1;
		for my $line (@lines) {
			if ($line =~ /^<br><br><\/td><\/tr>$/) {next;}    
			elsif ($line =~ /^<font size=small>.*?<\/font>/) {next;} # ignore ext-desc of a track
			elsif ($line =~ /^<tr><td valign=top> {0,1}$index\.<\/td><td valign=top> {0,1}(\d+:\d+)<\/td><td><b>(.+)<\/b>/) {
  				if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 3) {
					print STDERR "***found track: $line;\n";
				}
				$disc{trackinfo}[$index-1]=[$2,$1];
				$index++;
			} elsif ($line =~ /^<tr><td valign=top> \d+\.<\/td><td valign=top> (\d+:\d+)<\/td><td><b>(.+)<\/b>/) {
  				if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
					print STDERR "*out of sync for trackinfo:$line;\n";
				}
			} elsif ($line =~ /^<\/table>$/) {
				if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 2) {
					print STDERR "**found end of trackinfo & data: $line;\n";
				}
			} else {next;}

		}
		return %disc;
	} else {
	  #print STDERR "Url was: ".$url."\n";
		die $response->status_line;
	}
}

#####
# Description: User interactive method (console) for selecting CDs for retrieval
# Params: %Hash, where urls are Key and [Array of Artist,Album] is value%
#         (you got it from getdiscs())
# Returns: [Array of URLs, which where selected by User]
#####
sub ask4discurls {
	my $self = shift;
	my %discs = %{$_[0]};
    #sort for artists
    my @keys = sort { $discs{$a}[0] cmp $discs{$b}[0] || $discs{$a}[1] cmp $discs{$b}[1]} keys %discs;
    my @urls;

	if(!defined($keys[0])) {
		print STDERR "Sorry - no matching discs found\n";
		return 1;
}
	#giving list 2 user
	for (my $i=0;$i<@keys;$i++) {
		print STDERR "$i) ".$discs{$keys[$i]}[0]." / ".$discs{$keys[$i]}[1];
		if (defined $discs{$keys[$i]}[2]) {
			print STDERR " [".(@{$discs{$keys[$i]}} - 2)." alternatives]";
		}
		print STDERR "\n";
	}
	print STDERR "Select discs (space seperated numbers or <from>-<to>;alternatives by appending 'A' and alternate-number):\n";
	$userin = <STDIN>;
	chomp $userin;
	while($userin =~ /(\d+)A(\d+)-(\d+)A(\d+)/) {                                              # 23A2-42A3 - so with beginning alternatives
		if(!($1<$3)) {
			print STDERR "Ignoring $1-$3 ...";
		}
		my $tmpadd = $1."A".$2." ";
		for(my $i=$1+1;$i<=$3-1;$i++) {
			$tmpadd .= $i." ";
   	 	}
		$tmpadd .= $3."A".$4;
		$userin =~ s/$1A$2-$3A$4/$tmpadd/;
	}
	while($userin =~ /(\d+)A(\d+)-(\d+)/) {                                              # 23A2-42 - so with beginning alternatives
		if(!($1<$3)) {
			print STDERR "Ignoring $1-$3 ...";
   	 	}
		my $tmpadd = $1."A".$2." ";
		for(my $i=$1+1;$i<=$3;$i++) {
			$tmpadd .= $i." ";
		}
		$userin =~ s/$1A$2-$3/$tmpadd/;
	}
	while($userin =~ /(\d+)-(\d+)A(\d+)/) {                                              # 23-42A2 - so with beginning alternatives
		if(!($1<$2)) {
			print STDERR "Ignoring $1-$2 ...";
		}
		my $tmpadd = "";
		for(my $i=$1;$i<=$2-1;$i++) {
			$tmpadd .= $i." ";
		}
		$tmpadd .= $2."A".$3;
		$userin =~ s/$1-$2A$3/$tmpadd/;
	}
	while($userin =~ /(\d+)-(\d+)/) {                                              # 23-42 - so without alternatives
		if(!($1<$2)) {
			print STDERR "Ignoring $1-$2 ...";
		}
		my $tmpadd = "";
		for(my $i=$1;$i<=$2;$i++) {
			$tmpadd .= $i." ";
		}
		$userin =~ s/$1-$2/$tmpadd/;
	}
	@select = split (/ /,$userin);
	for my $cd (@select) {
		if ($cd =~ /^\d+$/ && defined($keys[$cd])) {
			push(@urls,$keys[$cd]);
		} elsif ($cd =~ /^(\d+)A(\d+)$/ && $discs{$keys[$1]}[($2+2)]) {
			push(@urls,$discs{$keys[$1]}[($2+2)]);
		} else {
			print STDERR "not defined '$cd' - ignoring!\n";
		}
	}
	return @urls;
}

#####
# Description: output-method of the retrieved CD
#              this goes out to STDOUT by using Data:Dumper
# Params: %Hash of items of the CD%
#         (you got it from getdiscinfo())
# Returns: nothing
#####
sub outdumper {
	if(!defined($disc{url})) {
		if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
			print STDERR "*no disc info \n";
		}
		return 1;
	}
	my $self = shift;
	my $disc = shift;
	print Dumper $disc;
}

#####
# Description: output-method of the retrieved CD
#              this goes out to STDOUT in a pretty formated Look
# Params: %Hash of items of the CD%
#         (you got it from getdiscinfo())
# Returns: nothing
#####
sub outstd {
	my $self = shift;
	my %disc = %{$_[0]};
	if(!defined($disc{url})) {
 		if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
			print STDERR "*no disc info \n";
		}
		return 1;
	}
	print "DiscInfo:\n########\n";
	print "Artist:".$disc{artist}." - Album: ".$disc{album}."\n";
	print "Reference:".$disc{url}."\n";
	print "Total-Tracks:".$disc{tracks}." - Total-Time:".$disc{totaltime}."\n";
	print "Year:".$disc{year}." - Genre:".$disc{genre}."\n";
	if(defined($disc{rest})) {print "Comment:".$disc{rest}."\n";}
	print "Tracks:\n";
	for (my $i=0;$i<@{$disc{trackinfo}};$i++) {
		print 1+$i.") ".${$disc{trackinfo}}[$i][0]." (".${$disc{trackinfo}}[$i][1].")\n";
	}
}

#####
# Description: output-method of the retrieved CD
#              this goes out to STDOUT in XML 
#              validating against example/cdcollection.dtd
# Params: %Hash of items of the CD%
#         (you got it from getdiscinfo())
# Returns: nothing
#####
sub outxml {
	my $self = shift;
	my %disc = %{$_[0]};
	if(!defined($disc{url})) {
 		if (defined $self->{ARG}->{DEBUG} && $self->{ARG}->{DEBUG} >= 1) {
			print STDERR "*no disc info \n" ;
		}
		return 1;
	}
    print "<cd type=\"".ascii2xml($disc{type})."\">\n";
    if(defined($disc{medium})) {print "\t<medium>".ascii2xml($disc{medium})."</medium>\n";}
    if(defined($disc{id})) {print "\t<id>".ascii2xml($disc{id})."</id>\n";}
    if (defined($disc{artist})) {print "\t<artist>".ascii2xml($disc{artist})."</artist>\n";}
    print "\t<title>".ascii2xml($disc{album})."</title>\n";
    if (defined($disc{year})) {print "\t<year>".ascii2xml($disc{year})."</year>\n";}
    if(defined($disc{source})) {print "\t<source>".ascii2xml($disc{source})."</source>\n";}
    if(defined($disc{quality})) {print "\t<quality>".ascii2xml($disc{quality})."</quality>\n";}
    if(defined($disc{comment})) {print "\t<comment>".ascii2xml($disc{comment})."</comment>\n";}
    print "\t<tracklist>\n";
    for (my $i=0;$i<@{$disc{trackinfo}};$i++) {
      my ($artist1,$name1) = split(/ \/ /,${$disc{trackinfo}}[$i][0]);
      my ($artist2,$name2) = split(/ - /,${$disc{trackinfo}}[$i][0]);
      if (defined($disc{type}) && $disc{type} eq "sampler" && defined $name1) {
        print "\t\t<track>\n";
		if(defined($artist1)) {print "\t\t\t<artist>".ascii2xml($artist1)."</artist>\n";}
		if(defined($name1)) {print "\t\t\t<name>".ascii2xml($name1)."</name>\n";}
		if(defined($disc{trackinfo}[$i][1])) {print "\t\t\t<time>".ascii2xml(${$disc{trackinfo}}[$i][1])."</time>\n";}
		if(defined($disc{trackinfo}[$i][2])) {print "\t\t\t<quality>".ascii2xml(${$disc{trackinfo}}[$i][2])."</quality>\n";}
		print "\t\t</track>\n";
        print STDERR "Splitted title ' / ' - highly recommed to check this !\n";                                                                         
      } elsif (defined($disc{type}) && $disc{type} eq "sampler" && defined $name2) {
        print "\t\t<track>\n";
		if(defined($artist2)) {print "\t\t\t<artist>".ascii2xml($artist2)."</artist>\n";}
		if(defined($name2)) {print "\t\t\t<name>".ascii2xml($name2)."</name>\n";}
		if(defined($disc{trackinfo}[$i][1])) {print "\t\t\t<time>".ascii2xml(${$disc{trackinfo}}[$i][1])."</time>\n";}
		if(defined($disc{trackinfo}[$i][2])) {print "\t\t\t<quality>".ascii2xml(${$disc{trackinfo}}[$i][2])."</quality>\n";}
		print "\t\t</track>\n";
        print STDERR "Splitted title ' - ' - highly recommed to check this !\n";
      } elsif (defined($disc{type}) && $disc{type} eq "sampler") {
        print "\t\t<track>\n";
		if(defined($disc{trackinfo}[$i][0])) {print "\t\t\t<name>".ascii2xml(${$disc{trackinfo}}[$i][0])."</name>\n";}
		if(defined($disc{trackinfo}[$i][1])) {print "\t\t\t<time>".ascii2xml(${$disc{trackinfo}}[$i][1])."</time>\n";}
		if(defined($disc{trackinfo}[$i][2])) {print "\t\t\t<quality>".ascii2xml(${$disc{trackinfo}}[$i][2])."</quality>\n";}
		print "\t\t</track>\n";
        print STDERR "NOT Splitted title - highly recommed to check this !\n";
      } else {
        print "\t\t<track>\n";
		if(defined($disc{trackinfo}[$i][0])) {print "\t\t\t<name>".ascii2xml(${$disc{trackinfo}}[$i][0])."</name>\n";}
		if(defined($disc{trackinfo}[$i][1])) {print "\t\t\t<time>".ascii2xml(${$disc{trackinfo}}[$i][1])."</time>\n";}
		if(defined($disc{trackinfo}[$i][2])) {print "\t\t\t<quality>".ascii2xml(${$disc{trackinfo}}[$i][2])."</quality>\n";}
		print "\t\t</track>\n";
      }
    }
    print "\t</tracklist>\n";
    print "</cd>\n";
}
#####
# Description: PRIVATE - not for use outside !
#              Converts special XML Chars to XML-style
# Params: <String Ascii encoded>
# Returns: <String XML encoded>
#####
sub ascii2xml {
	$ascii = $_[0];

	$ascii =~ s/&/&amp;/g;
	$ascii =~ s/</&lt;/g;
	$ascii =~ s/>/&gt;/g;
	$ascii =~ s/'/&apos;/g;
	$ascii =~ s/"/&quot;/g;

	return $ascii;
}

return 1;
__END__

=head1 NAME

WebService::FreeDB - retrieving entries from FreeDB by searching 
for keywords (artist,track,album,rest)

=head1 SYNOPSIS

use WebService::FreeDB;

Create an Object

 $freedb = WebService::FreeDB->new();

Get a list of all discs matching 'Fury in the Slaughterhouse'

 %discs = $cddb->getdiscs(
	"Fury in the Slaughterhouse",
	['artist','rest']
 );

Asks user to select one or more of the found discs

 @selecteddiscs = $cddb->ask4discurls(\%discs);

Get information of a disc

 %discinfo = $cddb->getdiscinfo(@selecteddiscs[0]);

print disc-information to STDOUT - pretty nice formatted

 $cddb->outstd(\%discinfo);

=head1 DESCRIPTION

WebService::FreeDB uses a FreeDB web interface (default is www.freedb.org)
for searching of CD Information. Using the webinterface, 
WebService::FreeDB searches for artist, song, album name or the ''rest'' field. 

The high level functions included in this modules makes it easy to search 
for an artist of a song, all songs of an artist, all CDs of an artist or 
whatever.

=head1 USING WebService::FreeDB

=head2 How to work with WebService::FreeDB

=over 5


=item B<Creating a WebService::FreeDB object>

This has to be the first step

 my $cddb = WebService::FreeDB->new()

You can configure the behaviour of the Module giving new() optional parameters:

Usage is really simple. To set the debug level to 1, simply:

my $cddb = WebService::FreeDB->new( DEBUG => 1 )

B<optional prameters>
B<DEBUG>: [0 to 3] - Debugging information,

C<0> is default (means no additional information), 3 gives a lot of stuff 
(hopefully) nobody needs.  All debug information goes to STDERR.

B<HOST>: FreeDB-Host where to connect to.

C<www.freedb.org> is default - has to have a webinterface - no normal 
FreeDB-Server !

B<PATH>: Path to the php-script (the webinterface)

C</freedb_search.php> is default - so working on www.freedb.org

B<PROXY>: proxy to use for connecting to FreeDB-Server

C<none> is default

B<DEFAULTVALUES>: Values with will be set for every request.

C<allfields=NO&grouping=none> is default, so the grouping feature is not 
supported until now.

=item B<Getting a list of all albums for keywords.>

Now we retrieve a list of CDs, which match to your keywords in given fields.
Available fields are C<artist,title,track,rest>.
Available categories are
C<blues,classical,country,data,folk,jazz,misc,newage,reggae,rock,soundtrack>
For explanation see the webinterface.

 %discs = $cddb->getdiscs(
     "Fury in the Slaughterhouse",
     [qw( artist rest )]
 );

The returned hash includes as key the urls for retriving the concrete data and 
as value a array of the artist,the album name followed by the 
alternative disc-urls

=item B<Selecting discs from the big %discs hash.>

After retrieving a huge list of possible matches we have to ask the user to 
select one or more CDs for retrieval of the disc-data. 

 @selecteddiscs = $cddb-E<gt>ask4discurls(\%discs);

The function returns an array of urls after asking user. (using STDERR)
The user can select the discs by typing numbers and ranges (e.g. 23-42)


=item B<Retrieving the concrete disc informations>

This functions gets a url and returns a hash including all disc information.

 %discinfo = $cddb-E<gt>getdiscinfo(@selecteddiscs[0]);

So we have to call this function n-times if the user selects n cds.
The hash includes the following keys
C<url,artist,totaltime,genre,album,trackinfo,rest,tracks,year>
These are all string except trackinfo, this is a array of arrays.
Every of these small arrays represent a track: first its name , second its time.

Please keep an eye on track vs. length of the trackinfo array.
Some entries in FreeDB store an other number of tracks than they have stored !

=item B<print out disc information.>

Now the last step is to print the information to the user.

 $cddb->outdumper(\%discinfo); # Like Data::Dumper
 $cddb->outstd(\%discinfo); # nicely formatted to stdout
 $cddb->outxml(\%discinfo); # XML format

These 3 functions print a retrieved disc out.

The XML format outputs according to example/cdcollection.dtd this method
does not use every information. 
This Function also prints some additional information out, if given.
This is, because it is used by other projects, such like music-moth
(www.moth.de)
I think this is the point for starting your work: Take %discinfo and write
whhat ever you want.

=back

=head1 NOTICE

Be aware this module is in B<BETA> stage. 

=head1 AUTHOR

Copyright 2002-2003, Henning Mersch All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: hm@mystical.de

=head1 BUGS

None known - but feel free to mail if you got some !

=head1 SEE ALSO

perl(1)

www.freedb.org


=cut

