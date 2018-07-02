package WWW::YNAB::Budget;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::Budget::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: Budget model object

use Carp;
use Moose::Util::TypeConstraints qw(find_type_constraint);

with 'WWW::YNAB::ModelHelpers';



has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has name => (
    is  => 'ro',
    isa => 'Str',
);


has last_modified_on => (
    is  => 'ro',
    isa => 'Str',
);


has first_month => (
    is  => 'ro',
    isa => 'Str',
);


has last_month => (
    is  => 'ro',
    isa => 'Str',
);


has server_knowledge => (
    is  => 'ro',
    isa => 'Int',
);


has _accounts => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[WWW::YNAB::Account]',
    init_arg => 'accounts',
    lazy     => 1,
    builder  => '_build_accounts',
    handles  => {
        accounts => 'elements',
    }
);


has _payees => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[WWW::YNAB::Payee]',
    init_arg => 'payees',
    lazy     => 1,
    builder  => '_build_payees',
    handles  => {
        payees => 'elements',
    }
);



has _category_groups => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[WWW::YNAB::CategoryGroup]',
    init_arg => 'category_groups',
    lazy     => 1,
    builder  => '_build_categories',
    handles  => {
        categories      => 'elements',
        category_groups => 'elements',
    }
);


has _months => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[WWW::YNAB::Month]',
    init_arg => 'months',
    lazy     => 1,
    builder  => '_build_months',
    handles  => {
        months => 'elements',
    }
);


has _transactions => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[WWW::YNAB::Transaction]',
    init_arg => 'transactions',
    lazy     => 1,
    builder  => '_build_transactions',
    handles  => {
        transactions => 'elements',
    }
);


has _scheduled_transactions => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[WWW::YNAB::ScheduledTransaction]',
    init_arg => 'scheduled_transactions',
    lazy     => 1,
    builder  => '_build_scheduled_transactions',
    handles  => {
        scheduled_transactions => 'elements',
    }
);

has _ua => (
    is       => 'ro',
    isa      => 'WWW::YNAB::UA',
    required => 1,
);

sub _build_accounts {
    my $self = shift;

    my $data = $self->_ua->get("/budgets/${\$self->id}/accounts");
    [
        map {
            $self->model_from_data('WWW::YNAB::Account', $_)
        } @{ $data->{data}{accounts} }
    ]
}


sub account {
    my $self = shift;
    my ($id) = @_;

    my $data = $self->_ua->get("/budgets/${\$self->id}/accounts/$id");
    my $account = $data->{data}{account};
    $self->model_from_data('WWW::YNAB::Account', $account);
}

sub _build_categories {
    my $self = shift;

    my $data = $self->_ua->get("/budgets/${\$self->id}/categories");
    [
        map {
            my %category_group = %$_;
            my @categories = map {
                $self->model_from_data('WWW::YNAB::Category', $_)
            } @{ $category_group{categories} };
            $category_group{categories} = \@categories;
            $self->model_from_data('WWW::YNAB::CategoryGroup', \%category_group)
        } @{ $data->{data}{category_groups} }
    ]
}


sub category {
    my $self = shift;
    my ($id) = @_;

    my $data = $self->_ua->get("/budgets/${\$self->id}/categories/$id");
    my $category = $data->{data}{category};
    $self->model_from_data('WWW::YNAB::Category', $category);
}

sub _build_payees {
    my $self = shift;

    my $data = $self->_ua->get("/budgets/${\$self->id}/payees");
    [
        map {
            $self->model_from_data('WWW::YNAB::Payee', $_)
        } @{ $data->{data}{payees} }
    ]
}


sub payee {
    my $self = shift;
    my ($id) = @_;

    my $data = $self->_ua->get("/budgets/${\$self->id}/payees/$id");
    my $payee = $data->{data}{payee};
    $self->model_from_data('WWW::YNAB::Payee', $payee);
}

sub _build_months {
    my $self = shift;

    my $data = $self->_ua->get("/budgets/${\$self->id}/months");
    [
        map {
            $self->model_from_data('WWW::YNAB::Month', $_)
        } @{ $data->{data}{months} }
    ]
}


sub month {
    my $self = shift;
    my ($id) = @_;

    my $data = $self->_ua->get("/budgets/${\$self->id}/months/$id");
    my $month = $data->{data}{month};
    my %month = %$month;
    my @categories = map {
        $self->model_from_data('WWW::YNAB::Category', $_)
    } @{ $month{categories} };
    $month{categories} = \@categories;
    $self->model_from_data('WWW::YNAB::Month', \%month);
}


