#!/usr/local/bin/perl -w

# grouper.pl - Manipulate the group file
# $Id: grouper.pl,v 1.1 1999/07/01 14:25:54 ssnodgra Exp $

use Unix::GroupFile;

unless (@ARGV > 1) {
    print "Instructions:\n";
    print "$0 -a group user ...     Add users to group\n";
    print "$0 -c group user ...     Create new group\n";
    print "$0 -r group user ...     Remove users from group\n";
    exit;
}

$grp = new Unix::GroupFile("/etc/group") or die "Can't open group file";
$option = shift;
$group = shift;
die "Bad group name: $group\n" unless $group =~ /^[a-z][a-z\d]{1,7}$/;
if ($option eq "-a") {	    # Add users to group
    $grp->add_user($group, @ARGV) or die "Add failed\n";
}
elsif ($option eq "-c") {
    die "Group $group already exists\n" if defined $grp->gid($group);
    $grp->group($group, "*", $grp->maxgid + 1, @ARGV);
}
elsif ($option eq "-r") {
    $grp->remove_user($group, @ARGV) or die "Remove failed\n";
}
else {
    die "Bogus option $option\n";
}

print "Rewriting group file...\n";
$grp->commit(backup => '~');
print "Done!\n";
