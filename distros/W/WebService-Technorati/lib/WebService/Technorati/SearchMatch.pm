package WebService::Technorati::SearchMatch;
use strict;
use utf8;
use fields qw(blog created title excerpt);

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



=head2 getCreated

 Usage     : getCreated();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setCreated

 Usage     : setCreated(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getTitle

 Usage     : getTitle();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 setTitle

 Usage     : setTitle(string);
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



{
    my %_attrs = (
        blog => undef,
        created => undef,
        title => undef,
        excerpt => undef
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
        created => $node->findvalue('created')->string_value,
        excerpt => $node->findvalue('excerpt')->string_value(),
        title => $node->findvalue('title')->string_value(),
    };
    my $self = bless ($data, ref ($class) || $class);
    return $self;
}

1;
