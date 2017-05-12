package XML::Reader::PP;
$XML::Reader::PP::VERSION = '0.04';
use 5.014;

use strict;
use warnings;

use XML::Reader 0.48 qw(XML::Parsepp slurp_xml);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(slurp_xml);

sub new {
    my $class = shift;
    XML::Reader->new(@_);
}

1;

__END__

=head1 NAME

XML::Reader::PP - Importing XML::Reader using XML::Parsepp

=head1 SYNOPSIS

XML::Reader::PP provides all the functionalities of XML::Reader using the pure perl parser
XML::Parsepp.

  use XML::Reader::PP;

  my $text = q{<init>n <?test pi?> t<page node="400">m <!-- remark --> r</page></init>};

  my $rdr = XML::Reader::PP->new(\$text);
  while ($rdr->iterate) {
      printf "Path: %-19s, Value: %s\n", $rdr->path, $rdr->value;
  }

This program produces the following output:

  Path: /init              , Value: n t
  Path: /init/page/@node   , Value: 400
  Path: /init/page         , Value: m r
  Path: /init              , Value:

To find out more about the different functionalities, please have a look at the documentation
for L<XML::Reader>.

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=head1 SEE ALSO

L<XML::Parsepp>,
L<XML::Reader>,
L<XML::Reader::RS>.

=cut
