package YAML::Parser::Syck;
use strict;

use vars qw( $VERSION @ISA );
$VERSION = '0.01';
require DynaLoader;
@ISA = qw(DynaLoader);

'YAML::Parser::Syck'->bootstrap($VERSION);

1;

=head1 NAME 

YAML::Parser::Syck - Perl Wrapper for the YAML Parser Extension: libsyck

=head1 SYNOPSIS

    use YAML::Parser::Syck;

    my $hash = YAML::Parser::Syck::Parse(<<'...');
    ---
    format: yaml
    parser:
      name: Syck
      speed: Fast!
    authors:
    - name: Why The Lucky Stiff
      code: libsyck
    - name: Brian Ingerson
      code: [YAML.pm, YAML::Parser::Syck]
    description: This simple XS module is a testament to
      the power of libsyck, which was originally written
      for the Ruby language.
    tasks left to do: &chart |
        brian     clark    oren    why
        -----     -----    ----    ---
        shout     beg      sneer   smile 

        total = YAML
    things we always do: *chart
    ...
    
    use Data::Dumper; print Dumper $hash;

=head1 DESCRIPTION

    libsyck is a *gift* from a gifted Stiff named 'Why'.

    YAML::Parser::Syck is an XS module that binds libsyck to Perl. 

=head1 DEPENDENCIES

You'll need to have libsyck installed on your system. See
http://whytheluckystiff.net/syck/ for some details.

=head1 HOWTO

Please put notes here: http://yaml.kwiki.org/index.cgi?PerlYamlParserSyckHowto

Also see http://www.yaml.org if you are new to YAML.

=head1 NOTE from the author.

YAML.pm is showing its age. It works ok most of the time for simple
stuff, and some medium stuff. It badly needs a rewrite. And I am working
on that rewrite now. The new YAML.pm will have the same simple Dump/Load
interface, but will also have much more advanced features like a
streaming (node at a time) interface.

The new YAML.pm will also be "pluggable". That means that there can be
any number of Parsers, Loaders, Dumpers and Emitters written for the
framework. YAML::Parser::Syck will be one of the Parsers. There will
also be a pure Perl Parser.

I have decided to release the module early so that people might benefit
from it. On one hand this Parser is wonderful because it understands the
entire current YAML Specification. On the other hand, my Perl wrapper
code currently ignores all type information, so it will not be useful
for deserializing classes. Be patient.

Still, I think this pre-alpha release is a cause for joy in the Perl
YAML community.

Enjoy!

=head1 BUGS

You kidding? Don't run this code with out parental supervision and a
*BIG* fire extinguisher.

  * Types are not supported.
  * Error reporting is poor.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
