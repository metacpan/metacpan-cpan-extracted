#!/usr/bin/perl


#####################################################################
#####################################################################
package testWikiGatewayDuringInstall;
use base qw(Test::Unit::TestCase);
#####################################################################
#####################################################################

use Wiki::Gateway;
use LWP::Simple;

sub set_up {
    my $self = shift;

    $self->{TESTWIKI_URL} ='http://interwiki.sourceforge.net/cgi-bin/wiki.pl';
    $self->{TESTWIKI_TYPE} ='usemod1';
    
    $self->{TESTPAGE_NAME} ='InterWikiSoftware';  
    $self->{TESTPAGE_URL} ='http://interwiki.sourceforge.net/cgi-bin/wiki.pl?InterWikiSoftware';  
    $self->{TESTPAGE_SOURCE_TEXT_TO_MATCH} ='SourceForge';
    $self->{TESTPAGE_RENDERED_TEXT_TO_MATCH} ='SourceForge';
	 
    $self->{TESTPAGE_RENDERED_TEXT_TO_MATCH_QUOTED} = quotemeta($self->{TESTPAGE_RENDERED_TEXT_TO_MATCH});
}



sub readTestPage {
    my $self = shift;
    print "reading $self->{TESTPAGE_NAME}\n";
    
    my $result = Wiki::Gateway::getPage($self->{TESTWIKI_URL}, $self->{TESTWIKI_TYPE}, $self->{TESTPAGE_NAME});
    return $result;
}



sub getLink {
    my $self = shift;

    return $self->{TESTPAGE_URL}; 
}




##################################
##################################
##################################
##################################

sub test_read {
    my $self = shift;
    print "\n--- test_read --\n";

    $res = $self->readTestPage();
    print $res."\n";
    
    print "\n";

	$self->assert ($res =~  /$self->{TESTPAGE_SOURCE_TEXT_TO_MATCH}/);
}

sub test_getLinkAndView {
    my $self = shift;

    my $link;

    print "\n--- test_getLinkAndView --\n";

    $link = $self->getLink();

    print "Going to get link: $link\n";

    $webPage = get($link);
    print "Page:\n---$webPage\n---\n\n";
    
    print "\n";
		 

    print STDERR "(about to assert (\$webPage =~  /$self->{TESTPAGE_RENDERED_TEXT_TO_MATCH_QUOTED})...";
    $self->assert ($webPage =~  /$self->{TESTPAGE_RENDERED_TEXT_TO_MATCH_QUOTED}/);
    print "succeeded\n";
    


}



1;

