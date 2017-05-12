use perfSONAR_PS::Error;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Error::MA - A module that provides the exceptions framework for perfSONAR PS

=head1 DESCRIPTION

This module provides the message exception types that will be presented.

head1 API

=cut

=head2 perfSONAR_PS::Error::Topology

Base error for topology from which all topology exceptions derive.

=cut
package perfSONAR_PS::Error::Topology;
use base "perfSONAR_PS::Error";


=head2 perfSONAR_PS::Error::Topology::InvalidParameter

invalid parameter error

=cut
package perfSONAR_PS::Error::Topology::InvalidParameter;
use base "perfSONAR_PS::Error::Topology";

=head2 perfSONAR_PS::Error::Topology

dependency error

=cut
package perfSONAR_PS::Error::Topology::Dependency;
use base "perfSONAR_PS::Error::Topology";

=head2 perfSONAR_PS::Error::Topology

invalid topology error

=cut
package perfSONAR_PS::Error::Topology::InvalidTopology;
use base "perfSONAR_PS::Error::Topology";


# YTL: i think these should return the common::storage errors
#package perfSONAR_PS::Error::Topology::MA;
#use base "perfSONAR_PS::Error::Topology";

# YTL: i reckon these should return teh common:query errors
#package perfSONAR_PS::Error::Topology::Query;
#use base "perfSONAR_PS::Error::Topology";

#package perfSONAR_PS::Error::Topology::Query::QueryNotFound;
#use base "perfSONAR_PS::Error::Topology::Query";

#package perfSONAR_PS::Error::Topology::Query::TopologyNotFound;
#use base "perfSONAR_PS::Error::Topology::Query";

#package perfSONAR_PS::Error::Topology::Query::InvalidKnowledgeLevel;
#use base "perfSONAR_PS::Error::Topology::Query";

1;



=head1 SEE ALSO

L<Exporter>, L<Error::Simple>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id$

=head1 AUTHOR

Yee-Ting Li <ytl@slac.stanford.edu>

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
