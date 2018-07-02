package WWW::YNAB::Transaction;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::Transaction::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: Transaction model object

use Moose::Util::TypeConstraints qw(enum maybe_type);



has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has date => (
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


has cleared => (
    is  => 'ro',
    isa => enum([qw(cleared uncleared reconciled)]),
);


has approved => (
    is  => 'ro',
    isa => 'Bool',
);


has flag_color => (
    is  => 'ro',
    isa => maybe_type(enum([qw(red orange yellow green blue purple)])),
);


has account_id => (
    is  => 'ro',
    isa => 'Str',
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


has import_id => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has deleted => (
    is  => 'ro',
    isa => 'Bool',
);


has account_name => (
    is  => 'ro',
    isa => 'Str',
);


has payee_name => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has category_name => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has subtransactions => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => 'ArrayRef[WWW::YNAB::SubTransaction]',
    handles => {
        subtransactions => 'elements',
    }
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB::Transaction - Transaction model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my @budgets = $ynab->budgets;
  my $transaction = $budgets[0]->transaction('12345678-1234-1234-1234-1234567890ab');

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/Transactions> for more information.

=head1 METHODS

=head2 id

=head2 date

=head2 amount

=head2 memo

=head2 cleared

=head2 approved

=head2 flag_color

=head2 account_id

=head2 payee_id

=head2 category_id

=head2 transfer_account_id

=head2 import_id

=head2 deleted

=head2 account_name

=head2 payee_name

=head2 category_name

=head2 subtransactions

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
