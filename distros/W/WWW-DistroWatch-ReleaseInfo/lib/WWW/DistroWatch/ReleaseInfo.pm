package WWW::DistroWatch::ReleaseInfo;

our $DATE = '2018-01-22'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       get_distro_releases_info
                       list_distros
                       list_distros_cached
               );

our %SPEC;

my %file_args = (
    file => {
        schema => 'str*',
        summary => "Instead of retrieving page from distrowatch.com, use this file's content",
        tags => ['category:testing'],
    },
);

$SPEC{list_distros} = {
    v => 1.1,
    summary => "List all known distros",
    args => {
        %file_args,
    },
};
sub list_distros {
    require Mojo::DOM;
    require Mojo::UserAgent;

    my %args = @_;

    my $ua   = Mojo::UserAgent->new;
    my $html;
    if ($args{file}) {
        {
            local $/;
            open my($fh), "<", $args{file}
                or return [500, "Can't read file '$args{file}': $!"];
            $html = <$fh>;
        }
    } else {
        my $url = "https://distrowatch.com/";
        my $tx = $ua->get($url);
        unless ($tx->success) {
            my $err = $tx->error;
            return [500, "Can't retrieve URL '$url': ".
                        "$err->{code} - $err->{message}"];
        }
        $html = $tx->res->body;
    }

    my $dom  = Mojo::DOM->new($html);
    my $distros = {};
    $dom->find("select[name=distribution] option")->each(
        sub {
            $distros->{ $_->attr("value") } = $_->text;
        }
    );
    [200, "OK", $distros];
}

