#
# $Id: DataDumper.pm,v 0.3 2006/03/22 22:10:28 dankogai Exp $
#
package Tie::DataDumper;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.3 $ =~ /(\d+)/g;
use base 'Tie::SaveLater';
use Carp;
use Data::Dumper;
__PACKAGE__->make_subclasses;
sub load{ 
    my $class = shift;
    my $filename = shift; 
    open my $fh, "<:raw", $filename or croak "$filename: $!";
    local $/; # slurp;
    my $str = <$fh>;
    close $fh;
    our $VAR1; # for data::dumper;
    my $result = eval($str);
    $@ and croak $@;
    undef $VAR1;
    return $result;
}
sub save{
    my $self = shift;
    my $filename = $self->filename;
    open my $fh, ">:raw", $filename or croak "$filename: $!";
    print $fh Dumper($self);
    close $fh;
    return 1;
} 
1;
__END__

=head1 NAME

Tie::DataDumper - Stores your object when untied via DataDumper

=head1 SYNOPSIS

  use Tie::DataDumper;
  {
      tie my $scalar => 'Tie::DataDumper', 'scalar.pl';
      $scalar = 42;
  } # scalar is automatically saved as 'scalar.pl'.
  {
      tie my @array => 'Tie::DataDumper', 'array.pl';
      @array = qw(Sun Mon Tue Wed Fri Sat);
  } # array is automatically saved as 'array.pl'.
  {
      tie my %hash => 'Tie::DataDumper', 'hash.pl';
      %hash = (Sun=>0, Mon=>1, Tue=>2, Wed=>3, Thu=>4, Fri=>5, Sat=>6);
  } # hash is automatically saved as 'hash.pl'.
  {
      tie my $object => 'Tie::DataDumper', 'object.pl';
      $object = bless { First => 'Dan', Last => 'Kogai' }, 'DANKOGAI';
  } # You can save an object; just pass a scalar
  {
      tie my $object => 'Tie::DataDumper', 'object.pl';
      $object->{WIFE} =  { First => 'Naomi', Last => 'Kogai' };
      # you can save before you untie like this
      tied($object)->save;
  }

=head1 DESCRIPTION

Tie::DataDumper stores tied variables when untied.  Usually that happens
when you variable is out of scope.  You can of course explicitly untie
the variable or C<< tied($variable)->save >> but the whole idea is not
to forget to save it.

This module uses L<DataDumper> as its backend so it can store and
retrieve anything that L<DataDumper> can.

=head1 SECURITY

This module uses C<eval()> on loading saved files.  That means there
is a security risk of executing malicious codes.
B<DO NOT USE THIS MODULE FOR ANYTHING SERIOUS.>
This module is just a proof-of-concept, example module to show how to
make use of L<Tie::SaveLater>.

=head1 SEE ALSO

L<Tie::SaveLater>, L<Tie::Storable>, L<Tie::YAML>

L<perltie>, L<Tie::Scalar>, L<Tie::Array>, L<Tie::Hash>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

