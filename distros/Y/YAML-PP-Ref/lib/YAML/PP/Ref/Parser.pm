package YAML::PP::Ref::Parser;
use strict;
use warnings;

our $VERSION = '0.02'; # VERSION

use Scalar::Util qw/ openhandle /;
use YAML::Parser;
use YAML::PP::Common qw(
    YAML_PLAIN_SCALAR_STYLE
    YAML_SINGLE_QUOTED_SCALAR_STYLE YAML_DOUBLE_QUOTED_SCALAR_STYLE
    YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
    YAML_BLOCK_SEQUENCE_STYLE YAML_FLOW_SEQUENCE_STYLE
    YAML_BLOCK_MAPPING_STYLE YAML_FLOW_MAPPING_STYLE
);

use base 'YAML::PP::Parser';

my %style_map = (
  plain   => YAML_PLAIN_SCALAR_STYLE,
  single  => YAML_SINGLE_QUOTED_SCALAR_STYLE,
  double  => YAML_DOUBLE_QUOTED_SCALAR_STYLE,
  literal => YAML_LITERAL_SCALAR_STYLE,
  folded  => YAML_FOLDED_SCALAR_STYLE,
);

sub parse {
    my ($self) = @_;
    my $reader = $self->reader;
    my $string;
    if ($reader->can('open_handle')) {
        if (openhandle($reader->input)) {
            $string = do { local $/; $reader->open_handle->getline };
        }
        else {
            open my $fh, '<:encoding(UTF-8)', $reader->input;
            $string = do { local $/; <$fh> };
            close $fh;
        }
    }
    else {
        $string = $reader->read;
    }
    my $co = $self->receiver;

    my $cb = sub {
        my ($info) = @_;
        # Transform events becayse YAML::Parser uses something
        # very differnt from libyaml and YAML::PP
        my $event = (delete $info->{event}) . '_event';
        if ($event eq 'alias_event') {
            $info->{value} = delete $info->{name};
        }
        elsif ($event eq 'scalar_event') {
            my $style = $style_map{ $info->{style} };
            $info->{style} = $style;
        }
        elsif ($event eq 'document_start_event') {
            $info->{implicit} = delete $info->{explicit} ? 0 : 1;
        }
        elsif ($event eq 'document_end_event') {
            $info->{implicit} = delete $info->{explicit} ? 0 : 1;
        }
        elsif ($event eq 'sequence_start_event') {
            if (delete $info->{flow}) {
                $info->{style} = YAML_FLOW_SEQUENCE_STYLE;
            }
            else {
                $info->{style} = YAML_BLOCK_SEQUENCE_STYLE;
            }
        }
        elsif ($event eq 'mapping_start_event') {
            if (delete $info->{flow}) {
                $info->{style} = YAML_FLOW_MAPPING_STYLE;
            }
            else {
                $info->{style} = YAML_BLOCK_MAPPING_STYLE;
            }
        }
        $info->{name} = $event;
        if (ref $co eq 'CODE') {
            $co->($self, $event, $info);
        }
        else {
            return $co->$event($info);
        }
    };
    my $refrec = PerlYamlReferenceParserReceiver->new(
        callback => $cb,
    );
    my $p = YAML::Parser->new(receiver => $refrec);
    $p->parse($string);
}

1;
