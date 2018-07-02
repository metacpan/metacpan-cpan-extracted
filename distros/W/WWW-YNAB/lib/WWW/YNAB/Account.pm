package WWW::YNAB::Account;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::Account::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: Account model object

use Moose::Util::TypeConstraints qw(enum);

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


has type => (
    is  => 'ro',
    isa => enum([
        qw(checking savings cash creditCard lineOfCredit
           otherAsset otherLiability payPal merchantAccount
           investmentAccount mortgage)
    ]),
);


has on_budget => (
    is  => 'ro',
    isa => 'Bool',
);


has closed => (
    is  => 'ro',
    isa => 'Bool',
);


has note => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has balance => (
    is  => 'ro',
    isa => 'Int',
);


has cleared_balance => (
    is  => 'ro',
    isa => 'Int',
);


has uncleared_balance => (
    is  => 'ro',
    isa => 'Int',
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

WWW::YNAB::Account - Account model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my @budgets = $ynab->budgets;
  my $account = $budgets[0]->account('12345678-1234-1234-1234-1234567890ab');

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/Accounts> for more information.

=head1 METHODS

=head2 id

=head2 name

=head2 type

=head2 on_budget

=head2 closed

=head2 note

=head2 balance

=head2 cleared_balance

=head2 uncleared_balance

=head2 deleted

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
