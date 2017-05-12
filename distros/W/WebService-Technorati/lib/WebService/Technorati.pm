
package WebService::Technorati;
use strict;
use utf8;

use WebService::Technorati::SearchApiQuery;
use WebService::Technorati::CosmosApiQuery;
use WebService::Technorati::OutboundApiQuery;
use WebService::Technorati::AuthorinfoApiQuery;
use WebService::Technorati::BloginfoApiQuery;

BEGIN {
    use vars qw ($VERSION);
    $VERSION    = 0.04;
}

# $Id: Technorati.pm,v 1.4 2004/12/30 23:10:47 ikallen Exp $ 

########################################### main pod documentation begin ##

=head1 NAME

WebService::Technorati - a Perl interface to the Technorati web services interface

=head1 SYNOPSIS

  use WebService::Technorati;

  my $apiKey = 'myverylongstringofcharacters';
  my $url = 'http://www.arachna.com/roller/page/spidaman';
  my $t = WebService::Technorati->new(key => $apiKey);
  my $q = $t->getCosmosApiQuery($url);
  $q->execute;
  
  my $linkedUrl = $q->getLinkQuerySubject();
  # do something with the linkedUrl
  
  my $links = $q->getInboundLinks();
  for my $link (@$links) {
      # do something with the link
  }

=head1 DESCRIPTION

The Technorati web services interfaces use REST wire protocol with a format
described at http://developers.technorati.com/

=head1 USAGE

Please see the test files in t/ and samples in eg/ for examples on how to use 
WebServices::Technorati

=head1 BUGS

No bugs currently open

=head1 SUPPORT

Join the Technorati developers mailing list at
http://mail.technorati.com/mailman/listinfo/developers

=head1 AUTHOR

    Ian Kallen
    ikallen _at_ technorati.com
    http://developers.technorati.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the terms of the following 
Creative Commons License:
http://creativecommons.org/licenses/by/2.0
as well as the indemnification provisions of the 
Apache 2.0 style license, the full text of which can be 
found in the LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 getCosmosApiQuery

 Usage     : getCosmosApiQuery('http://developers.technorati.com')
 Purpose   : Instantiates a CosmosApiQuery with the given url
 Returns   : WebService::Technorati::CosmosApiQuery
 Argument  : a URL
 Throws    : WebService::Technorati::InstantiationException when called 
           : without an api key
 Comments  : WebService::Technorati::CosmosApiQuery is a Perl interface to the Technorati
           : web services 'cosmos' interface 

See Also   : WebService::Technorati::CosmosApiQuery

=cut

sub getCosmosApiQuery {
    my $self = shift;
    my $url = shift;
    my $q = WebService::Technorati::CosmosApiQuery->new(key => $self->{'key'}, url => $url);
    return $q;
}

=head2 getSearchApiQuery

 Usage     : getSearchApiQuery('keyword')
 Purpose   : Instantiates a SearchApiQuery with the given keyword
 Returns   : a WebService::Technorati::SearchApiQuery that may be executed
 Argument  : a keyword search term
 Throws    : WebService::Technorati::InstantiationException when called 
           : without an api key
 Comments  : WebService::Technorati::SearchApiQuery is a Perl interface to the Technorati
           : web services 'search' interface 

See Also   : WebService::Technorati::SearchApiQuery

=cut

sub getSearchApiQuery {
    my $self = shift;
    my $keyword = shift;
    my $q = WebService::Technorati::SearchApiQuery->new(key => $self->{'key'}, url => $keyword);
    return $q;
}


=head2 getOutboundApiQuery

 Usage     : getOutboundApiQuery('http://developers.technorati.com')
 Purpose   : Instantiates a OutboundApiQuery with the given url
 Returns   : WebService::Technorati::OutboundApiQuery
 Argument  : a url
 Throws    : WebService::Technorati::InstantiationException when called 
           : without an api key
 Comments  : WebService::Technorati::OutboundApiQuery is a Perl interface to the Technorati
           : web services 'outbound' interface 

See Also   : WebService::Technorati::OutboundApiQuery

=cut

sub getOutboundApiQuery {
    my $self = shift;
    my $url = shift;
    my $q = WebService::Technorati::OutboundApiQuery->new(key => $self->{'key'}, url => $url);
    return $q;
}


=head2 getAuthorinfoApiQuery

 Usage     : getAuthorinfoApiQuery('username')
 Purpose   : Instantiates a AuthorinfoApiQuery with the given username
 Returns   : WebService::Technorati::AuthorinfoApiQuery
 Argument  : a url
 Throws    : WebService::Technorati::InstantiationException when called 
           : without an api key
 Comments  : WebService::Technorati::AuthorinfoApiQuery is a Perl interface to the Technorati
           : web services 'getinfo' interface 

See Also   : WebService::Technorati::AuthorinfoApiQuery

=cut

sub getAuthorinfoApiQuery {
    my $self = shift;
    my $url = shift;
    my $q = WebService::Technorati::AuthorinfoApiQuery->new(key => $self->{'key'}, url => $url);
    return $q;
}


=head2 getBloginfoApiQuery

 Usage     : getBloginfoApiQuery('http://developers.technorati.com')
 Purpose   : Instantiates a BloginfoApiQuery with the given url
 Returns   : WebService::Technorati::BloginfoApiQuery
 Argument  : a url
 Throws    : WebService::Technorati::InstantiationException when called 
           : without an api key
 Comments  : WebService::Technorati::BloginfoApiQuery is a Perl interface to the Technorati
           : web services 'bloginfo' interface 

See Also   : WebService::Technorati::BloginfoApiQuery

=cut

sub getBloginfoApiQuery {
    my $self = shift;
    my $url = shift;
    my $q = WebService::Technorati::BloginfoApiQuery->new(key => $self->{'key'}, url => $url);
    return $q;
}



################################################## subroutine header end ##


sub new {
    my ($class, %params) = @_;
    if (! exists $params{'key'}) {
        WebService::Technorati::InstantiationException->throw(
            "WebService::Technorati must be instantiated with at " .
            "least 'key => theverylongkeystring'"); 
    }
    my $self = bless (\%params, ref ($class) || $class);
    return $self;
}


1; #this line is important and will help the module return a true value
__END__

