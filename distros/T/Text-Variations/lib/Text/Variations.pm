package Text::Variations;

use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

Text::Variations - create many variations of the same message

=head1 SYNOPSIS

    use Text::Variations;

    # Simple variables that change each time
    my $mood     = Text::Variations->new( [ 'happy',  'sad' ] );
    my $activity = Text::Variations->new( [ 'shopping', 'surfing' ] );
    my $facebook_status = "I'm feeling $mood - going $activity now\n";

    # build up complex strings with interpolations
    my $announcement = Text::Variations->new(
        "The train at platform {{platform}} has been ",
        [   'delayed',
            'cancelled',
        ],
        " due to ",
        [   "engineering works",
            "maintenance issues",
            "operating difficulties",
            "a passenger incident",
            "leaves on the tracks",
            "the wrong kind of snow",
        ],
        " - we apologise for any ",
        [   "inconvenience",
            "disruption to your journey",
            "missed onward connections",
        ],
        " this may have caused\n"
    );

    print $announcement->generate( { platform => 4 } );

=head1 DESCRIPTION

Often you have a simple message that you want to get across, but you don't want
it to be the same format each time. This module helps you do that.

You can specify several alternatives and a random one will be picked each time.

This module was written to generate the tweets for
L<http://www.send-a-newbie.com> every time someone signed up or donated. To keep
the tweets interesting and feel more human they all had to be different, but all
generated from code.

=head1 METHODS

=head2 new

    my $tv = Text::Variations->new(
        "just a simple string",
        [ 'or', 'an', 'arrayref', 'of', 'alternatives' ],
        "can have {{placeholders}} to interpolate",
        $or_even_other_text_variations_objects,
    );

Create a new Text::Variations object.

The arguments are an array of strings, arrayrefs of alternatives, or other T::V
objects.

You can include placeholders for variables by using C<'{{key}}'> in the strings.
These placeholders will then be replaced by the value you specify in the
arguments to C<generate>.

=cut

sub new {
    my $class = shift;
    my @bits  = @_;

    my $self = bless {}, $class;

    $self->{bits} = \@bits;

    return $self;
}

=head2 generate

    my $string = $tv->generate();
    my $string = "$tv";
    my $string = $tv->generate( { name => 'Joe', } );

Generates and returns a string. The arguments are used to fill in the
placeholders if there are any. The various parts are chosen at random. If there
are any embedded T::V objects then the arguments are passed on to them so as
well.

Stringification is overloaded so that it is identical to calling C<generate>
with no arguments.

=cut

use overload '""' => \&generate;

sub generate {
    my $self = shift;
    my $args = shift || {};
    my @outs = ();

    foreach my $bit ( @{ $self->{bits} } ) {

        my $string = $self->_convert_bit_to_string( $bit, $args );
        next unless defined $string;

        my $interpolated = $self->_interpolate_string( $string, $args );

        push @outs, $interpolated;
    }

    return join '', @outs;
}

sub _convert_bit_to_string {
    my $self = shift;
    my $bit  = shift;
    my $args = shift;

    # return strings and undefs at once
    return $bit if !defined $bit;
    return $bit if !ref $bit;

    # If we have an array pick a random entry
    if ( ref $bit eq 'ARRAY' ) {
        my $index = int rand scalar @$bit;
        return $self->_convert_bit_to_string( $bit->[$index], $args );
    }

    # Check if we are nested
    my $bit_ref  = ref($bit);
    my $self_ref = ref($self);
    if ( $bit_ref eq $self_ref ) {
        return $bit->generate($args);
    }

    die "Don't know what to do with '$bit_ref': $bit";
}

sub _interpolate_string {
    my $self   = shift;
    my $string = shift;
    my $args   = shift;

    $string =~ s/ \{\{ (\w+) \}\} / $args->{$1} /xge;
    return $string;
}

=head1 SEE ALSO

L<Catalyst::Plugin::Twitter> - used to send the tweets that this module was created to generate.

=head1 GOTCHAS

If you're hoping to generate different looking messages make sure that there is
plenty of variation in the first part. Also think about creating several
different forms as T::V objects and then combining all of those into a single
final T::V object.

=head1 THANKS TO

... the British rail companies, for delaying my journey and providing so much
material for the example code. This module was entirely written on the late
running service between London Paddington and Newport.

=head1 AUTHOR

Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>.

L<http://www.ecclestoad.co.uk/>

=head1 CONTRIBUTING

Contributions welcome: L<https://github.com/evdb/Text-Variations>

TRavis build tests: L<https://travis-ci.org/evdb/Text-Variations>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

1;
