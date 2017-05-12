package WWW::BackpackTF::Currency;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.002001';

sub new{
	my ($class, $name, $content) = @_;
	$content->{name} = $name;
	bless $content, $class
}

sub name       { shift->{name} }
sub quality    { shift->{quality} }
sub priceindex { shift->{priceindex}}
sub single     { shift->{single} }
sub plural     { shift->{plural} }
sub round      { shift->{round} }
sub craftable  { shift->{craftable} eq 'Craftable' }
sub tradable   { shift->{tradable} eq 'Tradable' }
sub defindex   { shift->{defindex} }

sub quality_name { WWW::BackpackTF::QUALITIES->[shift->{quality}] }
sub stringify {
	my ($self, $nr) = @_;
	my $round = $self->round;
	$nr = sprintf "%.${round}f", $nr;
	my $suf = $nr == 1 ? $self->single : $self->plural;
	"$nr $suf";
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::BackpackTF::Currency - Class representing currency information

=head1 SYNOPSIS

  my @currencies = $bp->get_currencies;
  my $currency = $currencies[0];
  say 'Name: ',                               $currency->name;
  say 'Quality (number): ',                   $currency->quality;
  say 'Quality (human-readable): ',           $currency->quality_name;
  say 'Priceindex: ',                         $currency->priceindex;
  say 'Craftable: ',                         ($currency->craftable ? 'YES' : 'NO');
  say 'Tradable: ',                          ($currency->tradable ? 'YES' : 'NO');
  say 'Singular form: ',                      $currency->single;
  say 'Plural form: ',                        $currency->plural;
  say 'Round to this many decimal places: ',  $currency->round;
  say 'Defindex: ',                           $currency->defindex;
  say '3.15271 units of this currency is: ',  $currency->stringify(3.15271); # example return values: "3.15 keys", "3.15 ref", "3.15 buds"

=head1 DESCRIPTION

WWW::BackpackTF::Currency is a class representing information about a currency.

=head2 METHODS

=over

=item B<name>

The name of the currency.

=item B<quality>

The quality integer of the currency. Usually 6 (corresponding to the Unique quality).

=item B<quality_name>

The quality of the currency as a human-readable string. Usually 'Unique'.

=item B<priceindex>

The priceindex of a currency. Indicates a crate series or unusual effect. Usually 0.

=item B<craftable>

True if the currency is craftable, false otherwise. Usually true.

=item B<tradable>

True if the currency is tradable, false otherwise. Usually true.

=item B<single>

The singular form of the currency.

=item B<plural>

The plural form of the currency.

=item B<round>

The number of decimal places this currency should be rounded to.

=item B<defindex>

The definition index of the currency.

=item B<stringify>(I<$count>)

Rounds I<$count> to the number of decimal places returned by B<round>, then appends a space and the correct singular/plural form of the currency.

=back

=head1 SEE ALSO

L<http://backpack.tf/api/currencies>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
