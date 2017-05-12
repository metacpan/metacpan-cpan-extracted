package URI::git;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use base qw( URI::_login );

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

URI::git - git URI scheme

=head1 SYNOPSIS

  use URI;

  my $uri = URI->new("git://github.com/miyagawa/remedie.git");
  $uri->host; # github.com
  $uri->path; # /miyagawa/remedie.git

=head1 DESCRIPTION

URI::git is an URI scheme handler for L<git://> protocol.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<URI>

=cut
