package Woothee::Appliance;

use strict;
use warnings;
use Carp;

use Woothee::Util qw/update_map update_category update_version update_os update_os_version/;
use Woothee::DataSet qw/dataset/;

our $VERSION = "1.7.0";

sub challenge_playstation {
    my ($ua, $result) = @_;

    my $data;
    my $os_version;

    if (index($ua, "PSP (PlayStation Portable);") > -1) {
        if ($ua =~ m!PSP \(PlayStation Portable\); ([.0-9]+)\)!) {
            $os_version = $1;
        }
        $data = dataset("PSP");
    }
    elsif (index($ua, "PlayStation Vita") > -1) {
        if ($ua =~ m!PlayStation Vita ([.0-9]+)\)!) {
            $os_version = $1;
        }
        $data = dataset("PSVita");
    }
    elsif (index($ua, "PLAYSTATION 3 ") > -1 || index($ua, "PLAYSTATION 3;") > -1) {
        if ($ua =~ m!PLAYSTATION 3;? ([.0-9]+)\)!) {
            $os_version = $1;
        }
        $data = dataset("PS3");
    }
    elsif (index($ua, "PlayStation 4 ") > -1) {
        if ($ua =~ m!PlayStation 4 ([.0-9]+)\)!) {
            $os_version = $1;
        }
        $data = dataset("PS4");
    }

    return 0 unless $data;

    update_map($result, $data);
    if ($os_version) {
        update_os_version($result, $os_version);
    }
    return 1;
}

sub challenge_nintendo {
    my ($ua, $result) = @_;

    my $data;

    if (index($ua, "Nintendo 3DS;") > -1) {
        $data = dataset("Nintendo3DS");
    }
    elsif (index($ua, "Nintendo DSi;") > -1) {
        $data = dataset("NintendoDSi");
    }
    elsif (index($ua, "Nintendo Wii;") > -1) {
        $data = dataset("NintendoWii");
    }
    elsif (index($ua, "(Nintendo WiiU)") > -1) {
        $data = dataset("NintendoWiiU");
    }

    return 0 unless $data;

    update_map($result, $data);
    return 1;
}

# for Xbox Series, see OS.pm (Windows)

sub challenge_digitaltv {
    my ($ua, $result) = @_;

    my $data;

    if (index($ua, "InettvBrowser/") > -1) {
        $data = dataset("DigitalTV");
    }

    return 0 unless $data;

    update_map($result, $data);
    return 1;
}

1;

__END__

=head1 NAME

Woothee::Appliance - part of Woothee

For Woothee, see L<https://github.com/woothee/woothee>

=head1 DESCRIPTION

This module doesn't have any public interfaces. To parse user-agent strings, see module 'Woothee'.

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
