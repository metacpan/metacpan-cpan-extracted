package random;

use warnings;
use strict;
use 5.010;

=head1 NAME

random - have rand() return integers or fixed values

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use random;

    my $dice = 1 + rand 6; # one of 1 .. 6

    # or
    use random qw(integer);

    my $dice = 1 + rand 6; # one of 1 .. 6

    use random qw(fixed 6); # cheat on dice

    my $six = rand; # 6


=head1 EXPORT

Nothing.

=head1 FUNCTIONS

=head2 import

=cut

sub import   {
    shift; #
    my %args = @_<=1? ( "integer" => 1) :  @_;
    
    $^H{random} =  $args{fixed}   ? $args{fixed} 
                :  $args{integer} ? -123456789
                :  undef;
return
}

=head2 unimport

=cut

sub unimport {
  undef $^H{random};
  return;
}

=head2 rand

when random (integer) is in effect it returns int(rand)

when random (fixed) is in effect it returns the fixed value

otherwise CORE::rand

=cut

sub rand {
     my $ctrl_h = ( caller 0 )[10];
     my $param = $_[0] // 1;
     if ( !defined $ctrl_h->{random}) {
         return CORE::rand($param);
     }
     elsif ( -123456789 eq $ctrl_h->{random} ){
         return int($param * CORE::rand);
     } 
     else { 
         return $ctrl_h->{random};
     }
}

BEGIN {
    *CORE::GLOBAL::rand = *random::rand;
}


=head1 AUTHOR

Joerg Meltzer, C<< <joerg {at} joergmeltzer.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-random at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=random>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

The fixed value -123456789 doesn't work. The value is reserved to make the integer option work.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc random


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=random>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/random>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/random>

=item * Search CPAN

L<http://search.cpan.org/dist/random/>

=back


=head1 ACKNOWLEDGEMENTS

Thanx goes to Abeltje (http://yapc.tv/2008/ye/lt/lt2-02-abeltje-fixedtime).
I learned about pragmas watching your show.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Joerg Meltzer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

"Der liebe Gott wuerfelt nicht.";
