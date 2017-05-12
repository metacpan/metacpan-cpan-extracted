use Test;
BEGIN { plan tests => 1 }

use XML::SemanticDiff;

$xml1 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="good"/>
<el2 el2attr="good">Some Text</el2>
<el3/>
</root>
EOX

$xml2 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="bad"/>
<el2 bogus="true"/>
<el4>Rogue</el4>
</root>
EOX

my $handler = BetterDiff->new();

my $diff = XML::SemanticDiff->new(diffhandler => $handler);

my @results = $diff->compare($xml1, $xml2);

ok(@results == 6);

package BetterDiff;

use strict;

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = \%args;
    bless ($self, $class);
    return $self;
}

sub rogue_element {
    my $self = shift;
    my ($element_path, $new_element) = @_;
    return 1 if $element_path and $new_element;
}

sub rogue_attribute {
    my $self = shift;
    my ($attr, $element_path, $new_element, $old_element) = @_;
    return 1 if $attr and $element_path and $new_element and $old_element;
}

sub missing_element {
    my $self = shift;
    my ($element_path, $old_element) = @_;
    return 1 if $element_path and $old_element;
}

sub missing_attribute {
    my $self = shift;
    my ($attr, $element_path, $new_element, $old_element) = @_;
    return 1 if $attr and $element_path and $new_element and $old_element;
}

sub attribute_value {
    my $self = shift;
    my ($attr, $element_path, $new_element, $old_element) = @_;
    return 1 if $attr and $element_path and $new_element and $old_element;
}

sub element_value {
    my $self = shift;
    my ($element_path, $new_element, $old_element) = @_;
    return 1 if $element_path and $new_element and $old_element;
}

sub namespace_uri {
    return 1;
}

1;

