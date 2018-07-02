package WWW::YNAB::CategoryGroup;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::CategoryGroup::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: CategoryGroup model object



has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has name => (
    is  => 'ro',
    isa => 'Str',
);


has hidden => (
    is  => 'ro',
    isa => 'Bool',
);


has deleted => (
    is  => 'ro',
    isa => 'Bool',
);


has categories => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => 'ArrayRef[WWW::YNAB::Category]',
    handles => {
        categories => 'elements',
    }
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB::CategoryGroup - CategoryGroup model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my @budgets = $ynab->budgets;
  my @category_groups = $budgets[0]->category_groups

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/Categories> for more information.

=head1 METHODS

=head2 id

=head2 name

=head2 hidden

=head2 deleted

=head2 categories

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
