# NAME

Vector::QRCode::IntoPDF - A module to append QRCode as vector data into PDF

# SYNOPSIS

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

# DESCRIPTION

Vector::QRCode::IntoPDF makes to imprint QRCode as vector-data into PDF file.

# OPTIONS FOR CONSTRUCTOR / ACCESSOR METHODS

- pdf\_file

    Required. A path to source pdf.

- workdir

    Optional. A directory to use like temporary storage. Default is [File::Temp](https://metacpan.org/pod/File::Temp)::tempdir(CLEANUP => 1);

# METHODS

## pdf

Return PDF::API2 object for source pdf.

## imprint

Imprint a qrcode. You may use options for [Vector::QRCode::EPS](https://metacpan.org/pod/Vector::QRCode::EPS)::generate(), and following options.

- page

    Page number of target in pdf

- x

    Horizontal position of left-bottom of qrcode for imprinting (Left edge is criteria)

- y

    Vertical position of left-bottom of QRCode for imprinting (Bottom edge is criteria)

## save

Shortcut for $self->pdf->saveas(...);

Overwrite source pdf when arguments empty.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
