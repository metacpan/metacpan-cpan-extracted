package Type::Guess::Role::DateTime::Naive;

use Moo::Role;

has 'datetime_format' => (is => 'rw', default => sub { "" });

my @PATTERNS = (
    [ qr/^\d{4}-(\d{2})-\d{2}$/,                    '%Y-%m-%d'          ],
    [ qr/^\d{2}-[A-Za-z]{3}-\d{4}$/,                '%d-%b-%Y'          ],
    [ qr/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}$/, '%Y-%m-%d %H:%M:%S' ],
    [ qr/^\d{2}\.\d{2}\.\d{4}$/,                      '%d.%m.%Y'          ],
    [ qr/^\d{2}\/\d{2}\/\d{4}$/,                    '%d/%m/%Y'          ],
);

# returns ($type_string, $datetime_format) rather than just $type_string
sub _type_and_format {
    my ($class, @vals) = @_;
    for my $pat (@PATTERNS) {
        my ($re, $fmt) = @$pat;
        next unless $class->_enough(sub { /$re/ }, @vals);
        return ("DateTime", $fmt);
    }
    return (undef, undef);
}

around '_type' => sub {
    my ($orig, $class, @vals) = @_;
    my ($type) = $class->_type_and_format(@vals);
    return $type if defined $type;
    return $orig->($class, @vals);
};


around "new" => sub {
    my ($orig, $class, @vals) = @_;
    my $result = $orig->($class, @vals);
    return $result if ref $vals[0] eq 'HASH' || !@vals;
    if ($result->type eq 'DateTime') {
        my (undef, $fmt) = $class->_type_and_format(@vals);
        $result->datetime_format($fmt);
    }
    return $result;
};

1;

