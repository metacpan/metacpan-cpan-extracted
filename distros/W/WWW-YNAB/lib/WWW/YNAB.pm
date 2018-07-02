package WWW::YNAB;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: Wrapper for the YNAB API

use WWW::YNAB::Account;
use WWW::YNAB::Budget;
use WWW::YNAB::CategoryGroup;
use WWW::YNAB::Category;
use WWW::YNAB::Month;
use WWW::YNAB::Payee;
use WWW::YNAB::ScheduledSubTransaction;
use WWW::YNAB::ScheduledTransaction;
use WWW::YNAB::SubTransaction;
use WWW::YNAB::Transaction;
use WWW::YNAB::UA;
use WWW::YNAB::User;

with 'WWW::YNAB::ModelHelpers';



has access_token => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has base_uri => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://api.youneedabudget.com/v1/',
);


has ua => (
    is      => 'ro',
    isa     => 'HTTP::Tiny',
    lazy    => 1,
    default => sub { HTTP::Tiny->new },
);

has _ua => (
    is      => 'ro',
    isa     => 'WWW::YNAB::UA',
    lazy    => 1,
    default => sub {
        my $self = shift;
        WWW::YNAB::UA->new(
            access_token => $self->access_token,
            base_uri     => $self->base_uri,
            ua           => $self->ua,
        )
    },
);


sub user {
    my $self = shift;

    my $data = $self->_ua->get('/user');
    my $user = $data->{data}{user};
    $self->model_from_data('WWW::YNAB::User', $user);
}


sub budgets {
    my $self = shift;

    my $data = $self->_ua->get('/budgets');
    map {
        $self->model_from_data('WWW::YNAB::Budget', $_)
    } @{ $data->{data}{budgets} };
}


sub budget {
    my $self = shift;
    my ($id, $server_knowledge) = @_;

    my $params;
    if (defined $server_knowledge) {
        $params = {
            last_knowledge_of_server => $server_knowledge,
        }
    }

    my $data = $self->_ua->get("/budgets/$id", $params);
    my $budget = $data->{data}{budget};
    my %budget = %$budget;

    my @accounts = map {
        $self->model_from_data('WWW::YNAB::Account', $_)
    } @{ $budget{accounts} };
    $budget{accounts} = \@accounts;

    my @payees = map {
        $self->model_from_data('WWW::YNAB::Payee', $_)
    } @{ $budget{payees} };
    $budget{payees} = \@payees;

    my @category_groups = map {
        my %category_group = %$_;
        $category_group{categories} = [
            map {
                $self->model_from_data('WWW::YNAB::Category', $_)
            } grep {
                $_->{category_group_id} eq $category_group{id}
            } @{ $budget{categories} }
        ];
        $self->model_from_data('WWW::YNAB::CategoryGroup', \%category_group)
    } @{ $budget{category_groups} };
    $budget{category_groups} = \@category_groups;

    my @months = map {
        my %month = %$_;
        $month{categories} = [
            map {
                $self->model_from_data('WWW::YNAB::Category', $_)
            } @{ $month{categories} }
        ];
        $self->model_from_data('WWW::YNAB::Month', \%month)
    } @{ $budget{months} };
    $budget{months} = \@months;

    my @transactions = map {
        my %transaction = %$_;
        if ($transaction{account_id}) {
            ($transaction{account_name}) = map {
                $_->{name}
            } grep {
                $_->{id} eq $transaction{account_id}
            } @{ $budget{accounts} };
        }
        if ($transaction{payee_id}) {
            ($transaction{payee_name}) = map {
                $_->{name}
            } grep {
                $_->{id} eq $transaction{payee_id}
            } @{ $budget{payees} };
        }
        if ($transaction{category_id}) {
            ($transaction{category_name}) = map {
                $_->{name}
            } grep {
                $_->{id} eq $transaction{category_id}
            } @{ $budget{categories} };
        }
        $transaction{subtransactions} = [
            map {
                $self->model_from_data('WWW::YNAB::SubTransaction', $_)
            } grep {
                $_->{transaction_id} eq $transaction{id}
            } @{ $budget{subtransactions} }
        ];
        $self->model_from_data('WWW::YNAB::Transaction', \%transaction)
    } @{ $budget{transactions} };
    $budget{transactions} = \@transactions;

    my @scheduled_transactions = map {
        my %transaction = %$_;
        if ($transaction{account_id}) {
            ($transaction{account_name}) = map {
                $_->{name}
            } grep {
                $_->{id} eq $transaction{account_id}
            } @{ $budget{accounts} };
        }
        if ($transaction{payee_id}) {
            ($transaction{payee_name}) = map {
                $_->{name}
            } grep {
                $_->{id} eq $transaction{payee_id}
            } @{ $budget{payees} };
        }
        if ($transaction{category_id}) {
            ($transaction{category_name}) = map {
                $_->{name}
            } grep {
                $_->{id} eq $transaction{category_id}
            } @{ $budget{categories} };
        }
        $transaction{subtransactions} = [
            map {
                $self->model_from_data('WWW::YNAB::ScheduledSubTransaction', $_)
            } grep {
                $_->{scheduled_transaction_id} eq $transaction{id}
            } @{ $budget{scheduled_subtransactions} }
        ];
        $self->model_from_data('WWW::YNAB::ScheduledTransaction', \%transaction)
    } @{ $budget{scheduled_transactions} };
    $budget{scheduled_transactions} = \@scheduled_transactions;

    $self->model_from_data(
        'WWW::YNAB::Budget',
        \%budget,
        $data->{data}{server_knowledge},
    );
}


