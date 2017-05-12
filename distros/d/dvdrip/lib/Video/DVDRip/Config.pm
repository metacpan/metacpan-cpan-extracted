# $Id: Config.pm 2376 2009-02-22 18:49:03Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Config;
use Locale::TextDomain qw (video.dvdrip);
use POSIX qw(locale_h);

use base Video::DVDRip::Base;

use Video::DVDRip::Preset;

use strict;
use FileHandle;
use Data::Dumper;
use Carp;

sub config			{ shift->{config}			}

sub order			{ shift->{order}			}
sub presets			{ shift->{presets}			}
sub filename			{ shift->{filename}			}
sub last_saved_data		{ shift->{last_saved_data}		}

sub set_order			{ shift->{order}		= $_[1] }
sub set_presets			{ shift->{presets}		= $_[1] }
sub set_filename		{ shift->{filename}		= $_[1] }
sub set_last_saved_data		{ shift->{last_saved_data}	= $_[1] }

my @BPP = '<none>';
for ( my $b = 1.0; $b > 0 && push @BPP, sprintf( "%.2f", $b ); $b -= 0.05 ) {
;
}

my @LANG = (
    "en - English",
    "de - Deutsch",
    "fr - Francais",
    "es - Espanol",
    "it - Italiano",
    "nl - Nederlands",
    "aa - Afar",
    "ab - Abkhazian",
    "af - Afrikaans",
    "am - Amharic",
    "ar - Arabic",
    "as - Assamese",
    "ay - Aymara",
    "az - Azerbaijani",
    "ba - Bashkir",
    "be - Byelorussian",
    "bg - Bulgarian",
    "bh - Bihari",
    "bi - Bislama",
    "bn - Bengali / Bangla",
    "bo - Tibetan",
    "br - Breton",
    "ca - Catalan",
    "co - Corsican",
    "cs - Czech",
    "cy - Welsh",
    "da - Dansk",
    "dz - Bhutani",
    "el - Greek",
    "eo - Esperanto",
    "et - Estonian",
    "eu - Basque",
    "fa - Persian",
    "fi - Suomi",
    "fj - Fiji",
    "fo - Faroese",
    "fy - Frisian",
    "ga - Gaelic",
    "gd - Scots Gaelic",
    "gl - Galician",
    "gn - Guarani",
    "gu - Gujarati",
    "ha - Hausa",
    "he - Hebrew",
    "hi - Hindi",
    "hr - Hrvatski",
    "hu - Magyar",
    "hy - Armenian",
    "ia - Interlingua",
    "id - Indonesian",
    "ie - Interlingue",
    "ik - Inupiak",
    "in - Indonesian",
    "is - Islenska",
    "iu - Inuktitut",
    "iw - Hebrew",
    "ja - Japanese",
    "ji - Yiddish",
    "jw - Javanese",
    "ka - Georgian",
    "kk - Kazakh",
    "kl - Greenlandic",
    "km - Cambodian",
    "kn - Kannada",
    "ko - Korean",
    "ks - Kashmiri",
    "ku - Kurdish",
    "ky - Kirghiz",
    "la - Latin",
    "ln - Lingala",
    "lo - Laothian",
    "lt - Lithuanian",
    "lv - Latvian, Lettish",
    "mg - Malagasy",
    "mi - Maori",
    "mk - Macedonian",
    "ml - Malayalam",
    "mn - Mongolian",
    "mo - Moldavian",
    "mr - Marathi",
    "ms - Malay",
    "mt - Maltese",
    "my - Burmese",
    "na - Nauru",
    "ne - Nepali",
    "no - Norsk",
    "oc - Occitan",
    "om - Oromo",
    "or - Oriya",
    "pa - Punjabi",
    "pl - Polish",
    "ps - Pashto, Pushto",
    "pt - Portugues",
    "qu - Quechua",
    "rm - Rhaeto-Romance",
    "rn - Kirundi",
    "ro - Romanian",
    "ru - Russian",
    "rw - Kinyarwanda",
    "sa - Sanskrit",
    "sd - Sindhi",
    "sg - Sangho",
    "sh - Serbo-Croatian",
    "si - Sinhalese",
    "sk - Slovak",
    "sl - Slovenian",
    "sm - Samoan",
    "sn - Shona",
    "so - Somali",
    "sq - Albanian",
    "sr - Serbian",
    "ss - Siswati",
    "st - Sesotho",
    "su - Sundanese",
    "sv - Svenska",
    "sw - Swahili",
    "ta - Tamil",
    "te - Telugu",
    "tg - Tajik",
    "th - Thai",
    "ti - Tigrinya",
    "tk - Turkmen",
    "tl - Tagalog",
    "tn - Setswana",
    "to - Tonga",
    "tr - Turkish",
    "ts - Tsonga",
    "tt - Tatar",
    "tw - Twi",
    "ug - Uighur",
    "uk - Ukrainian",
    "ur - Urdu",
    "uz - Uzbek",
    "vi - Vietnamese",
    "vo - Volapuk",
    "wo - Wolof",
    "xh - Xhosa",
    "yi - Yiddish",
    "yo - Yoruba",
    "za - Zhuang",
    "zh - Chinese",
    "zu - Zulu",
);

