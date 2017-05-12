package Throwable::SugarFactory::Utils;

use strictures 2;
use parent 'Exporter';

our $VERSION = '0.152700'; # VERSION

# ABSTRACT: provide utility functions for Throwable::SugarFactory and friends

#
# This file is part of Throwable-SugarFactory
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

our @EXPORT_OK = qw( _getglob );

## no critic (ProhibitNoStrict)
sub _getglob { no strict 'refs'; \*{ join '::', @_ } }
## use critic

1;

__END__

=pod

=head1 NAME

Throwable::SugarFactory::Utils - provide utility functions for Throwable::SugarFactory and friends

=head1 VERSION

version 0.152700

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
