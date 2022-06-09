#!perl
use warnings;
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

require YA::CLI::Example;
YA::CLI::Example->run();

__END__

=head1 DESCRIPTION

Example script that deals with subcommands

=head1 SYNOPSIS

example [<options>] [<action>] [<options>]

=head2 OPTIONS

=over

=item --global-option-one

Some global option

=item --global-option-two

=item --help, -h

The help page of the given action. Or this help in case you don't provide an
action.

=item --man, -m

The manual page of the given action.

=back
