#!/usr/bin/perl -wT
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Video-TeletextDB.t'

use warnings;
use strict;
use Cwd;
use File::Temp qw(tempdir);
use File::Path qw(rmtree);

BEGIN {
    umask 0027;
};
use POSIX qw(ENOENT EACCES EISDIR EPERM);
my $ENOENT = quotemeta($! = ENOENT  || die "No ENOENT value");
my $EACCES = quotemeta($! = EACCES  || die "No EACCES value");
my $EISDIR = quotemeta($! = EISDIR  || die "No EISDIR value");
my $EPERM  = quotemeta($! = EPERM   || die "No EPERM value");

use Test::More "no_plan";
BEGIN { use_ok('Video::TeletextDB::Constants') };
BEGIN { use_ok('Video::TeletextDB::Parameters') };
BEGIN { use_ok('Video::TeletextDB::Access') };
BEGIN { use_ok('Video::TeletextDB') };
BEGIN { use_ok("t::Input") };

my $test_dir = "teletest";
my $temp_dir = tempdir(CLEANUP => 1);
my $taint = substr($0, 0, 0);
$ENV{HOME} = "$temp_dir/$test_dir$taint";

chdir($temp_dir) || die "Could not chdir to $temp_dir: $!"; 
END { 
    # Try to leave so directory cleanup will work on an OS that cares
    chdir("/");
}

# Try to make a new object without parameters
eval { Video::TeletextDB->new };
like($@, qr/Insecure dependency/, "Creating in curdir should be insecure");
$ENV{HOME} =~ /(.+)/s || die "No HOME='$ENV{HOME}' match ??";
my $home = $ENV{HOME} = $1;
like($home, qr!^/!, "home is absolute");
unlike($home, qr!/\z!, "home does not end on a /");

my $def_dir = "$home/.TeletextDB/cache";

sub list_files {
    my $dir = shift;
    opendir(my $dh, $dir) || die "Could not opendir $dir: $!";
    return grep $_ ne "." && $_ ne "..", sort map lc, readdir($dh);
}

sub blow_home {
    # Just some extreme paranoia so we don't blow away e.g. the user homedir
    $home =~ /\0/ && die "home $home contains a nul character";
    $home =~ m!/\Q$test_dir\E\z! ||
        die "home '$home' is unexpected versus '$test_dir'";
    rmtree($home);
}

sub rand_flag {
    return rand() < 1/3 ? undef : rand() < 0.5 ? 1 : 0;
}

sub test_accessor {
    my $object = shift;
    my $final = shift;
    for my $attr (@_) {
        my $old = $object->$attr;
        for (0, 1, 1, undef, 1, 0, undef, undef, $final) {
            is($object->$attr($_), $old,
               sprintf("Changing %s from %s to %s", $attr,
                       defined $old ? $old : "undef",
                       defined($_) ? $_ : "undef"));
            $old = $_;
        }
        is($object->$attr, $final, "Fetching last $attr");
    }
}

# Check all combinations of umask, dir and mkpath
for my $dir (undef, "$home/bar") {
    my $def_dir = $dir || "$home/.TeletextDB/cache";
    for my $mask (undef, 0077) {
        # Create a default dir
        for my $mkpath (undef, 0, 1) {
            my $creates = 0;
            for (1..4) {
                my $tele = eval {
                    Video::TeletextDB->new
                        ($mask ? (umask => $mask) : (),
                         $dir ? (cache_dir => $dir) :
                         $_ == 1 || $_ == 4 ? (cache_dir => undef) : (),
                         defined $mkpath ? (mkpath=>$mkpath) : ()) };
                if (($dir || $_ == 1) && !$mkpath ||
                    defined($mkpath) && $mkpath == 0) {
                    like($@, qr/No visible directory named/);
                    ok(!-e $def_dir, "Directory not created");
                    next;
                }
                isa_ok($tele, "Video::TeletextDB", "Right class");
                is($tele->cache_dir, "$def_dir/", "Proper dir");
                is($tele->umask, $mask, "Proper mask");

                my @stat = lstat($def_dir) or die "lstat $def_dir: $!";
                ok(-d _, "Is a directory");
                is($stat[2] & 07777, defined($mask) ? 0750 & ~$mask : 0750,
                   "Proper mode");
                is(list_files($def_dir), $creates++ ? 3 : 0,
                   "Directory contents ok");

                my $access = $tele->access(channel => "foo",
                                           creat => 1,
                                           want => 1);
                isa_ok($access, "Video::TeletextDB::Access");
                is ($access->cache_dir, "$def_dir/", "Proper dir");
                is($access->umask, $mask, "Proper mask");
                $access = "";

                my @files = list_files($def_dir);
                is_deeply(\@files, [sort qw(foo.want foo.lock foo.db)],
                          "Directory contains expected files");

                for my $file (@files) {
                    @stat = lstat("$def_dir/$file") or die "lstat $def_dir/$file: $!";
                    ok(-f _, "Is a directory");
                    is($stat[2] & 07777, $mask ? 0640 & ~$mask : 0640,
                       "Proper mode");
                }

                is(umask, 0027, "umask unchanged");
            }
            is(-d $def_dir ? 1 : 0, $creates ? 1 : 0, "Still exists");
            blow_home;
        }
    }
}

