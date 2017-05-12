#===============================================================================
#
#  DESCRIPTION:  Make XML 
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id: Writer.pm 845 2010-10-13 08:11:10Z zag $

package XML::ExtOn::Writer;
use strict;
use warnings;
use XML::SAX::Writer;
use base 'XML::SAX::Writer';

sub new  {
    my $self = shift;
    my $opt   = (@_ == 1)  ? { %{shift()} } : {@_};
    $opt->{Escape} = {};
    return $self->SUPER::new($opt);
}

1;


