package WWW::YNAB::ScheduledSubTransaction;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::ScheduledSubTransaction::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: ScheduledSubTransaction model object



has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has scheduled_transaction_id => (
    is  => 'ro',
    isa => 'Str',
);


has amount => (
    is  => 'ro',
    isa => 'Int',
);


has memo => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has payee_id => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has category_id => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has transfer_account_id => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has deleted => (
    is  => 'ro',
    isa => 'Bool',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB::ScheduledSubTransaction - ScheduledSubTransaction model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my @budgets = $ynab->budgets;
  my $scheduled_transaction = $budgets[0]->scheduled_transaction('12345678-1234-1234-1234-1234567890ab');
  my @scheduled_sub_transactions = $scheduled_transaction->subtransactions;

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/Scheduled_Transactions> for more
information.

=head1 METHODS

=head2 id

=head2 scheduled_transaction_id

=head2 amount

=head2 memo

=head2 payee_id

=head2 category_id

=head2 transfer_account_id

=head2 deleted

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
