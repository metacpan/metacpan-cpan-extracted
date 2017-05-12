=head1 NAME

Tie::Array::Random - Generates random for different fetched indexes

=head1 SYNOPSIS

  use Tie::Array::Random;

  my @array;
  tie @array, 'Tie::Array::Random';

  my $a_random_number           = $array[1];
  my $an_other_random_number    = $array[200];

  $a_random_number == $array[1]; ## True

  ## Set random type
  tie %hash, 'Tie::Array::Random', { set=> 'alpha', min=>5, max=>5 }};

=head1 DESCRIPTION

Tie::Array::Random generates a random number each time a different index is fetched.

The actual random data is generated using Data::Random rand_chars function. The default arguments are 
                ( set => 'all', min => 5, max => 8 )
which can be modifed using tie parameters as shown in the SYNOPSIS.                

=cut

package Tie::Array::Random; 

use 5.006;
use strict;
use warnings;
use vars qw($VERSION @ISA);
use Tie::Array;
use Data::Random qw(:all);

$VERSION = '1.01';
@ISA = qw(Tie::Array);


sub TIEARRAY  {
    my $storage = bless {}, shift;

    my $args = shift;

    $storage->{__rand_config} = { set => 'numeric', min => 5, max => 8 };
    $storage->{__max} = 0;

    foreach (keys %$args) {
        $storage->{__rand_config}->{$_} = $args->{$_};
    }
 
    return $storage;
}


=head2 STORE

Stores data 

=cut

sub STORE {
  my ($self, $key, $val) = @_;

  $self->{__max} = $key if $key > $self->{__max} ;

  $self->{$key} = $val;
}

=head2 FETCH

Fetchs

=cut

sub FETCH {
  my ($self, $key) = @_;

  $self->{$key} = join '', rand_chars( %{$self->{__rand_config}} ) if ! exists $self->{$key};


  $self->{__max} = $key if $key > $self->{__max} ;

  return $self->{$key};
}

=head2 FETCHSIZE

Fetchs size

=cut

sub FETCHSIZE {
  my ($self, $key) = @_;

  return $self->{__max};
}




1;
__END__


=head1 AUTHOR

Matias Alejo Garcia <matiu@cpan.org>

=head1 UPDATES

The latest version of this module will always be available from
from CPAN
at L<http://search.cpan.org/~ematiu>.

=head1 COPYRIGHT

Copyright (C) 2009, Matias Alejo Garcia

=head1 LICENSE

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), perltie(1), Tie::StdHash(1), Tie::Hash::Cannabinol, Data::Random, Tie::Hash::Array

=cut
