package sane;
our $VERSION = '0.99';

sub import {
    require strict;
    strict->import;

    require warnings;
    warnings->import;

    require utf8;
    utf8->import;

    require feature;
    feature->import(sprintf ":%vd", $^V);
}

1;
__END__

=head1 NAME

sane - provide sane default pragmas

=head1 SYNOPSIS

  use sane;

  # is the same as:

  use strict;
  use warnings;
  use utf8;
  use feature (sprintf(":%vd", $^V));

=head1 DESCRIPTION

C<sane> pragma is written for people who are tired of typing hackneyed expressions.
Every perl mongers write the same code on the top of scripts.

Assuming that it is true, what we should do about it is shorten it.

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
