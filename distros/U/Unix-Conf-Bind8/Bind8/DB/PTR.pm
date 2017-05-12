# Bind8 PTR record handling
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>

=head1 NAME

Unix::Conf::Bind8::DB::A - Class representing A records.

=head1 SYNOPSIS

Refer to the SYNOPSIS section for Unix::Conf::Bind8::DB::Record.

=head1 METHODS

Methods specified here are overridden. They might or not be differnt from
the derived ones. For other methods refer to the METHODS section for
Unix::Conf::Bind8::DB::Record.

=over 4

=cut

package Unix::Conf::Bind8::DB::PTR;

use strict;
use warnings;

use Unix::Conf::Bind8::DB::Record;

our (@ISA) = qw (Unix::Conf::Bind8::DB::Record);


# Inherit completely from the base class. We have nothing to add here.
1;
