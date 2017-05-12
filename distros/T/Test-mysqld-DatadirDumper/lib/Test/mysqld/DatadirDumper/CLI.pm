package Test::mysqld::DatadirDumper::CLI;
use strict;
use warnings;

use Getopt::Long;
use Test::mysqld::DatadirDumper;

sub run {
    my ($class, @argv) = @_;

    my ($opt,) = $class->parse_options(@argv);
    Test::mysqld::DatadirDumper->new($opt)->dump;
}

sub parse_options {
    my ($class, @argv) = @_;

    my $parser = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case/],
    );
    local @ARGV = @argv;
    $parser->getoptions(\my %opt, qw/
        ddl=s
        datadir=s
        fixtures=s@
    /);
    for my $opt (qw/ddl datadir/) {
        die "$opt option is required!" unless exists $opt{$opt};
    }

    if (exists $opt{fixtures}) {
        $opt{fixtures} = [
            map { split /,/, $_ } @{ $opt{fixtures} }
        ];
    }
    $opt{ddl_file} = delete $opt{ddl};

    (\%opt, \@ARGV);
}

1;
