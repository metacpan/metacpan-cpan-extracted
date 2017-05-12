package WebService::Technorati::LinkQuerySubject;
use strict;
use utf8;

use fields qw(blog rankingstart);

use WebService::Technorati::Blog;

use WebService::Technorati::BaseTechnoratiObject;
use base 'WebService::Technorati::BaseTechnoratiObject';


BEGIN {
    use vars qw ($VERSION $DEBUG);
    $VERSION    = 0.04;
    $DEBUG       = 0;
}

=head2 getBlog

 Usage     : getBlog();
 Purpose   : 
 Returns   : a scalar WebService::Technorati::Blog
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setBlog

 Usage     : setBlog(blog);
 Purpose   : 
 Returns   : void
 Argument  : a scalar WebService::Technorati::Blog
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


{
    my %_attrs = (
        blog => undef,
        inboundlinks => undef,
        inboundblogs => undef,
        url => undef,
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
    my $blog_node = $node->find('weblog')->pop;
    my $data = {
        rankingstart => $node->findvalue('rankingstart')->string_value,
        inboundlinks => $node->findvalue('inboundlinks')->string_value,
        inboundblogs => $node->findvalue('inboundblogs')->string_value,
        url => $node->findvalue('url')->string_value
    };
    if ($blog_node) {
        $data->{'blog'} = WebService::Technorati::Blog->new_from_node($blog_node);
    }
    my $self = bless ($data, ref ($class) || $class);
    return $self;
}

1;