our $distros = do {
    no warnings 'void';
    {};
 {
   "3cx"            => "3CX",
   "4mlinux"        => "4MLinux",
   "absolute"       => "Absolute",
   "abuledu"        => "Abul\xC3\x83\xC2\x89du",
   "alpine"         => "Alpine",
   "alt"            => "ALT",
   "androidx86"     => "Android-x86",
   "antergos"       => "Antergos",
   "antix"          => "antiX",
   "apodio"         => "APODIO",
   "arch"           => "Arch",
   "archbang"       => "ArchBang",
   "archlabs"       => "ArchLabs",
   "archman"        => "Archman",
   "archstrike"     => "ArchStrike",
   "artix"          => "Artix",
   "arya"           => "Arya",
   "asianux"        => "Asianux",
   "asterisknow"    => "AsteriskNOW",
   "audiophile"     => "Audiophile",
   "austrumi"       => "AUSTRUMI",
   "avlinux"        => "AV Linux",
   "backbox"        => "BackBox",
   "backslash"      => "BackSlash",
   "baruwa"         => "Baruwa",
   "beefree"        => "BeeFree",
   "berry"          => "Berry",
   "bicom"          => "Bicom",
   "biglinux"       => "BigLinux",
   "biolinux"       => "Bio-Linux",
   "bitkey"         => "BitKey",
   "blackarch"      => "BlackArch",
   "blacklab"       => "Black Lab",
   "blackpanther"   => "blackPanther",
   "blankon"        => "BlankOn",
   "blueonyx"       => "BlueOnyx",
   "bluestar"       => "Bluestar",
   "bodhi"          => "Bodhi",
   "boss"           => "BOSS",
   "bsdrp"          => "BSDRP",
   "bunsenlabs"     => "BunsenLabs",
   "cae"            => "CAELinux",
   "caine"          => "CAINE",
   "calculate"      => "Calculate",
   "canaima"        => "Canaima",
   "centos"         => "CentOS",
   "chakra"         => "Chakra",
   "chaletos"       => "ChaletOS",
   "chapeau"        => "Chapeau",
   "clear"          => "Clear",
   "clearos"        => "ClearOS",
   "clonezilla"     => "Clonezilla",
   "clonos"         => "ClonOS",
   "cloudready"     => "CloudReady",
   "connochaet"     => "Connochaet",
   "container"      => "Container",
   "crux"           => "CRUX",
   "cucumber"       => "Cucumber",
   "daphile"        => "Daphile",
   "debian"         => "Debian",
   "deepin"         => "deepin",
   "deft"           => "DEFT",
   "devuan"         => "Devuan",
   "dietpi"         => "DietPi",
   "dragonflybsd"   => "DragonFly",
   "dragora"        => "Dragora",
   "drbl"           => "DRBL",
   "duzeru"         => "DuZeru",
   "easynas"        => "EasyNAS",
   "edubuntu"       => "Edubuntu",
   "elastix"        => "Elastix",
   "elementary"     => "elementary",
   "elive"          => "Elive",
   "emmabuntus"     => "Emmabunt\xC3\x83\xC2\xBCs",
   "endian"         => "Endian",
   "endlessos"      => "Endless",
   "exe"            => "Exe",
   "exherbo"        => "Exherbo",
   "extix"          => "ExTiX",
   "fatdog"         => "Fatdog64",
   "fedora"         => "Fedora",
   "ferenos"        => "feren",
   "fermi"          => "Fermi",
   "freebsd"        => "FreeBSD",
   "freenas"        => "FreeNAS",
   "freepbx"        => "FreePBX",
   "freespire"      => "Freespire",
   "frugalware"     => "Frugalware",
   "fuguita"        => "FuguIta",
   "funtoo"         => "Funtoo",
   "gecko"          => "Gecko",
   "gentoo"         => "Gentoo",
   "ghostbsd"       => "GhostBSD",
   "gnewsense"      => "gNewSense",
   "gnustep"        => "GNUstep",
   "gobo"           => "GoboLinux",
   "gparted"        => "GParted",
   "greenie"        => "Greenie",
   "grml"           => "Grml",
   "guixsd"         => "GuixSD",
   "haiku"          => "Haiku",
   "hardenedbsd"    => "HardenedBSD",
   "heads"          => "heads",
   "ipfire"         => "IPFire",
   "kali"           => "Kali",
   "kanotix"        => "KANOTIX",
   "kaos"           => "KaOS",
   "karoshi"        => "Karoshi",
   "kdeneon"        => "KDE neon",
   "keysoft"        => "Keysoft",
   "knoppix"        => "KNOPPIX",
   "kodachi"        => "Kodachi",
   "kolibri"        => "KolibriOS",
   "korora"         => "Korora",
   "kubuntu"        => "Kubuntu",
   "kwort"          => "Kwort",
   "kxstudio"       => "KXStudio",
   "lakka"          => "Lakka",
   "leeenux"        => "Leeenux",
   "legacy"         => "Legacy",
   "lfs"            => "LFS",
   "libreelec"      => "LibreELEC",
   "linhes"         => "LinHES",
   "linspire"       => "Linspire",
   "linuxbbq"       => "LinuxBBQ",
   "linuxconsole"   => "LinuxConsole",
   "linuxfx"        => "Linuxfx",
   "lite"           => "Lite",
   "liveraizo"      => "Live Raizo",
   "lliurex"        => "LliureX",
   "lubuntu"        => "Lubuntu",
   "lunar"          => "Lunar",
   "luninux"        => "LuninuX",
   "lxle"           => "LXLE",
   "mageia"         => "Mageia",
   "makulu"         => "MakuluLinux",
   "mangaka"        => "Mangaka",
   "manjaro"        => "Manjaro",
   "maui"           => "Maui",
   "max"            => "MAX",
   "metamorphose"   => "Metamorphose",
   "midnightbsd"    => "MidnightBSD",
   "minino"         => "MiniNo",
   "minix"          => "MINIX",
   "mint"           => "Mint",
   "miros"          => "MirOS",
   "mll"            => "Minimal",
   "morpheusarch"   => "MorpheusArch",
   "mx"             => "MX Linux",
   "nas4free"       => "NAS4Free",
   "neptune"        => "Neptune",
   "netbsd"         => "NetBSD",
   "nethserver"     => "NethServer",
   "netrunner"      => "Netrunner",
   "nexentastor"    => "NexentaStor",
   "nitrux"         => "Nitrux",
   "nixos"          => "NixOS",
   "nst"            => "NST",
   "nutyx"          => "NuTyX",
   "ob2d"           => "OB2D",
   "olpc"           => "OLPC",
   "omoikane"       => "Omoikane",
   "openbsd"        => "OpenBSD",
   "openelec"       => "OpenELEC",
   "openindiana"    => "OpenIndiana",
   "openmandriva"   => "OpenMandriva",
   "openmediavault" => "OpenMediaVault",
   "opensuse"       => "openSUSE",
   "openwall"       => "Openwall",
   "opnsense"       => "OPNsense",
   "oracle"         => "Oracle",
   "osgeo"          => "OSGeo",
   "osmc"           => "OSMC",
   "ovios"          => "OviOS",
   "paldo"          => "paldo",
   "parabola"       => "Parabola",
   "pardus"         => "Pardus",
   "pardustopluluk" => "Pardus Topluluk",
   "parrotsecurity" => "Parrot",
   "partedmagic"    => "Parted Magic",
   "pclinuxos"      => "PCLinuxOS",
   "peachosi"       => "Peach OSI",
   "pearl"          => "Pearl",
   "pelicanhpc"     => "PelicanHPC",
   "pentoo"         => "Pentoo",
   "peppermint"     => "Peppermint",
   "pfsense"        => "pfSense",
   "photonos"       => "Photon",
   "pinguy"         => "Pinguy",
   "pisi"           => "Pisi",
   "plamo"          => "Plamo",
   "pld"            => "PLD",
   "plop"           => "Plop",
   "point"          => "Point",
   "popos"          => "Pop!_OS",
   "porteus"        => "Porteus",
   "porteuskiosk"   => "Porteus Kiosk",
   "primtux"        => "PrimTux",
   "proxmox"        => "Proxmox",
   "puppy"          => "Puppy",
   "pureos"         => "PureOS",
   "q4os"           => "Q4OS",
   "qubes"          => "Qubes",
   "quirky"         => "Quirky",
   "rancheros"      => "RancherOS",
   "raspbian"       => "Raspbian",
   "raspbsd"        => "RaspBSD",
   "rasplex"        => "RasPlex",
   "rds"            => "RDS",
   "reactos"        => "ReactOS",
   "rebeccablackos" => "RebeccaBlackOS",
   "rebellin"       => "Rebellin",
   "redcore"        => "Redcore",
   "redhat"         => "Red Hat",
   "refracta"       => "Refracta",
   "rescatux"       => "Rescatux",
   "revengeos"      => "Revenge",
   "risc"           => "RISC",
   "robolinux"      => "Robolinux",
   "rockscluster"   => "Rocks Cluster",
   "rockstor"       => "Rockstor",
   "rosa"           => "ROSA",
   "rss"            => "RSS",
   "runtu"          => "Runtu",
   "sabayon"        => "Sabayon",
   "salentos"       => "SalentOS",
   "salix"          => "Salix",
   "scientific"     => "Scientific",
   "securepoint"    => "Securepoint",
   "selks"          => "SELKS",
   "sharklinux"     => "Shark",
   "siduction"      => "siduction",
   "skolelinux"     => "Debian Edu",
   "slackel"        => "Slackel",
   "slackware"      => "Slackware",
   "slax"           => "Slax",
   "sle"            => "SUSE",
   "slitaz"         => "SliTaz",
   "smartos"        => "SmartOS",
   "smeserver"      => "SME Server",
   "smoothwall"     => "Smoothwall",
   "sms"            => "SMS",
   "solus"          => "Solus",
   "solydxk"        => "SolydXK",
   "sophos"         => "Sophos",
   "sourcemage"     => "Source Mage",
   "sparky"         => "SparkyLinux",
   "springdale"     => "Springdale",
   "star"           => "Star",
   "steamos"        => "SteamOS",
   "subgraph"       => "Subgraph",
   "sulix"          => "SuliX",
   "supergrub"      => "Super Grub2",
   "swagarch"       => "SwagArch",
   "swecha"         => "Swecha",
   "swift"          => "Swift",
   "systemrescue"   => "SystemRescue",
   "t2"             => "T2",
   "tails"          => "Tails",
   "talkingarch"    => "TalkingArch",
   "tanglu"         => "Tanglu",
   "tens"           => "TENS",
   "thinstation"    => "Thinstation",
   "tinycore"       => "Tiny Core",
   "tooppy"         => "ToOpPy",
   "torios"         => "ToriOS",
   "toutou"         => "Toutou",
   "trisquel"       => "Trisquel",
   "trueos"         => "TrueOS",
   "turnkey"        => "TurnKey",
   "tuxtrans"       => "tuxtrans",
   "ubos"           => "UBOS",
   "ubuntu"         => "Ubuntu",
   "ubuntubudgie"   => "Ubuntu Budgie",
   "ubuntudp"       => "Ubuntu DP",
   "ubuntukylin"    => "Ubuntu Kylin",
   "ubuntumate"     => "Ubuntu MATE",
   "ubuntustudio"   => "Ubuntu Studio",
   "uhu"            => "UHU-Linux",
   "ulteo"          => "Ulteo",
   "ultimate"       => "Ultimate",
   "univention"     => "Univention",
   "untangle"       => "Untangle",
   "urix"           => "URIX",
   "uruk"           => "Uruk",
   "ututo"          => "UTUTO",
   "vector"         => "Vector",
   "vine"           => "Vine",
   "vinux"          => "Vinux",
   "void"           => "Void",
   "volumio"        => "Volumio",
   "voyager"        => "Voyager",
   "vyos"           => "VyOS",
   "wattos"         => "wattOS",
   "webconverger"   => "Webconverger",
   "whonix"         => "Whonix",
   "wifislax"       => "Wifislax",
   "wmlive"         => "WM Live",
   "xstreamos"      => "XStreamOS",
   "xubuntu"        => "Xubuntu",
   "zentyal"        => "Zentyal",
   "zenwalk"        => "Zenwalk",
   "zeroshell"      => "Zeroshell",
   "zevenet"        => "Zevenet",
   "zorin"          => "Zorin",
 }

};

