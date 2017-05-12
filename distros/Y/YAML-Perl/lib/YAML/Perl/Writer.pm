package YAML::Perl::Writer;
use strict;
use warnings;

use YAML::Perl::Stream;

package YAML::Perl::Writer;
use YAML::Perl::Processor -base;

field next_layer => '';

field 'stream' => -init => 'YAML::Perl::Stream::Output->new()';
field 'encoding';

sub open {
    my $self = shift;
    $self->stream->open(@_);
    $self->SUPER::open(@_);
    return $self;
}

sub write {
    my $self = shift;
    $self->stream->write(@_);
}

1;
