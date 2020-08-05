#
# $Id: YAML.pm,v 0.05 2020/08/05 18:26:03 dankogai Exp dankogai $
#
package Tie::YAML;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.05 $ =~ /(\d+)/g;
use base 'Tie::SaveLater';
use Carp;
use YAML;
__PACKAGE__->make_subclasses;

sub load{
    # See https://rt.cpan.org/Public/Bug/Display.html?id=131985
    local $YAML::LoadBlessed = 1;
    my $class = shift;
    my $filename = shift; 
    open my $fh, "<:raw", $filename or croak "$filename: $!";
    local $/; # slurp;
    my $yaml = <$fh>;
    close $fh;
    return Load($yaml);
}

sub save{
    my $self = shift;
    my $filename = $self->filename;
    open my $fh, ">:raw", $filename or croak "$filename: $!";
    print $fh Dump(damn_scalar($self));
    close $fh;
    return 1;
} 

sub damn_scalar { # iff necessary
    return $_[0] unless ref($_[0]) =~ /::SCALAR$/;
    return \do{ my $scalar = ${ $_[0] }}
}
1;
__END__

=head1 NAME

Tie::YAML - Stores your object when untied via YAML

=head1 SYNOPSIS

  use Tie::YAML;
  {
      tie my $scalar => 'Tie::YAML', 'scalar.po';
      $scalar = 42;
  } # scalar is automatically saved as 'scalar.po'.
  {
      tie my @array => 'Tie::YAML', 'array.po';
      @array = qw(Sun Mon Tue Wed Fri Sat);
  } # array is automatically saved as 'array.po'.
  {
      tie my %hash => 'Tie::YAML', 'hash.po';
      %hash = (Sun=>0, Mon=>1, Tue=>2, Wed=>3, Thu=>4, Fri=>5, Sat=>6);
  } # hash is automatically saved as 'hash.po'.
  {
      tie my $object => 'Tie::YAML', 'object.po';
      $object = bless { First => 'Dan', Last => 'Kogai' }, 'DANKOGAI';
  } # You can save an object; just pass a scalar
  {
      tie my $object => 'Tie::YAML', 'object.po';
      $object->{WIFE} =  { First => 'Naomi', Last => 'Kogai' };
      # you can save before you untie like this
      tied($object)->save;
  }

=head1 DESCRIPTION

Tie::YAML stores tied variables when untied.  Usually that happens
when you variable is out of scope.  You can of course explicitly untie
the variable or C<< tied($variable)->save >> but the whole idea is not
to forget to save it.

This module uses L<YAML> as its backend so it can store and
retrieve anything that L<YAML> can.

=head1 DEPENDENCIES

This module requires L<YAML>.

=head1 SEE ALSO

L<Tie::SaveLater>, L<Tie::DataDumper>, L<Tie::Storable>

L<perltie>, L<Tie::Scalar>, L<Tie::Array>, L<Tie::Hash>

=head1 BUGS

As of YAML 0.58, YAML cannot serialize a blessed scalar reference to
blessed scalar reference.  For that reason, I had to implement a
funcition that looks like this.

  sub damn_scalar { # iff necessary
    return $_[0] unless ref($_[0]) =~ /::SCALAR$/;
    return \do{ my $scalar = ${ $_[0] }}
  }

Sigh.

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


