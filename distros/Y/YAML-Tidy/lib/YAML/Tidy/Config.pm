# ABSTRACT: yamltidy config module
use strict;
use warnings;
use v5.20;
use experimental qw/ signatures /;
package YAML::Tidy::Config;

our $VERSION = 'v0.9.0'; # VERSION

use Cwd;
use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE
    YAML_DOUBLE_QUOTED_SCALAR_STYLE YAML_LITERAL_SCALAR_STYLE
    YAML_FOLDED_SCALAR_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE
/;
my %stylemap = (
    plain => YAML_PLAIN_SCALAR_STYLE,
    single => YAML_SINGLE_QUOTED_SCALAR_STYLE,
    double => YAML_DOUBLE_QUOTED_SCALAR_STYLE,
#    literal => YAML_LITERAL_SCALAR_STYLE,
#    folded => YAML_FOLDED_SCALAR_STYLE,
);

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
    $indent->{'block-sequence-in-mapping'} //= 0;
    my $trimtrailing = $cfg->{'trailing-spaces'} || '';
    if ($trimtrailing eq 'fix') {
        $trimtrailing = 1;
    }
    else {
        $trimtrailing = 0;
    }
    my $scalarstyle = { default => YAML_PLAIN_SCALAR_STYLE };
    if (my $scalar = delete $cfg->{'scalar-style'}) {
        my $default = $scalar->{default};
        $scalarstyle->{default} = $default ? $stylemap{ $default } : undef;
    }
    my $serialize_aliases = 0;
    if (my $aliases = $cfg->{aliases}) {
        if ($aliases->{serialize}) {
            $serialize_aliases = 1;
        }
    }

    delete @args{qw/ configfile configdata /};
    if (my @unknown = keys %args) {
        die "Unknown configuration parameters: @unknown";
    }
    my $self = bless {
        version => $v,
        indentation => $indent,
        trimtrailing => $trimtrailing,
        header => delete $cfg->{header} // 'keep',
        footer => delete $cfg->{footer} // 'keep',
        adjacency => delete $cfg->{adjacency} // 'keep',
        scalar_style => $scalarstyle,
        serialize_aliases => $serialize_aliases,
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
sub indent_seq_in_map($self) {
    return $self->{indentation}->{'block-sequence-in-mapping'};
}

sub trimtrailing($self) {
    return $self->{trimtrailing};
}

sub addheader($self) {
    my $header = $self->{header};
    return 0 if $header eq 'keep';
    return $header ? 1 : 0;
}

sub addfooter($self) {
    my $footer = $self->{footer};
    return 0 if $footer eq 'keep';
    return $footer ? 1 : 0;
}

sub adjacency($self) {
    my $adjacency = $self->{adjacency};
    return undef if $adjacency eq 'keep';
    return $adjacency ? 1 : 0;
}

sub removeheader($self) {
    my $header = $self->{header};
    return 0 if $header eq 'keep';
    return $header ? 0 : 1;
}

sub removefooter($self) {
    my $footer = $self->{footer};
    return 0 if $footer eq 'keep';
    return $footer ? 0 : 1;
}

sub default_scalar_style($self) {
    return $self->{scalar_style}->{default};
}

# Turns
#    ---
#    - &color blue
#    - *color
#    - &color pink
#    - *color
#    ...
# into
#    ---
#    - &color_1 blue
#    - *blue_1
#    - &color_2 blue
#    - *blue_2
#    ...
sub serialize_aliases($self) { $self->{serialize_aliases} }

sub standardcfg {
    my $yaml = <<'EOM';
---
v: v0.1
indentation:
  spaces: 2
  block-sequence-in-mapping: 0
trailing-spaces: fix
header: true
scalar-style:
    default: plain
adjacency: 0
EOM
}

1;
