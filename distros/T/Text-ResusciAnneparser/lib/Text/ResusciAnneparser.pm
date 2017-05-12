use strict;    # To keep Test::Perl::Critic happy, Moose does enable this too...

package Text::ResusciAnneparser;
{
  $Text::ResusciAnneparser::VERSION = '0.03';
}

use Moose;
use namespace::autoclean;
use 5.012;
use autodie;

use DateTime;
use XML::Simple qw(:strict);
use Data::Dumper;

has infile => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

use Carp qw/croak carp/;

# Ensure we read the inputfile after constructing the object
sub BUILD {
    my $self = shift;
    $self->{_data} = {};
    $self->_read_infile;
}

sub _read_infile {

    my $self = shift;

    my $certificates =
      XMLin( $self->{infile}, ForceArray => 1, KeyAttr => { user => 'login' } );

# Sort users according to the ones who got a certificate and the ones who did not
    foreach my $user ( keys %{ $certificates->{user} } ) {

        my $fname = $certificates->{user}->{$user}->{familyname};
        my $gname = $certificates->{user}->{$user}->{givenname};

        # Ensure no leading/trailing spaces are in the name
        $fname =~ s/^\s+//; # strip white space from the beginning
        $fname =~ s/\s+$//; # strip white space from the end
        $gname =~ s/^\s+//; # strip white space from the beginning
        $gname =~ s/\s+$//; # strip white space from the end

        my $names = {
            'givenname'  => $gname,
            'familyname' => $fname
        };

        if ( defined $certificates->{user}->{$user}->{'course'} ) {
            my $course = $certificates->{user}->{$user}->{'course'}->[0];
            my $dt     = DateTime->new(
                year  => $course->{year},
                month => $course->{month},
                day   => $course->{day}
            );

            # Make an entry under {certs}
            # Entry contains the course date and email address
            push( @{ $self->{_data}->{certs}->{ $dt->ymd } }, $names );
        } else {
            push( @{ $self->{_data}->{training} }, $names );
        }
    }

}

sub certified {
    my $self = shift;
    return $self->{_data}->{certs};
}

sub in_training {
    my $self = shift;
    return $self->{_data}->{training};
}

# Speed up the Moose object construction
__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Parser for XML logfiles of the Resusci Anne Skills Station software

__END__

=pod

=head1 NAME

Text::ResusciAnneparser - Parser for XML logfiles of the Resusci Anne Skills Station software

=head1 VERSION

version 0.03

=head1 SYNOPSIS

my $certificates = Text::ResusciAnneparser->new(infile => 'certificates.xml');

=head1 DESCRIPTION

The Resusci Anne Skills Station is a basic life support training station used by people
involved in first-line support in healthcare.
The training station keeps track of who trained when. This module enables parsing the
xml output file to be able to process the data.

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new Text::ResusciAnneparser object. Supported parameters are listed below

=over

=item infile

The input file containing the raw data log of the skill station software

=back

=head2 C<certified>

Returns a hash of people who received a valid training certificate. The hash contains keys with the
training dates in the format YYYY-MM-DD. The value attached to a date key in the hash is an array
of people.

A single person entry is a hash containing the givenname and the familiname of a person.

E.g.
           '2013-04-07' => [
                             {
                               'givenname' => 'Piet',
                               'familyname' => 'Konijn'
                             }
                            ],
           '2013-03-25' => [
                             {
                               'givenname' => 'Zjuul',
                               'familyname' => 'Cesar'
                             },
                             {
                               'givenname' => 'Pette',
                               'familyname' => 'Sjiekke'
                             }
                           ]

=head2 C<in_training>

Returns an array of people who started the exercise but who did not completed it and hence have not received
a certificate yet

=head2 BUILD

Helper function to run custome code after the object has been created by Moose.

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
