################################################################
# XML::Encoding
#
# Version 1.x Copyright 1998 Clark Cooper <coopercc@netheaven.com>
# Changes in Version 2.00 onwards Copyright (C) 2007-2010 Steve Hay
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# See pod documentation at the end of the file
#

package XML::Encoding;

use 5.008001;

use XML::Parser;

use strict;
use vars qw(@ISA $VERSION);

@ISA = qw(XML::Parser);
$VERSION = '2.09';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  # Maybe require setting of PushPrefixFcn, PopPrefixFcn, and RangeSetFcn

  $self->setHandlers(Start => \&start, End => \&end, Final => \&fini);
  return $self;
}

sub start {
  my ($exp, $el, %attr) = @_;

  return if $exp->{EN_Skip};

  $exp->xpcroak("Root element must be encmap")
    if ($exp->depth == 0 and $el ne 'encmap');

  my $xpmode = $exp->{EN_ExpatMode};

  if ($el eq 'ch'
      or $el eq 'range')
    {
      my $byte = $attr{byte};
      $exp->xpcroak("Missing required byte attribute")
	unless defined($byte);

      $byte = cnvnumatt($exp, $byte, 'byte');
      $exp->xpcroak("byte attribute > 255") if $byte > 255;

      my $uni = $attr{uni};
      $exp->xpcroak("Missing required uni attribute")
	unless defined($uni);

      $uni = cnvnumatt($exp, $uni, 'uni');
      $exp->xpcroak("uni attribute > 0xFFFF") if $uni > 0xFFFF;

      my $len = 1;

      if ($el eq 'range') {
	$len = $attr{len};
	$exp->xpcroak("Missing required len attribute")
	  unless defined($len);

	$len = cnvnumatt($exp, $len, 'len');
	$exp->xpcroak("Len plus byte > 256") if ($len + $byte) > 256;
      }

      check_range($exp, $byte, $len, $uni)
	if ($xpmode
	    and $byte < 128
	    and $byte != $uni
	    and not $exp->in_element('prefix'));

      my $range_set_fcn = $exp->{RangeSetFcn};
      if (defined $range_set_fcn) {
	my $result = &$range_set_fcn($byte, $uni, $len);
	$exp->xpcroak($result)
	  if ($xpmode and $result);
      }
    }
  elsif ($el eq 'prefix') {
    $exp->xpcroak("prefix nested too deep")
      if ($xpmode and $exp->within_element('prefix') >= 3);

    my $byte = $attr{byte};
    $exp->xpcroak("Missing required byte attribute")
      unless defined($byte);

    $byte = cnvnumatt($exp, $byte, 'byte');
    $exp->xpcroak("byte attribute > 255") if $byte > 255;
    my $push_pfx_fcn = $exp->{PushPrefixFcn};
    if (defined $push_pfx_fcn) {
      my $result = &$push_pfx_fcn($byte);
      $exp->xpcroak($result)
	if ($xpmode and $result);
    }
  }
  elsif ($el eq 'encmap') {
    my $name = $attr{name};

    $exp->xpcroak("Missing required name attribute")
      unless defined($name);

    $exp->{EN_Name} = $name;

    my $expat = $attr{expat};
    if (defined($expat)) {
      $exp->xpcroak("Value of expat attribute should be yes or no")
	unless ($expat eq 'yes' or $expat eq 'no');
      $exp->{EN_ExpatMode} = $expat eq 'yes';
    }
    else {
      $exp->{EN_ExpatMode} = 0;
    }
    $exp->xpcroak("Not an expat mode encmap")
      if ($exp->{ExpatRequired} and ! $exp->{EN_ExpatMode});
  }
  else {
    my $depth = $exp->depth;
    $exp->xpcroak($exp, "Root element isn't encmap")
      unless $depth;

    $exp->xpcarp("Skipping unrecognized element '$el'\n");
    $exp->{EN_Skip} = $depth;
  }

}  # End start

