package MyTest;
use 5.012;
use warnings;
use Config;
use XS::Framework;
use Test::More;
use Test::Deep;
use Test::Catch;
use Data::Dumper;
use Test::Exception;

XS::Loader::load('MyTest');

sub import {
    my ($class, @reqs) = @_;
    if (@reqs) {
        no strict 'refs';
        &{"require_$_"}() for @reqs;
    }
    
    my $caller = caller();
    foreach my $sym_name (qw/Config is cmp_deeply ok done_testing skip isnt Dumper noclass subtest bag dies_ok new_ok isa_ok pass dies_ok is_deeply/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *$sym_name;
    }
    
    foreach my $sym_name (qw/dcnt/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *{"MyTest::$sym_name"};
    }
    
}

sub require_threads {
    plan skip_all => 'threaded perl required to run these tests'
        unless eval "use threads; use threads::shared; 1;";
}

# required for CPP tests
{
    package M1;

    our $call_cnt = 0;
    our $call_ret;
    
    our $allgv = "scalar";
    our @allgv = ("array");
    our %allgv = (key => "hash");
    sub allgv {1}
    
    our $gv2set;
    our $anon = sub { return time() };
    
    sub class_method { my $class = shift; return "$class-hi" }
    
    sub method { my $self = shift; return $$self + (shift()//0) + 10 }
    
    sub meth { return "$_[0]-1"; }
    use overload '""' => sub { return ref(shift).'(OBJ)' };
    
    sub dummy  {
        $call_cnt++;
        if (wantarray()) {
            return map { $_ * 5 } @_;
        }
        elsif (defined wantarray()) {
            my $ret = 0;
            map { $ret += ($_//0) } @_;
            return $ret;
        }
        else {
            $call_ret = 1;
            map { $call_ret *= ($_//0) } @_;
            return;
        }
    }
    
    sub dummy2 { return shift; }
}
{
    package M2;
    our @ISA = 'M1';
    sub child_method {}
    sub meth { return "$_[0]-2"; }
}
{    
    package M3;
    our @ISA = 'M1';
    sub meth { return "$_[0]-3"; }
}
{
    package M4;
    sub enable_c3  {mro->import('c3')}
    sub disable_c3 {mro->import('dfs')}
    our @ISA = qw/M2 M3/;
    sub meth { return "$_[0]-4"; }
}

{
    package MyTest::Mixin;
    use mro 'c3';
    our @ISA = qw/MyTest::MixPluginB MyTest::MixPluginA MyTest::MixBase/;
}

{    
    package MyTest::BadMixin;
    use mro 'c3';
    our @ISA = qw/MyTest::MixPluginB MyTest::MixBase/;
}

{    
    package MyTest::MyBRUnit;
    our @ISA = 'MyTest::BRUnit';
    
    sub id { my $self = shift; return @_ ? $self->SUPER::id(@_) : ($self->SUPER::id() + 111) }
}

{
    package MyTest::MyBRUnitAdvanced;
    our @ISA = 'MyTest::MyBRUnit';
    
    sub new {
        my $special = pop;
        my $self = shift->new_enabled(@_);
        XS::Framework::obj2hv($self);
        $self->{special} = $special;
        return $self;
    }
    
    sub special { shift->{special} }    
}

1;
