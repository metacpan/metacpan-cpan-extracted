#!perl
use strict;
use warnings;
use feature qw/ say /;;
use Test::More;
use Carp qw/ confess /;
use Fcntl;
use File::Temp;
my $open_file = File::Temp->new->filename;
my $open_file2 = File::Temp->new->filename;
my $sysopen_file = File::Temp->new->filename;
my $sysopen_file2 = File::Temp->new->filename;
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
        $hash->{$filename}++;
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

###
my $string_eval_sysopen_passes = 0;
eval 'sysopen(my $sysopen_fh2, $sysopen_file2, O_RDWR|O_CREAT) or die $!; close $sysopen_fh2 or die $!; $string_eval_sysopen_passes = 1'
    or do { $string_eval_sysopen_passes = 0; warn $@ || "zombie error" };
is $string_eval_sysopen_passes, 1, "Does not die when calling sysopen inside string eval";
###
my $string_eval_open_passes = 1;
eval 'open(my $open_fh2, ">", $open_file2) or die $!; $string_eval_open_passes = 1; close $open_fh2 or die $!; 1'
    or do { $string_eval_open_passes = 0; warn $@ || "zombie error" };
is $string_eval_open_passes, 1, "Does not die when calling open inside string eval";
###
is $open_hash{$open_file2}, 1, "file opened with open() is in open hash";
is $sysopen_hash{$sysopen_file2}, 1, "file opened with sysopen() is in sysopen hash";
is keys %sysopen_hash, 2, "Correct number of keys in sysopen hash";
is keys %open_hash, 2, "Correct number of keys in open hash";

#### For even more fun. Make sure if we die inside the hook we don't interfere with the open call
overload::open->prehook_open(sub { die });
overload::open->prehook_sysopen(sub { die });
%open_hash = ();
%sysopen_hash = ();
###
$string_eval_sysopen_passes = 0;
eval 'sysopen(my $sysopen_fh2, $sysopen_file2, O_RDWR|O_CREAT) or die $!; close $sysopen_fh2 or die $!; $string_eval_sysopen_passes = 1'
    or do { $string_eval_sysopen_passes = 0; warn $@ || "zombie error" };
is $string_eval_sysopen_passes, 1, "Does not die when calling sysopen inside string eval";
###
$string_eval_open_passes = 1;
eval 'open(my $open_fh2, ">", $open_file2) or die $!; $string_eval_open_passes = 1; close $open_fh2 or die $!; 1'
    or do { $string_eval_open_passes = 0; warn $@ || "zombie error" };
is $string_eval_open_passes, 1, "Does not die when calling open inside string eval";
###
done_testing();