# Check the creat option
for my $rw (undef, 0, 1) {
    for my $main_creat (undef, 0, 1) {
        for my $sub_creat (undef, 0, 1) {
            my $tele = Video::TeletextDB->new
                (defined $main_creat ? (creat => $main_creat) : ());
            is(list_files($def_dir), 0, "No files");
            my $expect = defined $sub_creat ? $sub_creat : $main_creat;
            my $access = eval {
                $tele->access(channel => "baz",
                              defined $sub_creat ? (creat => $sub_creat) : (),
                              defined $rw ? (RW => $rw) : ());
            };
            if ($expect) {
                is($@, "", "No errors");
                my @files = list_files($def_dir);
                is_deeply(\@files, [sort qw(baz.lock baz.db)],
                          "Created lock and database");
                is($access->creat, $expect, "Proper creat flag");
                is($tele->creat, $main_creat, "Proper creat flag");
                $access->release;
                is($tele->creat(undef), $main_creat, "Set and fetch creat");
                is($tele->creat, undef, "Proper create flag");

                unlink("$def_dir/baz.lock");
                unlink("$def_dir/baz.db");
                is(list_files($def_dir), 0, "No files");

                # Reacquire db, but parent has creat 0 now
                $access->acquire;
                @files = list_files($def_dir);
                is_deeply(\@files, [sort qw(baz.lock baz.db)],
                          "Created lock and database");
                is($access->creat, $expect, "Proper creat flag");
                my $new = rand_flag;
                is($access->creat($new), $expect, "Proper flag");
                is($access->creat, $new, "Proper creat flag");
            } else {
                like($@, qr/Could not open.*$ENOENT/, "good error message");
                is ($tele->creat, $main_creat, "Creat flag has the right value");
                is($tele->creat(undef), $main_creat, "Set and fetch creat");
                is($tele->creat, undef,
                   "Creat flag has the right value");
            }
            blow_home;
        }
    }
}

my $tele = Video::TeletextDB->new;
# Check defaults
is($tele->page_versions,undef);
is($tele->RW,		undef);
is($tele->creat,	undef);
is($tele->umask,	undef);
#is($tele->blocking,	1);
is($tele->channel,	undef);
is($tele->cache_dir,	"$def_dir/");
eval { $tele->want_file };
like($@, qr/No channel/);
eval { $tele->want };
like($@, qr/No channel/);
eval { $tele->lock_file };
like($@, qr/No channel/);
eval { $tele->lock };
like($@, qr/No channel/);
eval { $tele->db_file };
like($@, qr/No channel/);
eval { $tele->access };
like($@, qr/No channel/);

my $access = $tele->access(channel => "qux", creat => 1);
isa_ok($access, "Video::TeletextDB::Access");
is($access->page_versions, 5);
is($access->RW,		undef);
is($access->creat,	1);
is($access->umask,	undef);
#is($access->blocking,	1);
is($access->channel,	"qux");
is($access->cache_dir,	"$def_dir/");
is($access->want_file,	"$def_dir/qux.want");
is($access->lock_file,	"$def_dir/qux.lock");
is($access->db_file,	"$def_dir/qux.db");

