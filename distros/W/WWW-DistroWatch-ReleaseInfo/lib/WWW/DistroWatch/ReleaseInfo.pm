package WWW::DistroWatch::ReleaseInfo;

our $DATE = '2015-10-06'; # DATE
our $VERSION = '0.05'; # VERSION

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
        my $url = "http://distrowatch.com/";
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
   "0linux"         => "0Linux",
   "2x"             => "2XOS",
   "4mlinux"        => "4MLinux",
   "absolute"       => "Absolute",
   "alpine"         => "Alpine",
   "alt"            => "ALT",
   "androidx86"     => "Android-x86",
   "antergos"       => "Antergos",
   "antix"          => "antiX",
   "apodio"         => "APODIO",
   "arch"           => "Arch",
   "archbang"       => "ArchBang",
   "artistx"        => "ArtistX",
   "asterisknow"    => "AsteriskNOW",
   "austrumi"       => "AUSTRUMI",
   "avlinux"        => "AV Linux",
   "backbox"        => "BackBox",
   "baltix"         => "Baltix",
   "bardinux"       => "Bardinux",
   "baruwa"         => "Baruwa",
   "bella"          => "Bella",
   "berry"          => "Berry",
   "bicom"          => "Bicom",
   "biolinux"       => "Bio-Linux",
   "blackarch"      => "BlackArch",
   "blacklab"       => "Black Lab",
   "blackpanther"   => "blackPanther",
   "blag"           => "BLAG",
   "blankon"        => "BlankOn",
   "bodhi"          => "Bodhi",
   "boss"           => "BOSS",
   "bridge"         => "Bridge",
   "cae"            => "CAELinux",
   "caine"          => "CAINE",
   "caixamagica"    => "Caixa M\xE1gica",
   "calculate"      => "Calculate",
   "canaima"        => "Canaima",
   "catix"          => "C\xE0tix",
   "centos"         => "CentOS",
   "centrych"       => "Centrych",
   "chakra"         => "Chakra",
   "chaletos"       => "ChaletOS",
   "chapeau"        => "Chapeau",
   "chitwanix"      => "Chitwanix",
   "chromixium"     => "Chromixium",
   "clearos"        => "ClearOS",
   "clonezilla"     => "Clonezilla",
   "connochaet"     => "Connochaet",
   "coreos"         => "CoreOS",
   "crux"           => "CRUX",
   "debian"         => "Debian",
   "deepin"         => "deepin",
   "deft"           => "DEFT",
   "devil"          => "Devil",
   "doudou"         => "DoudouLinux",
   "dragonflybsd"   => "DragonFly",
   "edubuntu"       => "Edubuntu",
   "elastix"        => "Elastix",
   "elementary"     => "elementary",
   "elive"          => "Elive",
   "emmabuntus"     => "Emmabunt\xFCs",
   "endian"         => "Endian",
   "exe"            => "Exe",
   "exherbo"        => "Exherbo",
   "extix"          => "ExTiX",
   "fedora"         => "Fedora",
   "fermi"          => "Fermi",
   "finnix"         => "Finnix",
   "freebsd"        => "FreeBSD",
   "freenas"        => "FreeNAS",
   "frugalware"     => "Frugalware",
   "fuguita"        => "FuguIta",
   "funtoo"         => "Funtoo",
   "geexbox"        => "GeeXboX",
   "gentoo"         => "Gentoo",
   "ghostbsd"       => "GhostBSD",
   "gnewsense"      => "gNewSense",
   "gobo"           => "GoboLinux",
   "gparted"        => "GParted",
   "greenie"        => "Greenie",
   "grml"           => "Grml",
   "guadalinex"     => "Guadalinex",
   "haiku"          => "Haiku",
   "handy"          => "HandyLinux",
   "hanthana"       => "Hanthana",
   "ipcop"          => "IPCop",
   "ipfire"         => "IPFire",
   "kali"           => "Kali",
   "kanotix"        => "KANOTIX",
   "kaos"           => "KaOS",
   "karoshi"        => "Karoshi",
   "kdemar"         => "kademar",
   "knoppix"        => "KNOPPIX",
   "kolibri"        => "KolibriOS",
   "korora"         => "Korora",
   "kubuntu"        => "Kubuntu",
   "kwheezy"        => "Kwheezy",
   "kwort"          => "Kwort",
   "kxstudio"       => "KXStudio",
   "leeenux"        => "Leeenux",
   "legacy"         => "Legacy",
   "lfs"            => "LFS",
   "linex"          => "LinEx",
   "linhes"         => "LinHES",
   "linpus"         => "Linpus",
   "linuxbbq"       => "LinuxBBQ",
   "linuxconsole"   => "LinuxConsole",
   "linuxfx"        => "Linuxfx",
   "liquidlemur"    => "Liquid Lemur",
   "lite"           => "Lite",
   "lliurex"        => "LliureX",
   "lps"            => "LPS",
   "lubuntu"        => "Lubuntu",
   "lunar"          => "Lunar",
   "luninux"        => "LuninuX",
   "lxle"           => "LXLE",
   "madbox"         => "Madbox",
   "mageia"         => "Mageia",
   "makulu"         => "MakuluLinux",
   "mangaka"        => "Mangaka",
   "manjaro"        => "Manjaro",
   "matriux"        => "Matriux",
   "max"            => "MAX",
   "midnightbsd"    => "MidnightBSD",
   "minino"         => "MiniNo",
   "minix"          => "MINIX",
   "mint"           => "Mint",
   "miracle"        => "Miracle",
   "miros"          => "MirOS",
   "momonga"        => "Momonga",
   "musix"          => "Musix",
   "mythbuntu"      => "Mythbuntu",
   "nanolinux"      => "Nanolinux",
   "nas4free"       => "NAS4Free",
   "neptune"        => "Neptune",
   "netbsd"         => "NetBSD",
   "nethserver"     => "NethServer",
   "netrunner"      => "Netrunner",
   "netsecl"        => "NetSecL",
   "nexentastor"    => "NexentaStor",
   "nixos"          => "NixOS",
   "nova"           => "Nova",
   "nst"            => "NST",
   "nutyx"          => "NuTyX",
   "ojuba"          => "Ojuba",
   "olpc"           => "OLPC",
   "omoikane"       => "Omoikane",
   "openbsd"        => "OpenBSD",
   "openelec"       => "OpenELEC",
   "openindiana"    => "OpenIndiana",
   "openlx"         => "OpenLX",
   "openmamba"      => "openmamba",
   "openmandriva"   => "OpenMandriva",
   "openmediavault" => "OpenMediaVault",
   "opensuse"       => "openSUSE",
   "openwall"       => "Openwall",
   "opnsense"       => "OPNsense",
   "oracle"         => "Oracle",
   "osmc"           => "OSMC",
   "overclockix"    => "Overclockix",
   "ozunity"        => "Oz Unity",
   "paldo"          => "paldo",
   "parabola"       => "Parabola",
   "pardus"         => "Pardus",
   "parrotsecurity" => "Parrot Security OS",
   "parsix"         => "Parsix",
   "partedmagic"    => "Parted Magic",
   "pcbsd"          => "PC-BSD",
   "pclinuxos"      => "PCLinuxOS",
   "peachosi"       => "Peach OSI",
   "pelicanhpc"     => "PelicanHPC",
   "pentoo"         => "Pentoo",
   "peppermint"     => "Peppermint",
   "pfsense"        => "pfSense",
   "pidora"         => "Pidora",
   "pinguy"         => "Pinguy",
   "pisi"           => "Pisi",
   "plamo"          => "Plamo",
   "pld"            => "PLD",
   "plop"           => "Plop",
   "point"          => "Point",
   "poliarch"       => "PoliArch",
   "porteus"        => "Porteus",
   "porteuskiosk"   => "Porteus Kiosk",
   "proxmox"        => "Proxmox",
   "puppy"          => "Puppy",
   "q4os"           => "Q4OS",
   "qubes"          => "Qubes",
   "quirky"         => "Quirky",
   "raspbian"       => "Raspbian",
   "reactos"        => "ReactOS",
   "rebellin"       => "Rebellin",
   "redhat"         => "Red Hat",
   "remnux"         => "REMnux",
   "rescatux"       => "Rescatux",
   "risc"           => "RISC",
   "robolinux"      => "Robolinux",
   "rockscluster"   => "Rocks Cluster",
   "rockstor"       => "Rockstor",
   "rosa"           => "ROSA",
   "runtu"          => "Runtu",
   "sabayon"        => "Sabayon",
   "salentos"       => "SalentOS",
   "salix"          => "Salix",
   "scientific"     => "Scientific",
   "securepoint"    => "Securepoint",
   "selks"          => "SELKS",
   "semplice"       => "Semplice",
   "siduction"      => "siduction",
   "simplicity"     => "Simplicity",
   "skolelinux"     => "Skolelinux",
   "slackel"        => "Slackel",
   "slackware"      => "Slackware",
   "sle"            => "SUSE",
   "slitaz"         => "SliTaz",
   "smartos"        => "SmartOS",
   "smeserver"      => "SME Server",
   "smoothwall"     => "Smoothwall",
   "sms"            => "SMS",
   "solaris"        => "Solaris",
   "solus"          => "Solus",
   "solydxk"        => "SolydXK",
   "sonar"          => "Sonar",
   "sophos"         => "Sophos",
   "sourcemage"     => "Source Mage",
   "sparky"         => "SparkyLinux",
   "springdale"     => "Springdale",
   "steamos"        => "SteamOS",
   "stella"         => "Stella",
   "sulix"          => "SuliX",
   "superx"         => "SuperX",
   "symphony"       => "SymphonyOS",
   "systemrescue"   => "SystemRescue",
   "t2"             => "T2",
   "tails"          => "Tails",
   "tanglu"         => "Tanglu",
   "thinstation"    => "Thinstation",
   "tinycore"       => "Tiny Core",
   "toutou"         => "Toutou",
   "trisquel"       => "Trisquel",
   "turbolinux"     => "Turbolinux",
   "turnkey"        => "TurnKey",
   "uberstudent"    => "UberStudent",
   "ubuntu"         => "Ubuntu",
   "ubuntudp"       => "Ubuntu DP",
   "ubuntugnome"    => "Ubuntu GNOME",
   "ubuntukylin"    => "Ubuntu Kylin",
   "ubuntumate"     => "Ubuntu MATE",
   "ubuntupr"       => "UPR",
   "ubuntustudio"   => "Ubuntu Studio",
   "uhu"            => "UHU-Linux",
   "ulteo"          => "Ulteo",
   "ultimate"       => "Ultimate",
   "unity"          => "Unity",
   "univention"     => "Univention",
   "untangle"       => "Untangle",
   "vector"         => "Vector",
   "vine"           => "Vine",
   "void"           => "Void",
   "volumio"        => "Volumio",
   "vortexbox"      => "VortexBox",
   "voyager"        => "Voyager",
   "vyos"           => "VyOS",
   "wattos"         => "wattOS",
   "webconverger"   => "Webconverger",
   "wifislax"       => "Wifislax",
   "wmlive"         => "WM Live",
   "xange"          => "Open Xange",
   "xstreamos"      => "XStreamOS",
   "xubuntu"        => "Xubuntu",
   "zentyal"        => "Zentyal",
   "zenwalk"        => "Zenwalk",
   "zeroshell"      => "Zeroshell",
   "zevenos"        => "ZevenOS",
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

This document describes version 0.05 of WWW::DistroWatch::ReleaseInfo (from Perl distribution WWW-DistroWatch-ReleaseInfo), released on 2015-10-06.

=head1 FUNCTIONS


=head2 get_distro_releases_info(%args) -> [status, msg, result, meta]

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


=head2 list_distros(%args) -> [status, msg, result, meta]

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


=head2 list_distros_cached() -> [status, msg, result, meta]

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

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
