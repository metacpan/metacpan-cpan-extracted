package YAML::Perl::Nodes;
use strict;
use warnings;

package YAML::Perl::Node;
use YAML::Perl::Base -base;

use overload '""' => 'stringify';

field 'tag';
field 'value';
field 'start_mark';
field 'end_mark';
field 'style';

sub stringify {
    my $self = shift;
    my $class = ref($self) || $self;
    my $value = $self->value . "";
    my $tag = ($self->tag || '') . "";
    return "$class(tag=$tag, value=$value)";
}

package YAML::Perl::Node::Scalar;
use YAML::Perl::Node -base;

field 'style';

package YAML::Perl::Node::Collection;
use YAML::Perl::Node -base;

field 'flow_style';

package YAML::Perl::Node::Sequence;
use YAML::Perl::Node::Collection -base;

field id => 'sequence';

package YAML::Perl::Node::Mapping;
use YAML::Perl::Node::Collection -base;

field id => 'mapping';

1;