my @LANG_POPUP = ( [ "", "<none>" ] );
push @LANG_POPUP, [ $_, $_ ] for @LANG;

my %CONFIG_PARAMETER = (
    program_name => {
        type  => 'string',
        value => "dvd::rip",
    },
    dvd_device => {
        label => __ "Default DVD device",
        type  => 'file',
        value => "",
        dvd_button => 1,
    },
    selected_dvd_device => {
        value   => "/dev/dvd",
    },
    eject_command => {
        label => __ "Eject Command",
        type  => 'string',
        value => "eject",
        rules => "executable-command",
    },
    play_dvd_command => {
        label => __ "DVD player command",
        type  => 'string',
        value =>
            'mplayer <dvd://%t -aid %(%a+%b) -chapter %c -dvdangle %m -dvd-device %d>',
        presets => [
            'mplayer <dvd://%t -aid %(%a+%b) -chapter %c -dvdangle %m -dvd-device %d>',
            'xine -a %a -p <dvd://%d/%t.%c>',
        ],
        rules => "executable-command",
    },
    play_file_command => {
        label => __ "File player command",
        type  => 'string',
        value => 'mplayer <%f>',
        presets => [ 'xine -p <%f>', 'mplayer <%f>', ],
        rules   => "executable-command",
    },
    play_stdin_command => {
        label   => __ "STDIN player command",
        type    => 'string',
        value   => 'xine stdin://mpeg2 -g -pq -a %a',
        presets => [
            'mplayer -aid %(%a+128) -', 'xine stdin://mpeg2 -g -pq -a %a',
        ],
        rules => "executable-command",
    },
    rar_command => {
        label   => __ "rar command (for vobsub compression)",
        type    => 'string',
        value   => 'rar',
        presets => [ 'rar', ],
        rules   => "executable-command",
    },
    base_project_dir => {
        label => __ "Default data base directory",
        type  => 'dir',
        value => "$ENV{HOME}/dvdrip-data",
    },
    dvdrip_files_dir => {
        label => __ "Default directory for .rip project files",
        type  => 'dir',
        value => "$ENV{HOME}/dvdrip-data",
    },
    ogg_file_ext => {
        label => __ "OGG file extension",
        type  => 'string',
        value => 'ogm',
        presets => [ 'ogg', 'ogm', 'ogv' ],
    },
    cluster_master_local => {
        label => __ "Start cluster control daemon locally",
        type  => 'switch',
        value => 1,
    },
    cluster_master_server => {
        label => __ "Hostname of server with daemon",
        type  => 'string',
        value => "localhost",
    },
    cluster_master_port => {
        label => __ "TCP port number of daemon",
        type  => 'number',
        value => 28646,
        rules => "positive-integer",
    },
    default_video_codec => {
        label   => __ "Default video codec",
        type    => 'string',
        value   => 'xvid',
        presets => [
            "SVCD",   "VCD",  "XSVCD",   "XVCD",  "CVD",   "divx4",
            "divx5",  "xvid", "xvidcvs", "xvid2", "xvid3", "xvid4",
            "ffmpeg", "fame", "af6"
        ],
    },
    default_container => {
        label => __ "Default container format",
        type  => 'popup',
        value => 'avi',
        presets => [ [ "avi", "avi" ], [ "ogg", "ogg" ], [ "mpeg", "mpeg" ] ],
    },
    default_bpp => {
        label   => __ "Default BPP value",
        type    => 'number',
        value   => '<none>',
        presets => \@BPP,
        tooltip => __ "If this option is set dvd::rip automatically "
            . "calculates the video bitrate using this BPP value",
        rules => "positive-float",
    },
    default_subtitle_grab => {
        label   => __ "Grab subtitles while ripping",
        type    => "popup",
        value   => 0,
        presets => [
            [ 'all'   => __"Grab all subtitles" ],
            [ 'lang'  => __"Grab subtitles of preferred language" ],
            [ 0       => __"Don't grab subtitles" ],
        ],
    },
    default_preset => {
        label   => __"Default Clip & Zoom preset",
        type    => "popup",
        value   => "auto_medium_fast",
        presets => [],
    },
    preferred_lang => {
        label   => __ "Preferred language",
        type    => 'popup',
        value   => '',
        presets => \@LANG_POPUP,
    },
    workaround_nptl_bugs => {
        label => __ "Workaround transcode NPTL bugs",
        type  => 'switch',
        value => (check_nptl_workaround_possible() ? 1 : 0),
        avail_method => "check_nptl_workaround_possible",
    },
    nptl_ld_assume_kernel => {
        label   => __ "Set LD_ASSUME_KERNEL to",
        type    => "string",
        value   => "2.4.30",
        chained => 1,
        avail_method => "check_nptl_workaround_possible",
    },
    small_screen => {
        label   => __ "Optimize layout for small screens",
        type    => "switch",
        value   => get_default_small_screen_value(),
        tooltip =>
            __ "With this option the dvd::rip GUI may be tweaked "
              ."to fit even on small screens by adding scrollbars "
              ."to the notebook pages. dvd::rip needs to be restarted "
              ."to take effect"
    },
);

