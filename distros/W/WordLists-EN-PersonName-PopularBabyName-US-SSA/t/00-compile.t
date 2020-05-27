use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 29 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1900/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1900/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1910/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1910/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1920/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1920/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1930/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1930/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1940/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1940/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1950/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1950/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1960/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1960/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1970/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1970/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1980/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1980/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1990/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/1990/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2000/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2000/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2010/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2010/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2017/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2017/MaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2018/FemaleTop1000.pm',
    'WordList/EN/PersonName/PopularBabyName/US/SSA/2018/MaleTop1000.pm',
    'WordLists/EN/PersonName/PopularBabyName/US/SSA.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