sub end {
  my ($exp, $el) = @_;

  if ($exp->{EN_Skip}) {
    $exp->{EN_Skip} = 0
      if $exp->{EN_Skip} == $exp->depth;
  }
  elsif ($el eq 'prefix') {
    my $xpmode = $exp->{EN_ExpatMode};

    my $pop_pfx_fcn = $exp->{PopPrefixFcn};
    if (defined $pop_pfx_fcn) {
      my $result = &$pop_pfx_fcn();
      $exp->xpcroak($result)
	if ($xpmode and $result);
    }
  }
}  # End end

sub fini {
  my ($exp) = @_;
  $exp->{EN_Name};
}  # End fini

sub check_range {
  my ($exp, $start, $len, $uni) = @_;

  # The following characters are exceptions to the expat rule that characters
  # in the ascii set (ordinal values < 128) must have the same value in the
  # source encoding: $@\^`{}~'
  # The ordinal values for these are 36,92,94,96,123,125,126,39
  # Any len >= 3 implies you have to be hitting some non-special
  # For 2 just check start == 125 ('}')
  # For 1 check individually.

  if ($len == 1) {
    return if chr($start) =~ /[\$@\\^`{}~']/;
  }
  elsif ($len == 2 and $start == 125) {
    return;
  }

  $exp->xpcroak("Sets ascii character to non-ascii value");
}

sub cnvnumatt {
  my ($exp, $str, $name) = @_;

  $exp->xpcroak("$name attribute is not a decimal or hex value")
    unless ($str =~ /^(?:(\d+)|x([0-9a-f]+))$/i);

  if (defined($1)) {
    return $str + 0;
  }
  else {
    return hex($2);
  }
}  # End cnvnumatt

1;

__END__

=head1 NAME

XML::Encoding - A perl module for parsing XML encoding maps.

=head1 SYNOPSIS

  use XML::Encoding;
  my $em_parser = new XML::Encoding(ErrorContext  => 2,
                                    ExpatRequired => 1,
                                    PushPrefixFcn => \&push_prefix,
                                    PopPrefixFcn  => \&pop_prefix,
                                    RangeSetFcn   => \&range_set);

  my $encmap_name = $em_parser->parsefile($ARGV[0]);

=head1 DESCRIPTION

This module, which is built as a subclass of XML::Parser, provides a parser
for encoding map files, which are XML files. The file maps/encmap.dtd in the
distribution describes the structure of these files. Calling a parse method
returns the name of the encoding map (obtained from the name attribute of
the root element). The contents of the map are processed through the
callback functions push_prefix, pop_prefix, and range_set.

=head1 METHODS

This module provides no additional methods to those provided by XML::Parser,
but it does take the following additional options.

=over 4

=item * ExpatRequired

When this has a true value, then an error occurs unless the encmap
"expat" attribute is set to "yes". Whether or not the ExpatRequired option
is given, the parser enters expat mode if this attribute is set. In expat
mode, the parser checks if the encoding violates expat restrictions.

=item * PushPrefixFcn

The corresponding value should be a code reference to be called when
a prefix element starts. The single argument to the callback is an integer
which is the byte value of the prefix. An undef value should be returned
if successful. If in expat mode, a defined value causes an error and is
used as the message string.

=item * PopPrefixFcn

The corresponding value should be a code reference to be called when a
prefix element ends. No arguments are passed to this function. An undef
value should be returned if successful. If in expat mode, a defined value
causes an error and is used as the message string.

=item * RangeSetFcn

The corresponding value should be a code reference to be called when a
"range" or "ch" element is seen. The 3 arguments passed to this function are:
(byte, unicode_scalar, length)
The byte is the starting byte of a range or the byte being mapped by a
"ch" element. The unicode_scalar is the Unicode value that this byte (with
the current prefix) maps to. The length of the range is the last argument.
This will be 1 for the "ch" element. An undef value should be returned if
successful. If in expat mode, a defined value causes an error and is used
as the message string.

=back

=head1 AUTHOR

Clark Cooper <F<coopercc@netheaven.com>>

Steve Hay <F<shay@cpan.org>> is now maintaining XML::Encoding
as of version 2.00

=head1 SEE ALSO

XML::Parser

=cut
