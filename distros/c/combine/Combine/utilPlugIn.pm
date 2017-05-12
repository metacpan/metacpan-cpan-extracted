## $Id: utilPlugIn.pm 319 2009-11-20 15:45:12Z it-aar $

# See the file LICENCE included in the distribution.
# Ignacio Garcia Dorado 2008, and Anders Ardö 2008
# Utils to control the SVM, language, access to database, update...

package Combine::utilPlugIn;
use strict;

use Combine::XWI;
use Combine::MySQLhdb;
use Combine::LoadTermList;

my $svm;
my %term_set;
my $stoplist;
my $geoinfo;
my %server2country;

#######################################
#Analyze
#######################################
sub analyse {
    my ($xwi) = @_;

#Country for server
    use Geo::IP;
    use Locale::Country;
    # semi-private routines
    if ( ref($geoinfo) ne 'Geo::IP' ) { #INIT
      Locale::Country::alias_code('uk' => 'gb');
      Locale::Country::rename_country('gb' => 'Great Britain');
      Locale::Country::rename_country('tw' => 'Taiwan');
      $geoinfo = Geo::IP->new(GEOIP_STANDARD);
      my $configDir = Combine::Config::Get('configDir');
#      print "INIT server2country\n";
      if ( open(TT,"<$configDir/server2country") ) {
	  while (<TT>) { 
	      next if (/^\s*#/);
	      next if (/^\s*$/);
	      s/[\n\r\f]//g;
	      if (/^([^\s]+)\s+(.*)\s*$/) {
		  my $server=$1;
		  my $country=$2;
		  $server =~ s|^([^/]+)/.*$|$1|; #clean up
		  #do server translation
		  $server = $Combine::Config::serverbyalias{$server} || $server;
		  $server2country{$server}=$country;
	      }
	  }
	  close(TT);
      }
    }

   my $url = $xwi->url;
	#print "Doing $url\n";
   if ($url =~ m|http://([^/]+)/|) {
        my $country='';
        my $host=$1;
        $host =~ s/:\d+$//;
        $host =~ s/%..$//;
        $host =~ m/\.([a-z]+)$/;
        my $topdom = $1;

	if (defined($server2country{$host})) {
	    $country=$server2country{$host};
	    #print "server2country: $host => $country\n";
        } elsif ( $host =~ /^[\d\.]+$/ ) {
	    $country = $geoinfo->country_name_by_addr($host);
         #print "IP: $host -> $country\n";
        } elsif ( (length($topdom)==2) && !(($topdom eq 'tv') || ($topdom eq 'nu') || ($topdom eq 'to')) ) {
	    $country = code2country($topdom);
         #print "topdom: $host -> $country\n";
        } elsif ( ($topdom eq 'gov') || ($topdom eq 'edu') ) {
	    $country = 'United States';
         #print "gov,edu: $host -> $country\n";
        } else {
	    $country = $geoinfo->country_name_by_name($host);
         #print "geoip: $host -> $country\n";
        }
         #print "Got: $host -> $country\n";
	if ($country ne '') { $xwi->robot_add('country', $country); }
	else  { $xwi->robot_add('country', 'NotKnown'); }
   }

#Language of content
    my $text;
    if (defined($xwi->text)) { $text = substr(${$xwi->text},0,5000); } else { return; }
    require Lingua::Identify;
    if (length($text)<1000) {$text .= ' ' . $xwi->title;}
    my $lang = Lingua::Identify::langof($text); # gives the most probable language
    if ($lang ne '') { $xwi->robot_add('language', $lang); }

##Plugin for more analysis
  my $analysePlugin = Combine::Config::Get('analysePlugin');
  if (defined($analysePlugin) && $analysePlugin ne '') {
    eval "require $analysePlugin";
    $analysePlugin->analyse($xwi);
  }
}

########################################
sub init_stoplist {
    $stoplist = new Combine::LoadTermList;
    my $configDir = Combine::Config::Get('configDir');
    $stoplist->LoadStopWordList("$configDir/stopwords.txt");
}

#################################

#########################################################
# GETtext given a XMI								    								#
#########################################################
sub getTextXWI {
  my ( $xwi, $DoStem, $stopwords ) = @_;
  
  if ( ref($stopwords) eq 'Combine::LoadTermList' ) { }
  elsif ( ref($stoplist) eq 'Combine::LoadTermList' ) { $stopwords = $stoplist; }
  else { init_stoplist(); $stopwords=$stoplist; }

  my $urlpath ="";
  my $title="No Title";
  my $meta=""; my $head=""; my $text="";

  $urlpath = $xwi->urlpath;
  $urlpath =~ s/^\///;
  $urlpath =~ s/\// /g;

  $xwi->meta_rewind;
  my ($name,$content);
  while (1) {
    ($name,$content) = $xwi->meta_get;
    last unless $name;
    next if ($name eq 'Rsummary');
    next if ($name =~ /^autoclass/);
    $meta .= $content . " ";
  } 

  $title = $xwi->title;
  
  $xwi->heading_rewind;
  my $this;
  while (1) {
    $this = $xwi->heading_get or last; 
    $head .= $this . " "; 
  }

  $this = $xwi->text;
  if ($this) {
    $this = $$this;
    $text = $this ;
  }

    if ( defined($meta)  && ($meta ne '') )  { $meta = SimpletextConv($meta,  $DoStem, $stopwords); }
    if ( defined($head)  && ($head ne '') )  { $head = SimpletextConv($head,  $DoStem, $stopwords); }
    if ( defined($text)  && ($text ne '') )  { $text = SimpletextConv($text,  $DoStem, $stopwords); }
    if ( defined($urlpath) && ($urlpath ne '') ) { $urlpath =  SimpletextConv($urlpath,   $DoStem, $stopwords); }
    if ( defined($title) && ($title ne '') ) { $title = SimpletextConv($title, $DoStem, $stopwords); }

  return ($meta, $head, $text, $urlpath, $title);
}

########################
sub SimpletextConv {
  my ($txt, $DoStem, $stopwords) = @_;

#remove unwanted characters, pure numbers, and lowercase everything
  $txt =~ tr/0-9a-zA-ZÅÄÖåäöøæØÆ\/\'-/ /c; #Keep ' - /
  $txt =~ s/\b\d+\b/ /g;
  $txt =~ tr/A-ZÅÄÖØÆ/a-zåäöøæ/;

  my @text = map { 
       if ( exists ${$stopwords->{StopWord}}{$_} ) { (); } else { $_; }
       } split(/\s+/,$txt);

#  if ( $DoStem ) { $stext = Lingua::Stem::stem(@text); }
  return join(' ', @text);
}

#########################################################
# SVM												    												#
#########################################################
#Given a SVM (prepared or not), the term list used in
#the svm, the file of the trained svm and the text to
#analyce, it returns the score
sub SVM {
  require Algorithm::SVMLight;

	my ( $SVMtrainingFile, @text ) = @_;

	if ( !defined($svm) ) {
		($svm) = CreateSVM($SVMtrainingFile);
	}
	if ( !defined(%term_set) ) {
		(%term_set) = CreateTermSet($svm);
	}
	my %set;
	foreach my $term (@text) {
		if ( ( ( exists $term_set{$term} ) && ( !( exists $set{$term} ) ) ) )
		{    #
			$set{$term} = 1;
		}
	}

	#use the svm function
	my %test;
	$test{attributes} = {%set};
	my $result = $svm->predict(%test);
	return ($result);
}

sub CreateTermSet {
	my ($svm) = @_;
#	print "Creating term list\n";
	my @terms = $svm->feature_names();
	chomp(@terms);
	my %term_set = map { $_, 1 } @terms;
	delete $term_set{""};
#	print "End creation list\n";
	return (%term_set);
}

sub CreateSVM {
	my ($SVMtrainingFile) = @_;
	#print "----------------------------------------------->Loading SVM... $SVMtrainingFile\n";
	my $svm = Algorithm::SVMLight->new();
	$svm->read_model($SVMtrainingFile);
	#print "End loading SVM\n";
	return ($svm);
}

1;


__END__

=head1 NAME

utilPlugIn

=head1 DESCRIPTION

Utilities for:
 * extracting text from XWI's
 * SVM classification
 * language and country identification

=head1 AUTHOR

Ignacio Garcia Dorado
Anders Ardö <anders.ardo@eit.lth.se>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Ignacio Garcia Dorado, Anders Ardö

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

See the file LICENCE included in the distribution at
 L<http://combine.it.lth.se/>

=cut
