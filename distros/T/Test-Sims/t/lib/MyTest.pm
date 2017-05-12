package MyTest;

use base "Test::Builder::Module";

my $CLASS = __PACKAGE__;
our @EXPORT = qw(rand_ok);


sub rand_ok {
    my $min  = shift;
    my $max  = shift;
    my $have = shift;
    my $want = shift;
    my $name = shift;

    my $tb = $CLASS->builder;

    my $ok = 1;

    my $count = @$have;
    $ok &&= ( $min <= $count && $count <= $max );
    $tb->ok( $ok, "Wrong number of items: $name" );
    $tb->diag(<<DIAG) unless $ok;
Wrong number of items.
have: $count
want: $min .. $max
DIAG

    my %diff;
    my %want = map { $_ => 1 } @$want;
    for my $item (@$have) {
        $diff{$item}++ unless $want{$item};
    }

    if( keys %diff ) {
        $ok &&= $tb->ok( 0, $name );
        $tb->diag("Differing item: $_") for keys %diff;
    }
    else {
        $ok &&= $tb->ok( 1, $name );
    }

    return $ok;
}

