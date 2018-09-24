package Text::CSV::Base;

################################################################################
# HISTORY
#
# Written by:
#    Alan Citterman <alan@mfgrtl.com>
#
# Version 0.01  06/05/1997
#    original version
#
# Maintained (as Text::CSV::Base) by:
#    Robin Barker <rmbarker@cpan.org>
#
# Version 0.01  2007-12-30
#    converted to Text::CSV::Base
#	% perl -pwe 's/Text::CSV/Text::CSV::Base/ && s/ {6}\#/\#/' \ 
#		../Text-CSV-0.01/CSV.pm  > lib/Text/CSV/Base.pm
#
# Version 0.02  2007-12-31
#    correct POD; update BEGIN {}
#
# Version 0.03  2008-01-01
#    make ->version an inheritable package method
#    remove AutoLoader
#    use _CHAROK in combine
#    
# Version 0.10	2018-09-21
#     Thin wrapper around Text::CSV
################################################################################

use strict;
use warnings;
use base qw(Text::CSV);

our $VERSION = '0.10';

sub new { 
    my($self, $hash) = @_;
    return $self->SUPER::new( { always_quote => 1, %{ $hash || {} } } );
}

1;

__END__

=head1 NAME

Text::CSV::Base - comma-separated values manipulation routines

=head1 SYNOPSIS

 use Text::CSV::Base;

 $csv = Text::CSV::Base->new();        # create a new object

=head1 DESCRIPTION

The same functionality as Text::CSV but set C<always_quote => 1>.

This module exists to support Text::CSV::Unicode, 
which assumes C<always_quote => 1> in its functionality.

=head1 FUNCTIONS

=over 4

=item new

 $csv = Text::CSV::Base->new();

This function may be called as a class or an object method.  It returns a reference to a
newly created Text::CSV::Base object.

=back

=head1 AUTHOR

Robin M Barker <rmbarker@cpan.org>

=head1 SEE ALSO

perl(1)
Text::CSV

=cut
