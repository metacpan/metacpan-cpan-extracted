package WebService::Technorati::Author;
use strict;
use utf8;

use fields qw(firstname lastname username thumbnailpicture);

use WebService::Technorati::BaseTechnoratiObject;
use base 'WebService::Technorati::BaseTechnoratiObject';


BEGIN {
    use vars qw ($VERSION $DEBUG);
    $VERSION    = 0.04;
    $DEBUG       = 0;
}

=head2 getFirstname

 Usage     : getFirstname();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 setFirstname

 Usage     : setFirstname(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getLastname

 Usage     : getLastname();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 setLastname

 Usage     : setLastname(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getUsername

 Usage     : getUsername();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 setUsername

 Usage     : setUsername(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut


=head2 getThumbnailpicture

 Usage     : getThumbnailpicture();
 Purpose   : 
 Returns   : a scalar string
 Argument  : none
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

=head2 setThumbnailpicture

 Usage     : setThumbnailpicture(string);
 Purpose   : 
 Returns   : void
 Argument  : a scalar string
 Throws    : none
 Comments  : 
See Also   : WebService::Technorati

=cut

{
    my %_attrs = (
        firstname => undef,
        lastname => undef,
        username => undef,
        thumbnailpicture => undef
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
        firstname => $node->findvalue('firstname')->string_value(),
        lastname => $node->findvalue('lastname')->string_value(),
        username => $node->findvalue('username')->string_value(),
        thumbnailpicture => $node->findvalue('thumbnailpicture')->string_value()
    };
    my $self = bless ($data, ref ($class) || $class);
    return $self;
}

1;

