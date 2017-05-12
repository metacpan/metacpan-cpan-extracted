package URL::Encode::XS;

use strict;
use warnings;

BEGIN {
    our $VERSION = '0.03';
    our @EXPORT_OK = qw[ url_encode
                         url_encode_utf8
                         url_decode
                         url_decode_utf8
                         url_params_each
                         url_params_flat
                         url_params_mixed
                         url_params_multi ];
    require Exporter;
    *import = \&Exporter::import;

    require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);
}

1;

__END__

=head1 NAME

URL::Encode::XS - XS implementation of URL::Encode

=head1 DESCRIPTION

The main L<URL::Encode> package will use this package automatically if it 
can find it. Do not use this package directly, use L<URL::Encode> instead.

=head1 SUPPORT

Please report any bugs or feature requests to C<bug-url-encode-xs@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URL-Encode-XS>

=head1 AUTHOR

Christian Hansen, E<lt>chansen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Christian Hansen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
