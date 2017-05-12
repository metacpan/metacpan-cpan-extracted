package Text::Chomped;

use warnings;
use strict;

=head1 NAME

Text::Chomped - A chomp and chop that will return the chomped and chopped

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    # Old way
    sub sentence {
        my $value = <<_END_
A quick brown fox jumped over the lazy dog
_END_
        chomp $value;
        return $value;
    }

    # New way
    use Text::Chomped;

    sub sentence { chomped <<_END_ }
A quick brown fox jumped over the lazy dog
_END_

    # Chomp a list (have to use [], sorry)

    my @got = chomped [ "A\n", "b", "c\n", ... ]

    # ... or ...
    my $got = chomped [ "A\n", "b", "c\n", ... ]
    $got->[0] # A

=head1 DESCRIPTON

Text::Chomped will export C<chomped> and C<chopped> which behave like C<chomp> and C<chop> except return the cho[mp]ped value rather than
what was cho[mp]ped off (the character)

Unfortunately subroutine prototyping in Perl cannot ape the builtin chomp/chop prototype, so you'll have to pass in an ARRAY reference if you want to
chomp/chop a list

Another consequence of the above, is that we can't use C<$_> without making the interface annoying, so you can't do:

    map { chomped } "A\n", "b", "c\n"

You have to do:

    map { chomped $_ } "A\n", "b", "c\n"

=cut

use vars qw/@ISA @EXPORT/;
@ISA = qw/Exporter/;
@EXPORT = qw/chomped chopped/;

sub _chomped {
    my $value = $_[0];
    chomp $value;
    return $value;
}

sub chomped ($) {
    my $value = $_[0];
    if ( ref $value eq 'ARRAY' ) {
        my @result = map { _chomped $_ } @$value;
        return wantarray ? @result : \@result;
    }
    else {
        return _chomped $value;
    }
}

sub _chopped {
    my $value = $_[0];
    chop $value;
    return $value;
}

sub chopped ($)  {
    my $value = $_[0];
    if ( ref $value eq 'ARRAY' ) {
        my @result = map { _chopped $_ } @$value;
        return wantarray ? @result : \@result;
    }
    else {
        return _chopped $value;
    }
}

=head1 ACKNOWLEDGEMENTS

                                  Y\     /Y
                                  | \ _ / |
            _____                 | =(_)= |
        ,-~"     "~-.           ,-~\/^ ^\/~-.
      ,^ ___     ___ ^.       ,^ ___     ___ ^.
     / .^   ^. .^   ^. \     / .^   ^. .^   ^. \
    Y  l    O! l    O!  Y   Y  lo    ! lo    !  Y
    l_ `.___.' `.___.' _[   l_ `.___.' `.___.' _[
    l^~"-------------"~^I   l^~"-------------"~^I
    !\,               ,/!   !                   !
     \ ~-.,_______,.-~ /     \                 /
      ^.             .^       ^.             .^    -Row
        "-.._____.,-"           "-.._____.,-"

                   ->Mr&MrsPacman<-

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-chomped at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Chomped>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Chomped


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Chomped>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Chomped>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Chomped>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Chomped/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

'PACMAN'; # End of Text::Chomped
