
package ZOOM::IRSpy::Web;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy;
our @ISA = qw(ZOOM::IRSpy);

use ZOOM::IRSpy::Utils qw(xml_encode);


=head1 NAME

ZOOM::IRSpy::Web - subclass of ZOOM::IRSpy for use by Web UI

=head1 DESCRIPTION

This behaves exactly the same as the base C<ZOOM::IRSpy> class except
that the Clog()> method does not call YAZ log, but outputs
HTML-formatted messages on standard output.  The additional function
log_init_level() controls what log-levels are to be included in the
output.  Note that this arrangement only allows IRSpy-specific logging
to be generated, not underlying ZOOM logging.

=cut

sub log_init_level {
    my $this = shift();
    my($level) = @_;

    my $old = $this->{log_level};
    $this->{log_level} = $level if defined $level;
    return $old;
}

sub log {
    my $this = shift();
    my($level, @s) = @_;

    $this->{log_level} = "irspy" if !defined $this->{log_level};
    return if index(("," . $this->{log_level} . ","), ",$level,") < 0;

    my $message = "[$level] " . join("", @s);
    $| = 1;			# 
    print xml_encode($message), "<br/>\n";

    ### This is naughty -- it knows about HTML::Mason
    $HTML::Mason::Commands::m->flush_buffer();
}


=head1 SEE ALSO

ZOOM::IRSpy

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
