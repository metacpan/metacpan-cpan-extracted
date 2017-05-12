use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 17 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Time/Duration/Concise.pm',
    'Time/Duration/Concise/Locale/ar.pm',
    'Time/Duration/Concise/Locale/de.pm',
    'Time/Duration/Concise/Locale/es.pm',
    'Time/Duration/Concise/Locale/fr.pm',
    'Time/Duration/Concise/Locale/hi.pm',
    'Time/Duration/Concise/Locale/id.pm',
    'Time/Duration/Concise/Locale/it.pm',
    'Time/Duration/Concise/Locale/ja.pm',
    'Time/Duration/Concise/Locale/ms.pm',
    'Time/Duration/Concise/Locale/pl.pm',
    'Time/Duration/Concise/Locale/pt.pm',
    'Time/Duration/Concise/Locale/ru.pm',
    'Time/Duration/Concise/Locale/vi.pm',
    'Time/Duration/Concise/Locale/zh_cn.pm',
    'Time/Duration/Concise/Locale/zh_tw.pm',
    'Time/Duration/Concise/Localize.pm'
);



# no fake home requested

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

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


