# Bind8 CNAME record handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::DB::CNAME - Class represending CNAME records.

=head1 SYNOPSYS

Refer to the SYNOPSIS section for Unix::Conf::Bind8::DB::Record.

=head1 METHODS

Methods specified here are overridden. They might or not be differnt from
the derived ones. For other methods refer to the METHODS section for
Unix::Conf::Bind8::DB::Record.

=over 4

=cut

package Unix::Conf::Bind8::DB::CNAME;

use strict;
use warnings;

use Unix::Conf;
use Unix::Conf::Bind8::DB::Record;

our @ISA = qw (Unix::Conf::Bind8::DB::Record);

1;
__END__