$SPEC{list_distros_cached} = {
    v => 1.1,
    summary => "List all known distros (cached data)",
    args => {
    },
};
sub list_distros_cached {
    [200, "OK", $distros];
}

$SPEC{get_distro_releases_info} = {
    v => 1.1,
    summary => "Get information about a distro's releases",
    description => <<'_',

This routine scrapes `http://distrowatch.com/table.php?distribution=<NAME>` and
returns a data structure like the following:

    [
        {
             release_name => '17.2 rafaela',
             release_date => '2015-06-30',
             eol_date => '2019-04',
             abiword_version => '--',
             alsa_lib_version => '1.0.27.2',
             perl_version => '5.22.0',
             python_version => '2.7.5',
             ...
        },
        ...
   ]

_
    args => {
        distribution => {
            schema => 'str*',
            summary => 'Name of distribution, e.g. "mint", "ubuntu", "debian"',
            req => 1,
            pos => 0,
            completion => sub {
                require Complete::Util;
                my %args = @_;
                Complete::Util::complete_array_elem(
                    word=>$args{word}, array=>[keys %$distros],
                );
            },
        },
        %file_args,
    },
};
sub get_distro_releases_info {
    require Mojo::DOM;
    require Mojo::UserAgent;

    my %args = @_;

    my $ua   = Mojo::UserAgent->new;
    my $html;
    if ($args{file}) {
        {
            local $/;
            open my($fh), "<", $args{file}
                or return [500, "Can't read file '$args{file}': $!"];
            $html = <$fh>;
        }
    } else {
        my $url = "http://distrowatch.com/table.php?distribution=".
            $args{distribution};
        my $tx = $ua->get($url);
        unless ($tx->success) {
            my $err = $tx->error;
            return [500, "Can't retrieve URL '$url': ".
                        "$err->{code} - $err->{message}"];
        }
        $html = $tx->res->body;
    }

    if ($html =~ /The distribution you requested does not exist/) {
        return [404, "No such distribution: '$args{distribution}'"];
    }

    my $dom  = Mojo::DOM->new($html);

    my $table = $dom->find("th.TablesInvert")->[0]->parent->parent;
    my @table;
    $table->find("tr")->each(
        sub {
            my $row = shift;
            push @table, $row->find("td,th")->map(
                sub { [$_->to_string,$_->text] })->to_array;
        }
    );
    #use DD; dd \@table;

    my %relcolnums; # key=distro name, val=column index
    for my $i (1..$#{$table[0]}-1) {
        $relcolnums{$table[0][$i][1]} = $i;
    }
    #use DD; dd \%relcolnums;

    my %fieldindexes = ( # key=field name, val=column index in result
        release_name => 0,
        release_date => 1,
        eol_date     => 2,
    );
    my $j = 3;

    my %fieldrownums; # key=field name, val=row index
    for my $i (1..$#table) {
        my ($chtml, $ctext) = @{ $table[$i][0] };
        if ($ctext =~ /release date/i) {
            $fieldrownums{release_date} = $i;
        } elsif ($ctext =~ /end of life/i) {
            $fieldrownums{eol_date} = $i;
        } elsif ($chtml =~ m!<a[^>]+>([^<]+)</a> \(.+\)!) {
            my $software = lc($1);
            $software =~ s/\W+/_/g;
            $fieldrownums{"${software}_version"} = $i;
            $fieldindexes{"${software}_version"} = $j++;
        }
    }
    #use DD; dd \%fieldrownums;

    my @rels;
    for my $relname (sort {$relcolnums{$b}<=>$relcolnums{$a}}
                         keys %relcolnums) {
        my $rel = {release_name => $relname};
        my $colnum = $relcolnums{$relname};
        for my $field (keys %fieldrownums) {
            my $rownum = $fieldrownums{$field};
            $rel->{$field} = $table[$rownum][$colnum][1];
        }
        push @rels, $rel;
    }

    [200, "OK", \@rels, {
        'table.fields'=>[sort{$fieldindexes{$a}<=>$fieldindexes{$b}} keys %fieldindexes],
    }];
}