eval {$access->page_versions(12) };
like($@, qr"You can't change the page_versions on a",
     "page_versions not settable");
eval {$access->page_versions(5) };
like($@, qr"You can't change the page_versions on a",
     "Not even if you set it to the old value");

eval {$access->channel("quux") };
like($@, qr"You can't change the channel on a", "channel not settable");
eval {$access->channel("qux") };
like($@, qr"You can't change the channel on a", "even to the same channel");

test_accessor($access, "a", qw(RW creat umask));

$access = "";

$access = $tele->access(channel => "qux");
isa_ok($access, "Video::TeletextDB::Access");
is($access->page_versions, 5);
is($access->RW,		undef);
is($access->creat,	undef);
is($access->umask,	undef);
#is($access->blocking,	1);
is($access->channel,	"qux");
is($access->cache_dir,	"$def_dir/");

$access->release;

test_accessor($access, "b", qw(RW creat umask));
test_accessor($tele,   undef, qw(page_versions RW creat umask channel));
# Does not influence $access
is($access->page_versions, 5);
is($access->RW,		"b");
is($access->creat,	"b");
is($access->umask,	"b");
#is($access->blocking,	1);
is($access->channel,	"qux");

$access->umask(0027);

$access->acquire;

is($access->page_versions, 5);
is($access->RW,		"b");
is($access->creat,	"b");
is($access->umask,	0027);
#is($access->blocking,	1);
is($access->channel,	"qux");

$access = "";

$tele->page_versions(9);
$tele->umask(0077);
$tele->channel("grz");
$tele->RW(6);
$tele->creat(5);

$access = $tele->access;

is($access->page_versions, 9);
is($access->RW,		6);
is($access->creat,	5);
is($access->umask,	0077);
#is($access->blocking,	1);
is($access->channel,	"grz");
is($access->cache_dir,	"$def_dir/");

# Now override them
$access = $tele->access(page_versions => 1,
                        RW => 2,
                        creat => 3,
                        # blocking => 4,
                        umask => 067,
                        channel => "woo");

is($access->page_versions, 1);
is($access->RW,		2);
is($access->creat,	3);
is($access->umask,	067);
#is($access->blocking,	4);
is($access->channel,	"woo");
is($access->cache_dir,	"$def_dir/");

$access = "";

my @files = list_files($def_dir);
is_deeply(\@files, [sort qw(qux.db qux.lock
                            grz.db grz.lock woo.db woo.lock)]);

$tele = "";
$tele = Video::TeletextDB->new(cache_dir => "~/go",
                               mkpath => 1,
                               page_versions => 4,
                               RW	=> 5,
                               creat => 6,
                               umask => 057,
                               # blocking => 7,
                               channel => "do");
is($tele->page_versions,4);
is($tele->RW,		5);
is($tele->creat,	6);
is($tele->umask,	057);
# is($tele->blocking,	7);
is($tele->channel,	"do");
is($tele->cache_dir,	"$home/go/");
is($tele->want_file,	"$home/go/do.want");
is($tele->lock_file,	"$home/go/do.lock");
is($tele->db_file,	"$home/go/do.db");
$tele = "";

blow_home;

# Testing RW semantics and upgrade/downgrade
$tele = Video::TeletextDB->new(RW => 0,
                               channel => "foo");
eval { $tele->access };
like($@, qr/Could not open.*$ENOENT/, "Can't create without creat");
$access = $tele->access(creat => 1);
my $db = $access->db;
ok($db, "There is indeed a database");
ok($db->put("a", "b"), "Could indeed not store");
$access = "";
# Can open without creat if the file already exists though
$access = $tele->access;
$db = $access->db;
ok($db, "There is indeed a database");
# Still can't store
ok($db->put("a", "b"), "Could indeed not store");

eval { $access->upgrade };
like($@, qr"Can't upgrade pure readonly access", "no RO upgrade");
is($access->downgrade, $db, "downgrade is fine though");
$access = "";
eval { $db->put("a", "b") };
like($@, qr"Can't locate object method .put. via package",
     "db is invalidated");
$tele = "";
blow_home;

$tele = Video::TeletextDB->new(RW => undef,
                               channel => "foo");
