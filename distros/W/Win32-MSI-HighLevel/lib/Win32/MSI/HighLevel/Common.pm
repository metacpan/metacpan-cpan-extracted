use strict;
use warnings;

=head1 NAME

Win32::MSI::HighLevel::Common - Helper module for Win32::MSI::HighLevel.

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


package Win32::MSI::HighLevel::Common;

use Exporter 'import';
use Digest::MD5 qw(md5_hex);

BEGIN {
    use Carp;

    push our @CARP_NOT, qw(
        Win32::MSI::HighLevel::Handle
        Win32::MSI::HighLevel
        );
}

our @EXPORT_OK = qw(
    kMSIDBOPEN_READONLY kMSIDBOPEN_TRANSACT kMSIDBOPEN_DIRECT kMSIDBOPEN_CREATE
    kMSIDBOPEN_CREATEDIRECT

    kMSICOLINFO_NAMES kMSICOLINFO_TYPES k_MSICOLINFO_INDEX

    kMSITR_IGNORE_ADDEXISTINGROW kMSITR_IGNORE_DELMISSINGROW
    kMSITR_IGNORE_ADDEXISTINGTABLE kMSITR_IGNORE_DELMISSINGTABLE
    kMSITR_IGNORE_UPDATEMISSINGROW kMSITR_IGNORE_CHANGECODEPAGE
    kMSITR_VIEWTRANSFORM

    kMSITR_IGNORE_ALL
    );

use constant kMSIDBOPEN_READONLY => 0;
use constant kMSIDBOPEN_TRANSACT => 1;
use constant kMSIDBOPEN_DIRECT => 2;
use constant kMSIDBOPEN_CREATE => 3;
use constant kMSIDBOPEN_CREATEDIRECT => 4;

use constant kMSICOLINFO_NAMES => 0;
use constant kMSICOLINFO_TYPES => 1;
use constant k_MSICOLINFO_INDEX => 21231231;    # For own use, not defined by MS

use constant kMSITR_IGNORE_ADDEXISTINGROW => 0x1;
use constant kMSITR_IGNORE_DELMISSINGROW => 0x2;
use constant kMSITR_IGNORE_ADDEXISTINGTABLE => 0x4;
use constant kMSITR_IGNORE_DELMISSINGTABLE => 0x8;
use constant kMSITR_IGNORE_UPDATEMISSINGROW => 0x10;
use constant kMSITR_IGNORE_CHANGECODEPAGE => 0x20;
use constant kMSITR_VIEWTRANSFORM => 0x100;

use constant kMSITR_IGNORE_ALL =>
  kMSITR_IGNORE_ADDEXISTINGROW |
  kMSITR_IGNORE_DELMISSINGROW |
  kMSITR_IGNORE_ADDEXISTINGTABLE |
  kMSITR_IGNORE_DELMISSINGTABLE |
  kMSITR_IGNORE_UPDATEMISSINGROW |
  kMSITR_IGNORE_CHANGECODEPAGE;

# Shorthand to define API call constants
sub _def {
    return Win32::API->new("msi", @_, "I") || die $!;
}


sub listize {
    my ($hash, @keys) = @_;

    for my $key (@keys) {
        $hash->{"-${key}s"} = [$hash->{"-$key"}]
            if ! exists $hash->{"-${key}s"} and exists $hash->{"-$key"};
    }
}


sub require {
    my ($hash, @keys) = @_;

    for (@keys) {
        next if exists $hash->{$_};

        my ($package, $filename, $line, $subroutine) = caller 1;

        croak ("$subroutine requires a $_ parameter", 1);
    }
}


sub allow {
    my ($hash, @keys) = @_;
    my %okKeys = map {$_ => undef} @keys;

    for (keys %$hash) {
        next if exists $okKeys{$_};

        my ($package, $filename, $line, $subroutine) = caller 1;

        croak ("$subroutine does not allow $_ as a parameter");
    }
}


sub noneOf {
    my ($hash, @keys) = @_;

    return 0 == grep {exists $hash->{$_}} @keys;
}


sub someOf {
    my ($hash, @keys) = @_;

    return scalar grep {exists $hash->{$_}} @keys;
}


# Generate a GUID given a string
sub genGUID {
    my $seed = shift;
    my $md5 = uc md5_hex ($seed);
    my @octets = $md5 =~ /(.{2})/g;

    substr $octets[6], 0, 1, '4'; # GUID Version 4
    substr $octets[8], 0, 1, '8'; # draft-leach-uuids-guids-01.txt GUID variant
    my $GUID = "{@octets[0..3]-@octets[4..5]-@octets[6..7]-@octets[8..9]-@octets[10..15]}";

    $GUID =~ s/ //g;
    return $GUID;
}


1;
