package Test2::Harness::Worker::TestFile;
use strict;
use warnings;

use Test2::Harness::Util::File;

use File::Spec;

use Carp qw/croak/;

use Test2::Harness::Util::HashBase qw/-filename -_headers -_shbang -_scanned/;

sub TO_JSON {
    my $self = shift;
    return {
        filename   => $self->{+FILENAME},
        headers    => $self->headers,
        shbang     => $self->shbang,
        no_preload => $self->no_preload,
        content    => Test2::Harness::Util::File->new(name => $self->{+FILENAME})->read(),
    };
}

sub init {
    my $self = shift;

    croak "'filename' is required"
        unless $self->{+FILENAME};
}

sub headers {
    my $self = shift;
    $self->_scan unless $self->{+_SCANNED};
    return {} unless $self->{+_HEADERS};
    return { %{$self->{+_HEADERS}} };
}

sub shbang {
    my $self = shift;
    $self->_scan unless $self->{+_SCANNED};
    return {} unless $self->{+_SHBANG};
    return { %{$self->{+_SHBANG}} };
}

sub switches {
    my $self = shift;

    my $shbang = $self->shbang or return;
    return unless $shbang->{switches};
    return [ @{$shbang->{switches}} ];
}

sub no_preload {
    my $self = shift;

    $self->_scan unless $self->{+_SCANNED};

    if (my $shbang = $self->{+_SHBANG}) {
        return 1 if $shbang->{switches} && @{$shbang->{switches}};
    }

    if (my $headers = $self->{+_HEADERS}) {
        return 1 if exists($headers->{features}->{preload}) && !$headers->{features}->{preload};
    }

    return 0;
}

sub _scan {
    my $self = shift;

    return if $self->{+_SCANNED}++;

    open(my $fh, '<', $self->{+FILENAME}) or die "Could not open file '$self->{+FILENAME}': $!";

    my %headers;
    for(my $ln = 0; my $line = <$fh>; $ln++) {
        chomp($line);
        next if $line =~ m/^\s*$/;

        if( $ln == 0 ) {
            my $shbang = $self->_parse_shbang($line);
            if ($shbang) {
                $self->{+_SHBANG} = $shbang;
                next;
            }
        }

        next if $line =~ m/^(use|require|BEGIN)/;
        last unless $line =~ m/^\s*#/;

        next unless $line =~ m/^\s*#\s*HARNESS-(.+)$/;

        my ($dir, @args) = split /-/, lc($1);
        if($dir eq 'no') {
            my ($feature) = @args;
            $headers{features}->{$feature} = 0;
        }
        elsif($dir eq 'yes') {
            my ($feature) = @args;
            $headers{features}->{$feature} = 1;
        }
        else {
            warn "Unknown harness directive '$dir' at $self->{+FILENAME} line $ln.\n";
        }
    }

    $self->{+_HEADERS} = \%headers;
}

sub _parse_shbang {
    my $self = shift;
    my $line = shift;

    return {} if !defined $line;

    my %shbang;

    my $shbang_re = qr{
        ^
          \#!.*\bperl.*?        # the perl path
          (?: \s (-.+) )?       # the switches, maybe
          \s*
        $
    }xi;

    if ( $line =~ $shbang_re ) {
        my @switches = grep { m/\S/ } split /\s+/, $1 if defined $1;
        $shbang{switches} = \@switches;
        $shbang{line} = $line;
    }

    return \%shbang;
}

1;
