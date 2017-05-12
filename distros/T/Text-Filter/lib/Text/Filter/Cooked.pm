#! perl

package Text::Filter::Cooked;

use strict;
our $VERSION = "0.02";
use base q{Text::Filter};
use Carp;

# later use Encode;

=head1 NAME

Text::Filter::Cooked - Cooked reader for input files

=head1 SYNOPSIS

  use Text::Filter::Cooked;
  my $f = Text::Filter::Cooked->new
    (input => 'myfile.dat',
     comment => "#",
     join_lines => "\\");

  while ( my $line = $f->readline ) {
      printf("%3d\t%s\n", $f->lineno, $line);
  }

=head1 DESCRIPTION

Text::Filter::Cooked is a generic input reader. It takes care of a
number of things that are commonly used when reading data and
configuration files.

=over 4

=item *

Excess whitespace (leading and trailing) may be removed automatically.
Also, multiple whitespace characters may be replaced by a single blank.

=item *

Empty lines may be ignored automatically.

=item *

Lines that end with a custom defined join symbol, ususally a
backslash, are joined with the next line.

=item *

Lines that start with a custom defined comment symbol are ignored.

=back

=for later
On top of this, if the input file starts with a Unicode BOM, the input
will be correctly decoded into Perl internal format. It is also
possible to change the encoding used in a single file as often as
desired. See L<INPUT ENCODING>.

Text::Filter::Cooked is based on Text::Filter, see L<Text::Filter>.

=cut

################ Attribute Controls ################

my %_attributes =
  ( ignore_empty_lines		     => 1,
    ignore_leading_whitespace	     => 1,
    ignore_trailing_whitespace	     => 1,
    compress_whitespace		     => 1,
    # later	input		     => \&_diamond,
    # later	input_encoding	     => undef,
    input_postread		     => 'chomp',
    output_prewrite		     => 'newline',
    comment			     => undef,
    join_lines			     => undef,
    _lineno			     => undef,
    _open			     => 0,
  );

sub _standard_atts {
    my $self = shift;
    my %k;
    @k{ $self->SUPER::_standard_atts, keys %_attributes } = (0);
    return keys %k;
}

sub _attr_default {
    my ($self, $attr) = @_;
    return $_attributes{$attr} if exists $_attributes{$attr};
    return $self->SUPER::_attr_default($attr);
}

################ Constructor ################

=head1 CONSTRUCTOR

The constructor is called new() and takes a hash with attributes as
its parameter.

The following attributes are recognized and used by the constructor,
all others are passed to the base class, Text::Filter.

=over 4

=item ignore_empty_lines

If true, empty lines encountered in the input are ignored.

=item ignore_leading_whitespace

If true, leading whitespace encountered in the input is ignored.

=item ignore_trailing_whitespace

If true, trailing whitespace encountered in the input is ignored.

=item compress_whitespace

If true, multiple adjacent whitespace are compressed to a single space.

=item join_lines

This must be set to a string. Input lines that end with this string
(not taking the final line ending into account) are joined with the
next line read from the input.

=item comment

This must be set to a string. Input lines that start with this string
are ignored.

=for later
 (but see L<INPUT ENCODING>).

=begin later item input_encoding

Assume the input file to have this encoding.

Setting input_encoding will enable automatic and transparant handling
of different file encodings, see L<INPUT ENCODING>.

=back

=cut

# Inherited from base class.

################ Attributes ################

=head1 METHODS

All attributes have set and get methods, e.g., C<set_comment> and
C<get_input_encoding>.

Other methods:

=over 4

=item readline

Read a single line of input. If line ignoring is in effect, the
operation will be repeated internally until there is data to return.

=item lineno

Returns the number of the last line that was read from the input.

=item is_eof

Returns true iff the last record from the input has been read.

=back

=cut

sub set_input {
    my ($self, $input) = @_;
    $input = sub { $self->_diamond } if $input eq \&_diamond;
    $self->SUPER::set_input($input);
}

sub set_ignore_empty_lines {
    $_[0]->{ignore_empty_lines} = $_[1];
    return;
}

sub get_ignore_empty_lines {
    return $_[0]->{ignore_empty_lines};
}

=begin later

sub set_input_encoding {
    my ($self, $enc) = @_;
    $self->{input_encoding} = $enc;
    if ( my $fd = $self->get_filter_input_fd ) {
	binmode($fd, ':raw');
    }
    # warn("Input encoding = $enc\n");
    return;
}

sub get_input_encoding {
    return $_[0]->{input_encoding};
}

=cut

sub set_ignore_trailing_whitespace {
    $_[0]->{ignore_trailing_whitespace} = $_[1];
    return;
}

sub get_ignore_trailing_whitespace {
    return $_[0]->{ignore_trailing_whitespace};
}

sub _set_lineno {
    if ( @_ == 1 ) {
	$_[0]->{_lineno}++
    }
    else {
	$_[0]->{_lineno} = $_[1];
    }
    return;
}

sub _get_lineno {
    return $_[0]->{_lineno};
}

sub set_comment {
    my ($self, $c) = @_;
    # This check will probably fail with a custom regexp engine.
    $c = qr/^\Q$c\E(.*)$/ unless !defined($c) || ref($c) eq 'Regexp';
    $self->{comment} = $c;
    return;
}

sub get_comment {
    return $_[0]->{comment};
}

sub set_ignore_leading_whitespace {
    $_[0]->{ignore_leading_whitespace} = $_[1];
    return;
}

sub get_ignore_leading_whitespace {
    return $_[0]->{ignore_leading_whitespace};
}

sub set_compress_whitespace {
    $_[0]->{compress_whitespace} = $_[1];
    return;
}

sub get_compress_whitespace {
    return $_[0]->{compress_whitespace};
}

