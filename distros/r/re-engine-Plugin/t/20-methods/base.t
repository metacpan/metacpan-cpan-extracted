=pod

Tests methods on the re object

=cut

use strict;

use feature ':5.10';

use Test::More tests => 9;

use re::engine::Plugin (
    comp => sub  {
        my $re = shift;

        # Use a stash to pass a single scalar value to each executing
        # routine, references work perfectly a reference to anything
        # can be passed as well
        $re->stash( { x => 5, y => sub { 6 } } );

        # Return value not used for now..
    },
    exec => sub {
        my ($re, $str) = @_;

        # pattern
        cmp_ok($re->pattern, 'eq', ' foobar zoobar ' => '->pattern ok');

        # modifiers
        my %mod = $re->mod;
        ok(exists $mod{i}, 'str flags /i');
        ok(exists $mod{x}, 'str flags /x');
        like(join('', keys %mod), qr/^[cgimosx]+$/, 'flags contain all-good characters');

        # stash
        cmp_ok($re->stash->{"x"}, '==', 5, "data correct in stash");
        cmp_ok(ref $re->stash->{"y"}, 'eq', 'CODE', "data correct in stash");
        cmp_ok(ref $re->stash->{"y"}, 'eq', 'CODE', "data correct in stash");
        cmp_ok($re->stash->{"y"}->(), '==', 6, "data correct in stash");

        # Pattern contains "foo", "bar" and "zoo", return a true
        return $re->pattern =~ /zoo/;
    }
);

my $re = qr< foobar zoobar >xi;

if ("input" =~ $re ) {
    pass 'pattern matched';
} else {
    fail "pattern didn't match";
}

