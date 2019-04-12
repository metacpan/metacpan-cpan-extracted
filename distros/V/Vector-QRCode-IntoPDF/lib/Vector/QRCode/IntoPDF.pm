package Vector::QRCode::IntoPDF;
use 5.008005;
use strict;
use warnings;
use PostScript::Convert;
use PDF::API2;
use Vector::QRCode::EPS;
use File::Temp 'tempdir';
use File::Spec;
use Carp;
use Class::Accessor::Lite (
    new => 0,
    ro => [qw[pdf_file workdir]],
);

our $VERSION = "0.03";

sub new {
    my ($class, %opts) = @_;
    croak 'pdf_file is required' unless $opts{pdf_file};

    $opts{workdir} ||= tempdir(CLEANUP => 1);

    bless {%opts}, $class;
}

sub pdf {
    my $self = shift;
    $self->{__pdf} ||= PDF::API2->open($self->pdf_file) or croak $!;

    $self->{__pdf};
}

sub imprint {
    my ($self, %opts) = @_;

    my %_opts;
    for my $key (qw/x y page/) {
        $_opts{$key} = delete $opts{$key} or croak "$key is required";
    }

    my $qr = $self->_qr_pdf(%opts) or croak "could not create qrcode";
    my $page = $self->pdf->openpage($_opts{page}) or croak "illegal page";
    my $gfx = $page->gfx;

    my $xobj = $self->pdf->importPageIntoForm($qr, 1);
    $gfx->formimage($xobj, $_opts{x}, $_opts{y});
}

sub save {
    my ($self, $path) = @_;
    $path ||= $self->pdf_file;
    $self->pdf->saveas($path);
}

sub _qr_pdf {
    my ($self, %opts) = @_;

    my $qr = Vector::QRCode::EPS->generate(%opts);

    my $qr_data = $qr->get;
    my $qr_pdf = File::Spec->catfile($self->workdir, ($qr+0).'.pdf');

    psconvert(\$qr_data, filename => $qr_pdf, format => 'pdf');

    PDF::API2->open($qr_pdf);
}

1;
__END__

=encoding utf-8

=head1 NAME

Vector::QRCode::IntoPDF - A module to append QRCode as vector data into PDF

=head1 SYNOPSIS

    use Vector::QRCode::IntoPDF;
    
    my $target = Vector::QRCode::IntoPDF->new(pdf_file => '/path/to/source.pdf');
    
    $target->imprint(
        page => 2,
        x    => 200,
        y    => 300,
        text => 'Hello, world!',
        size => 6,
        unit => 'cm',
    );
    
    $target->save('/path/to/new.pdf');


=head1 DESCRIPTION

Vector::QRCode::IntoPDF makes to imprint QRCode as vector-data into PDF file.

=head1 OPTIONS FOR CONSTRUCTOR / ACCESSOR METHODS

=over 4

=item pdf_file

Required. A path to source pdf.

=item workdir

Optional. A directory to use like temporary storage. Default is L<File::Temp>::tempdir(CLEANUP => 1);

=back

=head1 METHODS

=head2 pdf

Return PDF::API2 object for source pdf.

=head2 imprint

Imprint a qrcode. You may use options for L<Vector::QRCode::EPS>::generate(), and following options.

=over 4

=item page

Page number of target in pdf

=item x

Horizontal position of left-bottom of qrcode for imprinting (Left edge is criteria)

=item y

Vertical position of left-bottom of QRCode for imprinting (Bottom edge is criteria)

=back

=head2 save

Shortcut for $self->pdf->saveas(...);

Overwrite source pdf when arguments empty.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

