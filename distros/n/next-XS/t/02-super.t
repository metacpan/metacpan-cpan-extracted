use 5.012;
use warnings;
use lib 't';
use mro;
use Test::More;
use next::XS;

{
    package M1;
    sub meth        { return 1*@_ }
    sub dmeth       { return 1*@_ }
    sub maybe_meth  { my $cnt = @_; return 1*$cnt + (shift->super::maybe::maybe_meth(@_)//0) }
    sub maybe_dmeth { return 1*@_ + (super::maybe::maybe_meth(@_)//0) }
    
    package M2;
    our @ISA = 'M1';
    sub meth       { my $cnt = @_; shift->super::meth(@_) + 2*$cnt }
    sub dmeth       { super::dmeth(@_) + 2*@_ }
    sub maybe_meth  { my $cnt = @_; shift->super::maybe::maybe_meth(@_) + 2*$cnt }
    sub maybe_dmeth { super::maybe::maybe_meth(@_) + 2*@_ }
    sub meth2       { my $self = shift; $self->super::meth(@_) + super::meth($self, @_) }
    
    package M4;
    our @ISA = 'M1';
    sub meth        { my $cnt = @_; shift->super::meth(@_) + 4*$cnt }
    sub maybe_meth  { my $cnt = @_; shift->super::maybe::maybe_meth(@_) + 4*$cnt }
    sub maybe_dmeth { super::maybe::maybe_meth(@_) + 4*@_ }
    sub dmeth       { super::dmeth(@_) + 4*@_ }
    
    package M8;
    our @ISA = ('M2', 'M4');
    sub meth        { my $cnt = @_; shift->super::meth(@_) + 8*$cnt }
    sub maybe_meth  { my $cnt = @_; shift->super::maybe::maybe_meth(@_) + 8*$cnt }
    sub maybe_dmeth { super::maybe::maybe_meth(@_) + 8*@_ }
    sub dmeth       { super::dmeth(@_) + 8*@_ }
    
    sub use_c3 { mro->import('c3') }
}

my $test = sub {
    my ($m1, $m2, $m4, $m8, $m8_ret) = @_;
    my $sub = sub {
        my $n = shift;
        my @args; $#args = $n-2;
        is($m1->meth(@args), 1*$n, 'm1');
        my $sub = sub {
            my $meth = shift;
            is($m2->$meth(@args), 3*$n, 'm2');
            is($m4->$meth(@args), 5*$n, 'm4');
            is($m8->$meth(@args), $m8_ret*$n, 'm8');
        };
        subtest 'super' => $sub => 'meth';
        subtest 'direct super' => $sub => 'dmeth';
        subtest 'maybe super' => $sub => 'maybe_meth';
        subtest 'direct maybe super' => $sub => 'maybe_dmeth';
        is($m2->meth2(@args), 2*$n, 'can call other method than enclosing');
    };
    subtest "pass $_" => $sub => $_ for 1..3;
};

my @classes = qw/M1 M2 M4 M8/;
my @objs = map { bless {}, $_ } @classes;

subtest 'DFS' => sub {
    subtest 'object methods' => $test => @objs, 11;
    subtest 'class methods'  => $test => @classes, 11;
};

subtest 'C3' => sub {
    M8->use_c3;
    subtest 'object methods' => $test => @objs, 15;
    subtest 'class methods'  => $test => @classes, 15;
};

done_testing();