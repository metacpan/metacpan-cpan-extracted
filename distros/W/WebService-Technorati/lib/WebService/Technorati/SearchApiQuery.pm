package WebService::Technorati::SearchApiQuery;
use strict;
use utf8;

use WebService::Technorati::ApiQuery;
use WebService::Technorati::SearchTerm;
use WebService::Technorati::SearchMatch;
use WebService::Technorati::Exception;
use base 'WebService::Technorati::ApiQuery';

use constant API_URI => '/cosmos';

BEGIN {
    use vars qw ($VERSION $DEBUG);
    $VERSION    = 0.04;
    $DEBUG       = 0;
}

sub new {
    my ($class, %params) = @_;
    if (! exists $params{'key'}) {
        WebService::Technorati::InstantiationException->throw(
            "WebService::Technorati::SearchApiQuery must be " .
            "instantiated with at least 'key => theverylongkeystring'"); 
    }
    my $data = {};
    if (! exists $params{'url'}) {
        $data->{'needs_url'}++;
    }
    for my $k (keys %params) {
         $data->{'args'}{$k} = $params{$k};
    }
    my $self = bless ($data, ref ($class) || $class);
    return $self;
}

sub url {
    my $self = shift;
    my $url = shift;
    if ($url) {
        $self->{'url'} = $url;
        delete($self->{'needs_url'});
    }
    return $self->{'url'};
}

sub execute {
    my $self = shift;
    my $apiUrl = $self->apiHostUrl() . API_URI;
    if (exists $self->{'needs_url'}) {
        WebService::Technorati::StateValidationException->throw(
            "WebService::Technorati::AuthorinfoApiQuery must have a " .
            "'url' attribute set prior to query execution");
    }
    $self->SUPER::execute($apiUrl,$self->{'args'});
}

sub readResults {
    my $self = shift;
    my $result_xp = shift;
    my $error = $result_xp->find('/tapi/document/result/error');
    if ($error) {
        WebService::Technorati::DataException->throw($error);
    }
    my $nodeset = $result_xp->find("/tapi/document/result");
    my $node = $nodeset->shift;
    my $searchTerm = WebService::Technorati::SearchTerm->new_from_node($node);
    
    $nodeset = $result_xp->find('/tapi/document/item');
    my @matches = ();
    for my $node ($nodeset->get_nodelist) {
        my $match = WebService::Technorati::SearchMatch->new_from_node($node);
        push(@matches, $match);
    }
    $self->{'subject'} = $searchTerm;
    $self->{'matches'} = \@matches;

}


=head2 getSubjectSearchTerm

 Usage     : getSubjectSearchTerm();
 Purpose   : 
 Returns   : a scalar WebService::Technorati::SearchTerm instance
 Argument  : none
 Throws    : none
 Comments  : call this to retrieve the search invocation metadata
See Also   : WebService::Technorati

=cut

sub getSubjectSearchTerm {
    my $self = shift;
    return $self->{'subject'};
}


=head2 getClaimedBlogs

 Usage     : getClaimedBlogs();
 Purpose   : 
 Returns   : an array of WebService::Technorati::SearchMatch instances
 Argument  : none
 Throws    : none
 Comments  : the search matches are returned with what Technorati
             knows about them
See Also   : WebService::Technorati

=cut

sub getSearchMatches {
    my $self = shift;
    return (wantarray) ? @{$self->{'matches'}} : $self->{'matches'};
}

1;