eval { $tele->access };
like($@, qr/Could not open.*$ENOENT/, "Can't create without creat");
$access = $tele->access(creat => 1);
$db = $access->db;
ok($db, "There is indeed a database");
is($db->put("a", "b"), 0, "Because we created it we have RW");
$access = "";
# Can open without creat if the file already exists though
$access = $tele->access;
$db = $access->db;
ok($db, "There is indeed a database");
# Can't store by default
ok($db->put("a", "b"), "Could indeed not store");

my $db1 = $access->upgrade;
isnt($db1, $db, "Handle really changed");
eval { $db->put("a", "b") };
like($@, qr"Can't locate object method .put. via package",
     "db is invalidated");
is($db1->put("a", "b"), 0, "Could indeed store");

$db = $access->downgrade;
isnt($db, $db1, "Handle really changed");
eval { $db1->put("a", "b") };
like($@, qr"Can't locate object method .put. via package",
     "db is invalidated");
ok($db->put("a", "b"), "Could indeed not store");

$access = "";
eval { $db->put("a", "b") };
like($@, qr"Can't locate object method .put. via package",
     "db is invalidated");
$tele = "";
blow_home;

$tele = Video::TeletextDB->new(RW => 1,
                               channel => "foo");
eval { $tele->access };
like($@, qr/Could not open.*$ENOENT/, "Can't create without creat");
$access = $tele->access(creat => 1);
$db = $access->db;
ok($db, "There is indeed a database");
is($db->put("a", "b"), 0, "and it's RW");
$access = "";
# Can open without creat if the file already exists though
$access = $tele->access;
$db = $access->db;
ok($db, "There is indeed a database");
# Can't store by default
is($db->put("a", "b"), 0, "and it's RW");

$db1 = $access->downgrade;
isnt($db1, $db, "Handle really changed");
is($access->downgrade, $db1, "downgrade is idempotent");
eval { $db->put("a", "b") };
like($@, qr"Can't locate object method .put. via package",
     "db is invalidated");
ok($db1->put("a", "b"), "Could indeed not store");

$db = $access->upgrade;
is($access->upgrade, $db, "upgrade is idempotent");
isnt($db, $db1, "Handle really changed");
eval { $db1->put("a", "b") };
like($@, qr"Can't locate object method .put. via package",
     "db is invalidated");
is($db->put("a", "b"), 0, "Could indeed store");

$access = "";
eval { $db->put("a", "b") };
like($@, qr"Can't locate object method .put. via package",
     "db is invalidated");
$tele = "";
blow_home;

# Readonly create with no permissions
$tele = Video::TeletextDB->new(channel => "foo");
eval { $tele->access(creat => 1, umask => 0777) };
like($@, qr/Could not db_open.*$EACCES/);
blow_home;

# Recheck the channel sanity checks
eval { Video::TeletextDB->new(channel => "fo.oo") };
like($@, qr/Channel 'fo.oo' contains forbidden character '\.'/, "Bad .");
eval { Video::TeletextDB->new(channel => "fo/oo") };
like($@, qr!Channel 'fo/oo' contains forbidden character '/'!, "Bad /");
eval { Video::TeletextDB->new(channel => "fo\0oo") };
like($@, qr/Channel 'fo\0oo' contains forbidden character '\0'/, "Bad \\0");
eval { Video::TeletextDB->new(channel => "fo:oo") };
like($@, qr/Channel 'fo:oo' contains forbidden character ':'/, "Bad :");

# Next try to change to an invalid channel
$tele = Video::TeletextDB->new(channel => "foo");
eval { $tele->channel("fo.oo") };
like($@, qr/Channel 'fo.oo' contains forbidden character '\.'/, "Bad .");
eval { $tele->channel("fo/oo") };
like($@, qr!Channel 'fo/oo' contains forbidden character '/'!, "Bad /");
eval { $tele->channel("fo\0oo") };
like($@, qr!Channel 'fo\0oo' contains forbidden character '\0'!, "Bad \\0");
eval { $tele->channel("fo'oo") };
like($@, qr"Channel 'fo'oo' contains forbidden character '''", "Bad '");
eval { $tele->channel("fo:oo") };
like($@, qr/Channel 'fo:oo' contains forbidden character ':'/, "Bad :");
eval { $tele->channel("fo;oo") };
like($@, qr/Channel 'fo;oo' contains forbidden character ';'/, "Bad ;");
is($tele->channel, "foo", "Failed attempts didn't change channel");

