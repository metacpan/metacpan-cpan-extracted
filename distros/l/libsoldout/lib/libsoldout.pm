package libsoldout;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use libsoldout ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('libsoldout', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

libsoldout - Perl extension  for libsoldout, a flexible library to parse markdow
n language

=head1 SYNOPSIS

  use strict;
  use warnings;
  use libsoldout;

  my $markdown_txt = '
  TEST
  ------
   - one arg
   - two arg
   - something else
  ';

  my $html = &libsoldout::markdown2html($markdown_txt);

  print $html;

=head1 DESCRIPTION

  This module provies a simple access to libsoldout, a simple, fast
  and flexible markdown parser. This initial provides functions to
  convert three makrdown  variants to  HTML.

  markdown2html : Converts a strict markdown text in HTML

  markdown2discount_html :  Converts a markdown text with discount
                  extensions to HTML

  markdown2nat_html : Converts a markdown text with discount and
                 natacha extensions to HTML


=head1 SEE ALSO

See http://fossil.instinctive.eu/libsoldout/index for more informations
about libsoldout.

See http://www.pell.portland.or.us/~orc/Code/markdown/ for more informations
about cdiscount markdown extensions.


=head1 AUTHOR

Rodrigo OSORIO, E<lt>rodrigo@bebik.netE<gt> for this perl module

Natacha Porte, E<lt>natbsd@instinctive.euE<gt> for libsoldout code

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Rodrigo OSORIO

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

