use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.042

use Test::More  tests => 13 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'WWW/DaysOfWonder/Memoir44.pm',
    'WWW/DaysOfWonder/Memoir44/App.pm',
    'WWW/DaysOfWonder/Memoir44/App/Command.pm',
    'WWW/DaysOfWonder/Memoir44/App/Command/list.pm',
    'WWW/DaysOfWonder/Memoir44/App/Command/update.pm',
    'WWW/DaysOfWonder/Memoir44/DB/Params.pm',
    'WWW/DaysOfWonder/Memoir44/DB/Scenarios.pm',
    'WWW/DaysOfWonder/Memoir44/Filter.pm',
    'WWW/DaysOfWonder/Memoir44/Scenario.pm',
    'WWW/DaysOfWonder/Memoir44/Types.pm',
    'WWW/DaysOfWonder/Memoir44/Url.pm',
    'WWW/DaysOfWonder/Memoir44/Utils.pm'
);

my @scripts = (
    'bin/mem44'
);

# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

   # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


