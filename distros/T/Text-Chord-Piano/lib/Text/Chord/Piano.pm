package Text::Chord::Piano;

use warnings;
use strict;
use Carp qw(croak);

use Music::Chord::Note;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(finger) );

our $VERSION = '0.061';

my $cn = Music::Chord::Note->new();

my $black_keys;
for my $black_key (qw(1 3 6 8 10 13 15 18 20 22)){
    $black_keys->{$black_key} = 2;
}

my @white_keys = (
#   C   C#  D   D#  E   F   F#  G   G#  A   A#  B
     2,  4,  6,  8, 10, 14, 16, 18, 20, 22, 24, 26,
    30, 32, 34, 36, 38, 42, 44, 46, 48, 50, 52, 54,
);


sub new {
    my $class = shift;
    bless {
        finger => '*',
    }, $class;
}

sub chord {
    my ($self, $chord_name) = @_;
    return $self->generate($chord_name, $self->_get_keys($chord_name));
}

sub gen {
    my ($self, $chord_name, @keys) = @_;
    return $self->generate($chord_name, @keys);
}
sub generate {
    my ($self, $chord_name, @keys) = @_;
    my $keyboard = $self->_draw_keyboard;
    for my $key (0..23){
        my $play = 0;
        for my $i (@keys){
            $play = 1 if $i == $key;
        }
        if($play){
            my $y = $black_keys->{$key} || 5;
            $keyboard->[$y]->[$white_keys[$key]] = $self->finger;
        }
    }
    return $self->put_keyboard($keyboard)."$chord_name\n";
}

sub put_keyboard {
    my $self     = shift;
    my $keyboard = shift;
    $keyboard = $self->_draw_keyboard if ref $keyboard ne 'ARRAY';
    my $text;
    for my $line (@{$keyboard}){
        for my $char (@{$line}){
            $text .= $char;
        }
    }
    return $text;
}

sub all_chords {
    my $self = shift;
    return $cn->all_chords_list;
}

sub _get_keys {
    my ($self, $chord_name) = @_;
    croak "no chord" unless $chord_name;
    my ($tonic, $kind) = ($chord_name =~ /([A-G][b#]?)(.+)?/);
    $kind = 'base' unless $kind;
    croak "undefined chord $chord_name" unless defined $tonic;
    my $scalic = $cn->scale($tonic);
    my @keys;
    for my $scale ( $cn->chord_num($kind) ){
        my $tone = $scale + $scalic;
        $tone = int($tone % 24) + 12 if $tone > 23;
        push(@keys, $tone);
    }
    return @keys;
}

sub _draw_keyboard {
    my $self = shift;
    return [
		[split(//, "|  | | | |  |  | | | | | |  |  | | | |  |  | | | | | |  |\n")],
		[split(//, "|  | | | |  |  | | | | | |  |  | | | |  |  | | | | | |  |\n")],
		[split(//, "|  | | | |  |  | | | | | |  |  | | | |  |  | | | | | |  |\n")],
		[split(//, "|  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |\n")],
		[split(//, "|   |   |   |   |   |   |   |   |   |   |   |   |   |   |\n")],
		[split(//, "|   |   |   |   |   |   |   |   |   |   |   |   |   |   |\n")],
		[split(//, "|___|___|___|___|___|___|___|___|___|___|___|___|___|___|\n")],
	];
}

1;

__END__


=head1 NAME

Text::Chord::Piano - This module is a chord table generator of Piano by the text


=head1 SYNOPSIS

    use Text::Chord::Piano;

    my $p = Text::Chord::Piano->new;

    print $p->chord('Csus4');

    print $p->generate('Bb/A', (9,14,17,22) );

    print $p->put_keyboard;

    print "@{$p->all_chords}";


=head1 METHOD

=over

=item new

constructor

=item chord(I<$chord_name>)

put chord table of $chord_name

=item generate(I<$chord_name>, I<@keys>)

generate chord table of $chord_name by @keys

=item gen(I<$chord_name>, I<@keys>)

alias method of generate

=item all_chords

list all kind of chord

=item put_keyboard

put keyboard by text

=item finger($string)

set/get finger position text (default is '*')

=back


=head1 SEE ALSO

GD::Chord::Piano


=head1 AUTHOR

Copyright (c) 2008, Dai Okabayashi C<< <bayashi@cpan.org> >>


=head1 LICENCE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
