package Test::Smoke::Util::FindHelpers;
use warnings;
use strict;

our $VERSION = '0.001';

=head1 NAME

Test::Smoke::Util::FindHelpers - Functions to help find Helpers (modules/bins)

=head1 SYNOPSIS

    use Test::Smoke::Util::FindHelpers ':all';

=cut

use Config;
use Test::Smoke::Util 'whereis';

=head1 EXPORT_OK/EXPORT_TAGS

    has_module whereis
    get_avail_tar get_avail_patchers
    get_avail_posters get_avail_sync get_avail_mailers
    get_avail_w32compilers
    get_avail_vms_make

    :all
=cut

use Exporter 'import';
our @EXPORT_OK = qw/
    has_module whereis
    get_avail_tar get_avail_patchers
    get_avail_posters get_avail_sync get_avail_mailers
    get_avail_w32compilers
    get_avail_vms_make
/;
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],

);

=head1 DESCRIPTION

=head2 has_module($module)

Retuns true if the named module could be C<require>d.

=cut

sub has_module {
    my ($module) = @_;
    { local $^W; eval "require $module"; }
    return !$@;
}

=head2 get_avail_patchers

Returns a list of available patch programs (gpatch npatch patch)

=cut

sub get_avail_patchers {
    my @patchers;

    foreach my $patcher (qw( gpatch npatch patch )) {
        if (my $patch_bin = whereis($patcher)) {
            my $version = `$patch_bin -version`;
            $? or push @patchers, $patch_bin;
        }
    }
    return @patchers;
}

=head2 get_avail_posters

Return a list of available modules/programs that can be used to HTTP/POST a message.
(HTTP::Tiny, LWP::UserAgent, curl)

=cut

sub get_avail_posters {
    my @posters;

    my @modules = qw/HTTP::Tiny LWP::UserAgent/;
    for my $module (@modules) {
        push @posters, $module if has_module($module);
    }
    push @posters, 'curl', if whereis('curl');

    return @posters;
}

=head2 get_avail_sync

Returns a list of available syncer modules/programs (git, rsync)

=cut

sub get_avail_sync {
    my @synctype = qw(copy hardlink snapshot);

    unshift @synctype, 'rsync' if whereis('rsync');

    unshift @synctype, 'git' if whereis('git');

    return @synctype;
}

=head2 get_avail_tar

Returns a list of available untar/ungzip modules/programs (Archive::Tar/...Zlib, tar/gzip)

=cut

sub get_avail_tar {
    my $use_modules = 0;

    my $has_archive_tar = has_module('Archive::Tar');
    if ($has_archive_tar) {
        if ( eval "$Archive::Tar::VERSION" >= 0.99 ) {
            $use_modules = has_module('IO::Zlib');
        } else {
            $use_modules = has_module('Compress::Zlib');
        }
    }

    my $fmt = tar_fmt();

    return $fmt && $use_modules
        ? ( $fmt, 'Archive::Tar' )
        : $fmt ? ( $fmt ) : $use_modules ? ( 'Archive::Tar' ) : ();
}

=head2 tar_fmt

Returns the format with wich to gunzip and untar.
(gzip -cd %s | tar -xf -) or (tar -xzf %s)

=cut

sub tar_fmt {
    my $tar  = whereis( 'tar' );
    my $gzip = whereis( 'gzip' );

    return $tar && $gzip
        ? "$gzip -cd %s | $tar -xf -"
        : $tar ? "tar -xzf %s" : "";
}

=head2 get_avail_mailers

Returns a list available mail modules/programs.

=cut

sub get_avail_mailers {
    my %map;

    for my $mailer (qw/mail mailx sendmail sendemail/) {
        local $ENV{PATH} = "$ENV{PATH}$Config{path_sep}/usr/sbin";
        if (my $mailer_bin = whereis($mailer)) {
            $map{$mailer} = $mailer_bin;
        }
    }

    for my $module (qw/Mail::Sendmail MIME::Lite/) {
        $map{$module} = $module if has_module($module);
    }
    return %map;
}

=head2 get_avail_w32compilers

Returns a list of compilers found (Win32 specific)

=cut

sub get_avail_w32compilers {

    my %map = (
        MSVC => { ccname => 'cl',    maker => [ 'nmake' ] },
        BCC  => { ccname => 'bcc32', maker => [ 'dmake' ] },
        GCC  => { ccname => 'gcc',   maker => [ 'dmake', 'gmake' ] },
    );

    my $CC = 'MSVC';
    if ( $map{ $CC }->{ccbin} = whereis( $map{ $CC }->{ccname} ) ) {
        # No, cl doesn't support --version (One can but try)
        my $output =`$map{ $CC }->{ccbin} --version 2>&1`;
        my $ccvers = $output =~ /^.*Version\s+([\d.]+)/ ? $1 : '?';
        $map{ $CC }->{ccversarg} = "ccversion=$ccvers";
        my $mainvers = $ccvers =~ /^(\d+)/ ? $1 : 1;
        $map{ $CC }->{CCTYPE} = $mainvers < 12 ? 'MSVC' : 'MSVC60';
    }

    $CC = 'BCC';
    if ( $map{ $CC }->{ccbin} = whereis( $map{ $CC }->{ccname} ) ) {
        # No, bcc32 doesn't support --version (One can but try)
        my $output = `$map{ $CC }->{ccbin} --version 2>&1`;
        my $ccvers = $output =~ /([\d.]+)/ ? $1 : '?';
        $map{ $CC }->{ccversarg} = "ccversion=$ccvers";
        $map{ $CC }->{CCTYPE} = 'BORLAND';
    }

    $CC = 'GCC';
    if ( $map{ $CC }->{ccbin} = whereis( $map{ $CC }->{ccname} ) ) {
        local *STDERR;
        open STDERR, ">&STDOUT"; #do we need an error?
        select( (select( STDERR ), $|++ )[0] );
        my $output = `$map{ $CC }->{ccbin} --version`;
        my $ccvers = $output =~ /(\d+.*)/ ? $1 : '?';
        $ccvers =~ s/\s+copyright.*//i;
        $map{ $CC }->{ccversarg} = "gccversion=$ccvers";
        $map{ $CC }->{CCTYPE} = $CC
    }

    return map {
       ( $map{ $_ }->{CCTYPE} => $map{ $_ } )
    } grep length $map{ $_ }->{ccbin} => keys %map;
}

=head2 get_avail_vms_make

Return a list of "make" programs installed on the VMS system.

=cut

sub get_avail_vms_make {

    return map +( $_ => undef ) => grep defined $_ && length( $_ )
        => map whereis( $_ ) => qw( MMK MMS );

    local *QXERR; open *QXERR, ">&STDERR"; close STDERR;

    my %makers = map {
        my $maker = $_;
        map +( $maker => /V([\d.-]+)/ ? $1 : '' )
        => grep /\b$maker\b/ && /V[\d.-]+/ => qx($maker/IDENT)
    } qw( MMK MMS );

    open STDERR, ">&QXERR"; close QXERR;

    return %makers;
}

1;

=head1 COPYRIGHT

(c) MMII - MMXV, The Test-Smoke Team <abeltje@cpan.org>

See L<Test::Smoke> for full acknowlegements.

=cut
