#!/usr/bin/perl -w -pi

BEGIN {
    undef $/;
}

my $LICENSE = <<EOS;


=head1 LICENSE

Copyright (C) Catalyst IT NZ Ltd
Copyright (C) Bywater Solutions

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Srdjan Janković E<lt>srdjan\@catalyst.net.nzE<gt>

=cut
EOS

s/(.*__END__).*/$1$LICENSE/s;
