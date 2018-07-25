package Woothee::OS;

use strict;
use warnings;
use Carp;

use Woothee::Util qw/update_map update_category update_version update_os update_os_version/;
use Woothee::DataSet qw/dataset/;

our $VERSION = "1.8.0";

sub challenge_windows {
    my ($ua, $result) = @_;

    return 0 if index($ua, "Windows") < 0;

    # Xbox Series
    if (index($ua, "Xbox") > -1) {
        my $data;
        if ($ua =~ m{Xbox; Xbox One\)}) {
            $data = dataset("XboxOne");
        }
        else {
            $data = dataset("Xbox360");
        }
        # overwrite browser detections as appliance
        update_map($result, $data);
        return 1;
    }

    my $data = dataset("Win");

    unless ($ua =~ /Windows ([ .a-zA-Z0-9]+)[;\\)]/o) {
        # Windows, but version unknown
        update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
        update_os($result, $data->{Woothee::DataSet->const('KEY_NAME')});
        return 1;
    }

    my $version = $1;
    if ($version eq "NT 10.0") { $data = dataset("Win10"); }
    elsif ($version eq "NT 6.3") { $data = dataset("Win8.1"); }
    elsif ($version eq "NT 6.2") { $data = dataset("Win8"); }
    elsif ($version eq "NT 6.1") { $data = dataset("Win7"); }
    elsif ($version eq "NT 6.0") { $data = dataset("WinVista"); }
    elsif ($version eq "NT 5.1") { $data = dataset("WinXP"); }
    elsif ($version =~ /^Phone(?: OS)? ([.0-9]+)/o) {
        $data = dataset("WinPhone");
        $version = $1;
    }
    elsif ($version eq "NT 5.0") { $data = dataset("Win2000"); }
    elsif ($version eq "NT 4.0") { $data = dataset("WinNT4"); }
    elsif ($version eq "98") { $data = dataset("Win98"); } # wow, WinMe is shown as 'Windows 98; Win9x 4.90', fxxxk
    elsif ($version eq "95") { $data = dataset("Win95"); }
    elsif ($version eq "CE") { $data = dataset("WinCE"); }

    # else, windows, but version unknown

    update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
    update_os($result, $data->{Woothee::DataSet->const('KEY_NAME')});
    update_os_version($result, $version);
    return 1;
}

sub challenge_osx {
    my ($ua, $result) = @_;

    return 0 if index($ua, "Mac OS X") < 0;

    # (Macintosh; U; Intel Mac OS X 10_5_4; ja-jp)
    # (Macintosh; Intel Mac OS X 10_9_2)
    # (Macintosh; U; PPC Mac OS X 10.5; ja-JP-mac; rv:1.9.1.19)
    my $data = dataset("OSX");
    my $version;

    if (index($ua, "like Mac OS X") > -1) {
        # iOS
        # (iPhone; CPU iPhone OS 5_0_1 like Mac OS X)
        # (iPad; U; CPU OS 4_3_2 like Mac OS X; ja-jp)
        if (index($ua, "iPhone;") > -1) {
            $data = dataset("iPhone");
        }elsif (index($ua, "iPad;") > -1) {
            $data = dataset("iPad");
        }elsif (index($ua, "iPod") > -1) {
            $data = dataset("iPod");
        }
        if ($ua =~ /; CPU(?: iPhone)? OS (\d+_\d+(?:_\d+)?) like Mac OS X/) {
            $version = $1;
            $version =~ s/_/./g;
        }
    } else {
        # OSX
        if ($ua =~ /Mac OS X (10[._]\d+(?:[._]\d+)?)(?:\)|;)/) {
            $version = $1;
            $version =~ s/_/./g;
        }
    }
    update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
    update_os($result, $data->{Woothee::DataSet->const('KEY_NAME')});
    if ($version){
        update_os_version($result, $version);
    }
    return 1;
}

sub challenge_linux {
    my ($ua, $result) = @_;

    return 0 if index($ua, "Linux") < 0;

    my $data;
    my $os_version;
    if (index($ua, "Android") > -1 ) {
        # (Linux; U; Android 2.3.5; ja-jp; ISW11F Build/FGK500)
        # (Linux; U; Android 3.1; ja-jp; L-06C Build/HMJ37)
        # (Linux; U; Android-4.0.3; en-us; Galaxy Nexus Build/IML74K)
        # (Linux; Android 4.2.2; SO-01F Build/14.1.H.1.281)
        $data = dataset("Android");
        if ($ua =~ /Android[- ](\d+\.\d+(?:\.\d+)?)/) {
            $os_version = $1;
        }
    }else {
        $data = dataset("Linux");
    }
    update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
    update_os($result, $data->{Woothee::DataSet->const('KEY_NAME')});
    if ($os_version) {
        update_os_version($result, $os_version);
    }
    return 1;
}

