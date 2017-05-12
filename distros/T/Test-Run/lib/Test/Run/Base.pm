package Test::Run::Base;

use strict;
use warnings;

use MRO::Compat;


=head1 NAME

Test::Run::Base - base class for all of Test::Run.

=head1 DESCRIPTION

This is the base class for all Test::Run classes. It inherits from
L<Class::Accessor> and provides some goodies of its own.

=head1 METHODS

=cut

use Moose;

use Text::Sprintf::Named;
use Test::Run::Sprintf::Named::FromAccessors;

use Test::Run::Class::Hierarchy (qw(hierarchy_of rev_hierarchy_of));

use Carp ();

has '_formatters' => (is => "rw", isa => "HashRef", default => sub { +{} },);

=head2 $package->new({%args})

The default constructor. Do not over-ride it. Instead, define a
L<BUILD()> method.

=cut

=head2 $dest->copy_from($source, [@fields])

Assigns the fields C<@fields> using their accessors based on their values
in C<$source>.

=cut

sub copy_from
{
    my ($dest, $source, $fields) = @_;

    foreach my $f (@$fields)
    {
        $dest->$f($source->$f());
    }

    return;
}

sub _get_formatter
{
    my ($self, $fmt) = @_;

    return
        Text::Sprintf::Named->new(
            { fmt => $fmt, },
        );
}

sub _register_formatter
{
    my ($self, $name, $fmt) = @_;

    $self->_formatters->{$name} = $self->_get_formatter($fmt);

    return;
}

sub _get_obj_formatter
{
    my ($self, $fmt) = @_;

    return
        Test::Run::Sprintf::Named::FromAccessors->new(
            { fmt => $fmt, },
        );
}

sub _register_obj_formatter
{
    my ($self, $args) = @_;

    my $name = $args->{name};
    my $fmt  = $args->{format};

    $self->_formatters->{$name} = $self->_get_obj_formatter($fmt);

    return;
}

sub _format
{
    my ($self, $format, $args) = @_;

    if (ref($format) eq "")
    {
        return $self->_formatters->{$format}->format({ args => $args});
    }
    else
    {
        return $self->_get_formatter(${$format})->format({ args => $args});
    }
}

sub _format_self
{
    my ($self, $format, $args) = @_;

    $args ||= {};

    return $self->_format($format, { obj => $self, %{$args}});
}

=head2 $self->accum_array({ method => $method_name })

This is a more simplistic version of the :CUMULATIVE functionality
in Class::Std. It was done to make sure that one can collect all the
members of array refs out of methods defined in each class into one big
array ref, that can later be used.

=cut

sub accum_array
{
    my ($self, $args) = @_;

    my $method_name = $args->{method};

    # my $class = ((ref($self) eq "") ? $self : ref($self));

    my @results;
    foreach my $isa_class (
        $self->meta->find_all_methods_by_name($method_name)
    )
    {
        my $body = $isa_class->{code}->body();
        push @results, @{ $self->$body() };
    }

    return \@results;
}

sub _list_pluralize
{
    my ($self, $noun, $list) = @_;

    return $self->_pluralize($noun, scalar(@$list));
}

sub _pluralize
{
    my ($self, $noun, $count) = @_;

    return sprintf("%s%s",
        $noun,
        (($count > 1) ? "s" : "")
    );
}

=head2 $self->_run_sequence(\@params)

Runs the sequence of commands specified using
C<_calc__${calling_sub}__callbacks> while passing @params to
each one. Generates a list of all the callbacks return values.

=cut

sub _run_sequence
{
    my $self = shift;
    my $params = shift || [];

    my $sub = (caller(1))[3];

    $sub =~ s{::_?([^:]+)$}{};

    my $calc_cbs_sub = "_calc__${1}__callbacks";

    return
    [
        map { my $cb = $_; $self->$cb(@$params); }
        @{$self->$calc_cbs_sub(@$params)}
    ];
}

1;

__END__

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

