# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# $Id: test.pl,v 1.4 2000/05/02 16:07:48 ssnodgra Exp $

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..58\n"; }
END {print "not ok 1\n" unless $loaded;}
use Unix::AliasFile;
use Unix::AutomountFile;
use Unix::GroupFile;
use Unix::PasswdFile;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
$num = 2;

#
# Unix::PasswdFile tests
#

# Test 2 - initialize PasswdFile object
print `cp passwd.orig passwd`;
chmod 0644, "passwd";
$pw = new Unix::PasswdFile "./passwd";
$status = defined $pw ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 3 - locking test
$pw2 = new Unix::PasswdFile "./passwd";
$status = !defined $pw2 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 4 - passwd accessor
$status = $pw->passwd("lp") eq "x" ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 5 - uid accessor
$status = $pw->uid("adm") == 4 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 6 - gid accessor
$status = $pw->gid("sys") == 3 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 7 - gecos accessor
$status = $pw->gecos("myself") eq "Me" ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 8 - home accessor
$status = $pw->home("adm") eq "/usr/adm" ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 9 - shell accessor
$status = $pw->shell("root") eq "/bin/csh" ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 10 - add user
$pw->user("test", "*", 8192, 2048, "Testy Test", "/home/test", "/bin/ksh");
$status = $pw->uid("test") == 8192 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 11 - modify user
$pw->uid('test', 2112);
$status = $pw->uid("test") == 2112 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 12 - delete user
$pw->delete("myself");
$status = !defined $pw->user("myself") ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 13 - access undefined data
$status = !defined $pw->uid("myself") ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 14 - get maximum uid
$status = $pw->maxuid == 60001 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 15 - get maximum uid with ignore
$status = $pw->maxuid(60000) == 2112 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 16 - get list of users
$status = $pw->users == 8 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 17 - commit the file
$pw->commit();
$status = !`diff passwd passwd.test` ? "ok" : "not ok";
print "$status ", $num++, "\n";
unlink "passwd";

#
# Unix::GroupFile tests
#

# Test 18 - initialize GroupFile object
print `cp group.orig group`;
chmod 0644, "group";
$grp = new Unix::GroupFile "./group";
$status = defined $grp ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 19 - locking test
$grp2 = new Unix::GroupFile "./group";
$status = !defined $grp2 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 20 - gid accessor
$status = $grp->gid("staff") == 10 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 21 - passwd accessor
$status = $grp->passwd("daemon") eq "*" ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 22 - add group
$grp->group("mygroup", "", 5150, "root", "johndoe", "bongo");
$status = $grp->gid("mygroup") == 5150 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 23 - add users to group
$grp->add_user("mygroup", "dude1", "dude2");
$status = $grp->members("mygroup") == 5 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 24 - remove users from group
$grp->remove_user("mygroup", "root");
$status = $grp->members("mygroup") == 4 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 25 - remove users from all groups
$grp->remove_user("*", "bin");
$status = $grp->members("sys") == 3 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 26 - modify group
$grp->group("staff", "*", 20, "dilbert", "wally", "alice");
$status = $grp->members("staff") == 3 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 27 - illegal attempt to reuse GID
$status = !$grp->gid("mygroup", 20) ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 28 - delete group
$grp->delete("tty");
$status = !$grp->group("tty") ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 29 - get maximum GID
$status = $grp->maxgid == 65534 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 30 - get list of groups
$status = $grp->groups == 16 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 31 - rename a user
$status = $grp->rename_user("adm", "admin") == 3 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 32 - commit the file
$grp->commit();
$status = !`diff group group.test` ? "ok" : "not ok";
print "$status ", $num++, "\n";
unlink "group";

#
# Unix::AliasFile tests
#

# Test 33 - initialize AliasFile object
print `cp aliases.orig aliases`;
chmod 0644, "aliases";
$al = new Unix::AliasFile "./aliases";
$status = defined $al ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 34 - locking test
$al2 = new Unix::AliasFile "./aliases";
$status = !defined $al2 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 35 - alias accessor
$status = $al->alias("staff") == 18 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 36 - add alias
$al->alias("stooges", qw(larry curly moe));
$status = $al->alias("stooges") == 3 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 37 - add users to alias
$al->add_user("webmaster", "webguy", "perlgod", "webby");
$status = $al->alias("webmaster") == 4 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 38 - remove users from alias
$al->remove_user("staff", qw(sklower olson bogon test2));
$status = $al->alias("staff") == 14 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 39 - remove users from all aliases
$al->remove_user("*", "owner1");
$status = $al->alias("owner-mylist-l") == 2 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 40 - access undefined data
$status = !defined $al->alias("noalias") ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 41 - modify alias
$al->alias("root", ":include:/lists/superusers");
$status = $al->alias("root") == 1 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 42 - delete alias
$al->delete("abuse");
$status = !defined $al->alias("abuse") ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 43 - get list of aliases
$status = $al->aliases == 20 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 44 - add comment
$ret = $al->comment("stooges", "# Funny guys");
$status = $ret ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 45 - remove comment
$ret = $al->uncomment("# Sample aliases:");
$status = $ret ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 46 - rename user
$status = $al->rename_user("perlgod", "lwall") == 1 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 47 - commit the file
$al->commit();
$status = !`diff aliases aliases.test` ? "ok" : "not ok";
print "$status ", $num++, "\n";
unlink "aliases";

#
# Unix::AutomountFile tests
#

# Test 48 - initialize AutomountFile object
print `cp auto_home.orig auto_home`;
chmod 0644, "auto_home";
$am = new Unix::AutomountFile "./auto_home";
$status = defined $am ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 49 - locking test
$am2 = new Unix::AutomountFile "./auto_home";
$status = !defined $am2 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 50 - options accessor
$status = $am->options("fsi") eq "-rw,intr" ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 51 - add automount point
$am->automount("bozo", "fileserv1:/users/&", "fileserv2:/users/&");
$status = $am->automount("bozo") == 2 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 52 - add servers to existing automount point
$am->add_server("bozo", "fileserv3:/users/&");
$status = $am->automount("bozo") == 3 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 53 - change automount options
$am->options("bozo", "-rw,nosuid");
$status = $am->options("bozo") eq "-rw,nosuid" ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 54 - modify automount point
$am->automount("ssnodgra", $am->automount("bozo"));
$status = $am->automount("ssnodgra") == 3 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 55 - delete automount point
$am->delete("bigguy");
$status = !defined $am->automount("bigguy") ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 56 - get list of mount points
$status = $am->automounts == 6 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 57 - rename mount point
$am->rename("coolguy", "linus");
$status = $am->automount("linus") == 1 ? "ok" : "not ok";
print "$status ", $num++, "\n";

# Test 58 - commit the file
$am->commit();
$status = !`diff auto_home auto_home.test` ? "ok" : "not ok";
print "$status ", $num++, "\n";
unlink "auto_home";
