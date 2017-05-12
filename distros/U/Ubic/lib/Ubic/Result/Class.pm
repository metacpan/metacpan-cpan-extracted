package Ubic::Result::Class;
$Ubic::Result::Class::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: ubic result object


use overload '""' => sub {
    my $self = shift;
    return $self->as_string;
}, 'eq' => sub {
    return ("$_[0]" eq "$_[1]")
}, 'ne' => sub {
    return ("$_[0]" ne "$_[1]")
};

use Params::Validate qw(:all);
use Carp;
use parent qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/ type msg /);

sub new {
    my $class = shift;
    my $self = validate(@_, {
        type => { type => SCALAR, optional => 1 },
        msg => { optional => 1 },
        cached => { optional => 1 },
    });
    $self->{type} ||= 'unknown';
    return bless $self => $class;
}

sub status {
    my $self = shift;
    croak 'status() is read-only method' if @_;
    if (grep { $_ eq $self->{type} } ('running', 'already running', 'started', 'already started', 'restarted', 'reloaded', 'stopping')) {
        return 'running';
    }
    elsif (grep { $_ eq $self->{type} } ('not running', 'stopped', 'starting')) {
        return 'not running';
    }
    elsif (grep { $_ eq $self->{type} } ('down')) {
        return 'down';
    }
    elsif (grep { $_ eq $self->{type} } ('autostarting')) {
        return 'autostarting';
    }
    else {
        return 'broken';
    }
}

sub action {
    my $self = shift;
    croak 'action() is read-only method' if @_;
    if (grep { $_ eq $self->{type} } ('started', 'stopped', 'reloaded')) {
        return $self->{type};
    }
    return 'none';
}

sub as_string {
    my $self = shift;
    my $cached_str = ($self->{cached} ? ' [cached]' : '');
    if (defined $self->{msg}) {
        if ($self->{type} eq 'unknown') {
            return "$self->{msg}\n";
        }
        else {
            return "$self->{type} ($self->{msg})".$cached_str;
        }
    }
    else {
        return $self->type.$cached_str;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Result::Class - ubic result object

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::Result qw(result);

    my $result = result("already running");
    print $result->status; # running
    print "$result"; # already running

=head1 DESCRIPTION

Ubic::Result::Class instances represent service operation results.

Many service actions can *do* something and *result* in something.
So, this class dissects service operation into C<action()> and C<status()>.
For example, "already running" result means that current service status is "running" and action is "none".

Also, it carry custom comment and serialize result into common stringified form.

Ubic::Result::Class instances are usually created via C<result()> function from L<Ubic::Result> package.

=head1 STATUSES

Possible statuses:

=over

=item I<running>

=item I<not running>

=item I<broken>

=item I<down>

=item I<autostarting>

=back

=head1 ACTIONS

Actions are something that was done which resulted in current status by invoked method.

Possible actions:

=over

=item I<started>

=item I<stopped>

=item I<none>

=item I<reloaded>

=back

=head1 METHODS

=over

=item B<< new({ type => $type, msg => $msg }) >>

Constructor.

=item B<< status() >>

Get status, see above for possible values.

=item B<< action() >>

Get action.

=item B<< as_string() >>

Get string representation.

=back

=head1 SEE ALSO

L<Ubic::Result> - service action's result.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