# Same thing on an access object
eval { $tele->access(channel => "fo.oo") };
like($@, qr/Channel 'fo.oo' contains forbidden character '\.'/, "Bad .");
eval { $tele->access(channel => "fo/oo") };
like($@, qr!Channel 'fo/oo' contains forbidden character '/'!, "Bad /");
eval { $tele->access(channel => "fo\0oo") };
like($@, qr/Channel 'fo\0oo' contains forbidden character '\0'/, "Bad \\0");
eval { $tele->access(channel => "fo'oo") };
like($@, qr"Channel 'fo'oo' contains forbidden character '''", "Bad '");
eval { $tele->access(channel => "fo:oo") };
like($@, qr/Channel 'fo:oo' contains forbidden character ':'/, "Bad :");
eval { $tele->access(channel => "fo;oo") };
like($@, qr/Channel 'fo;oo' contains forbidden character ';'/, "Bad ;");
is(list_files($def_dir), 0, "All failed access attempts caused no activity");
$tele = "";
blow_home;

# Check cache_dir path expansion
unlike($test_dir, qr!^/!, "Test directory is relative");
die "Empty test_dir" if $test_dir eq "";
# Avoid picking up tainted cwd
mkdir($home) || die "Could not create $home: $!";
mkdir("$home/foot") || die "Could not create $home/foo: $!";

# Relative dir
$tele = Video::TeletextDB->new(cache_dir => "$test_dir/foot");
is($tele->cache_dir, "$home/foot/", "relative path works");

# Absolute dir
$tele = Video::TeletextDB->new(cache_dir => "$home/foot");
is($tele->cache_dir, "$home/foot/", "absolute path works");

# Twiddle dir
$tele = Video::TeletextDB->new(cache_dir => "~/foot");
is($tele->cache_dir, "$home/foot/", "twiddle path works");

# Don't normalize end-/
$tele = Video::TeletextDB->new(cache_dir => "~/foot/////");
is($tele->cache_dir, "$home/foot/////", "twiddle path works");
$tele = "";
blow_home;

# channel listing
$tele = Video::TeletextDB->new;
is($tele->has_channel("foo"), undef, "No channel foo");
is_deeply([$tele->channels], [], "No channels to start with");
is($tele->channels, 0, "No channels to start with");

# Add a fake dir
my $cache_dir = $tele->cache_dir;
like($cache_dir, qr!^/!, "cache_dir is absolute");
mkdir("$cache_dir/baz.db") || die "Could not create $cache_dir/baz.db: $!";
is_deeply([$tele->channels], [], "Still no channels");
is($tele->channels, 0, "Still no channels");

# Add a fake file
open(my $fh, ">", "$cache_dir/bat") ||
    die "Could not create $cache_dir/bat: $!";
print $fh "batbat\n";
undef $fh;
is_deeply([$tele->channels], [], "Still no channels");
is($tele->channels, 0, "Still no channels");

# Add a fake db
open($fh, ">", "$cache_dir/b:z.db") ||
    die "Could not create $cache_dir/b:z.db: $!";
print $fh "bazbaz\n";
undef $fh;
is_deeply([$tele->channels], [], "Still no channels");
is($tele->channels, 0, "Still no channels");

# Add a fake lock
open($fh, ">", "$cache_dir/bas.lock") ||
    die "Could not create $cache_dir/bas.lock: $!";
print $fh "basbas\n";
undef $fh;
is_deeply([$tele->channels], [], "Still no channels");
is($tele->channels, 0, "Still no channels");

$tele->access(channel => "foo", creat => 1);
is_deeply([$tele->channels], ["foo"], "One channel");
is($tele->channels, 1, "One channel");
$tele->access(channel => "bar", creat => 1);
# We don't need the .lock file either
unlink("$def_dir/bar.lock") || die "Could not unlink $def_dir/bar.lock: $!";
is_deeply([sort $tele->channels], ["bar", "foo"], "Two channels");
is($tele->channels, 2, "Two channels");

