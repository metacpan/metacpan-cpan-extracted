use ExtUtils::MakeMaker;
use strict;

my %opts = (
            'NAME'          => "Test::Parser",
            'AUTHOR'        => "Bryce Harrington <bryce\@osdl.org>",
            'ABSTRACT_FROM' => "lib/Test/Parser.pm",
            'VERSION'       => '1.9',
            'EXE_FILES'     => [ qw(
                                     scripts/kernel2trpi
                                     scripts/parse_build_kernel
                                     scripts/parse_ltp
                                     scripts/parse_newpynfs
                                     scripts/parse_sysbench_cpu
                                     scripts/parse_sysbench_fileio
                                     scripts/parse_iozone
                                     scripts/parse_test
                                     ) ],
            'PREREQ_PM'     => {
                'Pod::Usage'     => 0,
                'Getopt::Long'   => 0,
                'XML::Twig'      => 0,
                'XML::Simple'    => 0,
                'CGI'            => 0,
            },
);

WriteMakefile( %opts )

# vi:set ai ts=4 sw=4 expandtab:
