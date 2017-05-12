package aliased::factory;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

=head1 NAME

aliased::factory - shorter versions of a class tree's constructors

=head1 SYNOPSIS

  use aliased::factory YAPI => 'Yahoo::Marketing';

  my $service = YAPI->KeywordResearchService->new(...);

  my $res = $service->getRelatedKeywords(
    relatedKeywordRequest =>
      YAPI->RelatedKeywordRequestType->new(...)
  );

=head1 About

This package is similar to L<aliased>, but performs on-demand loading
for packages below the shortened 'root package'.  For example, the above
code will automatically load the KeywordResearchService and
RelatedKeywordRequestType packages from the Yahoo::Marketing::
hierarchy.

To load a second-level package:

  use aliased::factory BAR => 'Foo::Bar';

  my $bort = BAR->Baz->Bort->new(...);

This would load the Foo::Bar::Baz and then Foo::Bar::Baz::Bort packages.
Each method call require()s the corresponding package and returns an
aliased::factory object, which has a new() method (see below.)

=cut

my $new_factory = sub {
  my $class = shift;
  bless \(shift) => $class;
};

my $err;

my $load = sub {
  my $package = shift;
  $package =~ s#::#/#g;
  $package .= '.pm';
  return 1 if(exists $INC{$package});

  local $@;
  my $ans = eval {require($package)};
  if($err = $@) {
    my $f = __FILE__;
    ($err = $@) =~ s/ at $f line \d+\.\n//;
    return;
  }

  return($ans);
};

=head1 Factory Method

=head2 new

Returns a new object of the class represented by the $factory object.

  my $instantiated = $factory->new(...);

The class being instantiated must have a new() method.

=cut

sub new {
  my $self = shift;
  return $$self->new(@_);
} ######################################################################

=head1 Meta Methods

The rest of this is functionality used to create the factory.

=head2 import

Installs a sub 'shortname' in your package containing an object pointed
at $package.

  aliased::factory->import(shortname => $package);

=cut

sub import {
  my $class = shift;
  @_ or return;

  my ($alias, $package, @also) = @_;
  croak("error") if(@also);

  my $caller = caller;

  unless(defined $package) {
    $package = $alias;
    $alias =~ s/.*:://;
  }

  $load->($package) or croak($err);

  my $obj = $class->$new_factory($package);
  no strict 'refs';
  *{$caller . '::' . $alias} = sub { $obj };
} ######################################################################

=head2 can

When called on a factory object, attempts to require the subpackage.  If
this succeeds, it will return a coderef (which will return the
subfactory when executed.)

  my $coderef = $factory->can('subpackage');

This method is used by AUTOLOAD().

=cut

sub can {
  my $self = shift;
  my $class = ref($self) or return($self->SUPER::can(@_));
  my ($subpack) = @_;

  my $package = $$self . '::' . $subpack;
  $load->($package) or return;
  my $obj = $class->$new_factory($package);
  return sub {$obj};
} ######################################################################

=head2 AUTOLOAD

Attempts to load the $factory's corresponding subpackage, returns a the
subfactory object or throws a fatal error: "Can't locate ... in @INC
...".

  my $subfactory = $factory->subpackage;

=cut

sub AUTOLOAD {
  my $self = shift;
  @_ and croak("subfactories cannot have arguments");

  (my $method = our $AUTOLOAD) =~ s/.*:://;
  return if $method eq 'DESTROY';
  my $sub = $self->can($method) or croak($err);
  return $sub->();
} ######################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

=head1 Acknowledgements

Thanks to HDP for the suggestion of using a factory object.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
