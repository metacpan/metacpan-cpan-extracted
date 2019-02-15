# XML::Axk - top-level module for XML::Axk distribution.
# This holds the main version, but doesn't do anything else at the moment.
package XML::Axk;
use strict;
use warnings;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.001006';

#use parent 'Exporter';
#our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
#BEGIN {
#    @EXPORT = qw();
#    @EXPORT_OK = qw();
#    %EXPORT_TAGS = (
#        default => [@EXPORT],
#        all => [@EXPORT, @EXPORT_OK]
#    );
#}

# Docs {{{1

=head1 NAME

XML::Axk - tools for processing XML files with an awk-like model

=head1 SYNOPSIS

See L<XML::Axk::App> for command-line usage and L<XML::Axk::Core> for
embedded usage in other Perl scripts.

=cut

# }}}1

1;
__END__
# vi: set fdm=marker: #
