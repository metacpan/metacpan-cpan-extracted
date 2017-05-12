package warnings::illegalproto;
$warnings::illegalproto::VERSION = '0.001003';
# ABSTRACT: Disable illegal prototype warnings on old Perls

our $WARN;
{
  no warnings;
  use warnings 'syntax';
  no warnings qw(
    ambiguous
    bareword
    digit
    parenthesis
    precedence
    printf
    prototype
    qw
    reserved
    semicolon
  );
  BEGIN { $WARN = ${^WARNING_BITS} };
}
use strict;
use warnings;

BEGIN {
  *_ILLEGALPROTO_SUPPORTED = $] >= 5.012 ? sub(){1} : sub(){0};
}

sub import {
   if (_ILLEGALPROTO_SUPPORTED) {
      warnings->import('illegalproto')
   }
   else {
      ${^WARNING_BITS} |= $WARN
   }
}

sub unimport {
   if (_ILLEGALPROTO_SUPPORTED) {
      warnings->unimport('illegalproto')
   } else {
      ${^WARNING_BITS} &= ~ $WARN
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

warnings::illegalproto - Disable illegal prototype warnings on old Perls

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

 use strictures 1;
 use signatures;
 no warnings::illegalproto;

 sub ($foo) { ... }

=head1 DESCRIPTION

This module was implemented so that people can C<< use strictures >> and
C<< use signatures >> at the same time.  Thanks to mst, in Perl 5.12 and
greater this is trivial, but before that a strange dance had to be done.

This module will do the right thing for both before and after 5.12, but if you
want to use the native 5.12 and greater without this module, feel free to cargo
cult the following:

 no if $[ >= 5.012, warnings => 'illegalproto';
 no if $[ < 5.012, 'warnings::illegalproto';

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
