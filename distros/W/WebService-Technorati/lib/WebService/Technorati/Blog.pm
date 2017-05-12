package WebService::Technorati::Blog;
use strict;
use utf8;

use fields qw(url name rssurl atomurl inboundblogs inboundlinks lastupdate lat lon rank);

use WebService::Technorati::BaseTechnoratiObject;
use base 'WebService::Technorati::BaseTechnoratiObject';


BEGIN {
    use vars qw ($VERSION $DEBUG);
    $VERSION    = 0.04;
    $DEBUG       = 0;
}

=head2 getUrl

 Usage     : getUrl();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setUrl

 Usage     : setUrl(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 getName

 Usage     : getName();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setName

 Usage     : setName(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 getRssurl

 Usage     : getRssurl();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setRssurl

 Usage     : setRssurl(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 getAtomurl

 Usage     : getAtomurl();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setAtomurl

 Usage     : setAtomurl(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

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

=head2 getInboundlinks

 Usage     : getInboundlinks();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setInboundlinks

 Usage     : setInboundlinks(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 getLastupdate

 Usage     : getLastupdate();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setLastupdate

 Usage     : setLastupdate(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getLat

 Usage     : getLat();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setLat

 Usage     : setLat(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getLon

 Usage     : getLon();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setLon

 Usage     : setLon(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getRank

 Usage     : getRank();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setRank

 Usage     : setRank(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut




{
    my %_attrs = (
        url => undef,
        name => undef,
        rssurl => undef,
        atomurl => undef,
        inboundblogs => undef,
        inboundlinks => undef,
        lastupdate => undef,
        lat => undef,
        lon => undef,
        rank => undef
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
        url => $node->findvalue('url')->string_value(),
        name => $node->findvalue('name')->string_value(),
        rssurl => $node->findvalue('rssurl')->string_value(),
        atomurl => $node->findvalue('atomurl')->string_value(),
        inboundblogs => $node->findvalue('inboundblogs')->string_value(),
        inboundlinks => $node->findvalue('inboundlinks')->string_value(), 
        lastupdate => $node->findvalue('lastupdate')->string_value(),
        lat => $node->findvalue('lat')->string_value(),
        lon => $node->findvalue('lon')->string_value(),
        rank => $node->findvalue('rank')->string_value()
    };
    my $self = bless ($data, ref ($class) || $class);
    return $self;
}

1;

