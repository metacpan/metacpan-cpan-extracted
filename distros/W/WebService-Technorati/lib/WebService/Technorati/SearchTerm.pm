package WebService::Technorati::SearchTerm;
use strict;
use utf8;

use WebService::Technorati::BaseTechnoratiObject;
use base 'WebService::Technorati::BaseTechnoratiObject';

use fields qw(inboundblogs query querycount querytime rankingstart);


BEGIN {
    use vars qw ($VERSION $DEBUG);
    $VERSION    = 0.04;
    $DEBUG       = 0;
}

=head2 getInboundblogs

 Usage     : getInboundblogs();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setInboundblogs

 Usage     : setInboundblogs(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getQuery

 Usage     : getQuery();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setQuery

 Usage     : setQuery(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getQuerycount

 Usage     : getQuerycount();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setQuerycount

 Usage     : setQuerycount(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getQuerytime

 Usage     : getQuerytime();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setQuerytime

 Usage     : setQuerytime(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getRankingstart

 Usage     : getRankingstart();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setRankingstart

 Usage     : setRankingstart(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


use WebService::Technorati::Blog;

{
    my %_attrs = (
        inboundblogs => undef,
        query => undef,
        querycount => undef,
        querytime => undef,
        rankingstart => undef
    );
    sub _accessible {
        if ($DEBUG) {
            print __PACKAGE__ . ": checking for attr [$_[1]]\n";
        }
        return exists($_attrs{$_[1]});
    }
}

sub new_from_node {
    my $class = shift;
    my $node = shift;
    my $data = {
        inboundblogs => $node->findvalue('inboundblogs')->string_value(),
        query => $node->findvalue('query')->string_value(),
        querycount => $node->findvalue('querycount')->string_value(),
        querytime => $node->findvalue('querytime')->string_value(),
        rankingstart => $node->findvalue('rankingstart')->string_value(),
    };
    my $self = bless ($data, ref ($class) || $class);
    return $self;
}

1;