my @CONFIG_ORDER = (
    __ "Basic settings" => [
        qw(
            dvd_device
            base_project_dir   dvdrip_files_dir
            preferred_lang     small_screen
            )
    ],
    __ "Commands" => [
        qw(
            play_dvd_command   play_file_command
            play_stdin_command rar_command
            )
    ],
    __ "Cluster options" => [
        qw(
            cluster_master_local cluster_master_server
            cluster_master_port
            )
    ],
    __ "Miscellaneous options" => [
        qw(
            default_video_codec
            default_container
            ogg_file_ext
            default_bpp
            default_preset
            default_subtitle_grab
            workaround_nptl_bugs nptl_ld_assume_kernel
            )
    ],
);

sub config_definition { \%CONFIG_PARAMETER }

sub new {
    my $type             = shift;

    my @presets = (
        Video::DVDRip::Preset->new(
            name              => "nopreset",
            title             => __ "- No Modifications (anamorph) -",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => undef,
            tc_zoom_height    => undef,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 0,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name           => "auto_clip",
            title          => __ "Autoadjust, Clipping only (anamorph)",
            auto_clip      => 1,
        ),
        Video::DVDRip::Preset->new(
            name           => "auto_big",
            title          => __ "Autoadjust, Big Frame Size, HQ Resize",
            tc_fast_resize => 0,
            auto           => 1,
            frame_size     => 'big',
        ),
        Video::DVDRip::Preset->new(
            name           => "auto_medium",
            title          => __ "Autoadjust, Medium Frame Size, HQ Resize",
            tc_fast_resize => 0,
            auto           => 1,
            frame_size     => 'medium',
        ),
        Video::DVDRip::Preset->new(
            name           => "auto_small",
            title          => __ "Autoadjust, Small Frame Size, HQ Resize",
            tc_fast_resize => 0,
            auto           => 1,
            frame_size     => 'small',
        ),
        Video::DVDRip::Preset->new(
            name           => "auto_big_fast",
            title          => __ "Autoadjust, Big Frame Size, Fast Resize",
            tc_fast_resize => 1,
            auto           => 1,
            frame_size     => 'big',
        ),
        Video::DVDRip::Preset->new(
            name           => "auto_medium_fast",
            title          => __ "Autoadjust, Medium Frame Size, Fast Resize",
            tc_fast_resize => 1,
            auto           => 1,
            frame_size     => 'medium',
        ),
        Video::DVDRip::Preset->new(
            name           => "auto_small_fast",
            title          => __ "Autoadjust, Small Frame Size, Fast Resize",
            tc_fast_resize => 1,
            auto           => 1,
            frame_size     => 'small',
        ),
        Video::DVDRip::Preset->new(
            name              => "vcd_pal_43",
            title             => __ "VCD 4:3, PAL",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 352,
            tc_zoom_height    => 288,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "vcd_pal_16_9",
            title             => __ "VCD 16:9, PAL",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 48,
            tc_clip1_right    => 48,
            tc_zoom_width     => 352,
            tc_zoom_height    => 248,
            tc_clip2_top      => -20,
            tc_clip2_bottom   => -20,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "svcd_pal_16_9_4_3",
            title             => __ "SVCD 16:9 -> 4:3 letterbox, PAL",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 480,
            tc_zoom_height    => 432,
            tc_clip2_top      => -72,
            tc_clip2_bottom   => -72,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "svcd_pal",
            title             => __ "SVCD anamorph, PAL",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 480,
            tc_zoom_height    => 576,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "xsvcd_pal",
            title             => __ "XSVCD anamorph, PAL",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 720,
            tc_zoom_height    => 576,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "cvd_pal",
            title             => __ "CVD anamorph, PAL",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 352,
            tc_zoom_height    => 576,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "vcd_ntsc_43",
            title             => __ "VCD 4:3, NTSC",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 352,
            tc_zoom_height    => 240,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "vcd_ntsc_16_9",
            title             => __ "VCD 16:9, NTSC",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 32,
            tc_clip1_right    => 32,
            tc_zoom_width     => 352,
            tc_zoom_height    => 200,
            tc_clip2_top      => -20,
            tc_clip2_bottom   => -20,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "svcd_ntsc_16_9_4_3",
            title             => __ "SVCD 16:9 -> 4:3 letterbox, NTSC",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 480,
            tc_zoom_height    => 432,
            tc_clip2_top      => -24,
            tc_clip2_bottom   => -24,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "svcd_ntsc",
            title             => __ "SVCD anamorph, NTSC",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 480,
            tc_zoom_height    => 480,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "xsvcd_ntsc",
            title             => __ "XSVCD anamorph, NTSC",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 720,
            tc_zoom_height    => 480,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
        Video::DVDRip::Preset->new(
            name              => "cvd_ntsc",
            title             => __ "CVD anamorph, NTSC",
            tc_clip1_top      => 0,
            tc_clip1_bottom   => 0,
            tc_clip1_left     => 0,
            tc_clip1_right    => 0,
            tc_zoom_width     => 352,
            tc_zoom_height    => 480,
            tc_clip2_top      => 0,
            tc_clip2_bottom   => 0,
            tc_clip2_left     => 0,
            tc_clip2_right    => 0,
            tc_fast_resize    => 1,
            tc_fast_bisection => 0,
        ),
    );

    my $default_presets_lref = $CONFIG_PARAMETER{"default_preset"}->{presets};
    
    foreach my $preset ( @presets ) {
        push @{$default_presets_lref}, 
            [ $preset->name, $preset->title ];
    }

    my %config_parameter = %CONFIG_PARAMETER;
    my @config_order     = @CONFIG_ORDER;

    my $self = {
        config  => \%config_parameter,
        order   => \@config_order,
        presets => \@presets,
    };

    return bless $self, $type;
}

sub init_nptl_bug_workaround {
    my $self = shift;

    if ( !check_nptl_workaround_possible() ) {
        $self->set_value("workaround_nptl_bugs", 0);
    }

    if ( $self->get_value("workaround_nptl_bugs") ) {
        $ENV{LD_ASSUME_KERNEL} = $self->get_value('nptl_ld_assume_kernel');
    }
    else {
        delete $ENV{LD_ASSUME_KERNEL};
    }

    1;
}

sub init_settings {
    my $self = shift;
    
    if ( $self->get_value("dvd_device") eq "" ) {
        $self->set_value( dvd_device => ($self->get_first_dvd_device || "/dev/dvd") );
        $self->save;
    }
    
    if ( $self->get_value("preferred_lang") eq "" ) {
        my $lc_messages = POSIX::setlocale("LC_MESSAGES");
        my ($lang) = split("_", $lc_messages, 2);
        $lang = lc($lang);
        $lang = "en" if $lang eq "c";
        $self->set_value( preferred_lang => "<none>" );
        foreach my $lang_list ( @LANG ) {
            if ( $lang_list =~ /$lang -/i ) {
                $self->set_value( preferred_lang => $lang_list );
                last;
            }
        }
    }
    
    1;
}

sub load {
    my $self = shift;

    my $filename = $self->filename;
    die "filename not set" if $filename eq '';
    die "can't read $filename" if not -r $filename;

    my $loaded;
    $loaded = do $filename;

    if ( $@ or ref $loaded ne 'Video::DVDRip::Config' ) {
        print "\nCan't load $filename (Preferences)\n$@\n"
            . "File is probably broken.\n"
            . "Remove it (Note: your Preferences will be LOST)\n"
            . "and try again.\n\n";
        exit 1;
    }

    foreach my $par ( keys %{ $self->config } ) {
        if ( exists $loaded->config->{$par} ) {
            $self->config->{$par}->{value} = $loaded->config->{$par}->{value};
        }
        if ( exists $self->config->{$par}->{onload} ) {
            my $onload = $self->config->{$par}->{onload};
            &$onload( $self->get_value($par) );
        }
    }

    $self->init_nptl_bug_workaround;

    1;
}

sub get_save_data {
    my $self = shift;

    my $last_saved_data = $self->last_saved_data;
    $self->set_last_saved_data(undef);

    my $dd = Data::Dumper->new( [$self], ['config'] );
    $dd->Indent(1);
    my $data = $dd->Dump;

    $self->set_last_saved_data($last_saved_data);

    return \$data;
}

sub save {
    my $self = shift;

    my $filename = $self->filename;
    die "filename not set" if $filename eq '';

    my $data_sref = $self->get_save_data;

    my $fh = FileHandle->new;

    open( $fh, "> $filename" ) or die "can't write $filename";
    print $fh q{# $Id: Config.pm 2376 2009-02-22 18:49:03Z joern $},
        "\n";
    print $fh
        "# This file was generated by Video::DVDRip Version $Video::DVDRip::VERSION\n\n";

    print $fh ${$data_sref};
    close $fh;

    $self->set_last_saved_data($data_sref);

    $self->init_nptl_bug_workaround;

    1;
}

sub changed {
    my $self = shift;

    return 1 if not $self->last_saved_data;

    my $actual_data_sref = $self->get_save_data;
    my $saved_data_sref  = $self->last_saved_data;

    my $actual = join( "\n", sort split( /\n/, $$actual_data_sref ) );
    my $saved  = join( "\n", sort split( /\n/, $$saved_data_sref ) );

    return $actual ne $saved;
}

sub get_value {
    my $self   = shift;
    my ($name) = @_;
    my $config = $self->config;
    confess "Unknown config parameter '$name'"
        if not exists $config->{$name};
    return $config->{$name}->{value};
}

sub set_value {
    my $self = shift;
    my ( $name, $value ) = @_;
    my $config = $self->config;
    confess "Unknown config parameter '$name'"
        if not exists $config->{$name};
    return $config->{$name}->{value} = $value;
}

sub entries_by_type {
    my $self = shift;
    my ($type) = @_;

    my %result;
    my $config = $self->config;
    my ( $k, $v );
    while ( ( $k, $v ) = each %{$config} ) {
        $result{$k} = $v if $v->{type} eq $type;
    }

    return \%result;
}

sub set_temporary {
    my $self = shift;
    my ( $name, $value ) = @_;
    return $self->config->{$name}->{value} = $value;
}

sub get_preset {
    my $self   = shift;
    my %par    = @_;
    my ($name) = @par{'name'};

    my $presets = $self->presets;

    foreach my $preset ( @{$presets} ) {
        return $preset if $preset->name eq $name;
    }

    return;
}

sub copy_values_from {
    my $self = shift;
    my ($config) = @_;

    foreach my $par ( keys %CONFIG_PARAMETER ) {
        $self->set_value( $par, $config->get_value($par) );
    }

    1;
}

sub selected_dvd_device_list {
    my $self = shift;

    return unless $self->has("hal");
    
    #-- scan lshal output for DVD devices
    my %devices;
    open (my $fh, "LC_ALL=C lshal |") or die "can't fork lshal";
    my $entry;
    while ( <$fh> ) {
        if ( /^udi/ ) {
            $devices{$entry->{device}} = $entry->{model} if $entry && $entry->{dvd};
            $entry = {};
        }
        if ( /storage\.model\s+=\s+'([^']+)/ ) {
            $entry->{model} = $1;
        }
        if ( /block\.device\s+=\s+'([^']+)/ ) {
            $entry->{device} = $1;
        }
        if ( /storage\.cdrom\.dvd\s+=\s+true/ ) {
            $entry->{dvd} = 1;
        }
    }
    close $fh;

    $devices{$entry->{device}} = $entry->{model} if $entry && $entry->{dvd};    

    return \%devices;
}

