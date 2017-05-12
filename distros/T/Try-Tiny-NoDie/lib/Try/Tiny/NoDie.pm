package Try::Tiny::NoDie;
use 5.008_005;

our $VERSION = '0.01';

use strict;
use warnings;

use Try::Tiny;

use Exporter 5.57 'import';
our @EXPORT = our @EXPORT_OK = qw(try_no_die try catch finally);

sub try_no_die (&;@) {
  local $SIG{__DIE__} = "IGNORE";
  &Try::Tiny::try;
}

1;
__END__

=encoding utf-8

=head1 NAME

Try::Tiny::NoDie - minimal try/catch with local-disabling of SIGDIE

=head1 SYNOPSIS

Preserves all of L<Try::Tiny>'s semantics to expect and handle exceptions but
adds a C<try_no_die> keyword which behaves exactly just like C<try> but with
a locally-disabled C<__DIE__> hook.

As such:

  try_no_die {
    die "foo";
  };

is exactly equivalent to:

  try {
    local $SIG{__DIE__} = "IGNORE";
    die "foo";
  };

=head1 DESCRIPTION

This module is primarily designed for developer convenience, for cases
wherein the desired behavior within the scope of the error throwing code
is a nullified C<__DIE__> handler.

=head1 FAQ

=head3 Why not add an option to disable C<__DIE__> on L<Try::Tiny>?

Yes, that's possible.

However, as L<Try::Tiny> aims to preserve compatibility as one of its design
objective, B<Try::Tiny::NoDie> holds a different opinion and offers this
option to the developer.

=head3 Why not override the default behavior of C<try> instead?

As disabling C<__DIE__> within the scope of the error throwing code is a
rather specific corner case, this poses a potential risk when the
developer expects otherwise if the same keyword was to be overriden.

Due to this, a separate C<try_no_die> keyword has been added instead.

=head1 AUTHOR

Arnold Tan Casis E<lt>atancasis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2016- Arnold Tan Casis

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Try::Tiny>

=cut
