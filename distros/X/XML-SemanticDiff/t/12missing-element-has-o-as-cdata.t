# This is a regression test file for bug:
#
#   http://rt.cpan.org/Ticket/Display.html?id=2322
#
# It seems to already have been fixed by the time this test was written.

use strict;
use warnings;

use Test::More tests => 1;

use XML::SemanticDiff;

package MyDiffHandler;

sub new
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->{save_CData} = [];

    return $self;
}

sub missing_element
{
    my $self = shift;

    my ($elem, $properties) = @_;

    push @{$self->{save_CData}}, { cdata => $properties->{CData} };

    return {};
}

package main;

my $handler = MyDiffHandler->new();

my $diff = XML::SemanticDiff->new(diffhandler => $handler);

my $xml_with_empty_element = <<'EOF';
<root><b>Quark</b><hello /></root>
EOF

my $xml_without_empty_element = <<'EOF';
<root><b>Quark</b></root>
EOF

my @results = $diff->compare(
    $xml_with_empty_element,
    $xml_without_empty_element,
);

# TEST
is_deeply ($handler->{save_CData},
    [ { cdata => undef } ],
    "Testing that the cdata for an empty element is the empty string."
);
