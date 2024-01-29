# ABSTRACT: yamltidy runner
use strict;
use warnings;
use v5.20;
use experimental qw/ signatures /;
package YAML::Tidy::Run;

our $VERSION = 'v0.9.0'; # VERSION

use YAML::Tidy;
use YAML::Tidy::Config;
use YAML::LibYAML::API;
use Getopt::Long::Descriptive;
use Encode;

my @options = (
    'yamltidy %o file',
    [ 'config-file|c=s' => 'Config file' ],
    [ 'config-data|d=s' => 'Configuration as a string' ],
    [ 'inplace|i' => 'Edit file inplace' ],
    [ 'debug' => 'Debugging output' ],
    [ 'partial' => 'Input is only a part of a YAML file' ],
    [ 'indent=i' => 'Override indentation spaces from config' ],
    [ 'batch|b' => 'Tidy all files - currently requires parameter "-" for filenames passed via STDIN' ],
    [ 'verbose|v' => 'Output information' ],
    [],
    [ 'help|h', "print usage message and exit", { shortcircuit => 1 } ],
    [ 'version', "Print version information", { shortcircuit => 1 } ],
);

sub new($class, %args) {
    my ($opt, $usage) = describe_options(@options);
    my $cfg = YAML::Tidy::Config->new(
        configfile => $opt->config_file,
        configdata => $opt->config_data,
        indentspaces => $opt->indent,
    );
    my $yt = YAML::Tidy->new(
        cfg => $cfg,
        partial => $opt->partial,
    );
    my $self = bless {
        opt => $opt,
        stdin => $args{stdin} || \*STDIN,
        tidy => $yt,
        usage => $usage,
    }, $class;
}

sub _output($self, $str) {
    print $str;
}

sub run($self) {
    my $opt = $self->{opt};
    my $usage = $self->{usage};
    $self->_output($usage->text), return if $opt->help;
    my @versions = (
        YAML::Tidy->VERSION, YAML::PP->VERSION,
        YAML::LibYAML::API->VERSION,
        YAML::LibYAML::API::XS::libyaml_version
    );
    if ($opt->version) {
        $self->_output(sprintf <<'EOM', @versions);
    yamltidy:           %s
    YAML::PP:           %s
    YAML::LibYAML::API: %s
    libyaml:            %s
EOM
        return;
    }

    if ($opt->batch) {
        my ($path) = @ARGV;
        unless ($path eq '-') {
            die "--batch currently requires '-' to receive filenames via STDIN\n";
        }
        unless ($opt->inplace) {
            die "--batch currently requires --inplace\n";
        }
        my $in = $self->{stdin};
        while (my $file = <$in>) {
            chomp $file;
            $self->_process_file($file);
        }
        return;
    }
    my ($file) = @ARGV;
    unless (defined $file) {
        $self->_output($usage->text);
        return;
    }

    if ($file eq '-') {
        $self->_process_stdin;
        return;
    }

    $self->_process_file($file);
}

sub _process_file($self, $file) {
    my $opt = $self->{opt};
    my $yt = $self->{tidy};
    my $changed = 0;
    open my $fh, '<:encoding(UTF-8)', $file or die "Could not open '$file': $!";
    my $yaml = do { local $/; <$fh> };
    close $fh;

    $opt->debug and $self->_before($file, $yaml);

    my $out = $yt->tidy($yaml);

    if ($out ne $yaml) {
        $changed = 1;
    }
    if ($opt->inplace) {
        $changed and $self->_write_file($file, $out);
    }
    else {
        $opt->debug or $self->_output(encode_utf8 $out);
    }
    $opt->debug and $self->_after($file, $out);
    $self->_info(sprintf "Processed '%s' (%s)", $file, $changed ? 'changed' : 'unchanged');
}

sub _info($self, $msg) {
    $self->{opt}->verbose and $self->_output("[info] $msg\n");
}

sub _write_file($self, $file, $out) {
    open my $fh, '>:encoding(UTF-8)', $file or die "Could not open '$file' for writing: $!";
    print $fh $out;
    close $fh;
}

sub _process_stdin($self) {
    my $opt = $self->{opt};
    my $yt = $self->{tidy};
    my $in = $self->{stdin};
    my $yaml = decode_utf8 do { local $/; <$in> };

    $opt->debug and $self->_before('-', $yaml);

    my $out = $yt->tidy($yaml);

    if ($opt->debug) {
        $self->_after('-', $out);
    }
    else {
        $self->_output(encode_utf8 $out);
    }
}

sub _before($self, $file, $yaml) {
    my $yt = $self->{tidy};
    $self->_output( "# Before: ($file)\n");
    $self->_output(encode_utf8 $yt->highlight($yaml));
}

sub _after($self, $file, $yaml) {
    my $yt = $self->{tidy};
    $self->_output("# After: ($file)\n");
    $self->_output(encode_utf8 $yt->highlight($yaml));
}
1;
