package MyNote;
use strict;
use warnings;
require Exporter;
require UUID;
use vars qw(@EXPORT);

@EXPORT = qw(note);

sub import {
    goto &Exporter::import;
}

my $realnode = UUID::_realnode();
substr $realnode, 0, 24, '' if $realnode;

# Yes, this clobbers Test::More::note,
# which is somewhat broken on Win32.
sub note {
    my $work = join '', map { defined($_) ? $_ : '<UNDEF>' } @_;
    chomp $work;

    # hide the real node anywhere it appears.
    $work =~ s/$realnode/XXXXXXXXXXXX/ig
        if $realnode;

    print '# ', $work, "\n";
}

1;
