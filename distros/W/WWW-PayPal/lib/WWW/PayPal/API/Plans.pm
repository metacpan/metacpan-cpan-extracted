package WWW::PayPal::API::Plans;

# ABSTRACT: PayPal Billing Plans API (v1)

use Moo;
use Carp qw(croak);
use WWW::PayPal::Plan;
use namespace::clean;

our $VERSION = '0.002';


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has openapi_operations => (
    is      => 'lazy',
    builder => sub {
        return {
            'billing.plans.create'     => { method => 'POST',  path => '/v1/billing/plans' },
            'billing.plans.list'       => { method => 'GET',   path => '/v1/billing/plans' },
            'billing.plans.get'        => { method => 'GET',   path => '/v1/billing/plans/{id}' },
            'billing.plans.patch'      => { method => 'PATCH', path => '/v1/billing/plans/{id}' },
            'billing.plans.activate'   => { method => 'POST',  path => '/v1/billing/plans/{id}/activate' },
            'billing.plans.deactivate' => { method => 'POST',  path => '/v1/billing/plans/{id}/deactivate' },
        };
    },
);

with 'WWW::PayPal::Role::OpenAPI';

sub _wrap {
    my ($self, $data) = @_;
    return WWW::PayPal::Plan->new(client => $self->client, data => $data);
}

sub create {
    my ($self, %args) = @_;
    croak 'product_id required'     unless $args{product_id};
    croak 'name required'           unless $args{name};
    croak 'billing_cycles required' unless ref $args{billing_cycles} eq 'ARRAY';

    my %body = (
        product_id     => $args{product_id},
        name           => $args{name},
        billing_cycles => $args{billing_cycles},
        payment_preferences => $args{payment_preferences} // {
            auto_bill_outstanding     => \1,
            payment_failure_threshold => 3,
        },
    );
    $body{description} = $args{description} if defined $args{description};
    $body{status}      = $args{status}      if defined $args{status};
    $body{taxes}       = $args{taxes}       if $args{taxes};
    $body{quantity_supported} = $args{quantity_supported} if defined $args{quantity_supported};

    my $data = $self->call_operation('billing.plans.create', body => \%body);
    return $self->_wrap($data);
}


sub create_monthly {
    my ($self, %args) = @_;
    croak 'product_id required' unless $args{product_id};
    croak 'name required'       unless $args{name};
    croak 'price required'      unless defined $args{price};
    my $currency = $args{currency} || 'EUR';

    my @cycles;
    if ($args{trial_days}) {
        push @cycles, {
            frequency    => { interval_unit => 'DAY', interval_count => 0 + $args{trial_days} },
            tenure_type  => 'TRIAL',
            sequence     => 1,
            total_cycles => 1,
            pricing_scheme => {
                fixed_price => { value => '0', currency_code => $currency },
            },
        };
    }
    push @cycles, {
        frequency    => { interval_unit => 'MONTH', interval_count => 1 },
        tenure_type  => 'REGULAR',
        sequence     => scalar(@cycles) + 1,
        total_cycles => $args{total_cycles} // 0,    # 0 = forever
        pricing_scheme => {
            fixed_price => { value => "$args{price}", currency_code => $currency },
        },
    };

    return $self->create(
        product_id     => $args{product_id},
        name           => $args{name},
        description    => $args{description},
        billing_cycles => \@cycles,
    );
}


sub get {
    my ($self, $id) = @_;
    croak 'plan id required' unless $id;
    return $self->_wrap($self->call_operation('billing.plans.get', path => { id => $id }));
}


sub list {
    my ($self, %args) = @_;
    my %query;
    for my $k (qw(product_id plan_ids page_size page total_required)) {
        $query{$k} = $args{$k} if defined $args{$k};
    }
    my $data = $self->call_operation('billing.plans.list',
        (%query ? (query => \%query) : ()));
    return [ map { $self->_wrap($_) } @{ $data->{plans} || [] } ];
}


sub activate {
    my ($self, $id) = @_;
    croak 'plan id required' unless $id;
    return $self->call_operation('billing.plans.activate', path => { id => $id }, body => '');
}

sub deactivate {
    my ($self, $id) = @_;
    croak 'plan id required' unless $id;
    return $self->call_operation('billing.plans.deactivate', path => { id => $id }, body => '');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::API::Plans - PayPal Billing Plans API (v1)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # Simple monthly flat-price plan
    my $plan = $pp->plans->create_monthly(
        product_id => $product->id,
        name       => 'Monthly VIP',
        price      => '9.99',
        currency   => 'EUR',
    );

    # Or full control:
    my $plan = $pp->plans->create(
        product_id     => $product->id,
        name           => 'Yearly VIP with 7 day trial',
        billing_cycles => [ ... ],
        payment_preferences => { ... },
    );

    $pp->plans->deactivate($plan->id);
    $pp->plans->activate($plan->id);

=head1 DESCRIPTION

Controller for PayPal's Billing Plans API. A plan defines the billing cycle
(frequency + pricing) that a L<subscription|WWW::PayPal::API::Subscriptions>
follows. Plans belong to a L<product|WWW::PayPal::API::Products>.

=head2 create

    my $plan = $pp->plans->create(
        product_id     => $pid,
        name           => 'Plan name',
        billing_cycles => [ ... ],
        payment_preferences => { ... },
    );

Creates a plan with full control over the billing cycles and payment
preferences. See PayPal's docs for the full schema.

=head2 create_monthly

    my $plan = $pp->plans->create_monthly(
        product_id => $pid,
        name       => 'Monthly VIP',
        price      => '9.99',
        currency   => 'EUR',           # default: EUR
        trial_days => 7,               # optional free trial
        total_cycles => 0,             # 0 = infinite, default
    );

Convenience shortcut for the common case: a monthly recurring plan with a
single fixed price and optional free trial. For anything more complex use
L</create>.

=head2 get

    my $plan = $pp->plans->get($id);

=head2 list

    my $plans = $pp->plans->list(product_id => $pid);

=head2 activate

=head2 deactivate

    $pp->plans->deactivate($id);
    $pp->plans->activate($id);

Activates / deactivates a plan. Deactivated plans can't be used for new
subscriptions but existing subscriptions continue to bill.

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
