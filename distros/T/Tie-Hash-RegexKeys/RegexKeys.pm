###########################################################
# Tie::Hash::RegexKeys package
# Perl license
#
# $Id: RegexKeys.pm 1 2007-03-06 20:14:50Z root $
# $Revision: 1 $
#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
###########################################################

=head1 NAME

Tie::Hash::RegexKeys - Match hash keys using Regular Expressions

=head1 SYNOPSIS

	use Tie::Hash::RegexKeys;
	use Data::Dumper;
	
	my %h;

	tie %h, 'Tie::Hash::RegexKeys';

	my $a = '.1.2.3.4.5.6.2';
	my $b = '.1.2.3.4.5.7';
	my $c = '.1.2.3.4.5.6.1';
	my $d = '.1.2.3.4.5.6.1.6';

	$h{$a}="key1";
	$h{$b}="key2";
	$h{$c}="subkey1";
	$h{$d}="subkey2";

	my $pat = '^\.1\.2\.3\.4\.5\.6.*';
	my @res = tied(%h)->FETCH_KEYS(qr/$pat/);
	print Dumper(@res);

Return this:

	$VAR1 = '.1.2.3.4.5.6.1';
	$VAR2 = '.1.2.3.4.5.6.1.6';
	$VAR3 = '.1.2.3.4.5.6.2'
	
=head1 DESCRIPTION

Extend Tie::Hash::Regex to retrieve the KEYS in place of values

=cut

package Tie::Hash::RegexKeys; 

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require  Tie::Hash::Regex;
use Attribute::Handlers autotie => { "__CALLER__::RegexKeys" => __PACKAGE__ };

@ISA = qw(Exporter Tie::StdHash );
@EXPORT = qw();
@EXPORT_OK =();

$VERSION = 1.21;

=head1 METHODS

=head2 FETCH_KEYS

Get KEY(S) from the hash. If there isn't an exact match try a regex
match.

=cut

sub FETCH_KEYS {
  my $self = shift;
  my $key = shift;

  my $is_re = (ref $key eq 'Regexp');

  return $self->{$key} if !$is_re && exists $self->{$key};

  $key = qr/$key/ unless $is_re;

  # NOTE: wantarray will _never_ be true when FETCH is called
  #       using the standard hash semantics. I've put that piece
  #       of code in for people who are happy using syntax like:
  #       tied(%h)->FETCH(qr/$pat/);

 if (wantarray) {
   return ( grep /$key/, keys %$self );
  } else {
    /$key/ and return $_ for keys %$self;
  }
  return;
}
1;
__END__


=head1 AUTHOR

Fabrice DULAUNOY <fabrice@dulaunoy.com>

=head1 COPYRIGHT

Copyright (C) 2005, Fabrice DULAUNOY.  All Rights Reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

perltie(1).

Tie::RegexHash(1)

Tie::Hash::Regex(1)

=cut
