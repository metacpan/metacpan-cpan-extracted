#!/usr/bin/env perl

use strict;
use warnings;

use Pod::Usage;
use Getopt::Long;

use FindBin;
use File::Spec;
use File::HomeDir;
use File::Temp ();
use lib File::Spec->catfile($FindBin::Bin, qw/.. lib/);

use YAML;
use ExtUtils::MakeMaker ();
use WWW::Google::Docs::Upload;

our $conf = File::Spec->catfile( File::HomeDir->my_home, '.gdoc_upload' );
our %config;
our $changed;

main();

END {
    save_config() if $changed;
}

sub prompt {
    my $value = ExtUtils::MakeMaker::prompt($_[0]);
    $changed++;
    $value;
}

sub main {
    GetOptions(
        \my %option,
        qw/help name=s/
    );
    pod2usage(0) if $option{help};

    setup_config();

    my ($filename, $fh);
    $filename = $ARGV[0];

    if (!$filename and my $stdin = do { local $/; <STDIN> }) {
        my ($suffix) = ($option{name} || '') =~ /(\.?[^.]+)$/;
        $fh = File::Temp->new( $suffix ? (SUFFIX => $suffix) : () );
        print $fh $stdin;
        $fh->close;

        $filename = $fh->filename;
    }

    pod2usage(1) unless $filename;

    my $gdoc = WWW::Google::Docs::Upload->new(
        email  => $config{email},
        passwd => $config{passwd},
    );

    $gdoc->upload($filename, { name => $option{name} || '' });
}

sub setup_config {
    my $config = eval { YAML::LoadFile($conf) } || {};
    %config = %$config;

    $config{email}  ||= prompt('email:');
    $config{passwd} ||= prompt('passwd:');
}

sub save_config {
    YAML::DumpFile($conf, \%config);
    chmod 0600, $conf;
}

__END__

=head1 NAME

gdoc-upload.pl - Upload documents to Google Docs.

=head1 SYNOPSIS

    gdoc-upload.pl [options] /path/to/documents
    
    Options:
        -n --name    name what you want call it in gdocs
        -h --help    show this help

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
