#!perl
use strict;
use warnings;
use feature qw/ say /;;
use Test::More;
use Carp qw/ confess /;
use Fcntl;
use File::Temp;
my $open_file = File::Temp->new->filename;
my $sysopen_file = File::Temp->new->filename;
my (%open_hash, %sysopen_hash);
use overload::open;

BEGIN {
    sub get_filename_sysopen {
        if ($_[1]) {
            return $_[1];
        }
        else {
            return undef;
        }
    }
    sub get_filename_open {
        if (@_ == 3) {
            return $_[2];
        }
        elsif (@_ == 2) {
            return $_[1];
        }
        else {
            return undef;
        }
    }
    sub record_opened_file_open {
        record_opened_file(\%open_hash, \&get_filename_open, @_);
    }
    sub record_opened_file_sysopen{
        record_opened_file(\%sysopen_hash, \&get_filename_sysopen, @_);
    }
    sub record_opened_file {
        my $hash = shift;
        my $get_filename = shift;
        my $filename = $get_filename->(@_);
        return if !defined $filename;
        $hash->{$filename} = 1;
    }
    overload::open->prehook_open(\&record_opened_file_open);
    overload::open->prehook_sysopen(\&record_opened_file_sysopen);
}
my $sysopen_fh;
sysopen $sysopen_fh, $sysopen_file, O_RDONLY;
open my $fh99, '>', "$open_file";
is $open_hash{$open_file}, 1, "file opened with open() is in open hash";
is $sysopen_hash{$sysopen_file}, 1, "file opened with sysopen() is in sysopen hash";
is keys %sysopen_hash, 1, "Correct number of keys in sysopen hash";
is keys %open_hash, 1, "Correct number of keys in open hash";
done_testing();