sub set_join_lines {
    my ($self, $v) = @_;
    # This check will probably fail with a custom regexp engine.
    $v = qr/^(.*)\Q$v\E$/ unless !defined($v) || ref($v) eq 'Regexp';
    $self->{join_lines} = $v;
    return;
}

sub get_join_lines {
    return $_[0]->{join_lines};
}

sub _set_eof {
    $_[0]->{_eof} = 1;
    return;
}

sub _is_eof {
    return $_[0]->{_eof};
}

sub _set_open {
    $_[0]->{_open} = 1;
    return;
}

sub _is_open {
    return $_[0]->{_open};
}

################ Methods ################

sub readline {
    my $self = shift;

    return if $self->_is_eof;

    my $post = sub {
	for ( shift ) {

	    # Whitespace ignore + compress.
	    s/^\s+//  if $self->get_ignore_leading_whitespace;
	    s/\s+$//  if $self->get_ignore_trailing_whitespace;
	    s/\s+/ /g if $self->get_compress_whitespace;

	    return $_;
	}
    };

    my $line;
    my $pre;

    while ( defined ($line = $self->SUPER::readline) ) {

=begin later

	my $ienc = $self->get_input_encoding;
	if ( $ienc && ! defined $self->_get_lineno ) {
	    # Detecting BOM...
	    if ( substr($line, 0, 2) eq "\xff\xfe" ) {
		# Found BOM (BE)
		$line = substr($line, 2);
		$self->set_input_encoding($ienc = "utf-16-be");
	    }
	    elsif ( substr($line, 0, 2) eq "\xfe\xff" ) {
		# Found BOM (LE)
		$line = substr($line, 2);
		$self->set_input_encoding($ienc = "utf-16le");
	    }
	}

=cut

	$self->_set_lineno;
	$self->{_start_line} = $self->_get_lineno unless defined $pre;

=begin later

	if ( $ienc ) {
	    $line = decode($ienc, $line, 0);
	}

=cut

	# Feature: ignore_empty_lines.
	next unless $self->get_ignore_empty_lines && $line =~ /\S/;

	my $t = $self->get_comment;
	if ( $t && $line =~ $t ) {

=begin later
	    $line = $1;
	    if ( $line =~ /^\s*
			   content-type \s*
			   : \s*
			   text \s* (?: \/ \s* plain \s* )?
			   ; \s* charset \s* = \s*
			   ([^\s;]+)
			   \s* $
                          /mix ) {
		$self->set_input_encoding($1);
	    }

=cut

	    next;
	}

 	$t = $self->get_join_lines;
	if ( $t && $line =~ $t ) {
	    $pre ||= "";
	    $pre .= $1;
	    next;
	}

	return $post->(defined $pre ? "$pre$line" : $line);
    }
    $self->_set_eof;

=for later
    $self->set_input_encoding($self->{input_encoding});

=cut

    return $post->($pre) if defined $pre;
    return;
}

sub lineno {
    my $self = shift;
    return $self->{_start_line};
}

sub _diamond {
    my $self = shift;

    while ( 1 ) {
	unless ( $self->_is_open ) {
	    return unless @ARGV;
	    my $argv = shift(@ARGV);
	    $self->{_argf} = undef;
	    open($self->{_argf}, '< :raw', $argv)
	      or die("$argv: $!\n");
	    $self->_set_open(1);
	}
	my $result = $self->{_argf}->readline;
	return $result if defined $result;
	close($self->{_argf});
	$self->_set_open(0);
    }
}

1;

__END__

=begin later head1 INPUT ENCODING

Text::Filter::Cooked is capable of dealing with input files that may
have arbitrary character encodings.

If the C<input_encoding> attribute is set, the input data is assumed
to be in the specified encoding.

If the input file starts with a Unicode BOM marker, it will be
considered UTF-16 and decoded accordingly.

If the file contains a comment record with non-comment contents of the
form

  Content-Type: text ; charset = FOO

the rest of the file is considered to be in encoding FOO.

All spaces in the Content-Type line are optional. Matching is
case-insensitive. C<text/plain> may be used instead of C<text>.

Input encoding is reset to its original value after reading the last
line of a file. When reading multiple files using the default input
mechanism each file starts with the original setting of input
encoding.

=end later

=head1 EXAMPLE

This filters the input according to the specified parameters.

  use Text::Filter::Cooked;
  Text::Filter::Cooked->run
    (input => 'myfile.dat',
     comment => "#",
     join_lines => "\\");

This filters the input and writes all cooked lines together with their
line numbers.

  use Text::Filter::Cooked;
  my $f = Text::Filter::Cooked->new
    (input => 'myfile.dat',
     comment => "#",
     join_lines => "\\");

  while ( my $line = $f->readline ) {
      printf("%3d\t%s\n", $f->lineno, $line);
  }

=begin later head1 EXAMPLE

  use Text::Filter::Cooked;
  my $f = Text::Filter::Cooked->new
    (input => 'myfile.dat',
     input_encoding => 'ascii',
     comment => "#",
     join_lines => "\\");

  while ( my $line = $f->readline ) {
      printf("%3d\t%s\n", $f->lineno, $line);
  }

Example data file:

  # This is comment, and ignored.
  This is data in ASCII
  This is data in ASCII
  This \
    will \
      be     glued   \
             together \
  as one line
  # Content-Type text/plain; charset=iso-8859-1
  Thïs ïs dätä ïn ISØ-8859.1 (Låtin1)
  Thïs ïs dätä ïn ISØ-8859.1 (Låtin1)

=end later

=head1 AUTHOR AND CREDITS

Johan Vromans (jvromans@squirrel.nl) wrote this module.

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2007,2013 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut
