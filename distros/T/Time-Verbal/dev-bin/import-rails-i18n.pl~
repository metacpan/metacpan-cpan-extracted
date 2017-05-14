#!/usr/bin/env perl
# import translations from rails i18n project

use strict;
use warnings;
use utf8;
use YAML::XS;
use JSON::Any;
use File::Find;
use FindBin;
use Cwd;

my $rails1i8n_dir = shift @ARGV or die;

my $out_i18n_dir = "$FindBin::Bin/i18n";

my $cwd = Cwd::getcwd();

find sub {
    /([^\/]+)\.yml/ or return;
    my $code = $1;
    my $dict = YAML::XS::LoadFile($File::Find::name)->{$code}{datetime}{distance_in_words};

    my %lexicon = (
        "less then a minute" => $dict->{less_than_x_minutes}{one},
        "1 minute"           => $dict->{x_minutes}{one},
        "%1 minutes"         => $dict->{x_minutes}{other},
        "about 1 hour"       => $dict->{about_x_hours}{one},
        "%1 hours"           => $dict->{about_x_hours}{other},
        "one day"            => $dict->{x_days}{one},
        "%1 days"            => $dict->{x_days}{other},
        "over a year"        => $dict->{over_x_years}{one},
    );

    for my $k (keys %lexicon) {
        $lexicon{$k} =~ s/%{count}/%1/g;
    }

    my $j = JSON::Any->new;
    my $out_file =  "$out_i18n_dir/$code.json";
    open(my $fh, ">", $out_file);
    print $fh $j->encode(\%lexicon);
    print $fh "\n";
    close $fh;

}, "${rails1i8n_dir}/rails/locale";
