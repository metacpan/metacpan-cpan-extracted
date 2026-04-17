package WWW::PayPal::Plan;

# ABSTRACT: PayPal Billing Plan entity

use Moo;
use namespace::clean;

our $VERSION = '0.002';


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => ( is => 'rw', required => 1 );


sub id             { $_[0]->data->{id} }
sub product_id     { $_[0]->data->{product_id} }
sub name           { $_[0]->data->{name} }
sub description    { $_[0]->data->{description} }
sub status         { $_[0]->data->{status} }
sub billing_cycles { $_[0]->data->{billing_cycles} }
sub create_time    { $_[0]->data->{create_time} }
sub update_time    { $_[0]->data->{update_time} }


sub activate {
    my ($self) = @_;
    $self->_client->plans->activate($self->id);
    $self->refresh;
    return $self;
}

sub deactivate {
    my ($self) = @_;
    $self->_client->plans->deactivate($self->id);
    $self->refresh;
    return $self;
}


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->plans->get($self->id);
    $self->data($fresh->data);
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::Plan - PayPal Billing Plan entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    print $plan->id;
    print $plan->name;
    print $plan->status;          # CREATED / ACTIVE / INACTIVE

    $plan->deactivate;
    $plan->activate;

=head1 DESCRIPTION

Wrapper around a PayPal Billing Plan JSON object.

=head2 data

Raw decoded JSON for the plan.

=head2 id

Plan ID (e.g. C<P-XXX...>). Pass this to
L<WWW::PayPal::API::Subscriptions/create>.

=head2 product_id

=head2 name

=head2 description

=head2 status

C<CREATED>, C<ACTIVE> or C<INACTIVE>.

=head2 billing_cycles

ArrayRef of billing cycle definitions (frequency + pricing).

=head2 create_time

=head2 update_time

=head2 activate

=head2 deactivate

    $plan->activate;
    $plan->deactivate;

Toggles the plan's C<status> and re-fetches.

=head2 refresh

    $plan->refresh;

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-paypal/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
