use strict;

use ExtUtils::MakeMaker qw(WriteMakefile);
use File::Spec::Functions;

my (@INC, @LIBPATH, @LIBS);

my $DEFINES = '-O2';
$DEFINES .= ' -Wall' unless $^O =~ /sun|solaris/i;
$DEFINES .= ' -Wno-unused-value -Wno-format-security' unless $^O =~ /Win32|sun|solaris/i;

unshift @INC, '-I. -I.. -Isrc';

my $inc_files = join(' ', glob 'src/*.h');
my $src_files = join(' ', glob 'src/*.c');
my $xs_files  = join(' ', glob '*.xs');

WriteMakefile(
    NAME              => 'Thrift::XS',
    VERSION_FROM      => 'lib/Thrift/XS.pm',
    PREREQ_PM         => {
        'Bit::Vector'       => 0,
        'Test::BinaryData'  => 0,
    },
    ABSTRACT_FROM     => 'lib/Thrift/XS.pm',
    AUTHOR            => 'Andy Grundman <andy@hybridized.org>',
    INC               => join(' ', @INC),
    LIBS              => [ join(' ', @LIBPATH, @LIBS) ],
    DEFINE            => $DEFINES,
    depend            => { 'XS.c' => "$inc_files $src_files $xs_files" },
    META_MERGE        => {
        resources => {
            license    => 'http://www.apache.org/licenses/LICENSE-2.0',
            repository => 'https://github.com/andygrundman/thrift-xs',
        },
    },
);
