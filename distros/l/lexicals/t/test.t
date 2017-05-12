use Test::More tests => 6;

use lexicals;

sub example {
    my $self = shift;
    my $worth;
    my $is = 'xxx';
    my $overrated = $self;
    my $lex1 = lexicals;
    my $what;
    my $lex2 = lexicals;
    test($lex1, "is overrated self worth");
    test($lex2, "is lex1 overrated self what worth");
}

sub test {
    my ($lex, $expect) = @_;
    my $keys = join ' ', sort keys %$lex;
    is $keys, $expect,
        'Got the correct lexicals';
    is ref($lex->{self}), 'main', 'object values seem right';
    is $lex->{is}, 'xxx', 'scalar values seem right';
}

bless({})->example();
