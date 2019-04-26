# XML::Axk - top-level module for XML::Axk distribution.
# This holds the main version, but doesn't do anything else at the moment.
package XML::Axk;
use strict;
use warnings;
use XML::Axk::Base;

our $VERSION = '0.001009';
our $AUTHORITY = 'cpan:CXW';

1;
# Docs {{{1
__END__

=head1 NAME

XML::Axk - tools for processing XML files with an awk-like model

=head1 SYNOPSIS

See L<XML::Axk::App> for command-line usage and L<XML::Axk::Core> for
embedded usage in other Perl scripts.

=cut

# }}}1
# vi: set fdm=marker: #
