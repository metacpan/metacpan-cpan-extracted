# ABSTRACT: yamltidy config module
use strict;
use warnings;
use v5.20;
use experimental qw/ signatures /;
package YAML::Tidy::Config;

our $VERSION = '0.003'; # VERSION

use Cwd;

sub new($class, %args) {
    my $yaml;
    my $overridespaces = delete $args{indentspaces};
    if (defined $args{configdata}) {
        $yaml = $args{configdata};
    }
    else {
        my $file = $args{configfile};
        unless (defined $file) {
            my ($home) = $class->_homedir;
            my $cwd = $class->_cwd;
            my @candidates = (
                "$cwd/.yamltidy",
                "$home/.config/yamltidy/config.yaml",
                "$home/.yamltidy",
            );
            for my $c (@candidates) {
                if (-f $c) {
                    $file = $c;
                    last;
                }
            }
        }
        if (defined $file) {
            open my $fh, '<', $file or die $!;
            $yaml = do { local $/; <$fh> };
            close $fh;
        }
    }
    unless (defined $yaml) {
        $yaml = $class->standardcfg('default');
    }
    my $cfg;
    my $yp = YAML::PP->new(
        schema => [qw/ + Merge /],
        cyclic_refs => 'fatal',
    );
    $cfg = $yp->load_string($yaml);
    my $v = delete $cfg->{v};
    my $indent = delete $cfg->{indentation} || {};
    $indent->{spaces} = $overridespaces if defined $overridespaces;
    $indent->{spaces} //= 2; # TODO support keeping original indent
    my $trimtrailing = $cfg->{'trailing-spaces'} || '';
    if ($trimtrailing eq 'fix') {
        $trimtrailing = 1;
    }
    else {
        $trimtrailing = 0;
    }

    delete @args{qw/ configfile configdata /};
    if (my @unknown = keys %args) {
        die "Unknown configuration keys: @unknown";
    }
    my $self = bless {
        version => $v,
        indentation => $indent,
        trimtrailing => $trimtrailing,
    }, $class;
    return $self;
}

sub _cwd {
    return Cwd::cwd();
}

sub _homedir($class) {
    return <~>;
}

sub indent($self) {
    return $self->{indentation}->{spaces};
}

sub trimtrailing($self) {
    return $self->{trimtrailing};
}


sub standardcfg {
    my $yaml = <<'EOM';
---
v: v0.1
indentation:
  spaces: 2
trailing-spaces: fix
EOM
}

1;
