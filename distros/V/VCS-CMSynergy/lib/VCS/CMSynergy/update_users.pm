# update($current_users_file, $old_md5, $new_users_file)
#
# to be used as
#
#       # write new users to tmpfile
#       ccm set text_editor 'perl -e "require VCS::CMSynergy::update_users; update(@ARGV)" %filename d71307df31aa26a0ba8d4bd584dd6bbd tmpfile'
#       ccm users
#
# $current_users_file   Synergy will write the current value of users
#                       to this file and read the new value from it
#                       when this command exits OK
#
# $old_md5              md5 checksum (in hex) of value of users that was
#                       last fetched by VCS::CMSynergy.pm
#
# $new_users_file       file containing new value of users
#
# program checks current_users_file against old_md5; if they agree copies
# new_users_file to current_users_file and exits 0, otherwise exists 1;
# this is to ensure that users has not changed since  VCS::CMSynergy last fetched it

use strict;
use warnings;
use File::Copy;
use Digest::MD5 qw(md5_hex);

sub update
{
    my ($current_users_file, $old_md5, $new_users_file) = @_;

    my $current_users;
    {
        local $/ = undef;               # slurp in whole file
        open my $fh, "<", $current_users_file
            or die "can't open `$current_users_file': $!";
        $current_users = <$fh>;
        close $fh;
    }
    chomp($current_users);              # because VCS::CMSynergy also did chomp

    die "Conflicting change to users list detected\n"
        unless md5_hex($current_users) eq $old_md5;

    copy($new_users_file, $current_users_file)
        or die "copy($new_users_file, $current_users_file) failed: $!";

    exit(0);
}

1;