sub get_first_dvd_device {
    my $self = shift;
    
    my $href = $self->selected_dvd_device_list;

    my $first_name;
    my $first_device;
    foreach my $device ( keys %{$href} ) {
        if ( !$first_name || $first_name gt $href->{$device} ) {
            $first_device = $device;
            $first_name = $href->{$device};
        }
    }

    return $first_device;
}

#---------------------------------------------------------------------
# Test methods
#---------------------------------------------------------------------

sub test_play_dvd_command     { _executable(@_) }
sub test_play_file_command    { _executable(@_) }
sub test_play_stdin_command   { _executable(@_) }
sub test_rar_command          { _executable(@_) }
sub test_dvd_device           { _exists(@_) }
sub test_writer_device        { _exists(@_) }
sub test_base_project_dir     { _abs_and_writable(@_) }
sub test_dvdrip_files_dir     { _abs_and_writable(@_) }
sub test_burn_writing_speed   { _numeric(@_) }
sub test_burn_cdrecord_device { _cdrecord_device(@_) }
sub test_burn_cdrecord_cmd    { _executable(@_) }
sub test_burn_cdrdao_cmd      { _executable(@_) }
sub test_burn_mkisofs_cmd     { _executable(@_) }
sub test_burn_vcdimager_cmd   { _executable(@_) }
sub test_burn_cdrdao_buffers  { _numeric_or_empty(@_) }
sub test_cluster_master_port  { _numeric(@_) }
sub test_eject_command        { _executable(@_) }

