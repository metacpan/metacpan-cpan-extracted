package meon::Web::Config;

use strict;
use warnings;

use meon::Web::SPc;
use Config::INI::Reader;
use File::Basename 'basename';
use Log::Log4perl;
use Path::Class 'file', 'dir';
use Run::Env;

Log::Log4perl::init(
    File::Spec->catfile(
        meon::Web::SPc->sysconfdir, 'meon', 'web-log4perl.conf'
    )
);

my $config = Config::INI::Reader->read_file(
    File::Spec->catfile(
        meon::Web::SPc->sysconfdir, 'meon', 'web-config.ini'
    )
);
foreach my $hostname_dir_name (keys %{$config->{domains} || {}}) {
    my $hostname_dir = File::Spec->catfile(
        meon::Web::SPc->srvdir, 'www', 'meon-web', $hostname_dir_name
    );
    my $hostname_dir_config = File::Spec->catfile(
        $hostname_dir, 'config.ini'
    );
    if (Run::Env->dev) {
        my $hostname_dir_config_dev = File::Spec->catfile(
            $hostname_dir, 'config_dev.ini'
        );
        $hostname_dir_config = $hostname_dir_config_dev
            if -e $hostname_dir_config_dev;
    }

    if (-e $hostname_dir_config) {
        $config->{$hostname_dir_name} = Config::INI::Reader->read_file(
            $hostname_dir_config
        );
        unless (Run::Env->dev) {
            if (my $js_dir = $config->{$hostname_dir_name}->{main}->{'js-dir'}) {
                $js_dir = dir($hostname_dir, $js_dir);
                my $merged_js = '';
                foreach my $js_file (sort $js_dir->children(no_hidden => 1)) {
                    $merged_js .= '/* '.$js_file." */\n\n".$js_file->slurp.";\n\n";
                }
                my $js_merged_file = file($hostname_dir, 'www','static','meon-Web-merged.js');
                $js_merged_file->spew($merged_js);
                system("cat $js_merged_file | yui-compressor --type js --charset UTF-8 -o $js_merged_file.tmp && mv $js_merged_file.tmp $js_merged_file")
                    and die 'failed to minify js '.$!;
            }
            if (my $css_dir = $config->{$hostname_dir_name}->{main}->{'css-dir'}) {
                $css_dir = dir($hostname_dir, $css_dir);
                my $merged_css = '';
                foreach my $css_file (sort $css_dir->children(no_hidden => 1)) {
                    $merged_css .= '/* '.$css_file." */\n\n".$css_file->slurp."\n\n";
                }
                my $css_merged_file = file($hostname_dir, 'www','static','meon-Web-merged.css');
                $css_merged_file->spew($merged_css);
                system("cat $css_merged_file | yui-compressor --type css --charset UTF-8 -o $css_merged_file.tmp && mv $css_merged_file.tmp $css_merged_file")
                    and die 'failed to minify css '.$!;
            }
        }
    }
}

sub get {
    return $config;
}

my %h2f;
sub hostname_to_folder {
    my ($class, $hostname) = @_;

    unless (%h2f) {
        foreach my $folder (keys %{$config->{domains} || {}}) {
            my @domains = map { $_ =~s/^\s+//;$_ =~s/\s+$//; $_ }  split(/\s*,\s*/, $config->{domains}{$folder});
            foreach my $domain (@domains) {
                $h2f{$domain} = $folder;
            }
        }
    }

    return $h2f{$hostname};
}

1;