is_deeply([sort &list_files($def_dir)],
          [sort qw(b:z.db bar.db bat baz.db foo.db foo.lock bas.lock)],
          "All happenined in the proper directory");

is($tele->has_channel("foo"), 1, "Have channel foo");
is($tele->has_channel("bar"), 1, "Have channel bar");
is($tele->has_channel("zap"), undef, "Have no channel zap");
is($tele->has_channel("bat"), undef, "Have no channel bat");
is($tele->has_channel("baz"), undef, "Have no channel baz");
is($tele->has_channel("b:z"), undef, "Have no channel b:z");

$tele->access(channel => "bat", creat => 1);
is_deeply([sort $tele->channels], ["bar", "bat", "foo"], "Three channels");
is($tele->channels, 3, "Three channels");
is($tele->has_channel("bat"), 1, "Have channel bat");
is_deeply([sort &list_files($def_dir)],
          [sort qw(b:z.db bar.db bat bat.db bat.lock baz.db foo.db foo.lock
                   bas.lock)],
          "All happenined in the proper directory");

is($tele->delete(channel => "foo"), 1, "deleting foo");
is($tele->has_channel(channel => "foo"), undef, 
   "Have nop channel foo anymore");
is($tele->delete(channel => "wak"), undef, "deleting wak");
is_deeply([sort &list_files($def_dir)],
          [sort qw(b:z.db bar.db bat bat.db bat.lock baz.db bas.lock)],
          "All happenined in the proper directory");
is($tele->delete(channel => "bas"), undef, "deleting bas");
is_deeply([sort &list_files($def_dir)],
          [sort qw(b:z.db bar.db bat bat.db bat.lock baz.db)],
          "All happenined in the proper directory");
is($tele->delete(channel => "bat"), 1, "deleting bat");
is_deeply([sort &list_files($def_dir)], [sort qw(b:z.db bar.db bat baz.db)],
          "All happenined in the proper directory");
eval { $tele->delete(channel => "baz") };
# Mm, solaris can unlink a dir if you are root. Maybe check euid here...
like($@, qr/Could not unlink.*($EISDIR|$EPERM)/, "Deleting baz fails");

$tele = "";
blow_home;

# Write some stuff to the database
$tele = Video::TeletextDB->new(creat => 1);
$access = $tele->access(channel => "test");
for my $fields (input()) {
    $access->write_feed(decoded_fields => $fields);
}
$access	= undef;
$tele	= undef;

$tele	= Video::TeletextDB->new(creat => 1);
$access = $tele->access(channel => "test");
my @ids = $access->page_ids;
is_deeply(\@ids, [qw(100/03 631/02 632/02 633/00 634/02 635/02 636/02 637/02 638/02 639/02 640/01 650/00 651/01 652/02 653/04 654/02 655/01 656/01 657/04 658/04 659/01 660/01 661/04 662/01 663/01 664/01 665/01 666/01 667/01 700/00 701/08 702/08 703/04 704/02 705/00 706/01 707/00 708/00 749/04 751/08 752/01 753/01 754/07 755/02 756/02 757/00 758/06 759/02 760/02 761/03 762/08 763/03 764/02 765/03 766/02 767/02 768/04 769/01 770/03 771/02 772/01 773/00 774/01 775/02 776/02 777/02 778/02 779/00 780/05 781/02 782/01 783/01 784/00 785/00 786/00 787/00 788/00 790/00 791/02 792/00 793/00 794/07 795/04 796/00 798/00 799/01 897/00)], "proper id list");

# Check subpages
my @subpages = $access->subpages(0x100);
is_deeply(\@subpages, [3], "Right subpage");

# Fetch a non-existing page
my $page = $access->fetch_page(1, 1);
is($page, undef, "No such page");

# Fetch an existing page
$page = $access->fetch_page(0x100, 3);
isa_ok($page, "Video::TeletextDB::Page", "Right page type");
my @rows = $page->text;
is(@rows, 24, "Right number of rows");
for (@rows) {
    is(length, 40+1, "Each row is 40chars+newline");
}
my $screen = $page->text;
is($screen, join("", @rows), "scalar text is all rows");

my $html = $page->html;

# Cleanup
$access = undef;
$tele	= undef;
