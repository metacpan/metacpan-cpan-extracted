use strict;
use Moose;
use Test::Routini;
use Test::More;
use CHI;
use Cache::Elasticache::Memcache;
use Test::MockObject;
use Symbol;
use Sub::Override;

has test_class => (
    is => 'ro',
    lazy => 1,
    default => 'CHI::Driver::Elasticache::Memcache'
);

has params => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return {
            foo => 'bar'
        };
    }
);

has parent_overrides => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $mock = Test::MockObject->new(gensym);
        $mock->set_isa('Cache::Elasticache::Memcache');
        my $overrides = Sub::Override->new()
                                     ->replace('Cache::Elasticache::Memcache::new', sub {
                                         my $object = shift;
                                         my $args = shift;
                                         if( $args->{'foo'} eq 'bar' ) {
                                             return $mock
                                         } else {
                                             ok 0;
                                             return undef;
                                         }
                                     });
        return $overrides;
    }
);

test "compiles" => sub {
    my $self = shift;
    use_ok 'CHI::Driver::Elasticache::Memcache';
    ok defined $self->test_class->VERSION;
};

test "contained cache is built" => sub {
    my $self = shift;
    my $subject = CHI->new(
        driver => 'Elasticache::Memcache',
        %{$self->params},
    );
    isa_ok $subject, $self->test_class;
};

run_me;
done_testing;
