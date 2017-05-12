#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, '..', 'lib');
use Module::Pluggable::Object; # TODO: switch to Module::Find
use Getopt::Long;
use autodie;
use File::Path qw/mkpath/;
use IO::Handle;
use Pod::Usage;

my $format = 'YAML';
my $datdir = File::Spec->catfile($FindBin::Bin, '..', 'dat');
GetOptions(
    'format=s' => \$format,
    'datdir=s' => \$datdir,
    'softbank' => \my $softbank,
) or pod2usage();
mkpath $datdir;
my $dumper = do {
    if ($format eq 'YAML') {
        require YAML;
        sub { YAML::Dump(@_) }
    } elsif ($format eq 'JSON') {
        require JSON;
        sub { JSON->new->utf8->canonical->encode(@_) }
    } else {
        print "Unknown format: $format";
        pod2usage();
    }
};

my $pluggable = Module::Pluggable::Object->new(
    'require' => 'yes',
    'search_path' => ['WWW::MobileCarrierJP'],
);

LOOP: for my $module ($pluggable->plugins()) {
    next if $module eq 'WWW::MobileCarrierJP::Declare';
    if ($softbank) {
        next if $module =~ /WWW::MobileCarrierJP::ThirdForce/;
    } else {
        next if $module =~ /WWW::MobileCarrierJP::Softbank/;
    }

    print "processing $module\n";

    my $fname = $module;
    $fname =~ s/^WWW::MobileCarrierJP:://;
    $fname =~ s/::/-/g;
    $fname = lc $fname;

    my $ofname = File::Spec->catfile($datdir, "$fname." . lc($format));
    my $serialized = $dumper->($module->scrape());
    
    # すでにファイルが存在し、内容が同一である場合には更新しない
    if (-f $ofname) {
        open my $ifh, '<:utf8', $ofname;
        my $original = do { local $/; <$ifh> };
        if ($original eq $serialized) {
            print "$ofname is not modified\n";
            next LOOP;
        }
    }

    print "writing $ofname\n";
    open my $fh, '>', $ofname;
    print { $fh } $serialized;
}

__END__

=encoding utf-8

=head1 SYNOPSIS

    % www-mobilecarrierjp-dump_all.pl --format=JSON --datdir=/path/to/output --softbank

    --format=JSON              出力フォーマットを指定する(JSON または YAML を選択可能)
    --datdir=/path/to/output   出力先ディレクトリを指定する
    --softbank                 ThirdForce ではなく Softbank というファイル名を仕様する

