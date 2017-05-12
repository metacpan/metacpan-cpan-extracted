package Devel::AssertOS::BeOS;

use Devel::CheckOS;

$VERSION = '1.4';

# weird special case, not quite like other OS modules, as this is both
# an OS *and* a family - maybe this should be fixed at some point
sub matches { return qw(Haiku) }
sub os_is {
    return 1 if(
        $^O =~ /^beos$/i ||
        Devel::CheckOS::os_is('Haiku')
    );
    return 0;
}

sub expn {
join("\n",
"This matches both Be Inc's original BeOS, as well as Haiku, an open-",
"source BeOS-compatible project.  This is because Haiku is intended",
"to be able to run BeOS software, while also having its own extra features."
)
}

Devel::CheckOS::die_unsupported() unless(os_is());

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2014 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
