package Text::ASCIITable::TW;
use Moose;
use Encode qw(encode decode);
extends 'Text::ASCIITable';

=head1 NAME

Text::ASCIITable::TW - add TW support for Text::ASCIITable

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

see L<Text::ASCIITable>

=cut

override 'new' => sub {
    my $class = shift;
    my $hash_ref = super;
    my $self = bless $hash_ref, $class;
    return $self;
};

override 'count' => sub {
    my ($self,$str) = @_;

    if (defined($self->{options}{cb_count}) && ref($self->{options}{cb_count}) eq 'CODE') {
        my $ret = eval { return &{$self->{options}{cb_count}}($str); };
        return $ret if (!$@);
        do { $self->reperror("Error: 'cb_count' callback returned error, ".$@); return 1; } if ($@);
    }
    elsif (defined($self->{options}{cb_count}) && ref($self->{options}{cb_count}) ne 'CODE') {
        $self->reperror("Error: 'cb_count' set but no valid callback found, found ".ref($self->{options}{cb_count}));
        return length($str);
    }
    $str =~ s/<.+?>//g if $self->{options}{allowHTML};
    $str =~ s/\33\[(\d+(;\d+)?)?[musfwhojBCDHRJK]//g if $self->{options}{allowANSI}; # maybe i should only have allowed ESC[#;#m and not things not related to
    $str =~ s/\33\([0B]//g if $self->{options}{allowANSI};                           # color/bold/underline.. But I want to give people as much room as they need.
    $str = decode("utf8", $str) if $self->{options}{utf8};

    return length(encode('big5', $str));
};

=head1 AUTHOR

Alec Chen, C<< <alec at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-asciitable-tw at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-ASCIITable-TW>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::ASCIITable::TW

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-ASCIITable-TW>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-ASCIITable-TW>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-ASCIITable-TW>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-ASCIITable-TW>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alec Chen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Text::ASCIITable::TW
