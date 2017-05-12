package Vector::QRCode::EPS;
use 5.008005;
use strict;
use warnings;
use PostScript::Simple;
use Text::QRCode;

our $VERSION = "0.08";

sub generate {
    my ($class, %opts) = @_;
    my $text = $opts{text};
    my $size = $opts{size} || 10;
    my $unit = $opts{unit} || 'cm';
    my $colour = $opts{colour} || [10, 10, 10];
    my $bgcolour = $opts{bgcolour} || [255,255,255];
    my $transparent = $opts{transparent};

    my $qrcode_options = $opts{qrcode_options} || {};

    my $qrdata = Text::QRCode->new(%$qrcode_options)->plot($text);
    $qrdata = [reverse @$qrdata]; ### avoid to upside down

    my $xsize = scalar( @{$qrdata->[0]} );
    my $ysize = scalar( @{$qrdata} );

    my $ps = PostScript::Simple->new(
        colour => 1, 
        eps => 1, 
        units => $unit, 
        xsize => $size, 
        ysize => $size
    );

    unless ($transparent) {
        $ps->setcolour(@$bgcolour);
        $ps->box({filled => 1}, 0, 0, $size, $size);
    }

    $ps->setcolour(@$colour);
    my ($x, $y);
    for $y (0 .. $#{$qrdata}) {
        for $x (0 .. $#{$qrdata->[$y]} ) {
            if ($qrdata->[$y][$x] eq '*') {
                $ps->box(
                    {filled => 1}, 
                    $size/$xsize*$x, $size/$ysize*$y, 
                    $size/$xsize*($x+1), $size/$ysize*($y+1)
                );
            }
        }
    }

    $ps;
}

1;
__END__

=encoding utf-8

=head1 NAME

Vector::QRCode::EPS - A generator class for vector data of QRCode

=head1 SYNOPSIS

    use Vector::QRCode::EPS;
    
    my $ps = Vector::QRCode::EPS->generate(
        text        => 'Hello, world!',
        colour      => [255, 0, 0], 
        bgcolour    => [150, 150, 150],
        transparent => 0,
        size        => 6,
        unit        => 'cm',
        qrcode_options => {
            version => 5,
            level   => 'H',
        },
    );
    $ps->output('qrcode.ps');


=head1 DESCRIPTION

Vector::QRCode::EPS is a generator that returns a QRCode data as L<PostScript::Simple> object.

=head1 REQUIREMENT

You have to install L<libqrencode|https://github.com/fukuchi/libqrencode> into your host before installing this module.

=head1 METHODS

=head2 generate

Returns a L<PostScript::Simple> object that contains a vector data of QRCode.

    $ps_obj = Vector::QRCode::EPS->generate(%options);

Options are followings.

=over 4

=item text

Required. Text that will be implemented into QRCode.

=item size

Optional. Multiple of unit. Default is 10.

=item unit

Optional. Unit from 'mm', 'cm', 'in', 'pt', and 'bp'. Default is 'cm'.

Please see more datail for L<CONSTRUCTOR Paragraph of the PostScript::Simple documentation|http://search.cpan.org/perldoc?PostScript::Simple#CONSTRUCTOR>.

=item colour

Optional. RGB colour specification in arrayref. Default is [10, 10, 10].

=item bgcolour

Optional. RGP colour specification for background color in arrayref. Default is [255, 255, 255].

=item transparent

Optional. Transparent background when true value is specified. Default is undef.

=item qrcode_options

Optional. Options as L<Text::QRCode>. Default is undef.

=back

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<libqrencode|https://github.com/fukuchi/libqrencode>

L<PostScript::Simple>

L<Text::QRCode>

=cut