sub challenge_smartphone {
    my ($ua, $result) = @_;

    my $data;
    my $os_version;
    if (index($ua, "iPhone") > -1) {
        $data = dataset("iPhone");
    } elsif (index($ua, "iPad") > -1) {
        $data = dataset("iPad");
    } elsif (index($ua, "iPod") > -1) {
        $data = dataset("iPod");
    } elsif (index($ua, "Android") > -1) {
        $data = dataset("Android");
    } elsif (index($ua, "CFNetwork") > -1) {
        $data = dataset("iOS");
    } elsif (index($ua, "BB10") > -1) {
        if ($ua =~ m!BB10(?:.+)Version/([.0-9]+)!) {
            $os_version = $1;
        }
        $data = dataset("BlackBerry10");
    } elsif (index($ua, "BlackBerry") > -1) {
        if ($ua =~ m!BlackBerry(?:\d+)/([.0-9]+) !) {
            $os_version = $1;
        }
        $data = dataset("BlackBerry");
    }

    if ($result->{Woothee::DataSet->const('KEY_NAME')} and
            $result->{Woothee::DataSet->const('KEY_NAME')} eq dataset('Firefox')->{Woothee::DataSet->const('KEY_NAME')}) {
        # Firefox OS (phone/tablet) specific pattern
        # http://lawrencemandel.com/2012/07/27/decision-made-firefox-os-user-agent-string/
        # https://github.com/woothee/woothee/issues/2
        if ($ua =~ m!^Mozilla/[.0-9]+ \((?:Mobile|Tablet);(?:.*;)? rv:([.0-9]+)\) Gecko/[.0-9]+ Firefox/[.0-9]+$!) {
            $data = dataset("FirefoxOS");
            $os_version = $1
        }
    }

    return 0 unless $data;

    update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
    update_os($result, $data->{Woothee::DataSet->const('KEY_NAME')});
    if ($os_version) {
        update_os_version($result, $os_version);
    }
    return 1;
}

sub challenge_mobilephone {
    my ($ua, $result) = @_;

    if (index($ua, "KDDI-") > -1) {
        if ($ua =~ m{KDDI-([^- /;()"']+)}o) {
            my $term = $1;
            my $data = dataset("au");
            update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
            update_os($result, $data->{Woothee::DataSet->const('KEY_OS')});
            update_version($result, $term);
            return 1;
        }
    }
    if (index($ua, "WILLCOM") > -1 || index($ua, "DDIPOCKET") > -1) {
        if ($ua =~ m{(?:WILLCOM|DDIPOCKET);[^/]+/([^ /;()]+)}o) {
            my $term = $1;
            my $data = dataset("willcom");
            update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
            update_os($result, $data->{Woothee::DataSet->const('KEY_OS')});
            update_version($result, $term);
            return 1;
        }
    }
    if (index($ua, "SymbianOS") > -1) {
        my $data = dataset("SymbianOS");
        update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
        update_os($result, $data->{Woothee::DataSet->const('KEY_OS')});
        return 1;
    }
    if (index($ua, "Google Wireless Transcoder") > -1) {
        update_map($result, dataset("MobileTranscoder"));
        update_version($result, "Google");
        return 1;
    }
    if (index($ua, "Naver Transcoder") > -1) {
        update_map($result, dataset("MobileTranscoder"));
        update_version($result, "Naver");
        return 1;
    }

    return 0;
}

sub challenge_appliance {
    my ($ua, $result) = @_;

    if (index($ua, "Nintendo DSi;") > -1) {
        my $data = dataset("NintendoDSi");
        update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
        update_os($result, $data->{Woothee::DataSet->const('KEY_OS')});
        return 1;
    }
    if (index($ua, "Nintendo Wii;") > -1) {
        my $data = dataset("NintendoWii");
        update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
        update_os($result, $data->{Woothee::DataSet->const('KEY_OS')});
        return 1;
    }

    return 0;
}

sub challenge_misc {
    my ($ua, $result) = @_;

    my $data;
    my $os_version;

    if (index($ua, "(Win98;") > -1) {
        $data = dataset("Win98");
        $os_version = "98";
    }
    elsif (index($ua, "Macintosh; U; PPC;") > -1 || index($ua, "Mac_PowerPC") > -1) {
        # (Macintosh; U; PPC; en-US; mimic; rv:9.2.1)
        if ($ua =~ /rv:(\d+\.\d+\.\d+)/) {
            $os_version = $1;
        }
        $data = dataset("MacOS");
    }
    elsif (index($ua, "X11; FreeBSD ") > -1) {
        # (X11; FreeBSD 8.2-RELEASE-p3 amd64; U; ja)
        if ($ua =~ /FreeBSD ([^;\)]+);/) {
            $os_version = $1;
        }
        $data = dataset("BSD");
    }
    elsif (index($ua, "X11; CrOS ") > -1) {
        # (X11; CrOS x86_64 5116.115.4)
        if ($ua =~ /CrOS ([^\)]+)\)/) {
            $os_version = $1;
        }
        $data = dataset("ChromeOS");
    }

    if ($data) {
        update_category($result, $data->{Woothee::DataSet->const('KEY_CATEGORY')});
        update_os($result, $data->{Woothee::DataSet->const('KEY_NAME')});
        if ($os_version) {
            update_os_version($result, $os_version);
        }
        return 1;
    }

    return 0;
}

1;

__END__

=head1 NAME

Woothee::OS - part of Woothee

For Woothee, see L<https://github.com/woothee/woothee>

=head1 DESCRIPTION

This module doesn't have any public interfaces. To parse user-agent strings, see module 'Woothee'.

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