sub _executable {
    my $self = shift;
    my ( $name, $value ) = @_;

    $value ||= $self->get_value($name);
    my ($file) = split( / /, $value );

    if ( not -f $file ) {
        foreach my $p ( split( /:/, $ENV{PATH} ) ) {
            $file = "$p/$file", last if -x "$p/$file";
        }
    }

    if ( -x $file ) {
        return ( __x( "{file} executable : Ok", file => $file ), 1);
    }
    else {
        return __x( "{file} not found : NOT Ok", file => $file )
            if not -e $file;
        return __x( "{file} not executable : NOT Ok", file => $file );
    }
}

sub _abs_and_writable {
    my $self = shift;
    my ($name) = @_;

    my $value = $self->get_value($name);

    return __("has whitespace : NOT Ok") if $value =~ /\s/;
    return __("is no absolute path : NOT Ok") if $value !~ m!^/!;

    if ( not -w $value ) {
        return __x( "{file} not found : NOT Ok", file => $value )
            if not -e $value;
        return __x( "{file} not writable : NOT Ok", file => $value );
    }
    else {
        return (__x( "{file} writable : Ok", file => $value ), 1);
    }
}

sub _numeric {
    my $self = shift;
    my ($name) = @_;

    my $value = $self->get_value($name);

    if ( $value =~ /^\d+$/ ) {
        return (__x( "{value} is numeric : Ok", value => $value ), 1);
    }
    else {
        return __x( "{value} isn't numeric : NOT Ok", value => $value );
    }
}

