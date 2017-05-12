## $Id: classifySVM.pm 266 2008-09-05 12:33:52Z anders $

# See the file LICENCE included in the distribution.
# Ignacio Garcia Dorado 2008, and Anders Ardö 2008
# SVM classifier for Focused Crawler

package Combine::classifySVM;

use Combine::XWI;       #Mandatory
use Combine::Config;    #to use the Combine configuration system
use Combine::MySQLhdb;
use Combine::utilPlugIn;    #the utils for plugIns
use strict;

#API:
#  a subroutine named 'classify' taking a XWI-object as in parameter
#    In this subroutine the current page is used to create a score
#    return 1 because it is also saved

sub classify {

	my ( $self, $xwi ) = @_;
	my ($SVMtrainingFile) = Combine::Config::Get('SVMmodel');
        my $configDir = Combine::Config::Get('configDir');
        $SVMtrainingFile = "$configDir/$SVMtrainingFile";
        my $log = Combine::Config::Get('LogHandle');
	my ($meta, $head, $text, $url, $title) = Combine::utilPlugIn::getTextXWI($xwi, 0, ''); #No stemming, Stopword list not intialized
        my @text = split(/\s+/,  $title . ' ' . $meta . ' ' . $head . ' ' . $text ); #use URL aswell?

#language
#	Combine::utilPlugIn::setLanguage($xwi);

	my ($result) =
	  Combine::utilPlugIn::SVM( $SVMtrainingFile, @text );
	# print "SVM result: $result\n";
	$xwi->topic_add( 'ALL', $result * 1000000, ($result) * 1000000, '', 'svm' );
        my $url=$xwi->url;
        $log->say("classifySVM $result $url");
	if ($result>0.0) { return 1; } else { return 0; }
}

#API:
#  a subroutine named 'scoreLink' taking a XWI-object and all the link information as in-parameters
#    This subroutine is called for each out-link. With the XWI (current page) and the link information, 
#    the link is scored and saved to be used as rank.
sub scoreLink {
	#skip if the link is not available
	my ( $self, $xwi, $urlid, $urlstr, $anchor, $linktype ) = @_;
	if ( ( !defined($urlid) ) || ( $urlid == 0 ) ) {
		return ();
	}

	# just process english web-pages
	if ( Combine::utilPlugIn::getLanguage($xwi) eq 'en' ) {
		my $sv = Combine::Config::Get('MySQLhandle');	
		
		# we need the score of the currante page
		my ($svmScore) = Combine::utilPlugIn::getScoreTopic( $xwi, "svm" );

		# skip if it has not score
		if ( defined($svmScore) ) {
			my ($BEFOREscore) = Combine::utilPlugIn::getScore( $sv, $urlid );
			
			# check if it has score, if it has, average them
			if ( defined($BEFOREscore) ) {
				my $finalScore = $svmScore + $BEFOREscore;
				$finalScore /= 2.0;
				
				# do not update if the new score is lower
				return () if ($finalScore <= $BEFOREscore);
				
				Combine::utilPlugIn::setUpdateScore( "update", $finalScore,
					$urlid, $sv, "svm:$urlstr" );
			}
			else {
				Combine::utilPlugIn::setUpdateScore( "set", $svmScore, $urlid,
					$sv, "svm:$urlstr" );
			}
		}
		else {
			##we don't have the score of the currant page
		}
	}
	else {
		#we don't use the links of non-english pages
	}
}
1;

__END__

=head1 NAME

classifySVM

=head1 DESCRIPTION

Classification plugin module using SVM (implementation SVMLight)

Uses SVM model loaded from file pointed to by configuration variable 'SVMmodel'

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
