package Text::VisualWidth;

use 5.006;
use strict;
use warnings;

use AutoLoader qw(AUTOLOAD);
our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Text::VisualWidth', $VERSION);

1;
__END__

=head1 NAME

Text::VisualWidth - Perl extension for trimming text by the number of the columns of terminals and mobile phones.

=head1 SYNOPSIS

  use Text::VisualWidth::EUC_JP;
  my $length = Text::VisualWidth::EUC_JP::width($str);
  my $str    = Text::VisualWidth::EUC_JP::trim($str, 20);

  use Text::VisualWidth::UTF8;
  my $length = Text::VisualWidth::UTF8::width($str);
  my $str    = Text::VisualWidth::UTF8::trim($str, 20);

=head1 DESCRIPTION

This module provides functions to treat half-width and full-width characters and display correct size of text in one line on terminals and mobile phones. You can know the visual width of any text and truncate text by the visual width.
Now this module support EUC-JP and UTF-8 and tested only with Japanese.

=head1 AUTHOR

Takaaki Mizuno, E<lt>module@takaaki.infoE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Takaaki Mizuno

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