1;
# ABSTRACT: Get information about a distro's releases

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DistroWatch::ReleaseInfo - Get information about a distro's releases

=head1 VERSION

This document describes version 0.06 of WWW::DistroWatch::ReleaseInfo (from Perl distribution WWW-DistroWatch-ReleaseInfo), released on 2018-01-22.

=head1 FUNCTIONS


=head2 get_distro_releases_info

Usage:

 get_distro_releases_info(%args) -> [status, msg, result, meta]

Get information about a distro's releases.

This routine scrapes C<< http://distrowatch.com/table.php?distribution=E<lt>NAMEE<gt> >> and
returns a data structure like the following:

 [
     {
          release_name => '17.2 rafaela',
          release_date => '2015-06-30',
          eol_date => '2019-04',
          abiword_version => '--',
          alsa_lib_version => '1.0.27.2',
          perl_version => '5.22.0',
          python_version => '2.7.5',
          ...
     },
     ...

   ]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<distribution>* => I<str>

Name of distribution, e.g. "mint", "ubuntu", "debian".

=item * B<file> => I<str>

Instead of retrieving page from distrowatch.com, use this file's content.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_distros

Usage:

 list_distros(%args) -> [status, msg, result, meta]

List all known distros.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file> => I<str>

Instead of retrieving page from distrowatch.com, use this file's content.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_distros_cached

Usage:

 list_distros_cached() -> [status, msg, result, meta]

List all known distros (cached data).

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WWW-DistroWatch-ReleaseInfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WWW-DistroWatch-ReleaseInfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-DistroWatch-ReleaseInfo>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
