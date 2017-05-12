package WebService::Technorati::BlogLink;
use strict;
use utf8;

use fields qw(blog nearestpermalink excerpt linkcreated linkurl);

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


=head2 getNearestpermalink

 Usage     : getNearestpermalink();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setNearestpermalink

 Usage     : setNearestpermalink(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut



=head2 getExcerpt

 Usage     : getExcerpt();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setExcerpt

 Usage     : setExcerpt(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut



=head2 getLinkcreated

 Usage     : getLinkcreated();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setLinkcreated

 Usage     : setLinkcreated(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getLinkurl

 Usage     : getLinkurl();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setLinkurl

 Usage     : setLinkurl(string);
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
        nearestpermalink => undef,
        excerpt => undef,
        linkcreated => undef,
        linkurl => undef
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
         blog => WebService::Technorati::Blog->new_from_node($blog_node),
         nearestpermalink => $node->findvalue('nearestpermalink')->string_value,
         excerpt => $node->findvalue('excerpt')->string_value(),
         linkcreated => $node->findvalue('linkcreated')->string_value(),
         linkurl => $node->findvalue('linkurl')->string_value()
     };
     my $self = bless ($data, ref ($class) || $class);
     return $self;
}

1;
