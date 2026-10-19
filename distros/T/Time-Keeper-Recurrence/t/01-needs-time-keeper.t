#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

# Time::Keeper and Time::Keeper::Zone are required, with nothing to fall
# back to, so each way of not having a usable one has to stop and say which
# it was. Each case is a child perl, because a module that failed to load
# cannot be loaded again in the same process to try the next one.
#
# The child's code is written to a script, never passed with -e: Windows has
# no argument vector, and perl does not escape a double quote inside an
# argument when it joins them into one command line. The script sends its own
# STDOUT and STDERR to a file, so the message comes back without a pipe.

my @inc = map { "-I$_" } grep { !ref } @INC;
my $work = tempdir(CLEANUP => 1);
my $script = File::Spec->catfile($work, 'child.pl');
my $output = File::Spec->catfile($work, 'child.out');

sub child {
    my ($code) = @_;
    open(my $fh, '>', $script) or die "cannot write $script: $!";
    print {$fh} "BEGIN { open STDOUT, '>', q{$output} or die \$!; "
              . "open STDERR, '>&', \\*STDOUT or die \$! }\n$code\n";
    close $fh or die "cannot close $script: $!";
    unlink $output;
    system($^X, @inc, $script);
    my $rc = $? >> 8;
    my $text = '';
    if (open(my $in, '<', $output)) {
        local $/;
        $text = <$in>;
        close $in;
    }
    return ($rc, defined $text ? $text : '');
}

# The control: the same child, with nothing in the way, loads and resolves
# both tables. Without this the cases below would pass against a module that
# never loads at all.
{
    my ($rc, $text) = child('require Time::Keeper::Recurrence; print "loaded ", join(" ", Time::Keeper::Recurrence->abi_versions), "\n"');
    is($rc, 0, 'with both installed the child loads Time::Keeper::Recurrence') or diag($text);
    like($text, qr/^loaded \d+ \d+$/m, 'and reports the two tables it resolved');
}

# Time::Keeper cannot be found.
{
    my ($rc, $text) = child(
        'BEGIN { unshift @INC, sub { die "Time::Keeper is hidden for this test\n" if $_[1] eq "Time/Keeper.pm"; return } } '
      . 'require Time::Keeper::Recurrence; print "LOADED\n"');
    isnt($rc, 0, 'with Time::Keeper hidden the load fails');
    unlike($text, qr/LOADED/, 'nothing after the require ran');
    like($text, qr/Time::Keeper is hidden for this test/, 'and the message carries the reason perl gave');
}

# Time::Keeper::Zone cannot be found: the module loads, the first named zone dies.
{
    my ($rc, $text) = child(
        'BEGIN { unshift @INC, sub { die "Zone is hidden for this test\n" if $_[1] eq "Time/Keeper/Zone.pm"; return } } '
      . 'require Time::Keeper::Recurrence; print "LOADED\n"; Time::Keeper::Recurrence->abi_versions; print "RESOLVED\n"');
    like($text, qr/LOADED/, 'with Time::Keeper::Zone hidden the module still loads');
    isnt($rc, 0, 'but asking for the zone table fails');
    unlike($text, qr/RESOLVED/, 'before anything after it ran');
    like($text, qr/needs Time::Keeper::Zone 0\.04 or later/, 'the message names what is needed');
    like($text, qr/could not load it/, 'says it could not be loaded');
    like($text, qr/Zone is hidden for this test/, 'and carries the reason perl gave');
}

# A Time::Keeper that loads and has no table to give, and one whose table is
# older than the one this module was built against. The table's first member
# is an int, so a packed int is a table of version 1, and `pack "p"` gives
# the address of that string's buffer. The address is pointer-sized, which is
# not the IV size on a 32-bit perl built with 64-bit integers, so it is read
# back as Q or L to match, never as J.
my $fake = tempdir(CLEANUP => 1);
sub fake_module {
    my ($module, $body) = @_;
    my @parts = split /::/, $module;
    my $file = File::Spec->catfile($fake, @parts[0 .. $#parts - 1], "$parts[-1].pm");
    (my $dir = $file) =~ s{[/\\][^/\\]+$}{};
    require File::Path;
    File::Path::make_path($dir);
    open(my $fh, '>', $file) or die "cannot write $file: $!";
    print {$fh} "package $module;\nour \$VERSION = '0.00';\n$body\n1;\n";
    close $fh or die "cannot close $file: $!";
}
my $use_fake = 'BEGIN { unshift @INC, q{' . $fake . '} } ';
my $old_table = 'our $TABLE = pack("i", 1); sub _abi_ptr { unpack(length(pack("p", "")) == 8 ? "Q" : "L", pack("p", $TABLE)) }';

{
    fake_module('Time::Keeper', 'sub _abi_ptr { 0 }');
    my ($rc, $text) = child($use_fake . 'require Time::Keeper::Recurrence; print "LOADED\n"');
    isnt($rc, 0, 'with a Time::Keeper that returns no table the load fails');
    unlike($text, qr/LOADED/, 'nothing after the require ran');
    like($text, qr/the Time::Keeper that loaded has no C ABI table/, 'and the message says there is no table');
}
{
    fake_module('Time::Keeper', $old_table);
    my ($rc, $text) = child($use_fake . 'require Time::Keeper::Recurrence; print "LOADED\n"');
    isnt($rc, 0, 'with a Time::Keeper whose table is too old the load fails');
    unlike($text, qr/LOADED/, 'nothing after the require ran');
    like($text, qr/at version (\d+) or later: the Time::Keeper that loaded has version 1/,
         'and the message names the version needed and the version found');
}
unlink File::Spec->catfile($fake, 'Time', 'Keeper.pm');
{
    fake_module('Time::Keeper::Zone', 'sub _abi_ptr { 0 }');
    my ($rc, $text) = child($use_fake . 'require Time::Keeper::Recurrence; Time::Keeper::Recurrence->abi_versions; print "RESOLVED\n"');
    isnt($rc, 0, 'with a Time::Keeper::Zone that returns no table the first named zone fails');
    unlike($text, qr/RESOLVED/, 'nothing after it ran');
    like($text, qr/the Time::Keeper::Zone that loaded has no C ABI table/, 'and the message says there is no table');
}
{
    fake_module('Time::Keeper::Zone', $old_table);
    my ($rc, $text) = child($use_fake . 'require Time::Keeper::Recurrence; Time::Keeper::Recurrence->abi_versions; print "RESOLVED\n"');
    isnt($rc, 0, 'with a Time::Keeper::Zone whose table is too old the first named zone fails');
    unlike($text, qr/RESOLVED/, 'nothing after it ran');
    like($text, qr/at version (\d+) or later: the Time::Keeper::Zone that loaded has version 1/,
         'and the message names the version needed and the version found');
}

done_testing;
