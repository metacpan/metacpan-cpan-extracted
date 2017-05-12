package Text::Scws;
# @(#) $Id: $
# Copyright (c) 2008 Xueron Nee <xueron@xueron.com>

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();
$VERSION = '0.01';

bootstrap Text::Scws $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the documentation for the module.

=head1 NAME

Text::Scws - Perl interface to libscws

=head1 SYNOPSIS

  use Text::Scws;
  $scws = Text::Scws->new();
  $scws->set_dict('/path/to/dict.xdb');
  $scws->set_rule('/path/to/rule.ini');
  $scws->set_ignore(1);
  $scws->set_multi(1);

  $s = shift;
  $scws->send_text($s);
  while ($r = $scws->get_result()) {
    foreach (@$r) {
        print $_->{word}, " ";
    }
  }
  print "\n";

=head1 DESCRIPTION

The B<Text::Scws> module provides a Perl interface to the libscws (by hightman).

=head2 Utility methods

B<Text::Scws> objects provide the following methods:

todo

=head1 ERRORS

todo

=head1 NOTES

todo


=head1 AUTHOR

Xueron Nee <xueron@xueron.com>

=head1 SEE ALSO

SCWS - http://www.hightman.cn/index.php?scws

=cut
