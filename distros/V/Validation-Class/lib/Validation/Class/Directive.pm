# ABSTRACT: Base Class for Validation Class Directives

package Validation::Class::Directive;

use strict;
use warnings;

use Validation::Class::Util;

use Carp 'confess';

our $VERSION = '7.900057'; # VERSION


# defaults

has 'mixin'         => 0;
has 'field'         => 0;
has 'multi'         => 0;
has 'message'       => '%s could not be validated';
has 'validator'     => sub { sub{1} };
has 'dependencies'  => sub {{ normalization => [], validation => [] }};
has 'name'          => sub {

    my ($self) = @_;

    my $name = ref $self || $self;

    my $regexp = qr/Validation::Class::Directive::(.*)$/;

    $name = $1 if $name =~ $regexp;

    $name =~ s/([a-z])([A-Z])/$1_$2/g;
    $name =~ s/\W/_/g;
    $name = lc $name;

    return $name;

};

sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    confess
        "Error creating directive without a name, specifying a name is " .
        "required to instatiate a new non-subclass directive"

        if 'Validation::Class::Directive' eq $class && ! $arguments->{name}

    ;

    my $self = bless {}, $class;

    while (my($key, $value) = each %{$arguments}) {
        $self->$key($value);
    }

    return $self;

}

sub error {

    my ($self, $proto, $field, $param, @tokens) = @_;

    my $name = $field->label || $field->name;

    unshift @tokens, $name;

    # use custom field-level error message
    if ($field->error) {
        $field->errors->add($field->error);
    }

    # use field-level error message override
    elsif (defined $field->{messages} && $field->{messages}->{$self->name}) {
        my $message = $field->{messages}->{$self->name};
        $field->errors->add(sprintf($message, @tokens));
    }

    # use class-level error message override
    elsif ($proto->messages->has($self->name)) {
        my $message = $proto->messages->get($self->name);
        $field->errors->add(sprintf($message, @tokens));
    }

    # use directive error message
    else {
        $field->errors->add(sprintf($self->message, @tokens));
    }

    return $self;

}

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    my $context = $proto->stash->{'validation.context'};

    # nasty hack, we need a better way !!!
    $self->validator->($context, $field, $proto->params);

    return $self;

}

1;

__END__

=pod

=head1 NAME

Validation::Class::Directive - Base Class for Validation Class Directives

=head1 VERSION

version 7.900057

=head1 SYNOPSIS

    package Validation::Class::Directive::CheckBlacklist;

    use base 'Validation::Class::Directive';

    use strict;
    use warnings;
    use Validation::Class::Util;
    use File::Slurp;

    has 'mixin'     => 0;
    has 'field'     => 1;
    has 'multi'     => 0;
    has 'message'   => '%s has been blacklisted';

    sub validate {

        my $self = shift;

        my ($proto, $field, $param) = @_;

        if (defined $field->{check_blacklist} && $param) {

            # is the parameter value blacklisted?
            my @blacklist = read_file('/blacklist.txt');

            $self->error if grep { $param =~ /^$_$/ } @blacklist;

        }

    }

    1;

... in your validation class:

    package MyApp::Person;

    use Validation::Class;

    field ip_address => {
        required        => 1,
        check_blacklist => 1
    };

    1;

... in your application:

    package main;

    use MyApp::Person;

    my $person = MyApp::Person->new(ip_address => '0.0.0.0');

    unless ($person->validates('ip_address')) {
        # handle validation error
    }

=head1 DESCRIPTION

You can extend Validation::Class by creating your own validation rules
(directives). Validation::Class::Directive provides a base-class for you to use
when creating new directive classes. Please see L<Validation::Class::Directives>
for a complete list of core directives.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