sub _numeric_or_empty {
    my $self = shift;
    my ($name) = @_;

    my $value = $self->get_value($name);

    return (__ "is empty : Ok", 1) if $value eq '';
    return $self->_numeric($name);
}

sub _exists {
    my $self = shift;
    my ($name) = @_;

    my $value = $self->get_value($name);

    if ( -e $value ) {
        return (__x( "{value} exists : Ok", value => $value ), 1);
    }
    else {
        return __x( "{value} doesn't exist : NOT Ok", value => $value );
    }
}

sub _one_of_these {
    my $self = shift;
    my ( $name, $lref ) = @_;

    my $value = $self->get_value($name);

    foreach my $val ( @{$lref} ) {
        return (__x( "'{value}' is known : Ok", value => $value ), 1)
            if $val eq $value;
    }

    return __x( "'{value}' unknown: NOT Ok", value => $value );
}

sub check_nptl_workaround_possible {
    my $check = qx[
        LD_ASSUME_KERNEL=2.4.30 ls >/dev/null 2>&1 && echo NPTL_OK
    ];
    return $check =~ /NPTL_OK/;
}

sub get_default_small_screen_value {
    my $root_info = qx[xwininfo -root];
    my ($width, $height) = $root_info =~ /Width:\s+(\d+).*?Height:\s+(\d+)/si;
    return $height < 1024;
}

1;
