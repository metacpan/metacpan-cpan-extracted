package WebService::Technorati::AuthorinfoApiQuery;
use strict;
use utf8;

use WebService::Technorati::ApiQuery;
use WebService::Technorati::Author;
use WebService::Technorati::Blog;
use WebService::Technorati::Exception;
use base 'WebService::Technorati::ApiQuery';

use constant API_URI => '/getinfo';

BEGIN {
    use vars qw ($VERSION $DEBUG);
    $VERSION    = 0.04;
    $DEBUG       = 0;
}

sub new {
    my ($class, %params) = @_;
    if (! exists $params{'key'}) {
        WebService::Technorati::InstantiationException->throw(
            "WebService::Technorati::AuthorinfoApiQuery must be " .
            "instantiated with at least 'key => theverylongkeystring'");
    }
    my $data = {};
    if (! exists $params{'username'}) {
        $data->{'needs_username'}++;
    }
    for my $k (keys %params) {
        $data->{'args'}{$k} = $params{$k};
    }
    my $self = bless ($data, ref ($class) || $class);
    return $self;
}

sub username {
    my $self = shift;
    my $username = shift;
    if ($username) {
        $self->{'username'} = $username;
        delete($self->{'needs_username'});
    }
    return $self->{'username'};
}

sub execute {
    my $self = shift;
    my $apiUrl = $self->apiHostUrl() . API_URI;
    if (exists $self->{'needs_username'}) {
        WebService::Technorati::StateValidationException->throw(
            "WebService::Technorati::AuthorinfoApiQuery must have a " .
            "'username' attribute set prior to query execution");
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
    my $authorSubject = WebService::Technorati::Author->new_from_node($node);
    
    $nodeset = $result_xp->find('/tapi/document/item/weblog');
    my @blogs = ();
    for my $node ($nodeset->get_nodelist) {
        my $blog = WebService::Technorati::Blog->new_from_node($node);
        push(@blogs, $blog);
    }
    $self->{'subject'} = $authorSubject;
    $self->{'blogs'} = \@blogs;

}


=head2 getSubjectAuthor

 Usage     : getSubjectAuthor();
 Purpose   : 
 Returns   : a scalar WebService::Technorati::Author instance
 Argument  : none
 Throws    : none
 Comments  : the member entity (author or not) is returned with what 
             Technorati knows about it
See Also   : WebService::Technorati

=cut

sub getSubjectAuthor {
    my $self = shift;
    return $self->{'subject'};
}


=head2 getClaimedBlogs

 Usage     : getClaimedBlogs();
 Purpose   : 
 Returns   : an array of WebService::Technorati::Blog instances
 Argument  : none
 Throws    : none
 Comments  : the claimed blogs are returned with what Technorati
             knows about them
See Also   : WebService::Technorati

=cut

sub getClaimedBlogs {
    my $self = shift;
    return (wantarray) ? @{$self->{'blogs'}} : $self->{'blogs'};
}

1;
