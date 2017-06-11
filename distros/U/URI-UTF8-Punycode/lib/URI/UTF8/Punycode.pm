package URI::UTF8::Punycode;

use strict;
use warnings;

use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw($VERSION);
our @EXPORT    = qw(puny_enc puny_dec);

our $VERSION = '1.05';

use XSLoader;
XSLoader::load('URI::UTF8::Punycode', $VERSION);

1;

__END__

=head1 NAME

URI::UTF8::Punycode - Punycode conversion of UTF-8 string.

=head1 SYNOPSIS

  use URI::UTF8::Punycode;

  $punycode = puny_enc($utf8str);
  $utf8onsv = puny_dec($punycode);

=head1 DESCRIPTION

Punycode conversion of UTF-8 string.

=head1 AUTHOR

Twinkle Computing <twinkle@cpan.org>

=head1 LISENCE

This released under The GPL General Public License.

=cut
