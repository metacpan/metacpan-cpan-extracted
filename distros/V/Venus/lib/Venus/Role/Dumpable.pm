package Venus::Role::Dumpable;

use 5.018;

use strict;
use warnings;

use Moo::Role;

# METHODS

sub dump {
  my ($self, $method, @args) = @_;

  require Data::Dumper;

  no warnings 'once';

  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;

  my $data = Data::Dumper->Dump([
    $method ? scalar($self->$method(@args)) : $self
  ]);

  $data =~ s/^"|"$//g;

  return $data;
}

sub dump_pretty {
  my ($self, $method, @args) = @_;

  require Data::Dumper;

  no warnings 'once';

  local $Data::Dumper::Indent = 2;
  local $Data::Dumper::Trailingcomma = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Pad = '';
  local $Data::Dumper::Varname = 'VAR';
  local $Data::Dumper::Useqq = 0;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Freezer = '';
  local $Data::Dumper::Toaster = '';
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Bless = 'bless';
  local $Data::Dumper::Pair = ' => ';
  local $Data::Dumper::Maxdepth = 0;
  local $Data::Dumper::Maxrecurse = 1000;
  local $Data::Dumper::Useperl = 0;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sparseseen = 0;

  my $data = Data::Dumper->Dump([
    $method ? scalar($self->$method(@args)) : $self
  ]);

  $data =~ s/^'|'$//g;

  chomp $data;

  return $data;
}

1;



=head1 NAME

Venus::Role::Dumpable - Dumpable Role

=cut

=head1 ABSTRACT

Dumpable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  has 'test';

  with 'Venus::Role::Dumpable';

  package main;

  my $example = Example->new(test => 123);

  # $example->dump;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for dumping
the object or the return value of a dispatched method call.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 dump

  dump(Str | CodeRef $method, Any @args) (Str)

The dump method returns a string representation of the underlying data. This
method supports dispatching, i.e. providing a method name and arguments whose
return value will be acted on by this method.

I<Since C<0.01>>

=over 4

=item dump example 1

  package main;

  my $example = Example->new(test => 123);

  my $dump = $example->dump;

  # "bless( {test => 123}, 'Example' )"

=back

=cut

=head2 dump_pretty

  dump_pretty(Str | CodeRef $method, Any @args) (Str)

The dump_pretty method returns a string representation of the underlying data
that is human-readable and useful for debugging. This method supports
dispatching, i.e. providing a method name and arguments whose return value will
be acted on by this method.

I<Since C<0.01>>

=over 4

=item dump_pretty example 1

  package main;

  my $example = Example->new(test => 123);

  my $dump_pretty = $example->dump_pretty;

  # bless( {
  #          test => 123
  #        }, 'Example' )

=back

=cut

=head1 AUTHORS

Cpanery, C<cpanery@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2021, Cpanery

Read the L<"license"|https://github.com/cpanery/venus/blob/master/LICENSE> file.

=cut