# Is the 'file' option handled correctly?

use Test::More;
use Text::TypingEffort qw( effort );

# make sure the user has File::Temp and try to make the temporary file
my $tmp;
eval {
    require File::Temp;
    $tmp = File::Temp->new();
};

# if there was an error, skip everything
# otherwise, establish our plan
if ($@) {
    plan skip_all => 'test requires object-oriented File::Temp';
}
else {
    plan tests => 3;
}

# establish some test data
my $text = "   \tThe quick brown fox jumps over the lazy dog\n";
$text   .= "\t  The quick brown fox jumps over the lazy dog\n";
my %ok = (
    characters => 88,
    presses    => 90,
    distance   => 2040,
    energy     => 4.7618,
);

print $tmp $text;
seek($tmp, 0, 0);  # rewind

# file parameter as an open filehandle
$effort = effort( file => $tmp );
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'leading whitespace ignored' );
close($tmp);

# file parameter as a filename
my $effort = effort( file  => "$tmp" );
$effort->{energy} = sprintf("%.4f", $effort->{energy});
is_deeply( $effort, \%ok, 'leading whitespace ignored' );

# find a non-existent file
my $junk_file = 'a';
$junk_file .= 'a' while length($junk_file)<64 and -e $junk_file;
SKIP: {
    skip 'Unable to find a non-existent file', 1 unless length($junk_file)<64;

    eval {
        $effort = effort( file => $junk_file );
    };
    ok( $@, "died for non-existent file" );
}
