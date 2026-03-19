use strict;
use warnings;
use Test::Most;
use Text::Names::Canonicalize qw(canonicalize_name_struct);

sub surname {
    my ($name) = @_;
    my $s = canonicalize_name_struct($name, locale => 'de_DE');
    return $s->{parts}{surname};
}

is_deeply surname("Otto von Bismarck"), ["von", "bismarck"], "von Bismarck";
is_deeply surname("Karl von der Heide"), ["von der", "heide"], "von der Heide";
is_deeply surname("Hans zur Linde"), ["zur", "linde"], "zur Linde";
is_deeply surname("Fritz vom Stein"), ["vom", "stein"], "vom Stein";
is_deeply surname("Ulrich zu Bremen"), ["zu", "bremen"], "zu Bremen";

done_testing;