sub rate_limit {
    my $self = shift;

    $self->_ua->rate_limit
}


sub knows_rate_limit {
    my $self = shift;

    $self->_ua->knows_rate_limit
}


sub total_rate_limit {
    my $self = shift;

    $self->_ua->total_rate_limit
}


sub knows_total_rate_limit {
    my $self = shift;

    $self->_ua->knows_total_rate_limit
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB - Wrapper for the YNAB API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(access_token => 'SECRET');
  my @budgets = $ynab->budgets;

=head1 DESCRIPTION

This module is a wrapper around the V1 YNAB API. It follows the API structure
quite closely, so the API documentation should be used for information about
the data that this module returns. You can find the API documentation at L<https://api.youneedabudget.com/>.

=head1 ATTRIBUTES

=head2 access_token

Your personal access token. Information about generating a personal access
token can be found at
L<https://api.youneedabudget.com/#personal-access-tokens>. Required.

=head2 base_uri

The base uri for all API requests. Defaults to
C<https://api.youneedabudget.com/v1/>. It's unlikely you'll need to change
this.

=head2 ua

The HTTP user agent to use. Must be compatible with L<HTTP::Tiny>.

=head1 METHODS

=head2 user

=head2 budgets

=head2 budget($id, $server_knowledge=undef)

Returns the budget with id C<$id>. The returned budget object will have a
C<server_knowledge> method which represents the state of the server when that
object was returned. If the C<$server_knowledge> parameter is passed here with
a value that came from an object previously returned by this method, this
method will only return sub-objects (transactions, accounts, etc.) which have
changed since that previous object was generated.

=head2 rate_limit

Returns the number of requests in the current rate limit bucket.

=head2 knows_rate_limit

Returns true if the current rate limit is known. This will only be true after a
request has already been made (since the API currently doesn't provide a way to
just request the current rate limit).

=head2 total_rate_limit

Returns the total number of requests that will be allowed in the current rate
limit bucket.

=head2 knows_total_rate_limit

Returns true if the current total rate limit is known. This will only be true
after a request has already been made (since the API currently doesn't provide
a way to just request the current rate limit).

=head1 BUGS/LIMITATIONS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/www-ynab/issues>.

Not all of the API is exposed by this wrapper yet. In particular, these things
are missing:

=over 4

=item All modification endpoints (this module currently only exposes read-only operations)

=item The payee location API

=item OAuth authentication

=back

Patches are greatly appreciated if you are interested in this functionality.

=head1 SEE ALSO

L<https://api.youneedabudget.com/>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc WWW::YNAB

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/WWW-YNAB>

=item * Github

L<https://github.com/doy/www-ynab>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-YNAB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-YNAB>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
