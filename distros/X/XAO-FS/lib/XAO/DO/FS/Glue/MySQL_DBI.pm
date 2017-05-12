=head1 NAME

XAO::DO::FS::Glue::MySQL_DBI - DBD::mysql driver for XAO::FS

=head1 SYNOPSIS

Should not be used directly.

=head1 DESCRIPTION

The module uses DBD/DBI interface; whenever possible it is recommended
to use direct MySQL module that works directly with database without
DBD/DBI layer in between.

This is the lowest level XAO::FS knows about.

See L<XAO::DO::FS::Glue::Base_DBI> and 
L<XAO::DO::FS::Glue::Base_MySQL> for method details.

=cut

###############################################################################
package XAO::DO::FS::Glue::MySQL_DBI;
use strict;
use Error qw(:try);
use XAO::Utils qw(:debug :args :keys);
use XAO::Objects;

use base XAO::Objects->load(objname => 'FS::Glue::Base_MySQL');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: MySQL_DBI.pm,v 2.12 2007/05/09 21:03:09 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

sub connector_create ($) {
    return XAO::Objects->new(objname => 'FS::Glue::Connect_DBI');
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Glue::SQL_DBI>,
L<XAO::DO::FS::Glue>.

=cut
