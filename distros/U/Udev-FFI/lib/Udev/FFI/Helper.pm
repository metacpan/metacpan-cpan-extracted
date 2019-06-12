package Udev::FFI::Helper;

use strict;
use warnings;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);

require Exporter;
@ISA = qw(Exporter);

use Udev::FFI::Functions qw(:all);


@EXPORT_OK = qw(get_entries_all);



sub get_entries_all {
    my $entry = shift;

    if (defined($entry)) {
        if (wantarray) {
            my @a = ();

            do {
                push @a, udev_list_entry_get_name($entry);
                $entry = udev_list_entry_get_next($entry);
            } while (defined($entry));

            return @a;
        }


        my %h = ();

        do {
            $h{ udev_list_entry_get_name($entry) } = udev_list_entry_get_value($entry);
            $entry = udev_list_entry_get_next($entry);
        } while (defined($entry));

        return \%h;
    }
    elsif (wantarray) {
        return ();
    }

    return undef;
}