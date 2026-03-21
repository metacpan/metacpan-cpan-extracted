use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 43;

my @module_files = (
    'Date/Format.pm',
    'Date/Format/Generic.pm',
    'Date/Language.pm',
    'Date/Language/Afar.pm',
    'Date/Language/Amharic.pm',
    'Date/Language/Arabic.pm',
    'Date/Language/Austrian.pm',
    'Date/Language/Brazilian.pm',
    'Date/Language/Bulgarian.pm',
    'Date/Language/Chinese.pm',
    'Date/Language/Chinese_GB.pm',
    'Date/Language/Czech.pm',
    'Date/Language/Danish.pm',
    'Date/Language/Dutch.pm',
    'Date/Language/English.pm',
    'Date/Language/Finnish.pm',
    'Date/Language/French.pm',
    'Date/Language/Gedeo.pm',
    'Date/Language/German.pm',
    'Date/Language/Greek.pm',
    'Date/Language/Hungarian.pm',
    'Date/Language/Icelandic.pm',
    'Date/Language/Italian.pm',
    'Date/Language/Norwegian.pm',
    'Date/Language/Occitan.pm',
    'Date/Language/Oromo.pm',
    'Date/Language/Portuguese.pm',
    'Date/Language/Romanian.pm',
    'Date/Language/Russian.pm',
    'Date/Language/Russian_cp1251.pm',
    'Date/Language/Russian_koi8r.pm',
    'Date/Language/Sidama.pm',
    'Date/Language/Somali.pm',
    'Date/Language/Spanish.pm',
    'Date/Language/Swedish.pm',
    'Date/Language/Tigrinya.pm',
    'Date/Language/TigrinyaEritrean.pm',
    'Date/Language/TigrinyaEthiopian.pm',
    'Date/Language/Turkish.pm',
    'Date/Parse.pm',
    'Time/Zone.pm',
    'TimeDate.pm'
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


