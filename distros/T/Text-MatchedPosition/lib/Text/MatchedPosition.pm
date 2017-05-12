package Text::MatchedPosition;
use strict;
use warnings;
use utf8;

our $VERSION = '0.03';

sub new {
    my ($class, $text, $regex) = @_;

    my $args = +{};

    $args->{text} = (ref $text eq 'SCALAR') ? $$text : $text;

    if (ref $regex ne 'Regexp') {
        require Carp;
        Carp::croak("The 2nd arg requires 'Regexp': $regex");
    }
    $args->{regex} = $regex;

    bless $args, $class;
}

sub text { $_[0]->{text} }

sub regex { $_[0]->{regex} }

sub line {
    my $self = shift;

    $self->_position unless $self->{position};

    return ${$self->{position}}[0];
}

sub offset {
    my $self = shift;

    $self->_position unless $self->{position};

    return ${$self->{position}}[1];
}

sub _position {
    my $self = shift;

    unless ($self->text =~ $self->regex) {
        $self->{position} = [undef, undef];
        return;
    }

    my $match = (split $self->regex, $self->text)[0];
    $match =~ s/\x0D\x0A/\n/g;
    $match =~ tr/\r/\n/;

    my $line_count = ($match =~ s/\n/\n/g);
    $line_count++;

    my $offset = length( (split /\n/, $match, -1)[-1] || '' ) + 1;

    $self->{position} = [$line_count, $offset];
}

1;

__END__

=head1 NAME

Text::MatchedPosition - find the matched position in a text


=head1 SYNOPSIS

    use Text::MatchedPosition;
    
    my $text = <<"_TEXT_";
    01234567890
    abcdefghijklmn
    opqrstuvwxyz
    _TEXT_
    
    my $regex = qr/jk/;
    
    my $pos = Text::MatchedPosition->new(\$text, $regex);
    warn $pos->line, $pos->offset; # 2, 10


=head1 DESCRIPTION

Text::MatchedPosition is the module for finding the matched position in a text.

=head1 METHODS

=head2 new($text_ref || $text, $regex)

This is the constractor method.

=head2 line

return the count of line number. The beginning is C<1>;

If regex is no match, C<line> to be C<undef>.

=head2 offset

return the count of offset number. The beginning is C<1>;

If regex is no match, C<offset> to be C<undef>.

=head2 text

getter for text lines

=head2 regex

getter for regex


=head1 REPOSITORY

Text::MatchedPosition is hosted on github
<http://github.com/bayashi/Text-MatchedPosition>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
