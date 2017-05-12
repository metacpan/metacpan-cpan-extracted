use ExtUtils::MakeMaker;
use strict;

my %args = (
            pkg_name  => 'Test::Presenter',
            name      => 'Test::Presenter',
            DESTDIR   => undef
            );

my %opts = (
            'NAME'          => "$args{'name'}",
            'AUTHOR'        => "John Daiker <daikerjohn\@gmail.com>",
            'ABSTRACT_FROM' => "lib/Test/Presenter.pm",
            'VERSION_FROM'  => "lib/Test/Presenter.pm",
            'EXE_FILES'     => [ qw( scripts/treport
                                     scripts/test_report_example
                                     scripts/plot-iostat
                                     scripts/plot-mpstat
                                     scripts/plot-sar
                                     scripts/plot-vmstat
                               ) ],
            'PREREQ_PM'     => {
                'Pod::Usage'            => 0,
                'Getopt::Long'          => 0,
                'IO::File'              => 0,
                'Template'              => 0,
                'Test::Parser'          => 0,
                'Chart::Graph::Gnuplot' => 0,
                'SVG::TT::Graph'        => 0,
            },
);

WriteMakefile( %opts );

# vi:set ai ts=4 sw=4 expandtab:
