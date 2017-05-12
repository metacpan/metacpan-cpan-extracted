# pyyaml/lib/yaml/resolver.py

package YAML::Perl::Resolver;
use strict;
use warnings;

# package YAML::Perl::Resolver::Base;
use YAML::Perl::Base -base;

use constant DEFAULT_SCALAR_TAG => 'tag:yaml.org,2002:str';
use constant DEFAULT_SEQUENCE_TAG => 'tag:yaml.org,2002:seq';
use constant DEFAULT_MAPPING_TAG => 'tag:yaml.org,2002:map';

my $yaml_implicit_resolvers = {};
my $yaml_path_resolvers = {};

field resolver_exact_paths => [];
field resolver_prefix_paths => [];

sub add_implicit_resolver {
    die "add_implicit_resolver";
}

sub add_path_resolver {
    die "add_path_resolver";
}

sub descend_resolver {
    return;
    die "descend_resolver";
}

sub ascend_resolver {
    return;
    die "ascend_resolver";
}

sub check_resolver_prefix {
    die "check_resolver_prefix";
}

sub resolve {
    my $self = shift;
    my $kind = shift;
    my $value = shift;
    my $implicit = shift;

    if ($kind eq 'YAML::Perl::Node::Scalar' and $implicit->[0]) {
#         my $resolvers;
#         if ($value eq '') {
#             $resolvers = $self->yaml_implicit_resolvers->{''} || [];
#         }
#         else {
#             $resolvers = $self->yaml_implicit_resolvers->{$value->[0]} || [];
#         }
#         resolvers += self.yaml_implicit_resolvers.get(None, [])
#         for tag, regexp in resolvers:
#             if regexp.match(value):
#                 return tag
        $implicit = $implicit->[1];
    }
#     if self.yaml_path_resolvers:
#         exact_paths = self.resolver_exact_paths[-1]
#         if kind in exact_paths:
#             return exact_paths[kind]
#         if None in exact_paths:
#             return exact_paths[None]
#     if kind is ScalarNode:
#         return self.DEFAULT_SCALAR_TAG
#     elif kind is SequenceNode:
#         return self.DEFAULT_SEQUENCE_TAG
#     elif kind is MappingNode:
#         return self.DEFAULT_MAPPING_TAG


    return ''; # XXX
}

1;
