package Win32::Netsh::Utils;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Win32::Netsh::Utils - Module contains utility functions used by various
Win32::Netsh modules

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Win32::Netsh::Utils;
  
=cut

##****************************************************************************
##****************************************************************************
use strict;
use warnings;
use 5.010;
use Readonly;
use Data::Dumper;
use Exporter::Easy (
  EXPORT => [],
  OK   => [qw(str_trim initialize_hash_from_lookup get_key_from_lookup parse_ip_address)],
  TAGS => [
    lookup  => [qw(initialize_hash_from_lookup get_key_from_lookup)],
    all     => [qw(:lookup str_trim parse_ip_address)],
  ],
);

## Version string
our $VERSION = qq{0.01};

##---------------------------------------------
Readonly::Scalar my $IP_OCTET =>
  qr/([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])/x;

##****************************************************************************
## Functions
##****************************************************************************

=head1 FUNCTIONS

=cut

##****************************************************************************
##****************************************************************************

=head2 str_trim($string)

=over 2

=item B<Description>

Trim leading and trailing whitespace from the given string

=item B<Parameters>

=over 4

=item I<$string>

String to trim

=back

=item B<Return>

SCALAR - Trimmed string

=back

=cut

##----------------------------------------------------------------------------
sub str_trim
{
  my $string = shift // qq{};

  $string =~ s/^\s+|\s+$//gx;

  return ($string);
}

##****************************************************************************
##****************************************************************************

=head2 initialize_hash_from_lookup($lookup)

=over 2

=item B<Description>

Return a hash reference with keys associated with the lookup defined as
empty strings

=item B<Parameters>

=over 4

=item I<$lookup>

HASH reference whose values will be used as keys for the returned hash reference

=back

=item B<Return>

HASH reference whose keys are the values of the provided lookup

=back

=cut

##----------------------------------------------------------------------------
sub initialize_hash_from_lookup
{
  my $lookup = shift // {};
  my $hash = {};

  foreach my $key (values(%{$lookup}))
  {
    $hash->{$key} = qq{};
  }

  return ($hash);
}

##****************************************************************************
##****************************************************************************

=head2 get_key_from_lookup($text, $lookup)

=over 2

=item B<Description>

Use the provided lookup to determine the key associated with the provided
text.

=item B<Parameters>

=over 4

=item I<$text>

String to match

=item I<$lookup>

Hash reference whose keys will be used to match the provided text

=back

=item B<Return>

SCALAR - Empty string if no match, or the value associated with the text

=back

=cut

##----------------------------------------------------------------------------
sub get_key_from_lookup
{
  my $text   = shift // qq{};
  my $lookup = shift // {};

  if (length($text))
  {
    $text = uc($text);
    foreach my $key (keys(%{$lookup}))
    {
      return ($lookup->{$key}) if ($text eq uc($key));
    }
  }
  return (qq{});
}

##****************************************************************************
##****************************************************************************

=head2 parse_ip_address($string)

=over 2

=item B<Description>

Parse the given string to determine if a valid IP address in dotted quad 
notation  (i.e. 10.0.0.10)

=item B<Parameters>

=over 4

=item I<$string>

Value to parse

=back

=item B<Return>

SCALAR - Valid IP in dotted quad notation or an empty string

=back

=cut

##----------------------------------------------------------------------------
sub parse_ip_address
{
  my $string = shift;

  if ($string =~ /($IP_OCTET\.$IP_OCTET\.$IP_OCTET\.$IP_OCTET)/x)
  {
    my $ip = $1;
    return ($ip);
  }

  return (qq{});
}

##****************************************************************************
## Additional POD documentation
##****************************************************************************

=head1 AUTHOR

Paul Durden E<lt>alabamapaul AT gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 by Paul Durden.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    ## End of module
__END__
