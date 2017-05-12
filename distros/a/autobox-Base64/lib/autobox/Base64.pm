#
# This file is part of autobox-Base64
#
# This software is Copyright (c) 2013 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package autobox::Base64;
{
  $autobox::Base64::VERSION = '0.001';
}

# ABSTRACT: Convert strings to and from base64 easily

use v5.10;
use strict;
use warnings;
use utf8;

use parent 'autobox';

sub import { shift->SUPER::import(STRING => 'autobox::Base64::STRING') }


{
    package autobox::Base64::STRING;
{
  $autobox::Base64::STRING::VERSION = '0.001';
}
    use strict;
    use warnings;
    use utf8;

    use MIME::Base64 ();

    sub decode_base64 { MIME::Base64::decode_base64(shift) }
    sub from_base64   { goto \&decode_base64               }

    sub encode_base64 { MIME::Base64::encode_base64(shift, shift // undef) }
    sub to_base64     { goto \&encode_base64                               }
}

!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl

=head1 NAME

autobox::Base64 - Convert strings to and from base64 easily

=head1 VERSION

This document describes version 0.001 of autobox::Base64 - released May 20, 2013 as part of autobox-Base64.

=head1 SYNOPSIS

    use autobox::Base64;

    my $encode = 'la la la'->encode_base64;      # bGEgbGEgbGE=
    my $decode = 'bGEgbGEgbGE='->decode_base64;  # la la la

=head1 DESCRIPTION

Pretty simple -- just provides autobox methods to strings that work in the way
you expect.

=head1 STRING METHODS

=head2 encode_base64

This method behaves the same as L<MIME::Base64/encode_base64>.

=head2 decode_base64

This method behaves the same as L<MIME::Base64/decode_base64>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<autobox|autobox>

=item *

L<autobox::Core|autobox::Core>

=item *

L<autobox::JSON|autobox::JSON>

=item *

L<MIME::Base64|MIME::Base64>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/autobox-Base64>
and may be cloned from L<git://github.com/RsrchBoy/autobox-Base64.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/autobox-Base64/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
