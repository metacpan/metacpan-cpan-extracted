package WWW::YNAB::Month;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::Month::VERSION = '0.02';

use 5.010;
use Moose;
# ABSTRACT: Month model object



has month => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has note => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);


has to_be_budgeted => (
    is  => 'ro',
    isa => 'Maybe[Int]',
);


has age_of_money => (
    is  => 'ro',
    isa => 'Maybe[Int]',
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

WWW::YNAB::Month - Month model object

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use WWW::YNAB;

  my $ynab = WWW::YNAB->new(...);
  my @budgets = $ynab->budgets;
  my $month = $budgets[0]->month('2018-06-01');

=head1 OVERVIEW

See L<https://api.youneedabudget.com/v1#/Months> for more information.

=head1 METHODS

=head2 month

=head2 note

=head2 to_be_budgeted

=head2 age_of_money

=head2 categories

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
