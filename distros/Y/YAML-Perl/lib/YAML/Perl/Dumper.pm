# pyyaml/lib/yaml/dumper.py

package YAML::Perl::Dumper;

use strict;
use warnings;
use YAML::Perl::Processor -base;

field 'next_layer' => 'representer';

# These fields are chained together such that you can access any lower
# level from any higher level.
field 'representer', -chain, -init => '$self->create("representer")';
field 'serializer',    -chain, -init => '$self->representer->serializer';
field 'emitter',      -chain, -init => '$self->serializer->emitter';
# field 'painter',     -chain, -init => '$self->emitter->painter';
field 'writer',      -chain, -init => '$self->emitter->writer';

# Setting a class name from the loader will set it in the appropriate
# class. When setting class names it is important to set the higher
# level ones first since accessing a lower level one will instantiate
# any higher level objects with their default class names.
field 'representer_class', -chain => -init  => '"YAML::Perl::Representer"';
field 'serializer_class',    -chain => -onset => '$self->representer->serializer_class($_)';
field 'emitter_class',      -chain => -onset => '$self->serializer->emitter_class($_)';
# field 'painter_class',     -chain => -onset => '$self->emitter->painter_class($_)';
field 'writer_class',      -chain => -onset => '$self->emitter->writer_class($_)';

sub dump {
    my $self = shift;
    for (@_) {
        $self->representer->represent_document($_);
    }
    return $self->stream();
}

sub stream {
    my $self = shift;
    return ${$self->representer->serializer->emitter->writer->stream->buffer};
}

1;
