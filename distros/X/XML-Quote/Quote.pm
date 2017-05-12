package XML::Quote;
# $Version: release/perl/base/XML-Quote/Quote.pm,v 1.6 2003/01/31 09:03:57 godegisel Exp $

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
	xml_quote
	xml_dequote
);
@EXPORT_OK = qw(
	xml_quote
	xml_dequote
	xml_quote_min
);
%EXPORT_TAGS = (
	all	=> [qw(
	xml_quote
	xml_dequote
	xml_quote_min
	)],
);
$VERSION = '1.02';

bootstrap XML::Quote $VERSION;

1;
__END__
=pod

=head1 NAME

XML::Quote - XML quote/dequote functions

=head1 SYNOPSIS

  use strict;
  use XML::Quote qw(:all);
  
  my $str=q{666 > 444 & "apple" < 'earth'};
  print xml_quote($str),"\n";
  # 666 &gt; 444 &amp; &quot;apple&quot; &lt; &apos;earth&apos;

  my $str2=q{666 &gt; 444 &amp; &quot;apple&quot; &lt; &apos;earth&apos;};
  print xml_dequote($str2),"\n";
  # 666 > 444 & "apple" < 'earth'

  my $str3=q{666 > 444 & "apple" < 'earth'};
  print xml_quote_min($str3),"\n";
  # 666 > 444 &amp; &quot;apple&quot; &lt; 'earth'

=head1 DESCRIPTION

This module provides functions to quote/dequote strings in "xml"-way.

All functions are written in XS and are very fast; they correctly process
utf8, tied, overloaded variables and all the rest of perl "magic".

=head1 FUNCTIONS

=over 4

=item $quoted = xml_quote($str);

This function replaces all occurences of symbols '&', '"', ''', '>', '<'
to '&amp;', '&quot;', '&apos;', '&gt;', '&lt;' respectively.

Returns quoted string or undef if $str is undef.

=item $dequoted = xml_dequote($str);

This function replaces all occurences of '&amp;', '&quot;', '&apos;', '&gt;',
'&lt;' to '&', '"', ''', '>', '<' respectively.
All other entities (for example &nbsp;) will not be touched.

Returns dequoted string or undef if $str is undef.

=item $quoted = xml_quote_min($str);

This function replaces all occurences of symbols '&', '"', '<'
to '&amp;', '&quot;', '&lt;' respectively. Symbols ''' and '>' are not
replaced.

Returns quoted string or undef if $str is undef.

=back

=head1 EXPORT

xml_quote(), xml_dequote() are exported as default.

=head1 PERFORMANCE

You can use t/benchmark.pl to test the perfomance.  Here is the result
on my P4 box.

  Benchmark: timing 1000000 iterations of perl quote, xs quote...
  perl quote: 108 wallclock secs (88.08 usr +  0.01 sys = 88.09 CPU) @ 11351.64/s (n=1000000)
    xs quote: 20 wallclock secs (16.78 usr +  0.00 sys = 16.78 CPU) @ 59591.20/s (n=1000000)

  Benchmark: timing 1000000 iterations of perl dequote, xs dequote...
  perl dequote: 106 wallclock secs (85.22 usr +  0.09 sys = 85.31 CPU) @ 11721.54/s (n=1000000)
    xs dequote: 19 wallclock secs (15.92 usr +  0.02 sys = 15.94 CPU) @ 62743.13/s (n=1000000)

=head1 AUTHOR

Sergey Skvortsov E<lt>skv@protey.ruE<gt>

=head1 SEE ALSO

L<http://www.w3.org/TR/REC-xml>,
L<perlre>

=head1 COPYRIGHT

Copyright 2003 Sergey Skvortsov E<lt>skv@protey.ruE<gt>.
All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
