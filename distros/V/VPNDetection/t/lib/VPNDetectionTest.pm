package VPNDetectionTest;

use strict;
use warnings;

use Mojo::File 'path';
use Mojo::JSON 'decode_json';

# The language-neutral conformance corpus, generated into every VPNDetection SDK
# so a binding that drifts fails its own suite.
sub corpus {
    return decode_json(_root()->child('testdata', 'testdata.json')->slurp);
}

sub lookup_case {
    my ($name) = @_;
    my ($case) = grep { $_->{name} eq $name } @{ corpus()->{lookup} };
    die "no lookup case named '$name'" unless $case;
    return $case;
}

sub batch_case {
    my ($name) = @_;
    my ($case) = grep { $_->{name} eq $name } @{ corpus()->{batch} };
    die "no batch case named '$name'" unless $case;
    return $case;
}

# The members of the enum at @path in the pinned spec, following a `$ref` wherever
# the path lands on one, without the `null` a nullable enum lists. Read by
# indentation, since no YAML parser is among the suite's dependencies, and a path
# it cannot follow dies.
sub spec_enum {
    my (@path) = @_;
    my @document = grep { !/^\s*#/ } split /\n/, _root()->child('spec', 'openapi.yaml')->slurp;
    return _enum(\@document, @path);
}

# A built distribution leaves spec/ out and carries META files, which a checkout
# never has, so a checkout whose spec went missing fails at the read instead of
# skipping.
sub is_distribution {
    return scalar grep { -e _root()->child($_) } qw(META.json META.yml);
}

sub _root {
    return path(__FILE__)->to_abs->dirname->dirname->dirname;
}

sub _enum {
    my ($document, @path) = @_;
    my $node = $document;
    for my $key (@path) {
        (undef, $node) = _entry($node, $key);
        die "the pinned spec has no @path\n" unless $node;
    }
    my ($ref) = _entry($node, '$ref');
    my ($target) = defined $ref ? $ref =~ m{^['"]?#/(.+?)['"]?$} : ();
    return _enum($document, split m{/}, $target) if defined $target;

    my (undef, $enum) = _entry($node, 'enum');
    die "@path in the pinned spec is neither an enum nor a \$ref\n" unless $enum && @$enum;
    return [grep { $_ ne 'null' } map { /^\s*- (.+)$/ ? $1 : () } @$enum];
}

# A key's value on its own line, and the lines nested under it: everything up to
# the next line indented no deeper, blank lines included, since a block scalar
# can carry them.
sub _entry {
    my ($block, $key) = @_;
    my ($indent) = map { /^( *)\S/ ? length $1 : () } @$block;
    return unless defined $indent;
    for my $at (0 .. $#$block) {
        next unless $block->[$at] =~ /^ {$indent}\Q$key\E:\s*(.*)$/;
        my $value = $1;
        my @nested;
        for my $line (@$block[$at + 1 .. $#$block]) {
            last if $line =~ /^( *)\S/ && length $1 <= $indent;
            push @nested, $line;
        }
        return ($value, \@nested);
    }
    return;
}

1;
