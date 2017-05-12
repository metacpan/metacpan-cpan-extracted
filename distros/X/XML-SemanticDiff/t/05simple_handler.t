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

my $handler = SimpleDiff->new();

my $diff = XML::SemanticDiff->new(diffhandler => $handler);

my @results = $diff->compare($xml1, $xml2);

ok(@results == 8);

package SimpleDiff;

use strict;

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self  = \%args;
    bless ($self, $class);
    return $self;
}

sub init {
    return 1;
}

sub rogue_element {
    return 1;
}

sub rogue_attribute {
    return 1;
}

sub missing_element {
    return 1;
}

sub missing_attribute {
    return 1;
}

sub attribute_value {
    return 1;
}

sub element_value {
    return 1;
}

sub namespace_uri {
    return 1;
}

sub final {
   #
   return 1;
}
1;

