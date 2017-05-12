package DropTest;

# $Id: DropTest.pm,v 1.1 2006/04/25 21:38:19 robertemay Exp $
# package to hide away the complexity of generating a WM_DROPEVENT on a window.
# Written by Robert May, April 2006
#
# This would be an ideal candidate for implementing in XS within a Win32::GUI::Test
# module
#


use strict;
use warnings;

use Win32();
use Win32::GUI();
use Win32::API();

Win32::API->Import('Kernel32', 'GlobalAlloc', 'LL', 'L') || die "No GlobalAlloc: $^E";
Win32::API->Import('Kernel32', 'GlobalLock', 'L', 'L') || die "No GlobalLock: $^E";
Win32::API->Import('Kernel32', 'GlobalUnlock', 'L', 'L') || die "No GlobalUnlock: $^E";
Win32::API->Import('Kernel32', 'GlobalFree', 'L', 'L') || die "No GlobalFree: $^E";
Win32::API->Import('Kernel32', 'GlobalFlags', 'L', 'L') || die "No GlobalFree: $^E";
Win32::API->Import("kernel32", "RtlMoveMemory", "LPI", "V") || die "No RtlMoveMemory: $^E";

sub WM_DROPFILES() {563}
sub NO_ERROR()     {0}
sub GHND()         {0x0042} # GHND = GMEM_MOVEABLE|GMEM_ZERO_INIT = 0x0042
sub GMEM_INVALID_HANDLE() {32768}

sub new {
    my $class = shift;
    my %options = @_;

    $options{x} ||= 0;
    $options{y} ||= 0;
    $options{wide} ||= 0;
    $options{client} = 1 unless defined $options{client};
    my $files = [];
    if(exists $options{files}) {
        if(ref($options{files}) eq "ARRAY") {
            for my $file (@{$options{files}}) {
                push @{$files}, $file;
            }
        }
        else {
            die("files option must be an array ref");
        }
    }
    else {
        $files = ['File1', 'File2', 'File3',];
    }
    if($options{wide}) {
        require Unicode::String; # use this in place of Encode, as Encode does not ship with Perl 5.6
        for my $file (@{$files}) {
            $file = Unicode::String::utf8($file)->byteswap->ucs2;
        }
    }
    $options{files} = $files;

    return bless \%options, $class;
}

sub PostDropMessage {
    my ($self,$dest) = @_;

    # always create a new handle, as the receiver is supposed to  free it.
    my $hdrop = $self->_create_new_drop_handle();

    $dest->PostMessage(WM_DROPFILES, $hdrop, 0);

    # The recieving process should free the hdrop handle,
    # and the handle should be invalid sometime after this call
    # Check using isFree before calling PostDropMessage again

    return;
}

# return TRUE if the hdrop handle associated with the object is freed (invalid)
# if not freed, free it and return false
sub Free {
    my ($self) = @_;

    my $hdrop = $self->{hdrop};

    return 1 unless $hdrop;

    my $locks = GlobalFlags($hdrop);
    delete $self->{hdrop};

    return 1 if $locks == GMEM_INVALID_HANDLE;

    GlobalFree($hdrop);

    return 0;
}

sub _create_new_drop_handle
{
    my ($self) = @_;

    # Free any previous handle, and warn us if it wasn't freed
    if(!$self->Free()) {
        warn "Old drop handle not freed - check for error";
    }

    # DROPFILES struct:
    # typedef struct _DROPFILES {
    #   DWORD pFiles;
    #   POINT pt;
    #   BOOL fNC;
    #   BOOL fWide;
    # } DROPFILES, *LPDROPFILES;
    # followed by double NULL terminated string structure

    my $term = "x";
    $term = "xx" if $self->{wide};

    my $buffer = pack("LLLLL" . "a*$term" x @{$self->{files}} . $term,
               20,    # sizeof(DROPFILES) - string ptr offset
               $self->{x},
               $self->{y},
               $self->{client} ? 0 : 1,
               $self->{wide} ? 1 : 0,
               @{$self->{files}},
           );

    my $size = length($buffer);

    my $hdrop = GlobalAlloc(GHND, $size) or die "GlobalAlloc failed: $^E";
    my $ptr = GlobalLock($hdrop)         or die "GlobalLock failed: $^E";
    RtlMoveMemory($ptr, $buffer, $size);
    GlobalUnlock($hdrop);
    return $self->{hdrop} = $hdrop;
}

sub dump {
    my $self = shift;

    if($self->{hdrop}) {
        my $hdrop = $self->{hdrop};
        print "Dumping handle: $hdrop\n";

        my $ptr = GlobalLock($hdrop);
        die "GlobalLock failed: $^E" unless $ptr;

        # Get the header (HROPFILES) structure
        my ($poff, $x, $y, $nc, $fwide) = unpack("LLLLL", unpack("P20", pack("L", $ptr)));
        print "  poff:\t$poff\n";
        print "  x:\t$x\n";
        print "  y:\t$y\n";
        print "  nc:\t$nc\n";
        print "  wide:\t$fwide\n";

        my $count = 0;
        $ptr += $poff;

        # This is probably hideously slow, but as it's only for debug ...
        my $pack_str = "C";
        my $char_len = 1;
        if($fwide) {
            $pack_str = "v";
            $char_len = 2;
        }
        my $last_char_null = 0;
        my $file = "";
        while(1) {
            my $char = unpack($pack_str, unpack("P$char_len", pack("L", $ptr)));
            $ptr += $char_len;

            last if $last_char_null && $char == 0;

            if($char == 0) {
                $last_char_null = 1;
                printf "  File $count: $file [%vx]\n", $file;
                $count++;
                $file = "";
                next;
            }

            $last_char_null = 0;
            $file .= chr $char;
        }

        GlobalUnlock($hdrop);
    }
    else {
        print "No data to dump\n";
    }
    return;
}

sub DESTROY
{
    # free the handle if necessary
    $_[0]->Free();
}

# Static function to determine if a drop handle is valid or not
sub isValidHandle
{
    my $handle = shift;

    my $locks = GlobalFlags($handle);
    return 0 if $locks == GMEM_INVALID_HANDLE;
    return 1;
}
1; # End of DropTest.pm