sub find_transactions {
    my $self = shift;
    my %query = @_;

    if ((grep { defined } @query{qw(account category payee type)}) > 1) {
        croak "You can only query transactions by at most one of account, category, payee, or type";
    }

    my $path;
    if ($query{account}) {
        $path = "/budgets/${\$self->id}/accounts/$query{account}/transactions";
    }
    elsif ($query{category}) {
        $path = "/budgets/${\$self->id}/categories/$query{category}/transactions";
    }
    elsif ($query{payee}) {
        $path = "/budgets/${\$self->id}/payees/$query{payee}/transactions";
    }
    else {
        $path = "/budgets/${\$self->id}/transactions";
    }

    my $params;
    if ($query{type}) {
        $params ||= {};
        $params->{type} = $query{type};
    }
    if ($query{since_date}) {
        $params ||= {};
        $params->{since_date} = $query{since_date};
    }

    my $data = $self->_ua->get($path, $params);
    map {
        my %transaction = %$_;
        my @subtransactions = map {
            $self->model_from_data('WWW::YNAB::SubTransaction', $_)
        } @{ $transaction{subtransactions} };
        $transaction{subtransactions} = \@subtransactions;
        $self->model_from_data('WWW::YNAB::Transaction', \%transaction)
    } @{ $data->{data}{transactions} };
}

sub _build_transactions {
    my $self = shift;

    $self->find_transactions
}


sub transaction {
    my $self = shift;
    my ($id) = @_;

    my $data = $self->_ua->get("/budgets/${\$self->id}/transactions/$id");
    my $transaction = $data->{data}{transaction};
    my %transaction = %$transaction;
    my @subtransactions = map {
        $self->model_from_data('WWW::YNAB::SubTransaction', $_)
    } @{ $transaction{subtransactions} };
    $transaction{subtransactions} = \@subtransactions;
    $self->model_from_data('WWW::YNAB::Transaction', \%transaction);
}

sub _build_scheduled_transactions {
    my $self = shift;

    my $data = $self->_ua->get("/budgets/${\$self->id}/scheduled_transactions");
    [
        map {
            my %transaction = %$_;
            my @subtransactions = map {
                $self->model_from_data('WWW::YNAB::ScheduledSubTransaction', $_)
            } @{ $transaction{subtransactions} };
            $transaction{subtransactions} = \@subtransactions;
            $self->model_from_data('WWW::YNAB::ScheduledTransaction', \%transaction)
        } @{ $data->{data}{scheduled_transactions} }
    ]
}


sub scheduled_transaction {
    my $self = shift;
    my ($id) = @_;

    my $data = $self->_ua->get("/budgets/${\$self->id}/scheduled_transactions/$id");
    my $transaction = $data->{data}{scheduled_transaction};
    my %transaction = %$transaction;
    my @subtransactions = map {
        $self->model_from_data('WWW::YNAB::ScheduledSubTransaction', $_)
    } @{ $transaction{subtransactions} };
    $transaction{subtransactions} = \@subtransactions;
    $self->model_from_data('WWW::YNAB::ScheduledTransaction', \%transaction);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB::Budget - Budget model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my $budget = $ynab->budget('12345678-1234-1234-1234-1234567890ab');

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/Budgets> for more information.

=head1 METHODS

=head2 id

=head2 name

=head2 last_modified_on

=head2 first_month

=head2 last_month

=head2 server_knowledge

=head2 accounts

=head2 payees

=head2 categories

=head2 category_groups

Alias for C<categories>.

=head2 months

=head2 transactions

=head2 scheduled_transactions

=head2 account($id)

Returns the account with id C<$id>.

=head2 category($id)

Returns the category with id C<$id>.

=head2 payee($id)

Returns the payee with id C<$id>.

=head2 month($id)

Returns the month with id C<$id>.

=head2 find_transactions(%query)

Finds transactions based on query parameters. Valid options are (all optional):

=over 4

=item account

=item category

=item payee

=item type

=item since_date

=back

Note that only one of C<account>, C<category>, C<payee>, or C<type> may be
specified.

=head2 transaction($id)

Returns the transaction with id C<$id>.

=head2 scheduled_transaction($id)

Returns the scheduled transaction with id C<$id>.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
