package WWW::YNAB::Category;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::Category::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: Category model object



has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has category_group_id => (
    is  => 'ro',
    isa => 'Str',
);


has name => (
    is  => 'ro',
    isa => 'Str',
);


has hidden => (
    is  => 'ro',
    isa => 'Bool',
);


has note => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has budgeted => (
    is  => 'ro',
    isa => 'Int',
);


has activity => (
    is  => 'ro',
    isa => 'Int',
);


has balance => (
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

WWW::YNAB::Category - Category model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my @budgets = $ynab->budgets;
  my $transaction = $budgets[0]->category('12345678-1234-1234-1234-1234567890ab');

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/Categories> for more information.

=head1 METHODS

=head2 id

=head2 category_group_id

=head2 name

=head2 hidden

=head2 note

=head2 budgeted

=head2 activity

=head2 balance

=head2 deleted

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
