package WebService::Backlog::Priority;

# $Id: Priority.pm 560 2007-11-05 07:15:10Z yamamoto $

use strict; 
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/id name/);

1;
__END__
