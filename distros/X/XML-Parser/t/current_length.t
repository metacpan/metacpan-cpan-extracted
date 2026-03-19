BEGIN { print "1..5\n"; }
END { print "not ok 1\n" unless $loaded; }
use XML::Parser;
$loaded = 1;
print "ok 1\n";

# Test that current_length returns byte counts for events

my $xml = '<root><child attr="val">text</child></root>';

my ($start_byte, $start_length);
my ($end_byte, $end_length);
my ($char_byte, $char_length);

my $parser = XML::Parser->new(
    Handlers => {
        Start => sub {
            my ($p, $el, %attrs) = @_;
            if ($el eq 'child') {
                $start_byte = $p->current_byte;
                $start_length = $p->current_length;
            }
        },
        End => sub {
            my ($p, $el) = @_;
            if ($el eq 'child') {
                $end_byte = $p->current_byte;
                $end_length = $p->current_length;
            }
        },
        Char => sub {
            my ($p, $str) = @_;
            if ($str eq 'text') {
                $char_byte = $p->current_byte;
                $char_length = $p->current_length;
            }
        },
    }
);

$parser->parse($xml);

# Test 2: current_length returns a defined value for start tags
if (defined $start_length && $start_length > 0) {
    print "ok 2\n";
} else {
    print "not ok 2 # start_length=" . (defined $start_length ? $start_length : 'undef') . "\n";
}

# Test 3: start tag <child attr="val"> should have correct length
# The tag is: <child attr="val"> which is 18 bytes
if ($start_length == 18) {
    print "ok 3\n";
} else {
    print "not ok 3 # expected 18, got " . (defined $start_length ? $start_length : 'undef') . "\n";
}

# Test 4: end tag </child> should have correct length (8 bytes)
if ($end_length == 8) {
    print "ok 4\n";
} else {
    print "not ok 4 # expected 8, got " . (defined $end_length ? $end_length : 'undef') . "\n";
}

# Test 5: character data "text" should have correct length (4 bytes)
if ($char_length == 4) {
    print "ok 5\n";
} else {
    print "not ok 5 # expected 4, got " . (defined $char_length ? $char_length : 'undef') . "\n";
}
