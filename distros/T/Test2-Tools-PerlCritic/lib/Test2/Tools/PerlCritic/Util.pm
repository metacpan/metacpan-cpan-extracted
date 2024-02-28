package Test2::Tools::PerlCritic::Util;

use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );
use Ref::Util qw( is_blessed_ref );
use Carp qw( croak );
use Exporter qw( import );
use Data::Dumper ();
use Digest::MD5 qw( md5_hex );
use Perl::Critic;

our @EXPORT_OK = qw( perl_critic_config_id );

# ABSTRACT: Utility functions
our $VERSION = '0.08'; # VERSION


sub perl_critic_config_id ($config=undef)
{
  my @policies = sort { $a->get_short_name cmp $b->get_short_name } do {
    $config //= Perl::Critic->new;
    $config = $config->config if is_blessed_ref($config) and $config->isa('Perl::Critic');
    croak "Argument must be a Perl::Critic or Perl::Critic::Config"
      unless is_blessed_ref($config) and $config->isa('Perl::Critic::Config');
    $config->policies;
  };

  my %config = (
    perl_critic_version => Perl::Critic->VERSION,
    test2_tools_perl_critic_version => __PACKAEG__->VERSION,
    policies => {},
  );

  foreach my $policy (@policies)
  {
    next unless $policy->is_enabled;
    my $name = $policy->get_short_name;

    my $severity = $policy->get_severity;
    my $maximum_violations_per_document = $policy->get_maximum_violations_per_document;

    # we are assuming that we aren't using the same policy twice
    my $policy_config = $config{policies}->{$policy->get_short_name} = {
      version    => $policy->VERSION // '',
      parameters => {},
    };

    $policy_config->{severity} = $severity if defined $severity;
    $maximum_violations_per_document = $maximum_violations_per_document if defined $maximum_violations_per_document;

    foreach my $parameter ($policy->get_parameters->@*)
    {
      my $name = $parameter->get_name;
      # NOTE: this is private data to the policy, but
      # the convential way to store a parameter seems
      # to be with _$name
      my $value = $policy->{"_$name"};
      $policy_config->{parameters}->{$name} = $value;
    }
  }

  my $dumper = Data::Dumper
    ->new([\%config], ['config'])
    ->Sortkeys(1)
    ->Indent(1);

  my $dump = $dumper->Dump;

  return md5_hex($dump);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::PerlCritic::Util - Utility functions

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 use Test2::Tools::PerlCritic::Util qw( perl_critic_config_id );

=head1 DESCRIPTION

This module provides some utility functions useful when working with L<Perl::Critic> testing.

=head1 FUNCTIONS

=head2 perl_critic_config_id

 my $id = perl_critic_config_id $config;
 my $id = perl_critic_config_id;

Computes an id of the L<Perl::Critic> configuration.  The argument C<$config>
should be either an instance of L<Perl::Critic> or L<Perl::Critic::Config>.
If not provided then a default L<Perl::Critic::Config> will be created.

CAVEAT: This isn't really possible with 100% accuracy with the L<Perl::Critic>
API, so we make some assumptions common conventions that typically do hold
in virtually all cases.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
