package Ubic::Multiservice::Simple;
$Ubic::Multiservice::Simple::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: simplest multiservice, configured in constructor


use Params::Validate qw(:all);
use Scalar::Util qw(blessed);
use parent qw(Ubic::Multiservice);

sub new {
    my $class = shift;
    my ($params) = validate_pos(@_, {
        type => HASHREF,
        callbacks => {
            'values are services' => sub {
                for (values %{shift()}) {
                    return unless blessed($_) and $_->isa('Ubic::Service')
                }
                return 1;
            },
        }
    });
    return bless { services => $params } => $class;
}

sub has_simple_service($$) {
    my ($self, $name) = @_;
    return exists $self->{services}{$name};
}

sub simple_service($$) {
    my ($self, $name) = @_;
    return $self->{services}{$name};
}

sub service_names($) {
    my $self = shift;
    return keys %{ $self->{services} };
}

sub multiop {
    return 'allowed'; # simple multiservices are usually simple enough to allow multiservice-wide actions by default
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Multiservice::Simple - simplest multiservice, configured in constructor

=head1 VERSION

version 1.60

=head1 SYNOPSIS

use Ubic::Multiservice::Simple;

$ms = Ubic::Multiservice::Simple->new({
    service1 => $s1,
    service2 => $s2,
});

=head1 METHODS

=over

=item C<< new($params) >>

Construct new C<Ubic::Multiservice::Simple> object.

C<$params> must be hashref with service names as keys and services as values.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
