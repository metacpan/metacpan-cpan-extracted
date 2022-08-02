package YS::TestMore;
use Mo qw(xxx);

use Test::Builder();

my $t;
BEGIN {
    $t = Test::Builder->new;
    $t->level(2);
}

sub like_args {
    my ($str, $qr, $label) = @_;
    $qr =~ s{^/?(.*?)/?$}{$1}s;
    $qr = qr/$qr/;
    return ($str, $qr, $label);
}

sub define {
    my ($self, $ns) = @_;

    [ plan => 1 => sub { $t->plan(tests => @_) } ],
    [ pass => 1 => sub { $t->ok(1, @_) } ],
    [ fail => 1 => sub { $t->ok(0, @_) } ],
    [ note => 1 => sub { $t->note(@_) } ],
    [ diag => 1 => sub { $t->diag(@_) } ],
    [ ok => 2 => sub { $t->ok(@_) } ],
    [ is => 3 => sub { $t->is_eq(@_) } ],
    [ isnt => 3 => sub { $t->isnt_eq(@_) } ],
    [ like => 3 => sub { $t->like(like_args(@_)) } ],
    [ unlike => 3 => sub { $t->unlike(like_args(@_)) } ],
    [ todo => 2 => sub { $t->todo_skip($_[0]) }, lazy => 1 ],
    [ skip => 2 => sub { $t->skip($_[0]) }, lazy => 1 ],
    [ skip_all => 1 => sub { $t->skip_all($_[0]) } ],
    [ done_testing =>
        0 => sub { $t->done_testing() },
        1 => sub { $t->done_testing(@_) } ],
    [ subtest =>
        _ => sub {
            my ($label, @expr) = @_;
            $t->subtest(
                $label,
                sub {
                    for my $expr (@expr) {
                        $expr->call;
                    }
                },
            );
        },
        lazy => 1,
    ],

    # TODO
    # [ is_deeply => ...
}

1;
