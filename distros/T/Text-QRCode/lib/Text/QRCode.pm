package Text::QRCode;

use warnings;
use strict;
use base qw(Exporter);
use vars qw(@ISA $VERSION @EXPORT_OK);

@EXPORT_OK = qw(plot_qrcode);

use Carp qw(croak);

BEGIN {
    $VERSION = '0.05';
    eval {
        require XSLoader;
        XSLoader::load('Text::QRCode', $VERSION);
        1;
    } or do {
        require DynaLoader;
        push @ISA, 'DynaLoader';
        bootstrap Text::QRCode $VERSION;
    };
}

sub new {
    my $class  = shift;
    my $params = scalar ref $_[0] eq 'HASH' ? $_[0] : { @_ };
    return bless { params => $params }, $class;
}

sub plot {
    my ( $self, $text ) = @_;
    defined $text or croak 'Not enough arguments for plot()';
    return _plot($text, $self->{params});
}

sub plot_qrcode {
    my ( $text, $params ) = @_;
    defined $text or croak 'Not enough arguments for plot()';
    $params ||= {} if !$params || ref $params ne 'HASH';
    return _plot( $text, $params );
}

=head1 NAME

Text::QRCode - Generate text base QR Code

=head1 SYNOPSIS

    use Text::QRCode;

    my $arrayref = Text::QRCode->new()->plot("Some text here.");
    print join "\n", map { join '', @$_ } @$arrayref;

    # You will get following output.
    ******* *  ** *******
    *     *   * * *     *
    * *** *       * *** *
    * *** *   **  * *** *
    * *** *  * *  * *** *
    *     *  **** *     *
    ******* * * * *******
            *  **        
    ** ** *   *** *     *
    *   **  ***    * *   
     * ****     * *    **
    *    * * * * * ** ***
      **  *   ***   ** **
            * **  * **  *
    *******  *****  ***  
    *     *  * ** * **** 
    * *** * *   *    * * 
    * *** * * **   *  *  
    * *** *     *** * ***
    *     * **  * *   ***
    ******* * *  ****    

=head1 DESCRIPTION

This module allows you to generate QR Code using ' ' and '*'. This module use libqrencode '2.0.0' and above.

=head1 METHODS

=over 4

=item new

    $qrcode = Text::QRCode->new(%params);

The C<new()> constructor method instantiates a new Text::QRCode object. C<new()> accepts some parameters are the same as C<Imager::QRCode>.

=item plot($text)

    $arrayref = $qrcode->plot("blah blah");

Create a QR Code map. This method returns array reference ploted QR Code with the given text.

=back

=head1 INSTANT METHODS

=over 4

=item plot_qrcode($text, \%params)

Instant method. C<$text> is input text. C<%params> is same parameter as C<new()>.

=back

=head1 SEE ALSO

C<Imager::QRCode>, C<Term::QRCode>, C<HTML::QRCode>, C<http://www.qrcode.com/>, C<http://megaui.net/fukuchi/works/qrencode/index.en.html>

=head1 AUTHOR

Yoshiki Kurihara C<< <kurihara __at__ cpan.org> >>

=head1 LICENCE

Copyright (c) 2013, Yoshiki KURIHARA C<< <kurihara __at__ cpan.org> >>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::QRCode
