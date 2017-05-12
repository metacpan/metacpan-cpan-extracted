# pyyaml/lib/yaml/loader.py

package YAML::Perl::Loader;
use strict;
use warnings;
use YAML::Perl::Processor -base;

field 'next_layer' => 'constructor';

# These fields are chained together such that you can access any lower
# level from any higher level.
field 'constructor', -chain, -init => '$self->create("constructor")';
field 'composer',    -chain, -init => '$self->constructor->composer';
field 'parser',      -chain, -init => '$self->composer->parser';
field 'scanner',     -chain, -init => '$self->parser->scanner';
field 'reader',      -chain, -init => '$self->scanner->reader';

# Setting a class name from the loader will set it in the appropriate
# class. When setting class names it is important to set the higher
# level ones first since accessing a lower level one will instantiate
# any higher level objects with their default class names.
field 'constructor_class', -chain => -init  => '"YAML::Perl::Constructor"';
field 'composer_class',    -chain => -onset => '$self->constructor->composer_class($_)';
field 'parser_class',      -chain => -onset => '$self->composer->parser_class($_)';
field 'scanner_class',     -chain => -onset => '$self->parser->scanner_class($_)';
field 'reader_class',      -chain => -onset => '$self->scanner->reader_class($_)';

sub load {
    my $self = shift;
    if (wantarray) {
        my @data = ();
        while ($self->constructor->check_data()) {
            push @data, $self->constructor->get_data();
        }
        return @data;
    }
    else {
        return $self->constructor->check_data()
            ? $self->constructor->get_data()
            : ();
    }
}

1;
