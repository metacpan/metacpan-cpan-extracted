package WWW::MenuGrinder::Plugin::Variables;
BEGIN {
  $WWW::MenuGrinder::Plugin::Variables::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that does variable substitutions and checks.

use Moose;
use List::Util;

with 'WWW::MenuGrinder::Role::ItemMogrifier';

sub plugin_required_grinder_methods { qw(get_variable) }

has 'substitute_fields' => (
  is => 'ro',
  default => sub { [ 'label' ] }
);

sub get_var {
  my ($self, $varname) = @_;

  return $self->grinder->get_variable($varname);
}

sub get_defined_var {
  my ($self, $varname) = @_;

  my $value = $self->grinder->get_variable($varname);
  warn "Menu variable '$varname' was undefined in substitution." unless defined $value;
  return $value;
}

sub item_mogrify {
  my ($self, $item) = @_;

  if (exists $item->{need_var}) {
    my @vars = ref($item->{need_var}) ? 
      @{ $item->{need_var} } : $item->{need_var};
    for my $var (@vars) {
      if (!defined $self->get_var($var) ) {
        return ();
      }
    }
  }

  if (exists $item->{no_var}) {
    my @vars = ref($item->{no_var}) ? 
      @{ $item->{no_var} } : $item->{no_var};
    for my $var (@vars) {
      if (defined $self->get_var($var) ) {
        return ();
      }
    }
  }

  for my $field (@{ $self->substitute_fields }) {
    next unless exists $item->{$field};

    $item->{$field} =~ s/\${([^}]+)}/$self->get_defined_var($1)/eg;
  }

  return $item;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::Variables - WWW::MenuGrinder plugin that does variable substitutions and checks.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::Variables> is a plugin for C<WWW::MenuGrinder>. You
should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

When loaded, this plugin will interpolate named variables into menu fields from
the application context. It will also remove any item containing a C<need_var>
key naming a variable that does exist (and all of that item's descendents), as
well as any item containing a C<no_var> key naming a variable that I<does> exist
(and all of that item's descendents).

The variable interpolation syntax is akin to Perl's, except that curly braces
are mandatory. For example, the string C<"Hello, ${object}!"> becomes 
C<"Hello, world!"> if the variable C<object> holds the value C<"world">.

=head2 Configuration

=over 4

=item * C<substitute_fields>

An arrayref containing the names of menu keys to perform variable substitution
on. Defaults to C<['label']>.

=head2 Required Methods

In order to load this plugin your C<WWW::MenuGrinder> subclass must implement
the method C<get_variable> accepting a variable name (without C<${}>) and
returning the value of that variable, or undef if the variable does not exist or
is not set. Existence and definedness are not distinguished. The source of
"variables" is left entirely to the implementer, but might be the stash, the
session, the application configuration, or some combination.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

