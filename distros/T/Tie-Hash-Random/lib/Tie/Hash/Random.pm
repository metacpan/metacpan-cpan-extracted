=head1 NAME

Tie::Hash::Random - Generates random for different fetched keys

=head1 SYNOPSIS

  use Tie::Hash::Random;

  my %hash;
  tie %hash, 'Tie::Hash::Random';

  my $a_random_number           = $hash{foo};
  my $an_other_random_number    = $hash{bar};

  $a_random_number == $hash{foo}; ## True

  ## Set a seed
  tie %hash, 'Tie::Hash::Random', { set=> 'alpha', min=>5, max=>5 }};

=head1 DESCRIPTION

Tie::Hash::Random generates a random number each time a different key is fetched.

The actual random data is generated using Data::Random rand_chars function. The default arguments are 
                ( set => 'all', min => 5, max => 8 )
which can be modifed using tie parameters as shown in the SYNOPSIS.                

=cut

package Tie::Hash::Random; 

use 5.006;
use strict;
use warnings;
use vars qw($VERSION @ISA);
use Tie::Hash;
use Data::Random qw(:all);

$VERSION = '1.02';
@ISA = qw(Tie::Hash);


sub TIEHASH  {
    my $storage = bless {}, shift;

    my $args = shift;

    $storage->{__rand_config} = { set => 'numeric', min => 5, max => 8 };

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
  $self->{$key} = $val;
}

=head2 FETCH

Fetchs

=cut

sub FETCH {
  my ($self, $key) = @_;

  $self->{$key} = join '', rand_chars( %{$self->{__rand_config}} ) if ! exists $self->{$key};

  return $self->{$key};
}


=head2 FIRSTKEY


=cut

sub FIRSTKEY {
  my ($self) = @_;
  return 1;
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

perl(1), perltie(1), Tie::StdHash(1), Tie::Hash::Cannabinol, Data::Random

=cut
