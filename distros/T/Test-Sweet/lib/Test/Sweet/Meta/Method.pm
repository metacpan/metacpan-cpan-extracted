package Test::Sweet::Meta::Method;
BEGIN {
  $Test::Sweet::Meta::Method::VERSION = '0.03';
}
# ABSTRACT: metamethod for tests
use Moose::Role;

use MooseX::Types::Moose qw(CodeRef ArrayRef Str);
use Sub::Name;
use Test::Builder;
use Try::Tiny;
use Test::Sweet::Exception::FailedMethod;
use Test::Sweet::Meta::Test;

use namespace::autoclean;

has 'original_body' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has 'requested_test_traits' => (
    is         => 'ro',
    isa        => ArrayRef[Str],
    predicate  => 'has_requested_test_traits',
    auto_deref => 1,
);

has 'test_traits' => (
    is         => 'ro',
    isa        => ArrayRef[Str],
    lazy_build => 1,
);

sub _resolve_trait {
    my ($self, $trait_name) = @_;

    my $real_test_trait = "Test::Sweet::Meta::Test::Trait::$trait_name";
    my $anon_test_trait = 'Test::Sweet::Meta::Test::Trait::__ANON__::' .
        $self->associated_metaclass->name. "::$trait_name";

    if($trait_name =~ /^[+](.+)$/){
        $trait_name = $1;
        Class::MOP::load_class($trait_name);
        return $trait_name;
    }
    elsif ( eval { Class::MOP::load_class($anon_test_trait); 1 } ) {
        return $anon_test_trait;
    }
    elsif ( eval { Class::MOP::load_class($real_test_trait); 1 } ) {
        return $real_test_trait;
    }
    else {
        confess "Cannot resolve test trait '$trait_name' to a class name.";
    }
}

sub _build_test_traits {
    my ($self) = @_;
    return [] unless $self->has_requested_test_traits;
    return [ map { $self->_resolve_trait($_) } $self->requested_test_traits ];
}

sub has_actual_test_traits {
    my ($self) = @_;
    return 1 if $self->has_requested_test_traits && @{$self->test_traits} > 0;
    return;
}

has 'test_metaclass' => (
    is         => 'ro',
    isa        => 'Class::MOP::Class',
    lazy_build => 1,
);

sub _build_test_metaclass {
    my ($self) = @_;
    # XXX: don't hard-code superclass, make it a role
    return Moose::Meta::Class->create_anon_class(
        superclasses => [ 'Test::Sweet::Meta::Test' ],
        cache        => 1,
        ($self->has_actual_test_traits ? (roles => $self->test_traits) : ()),

    );
}

requires 'wrap';
requires 'body';

around 'wrap' => sub {
    my ($orig, $class, $code, %params) = @_;
    my $self = $class->$orig($params{original_body}, %params);
    return $self;
};

around 'body' => sub {
    my ($orig, $self) = @_;

    return (subname "<Test::Sweet test wrapper>", sub {
        my @args = @_;
        my $context = wantarray;
        my ($result, @result);

        my $b = Test::Builder->new; # TODO: let this be passed in
        $b->subtest(
            $self->name =>
                subname "<Test::Sweet subtest>", sub {
                    try {
                        my $TEST = $self->test_metaclass->name->new( # BUILD
                            test_body => sub {
                                my @args = @_;
                                return $self->$orig->(@args);
                            },
                        );

                        # run actual test method
                        if($context){
                            @result = $TEST->run(@args);
                        }
                        elsif(defined $context){
                            $result = $TEST->run(@args);
                        }
                        else {
                            $TEST->run(@args);
                        }
                        undef $TEST; # DEMOLISH
                        $b->done_testing;
                    }
                        catch {
                            die Test::Sweet::Exception::FailedMethod->new(
                                class  => $self->package_name,
                                method => $self->name,
                                error  => $_,
                            );
                        };
                },
        );
        return @result if $context;
        return $result if defined $context;
        return;
    });
};

1;



=pod

=head1 NAME

Test::Sweet::Meta::Method - metamethod for tests

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
