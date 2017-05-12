#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Perl source filter to filter Unicode representations of some operators
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------

package UnicodeOperators;
use Filter::Util::Call;

sub import
 {my ($type) = @_;
  my ($ref) = [];
  filter_add(bless $ref);
 }

sub filter
 {my ($self) = @_;
  my $status = filter_read();
  if ($status > 0)
   {s/\xE2\x88\x99/->/gs;
    s/\xE2\x96\xBA/=>/gs;
    s/\xE2\x97\x8B/=~/gs;
   }
  $status
 }

$VERSION = '1.002'; # Monday 19 September 2016

1;

=encoding utf-8

=head1 Name

UnicodeOperators - Unicode versions of some Perl operators

=head1 Synopsis

 use UnicodeOperators;

 say STDERR sub {$_[0]}∙(2), {a►1, b►2, c►3}∙{a}, "aaa" ○ s/a/b/gsr;

 # 21bbb

=head1 Description

 Replace -> with ∙, => with ► and =~ with ○

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2016 Philip R Brenan.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
