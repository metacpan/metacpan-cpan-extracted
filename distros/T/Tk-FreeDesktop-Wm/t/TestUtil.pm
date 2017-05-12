# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2015 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
#

package TestUtil;
use strict;

=head2 tk_sleep

=for category Tk

    $top->tk_sleep($s);

Sleep $s seconds (fractions are allowed). Use this method in Tk
programs rather than the blocking sleep function. The difference to
$top->after($s/1000) is that update events are still allowed in the
sleeping time.

=cut

sub Tk::Widget::tk_sleep {
    my($top, $s) = @_;
    my $sleep_dummy = 0;
    $top->after($s*1000,
                sub { $sleep_dummy++ });
    $top->waitVariable(\$sleep_dummy)
	unless $sleep_dummy;
}

1;

__END__
