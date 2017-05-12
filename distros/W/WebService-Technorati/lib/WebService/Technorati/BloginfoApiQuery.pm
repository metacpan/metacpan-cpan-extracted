package WebService::Technorati::BloginfoApiQuery;
use strict;
use utf8;

use WebService::Technorati::ApiQuery;
use WebService::Technorati::BlogLink;
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
        "WebService::Technorati::BloginfoApiQuery must be " .
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
    my $nodeset = $result_xp->find("/tapi/document/result/weblog");
    my $node = $nodeset->shift;
    my $blog = WebService::Technorati::Blog->new_from_node($node);
    
    $self->{'blog'} = $blog;
}


=head2 getSubjectBlog

 Usage     : getSubjectBlog();
 Purpose   : 
 Returns   : a scalar WebService::Technorati::Blog instance
 Argument  : none
 Throws    : none
 Comments  : the URL subject (blog or not) is returned with what 
             Technorati knows about it
See Also   : WebService::Technorati

=cut

sub getSubjectBlog {
    my $self = shift;
    return $self->{'blog'};
}

1;
