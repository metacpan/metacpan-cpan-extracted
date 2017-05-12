package Test::U32;

use strict;
use warnings;

require Exporter;

use vars qw( @ISA $VERSION @EXPORT @EXPORT_OK );
@ISA = qw(Exporter);
$VERSION = '0.01';
@EXPORT = qw(check_u32 check_have_u32);
@EXPORT_OK = @EXPORT;

require XSLoader;
XSLoader::load('Test::U32', $VERSION);

sub check_have_u32 {
    print "1..1\n";
    print check_u32() ? "ok 1\n" : "not ok\n";
}

1;
__END__

=head1 NAME

Test::U32 - Designed to test the proposition that U32 is 32 bits wide

=head1 SYNOPSIS

  use Test::U32;
  check_have_u32();  # prints 1..1 ok/not ok depending
  check_u32();       # returns true is U32 is exactly 32 bits wide

=head1 DESCRIPTION

This module is no use to anyone except authors of XS extensions who want to
know about the bahaviour of the U32 type defined by perl across multiple
different versions of perl on different OS. The results are of this survey
are kindly provided by CPANTESTERS.

=head1 EXPORT

=head2 check_have_u32()

This produces a standard 1 test TAP compliant output. See t/ for an example.

=head2 check_u32()

The actual underlying test. Returns 1 if U32 is exactly 32 bits wide.

=head1 AUTHOR

Dr James Freeman

=head1 COPYRIGHT

Copyright (C) 2008 by Dr James Freeman

=head1 LICENSE

This package is free software and is provided "as is" without express or
implied warranty. It may be used, redistributed and/or modified under the
terms of the Artistic License 2.0. A copy is include in this distribution.

=cut
