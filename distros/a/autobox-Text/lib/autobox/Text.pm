use strict;
use warnings;
package autobox::Text;

# ABSTRACT: turns baubles into trinkets

use base qw/autobox/;

sub import {
    my $class = shift;
    # $class->SUPER::import(DEFAULT => 'autobox::Core::', @_);
    $class->SUPER::import(
			  ARRAY => 'autobox::Text::Subs',
			  SCALAR => 'autobox::Text::Subs',
			 );
}

package autobox::Text::Subs;

no warnings qw/redefine/;

use Text::Wrap;
use Encode qw(find_encoding);

sub wrap {
    my $text = shift;
    $Text::Wrap::columns = shift || 80;
    return Text::Wrap::wrap('', '', $text);
}

sub unwrap {
    my @text = split /\n\n/, shift;
    s/\n/ /g for (@text);
    return (join "\n\n", @text) =~ s/^\s*|\s*$//rg;
}

sub bulletize {
    my @text = split /\n/, shift;
    my $bullet = shift || '-';

    if ($bullet =~ /\d/) {
	my $fmt = shift || "%i. %s";
	return (join "\n", map { sprintf $fmt, $bullet++, $_ } @text) =~ s/^\s*|\s*$//rg
    } else {
	my $fmt = shift || "%s %s";
	return (join "\n", map { sprintf $fmt, $bullet, $_ } @text) =~ s/^\s*|\s*$//rg;
    }
}

sub unbulletize {
    my @text = split /\n/, shift;
    for (@text) {
	s/^[\*\-\_]\s//;
	s/\d+\.\s//;
    }
    return (join "\n", @text) =~ s/^\s*|\s*$//rg;
}

sub trim {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub tidy {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str =~ s/[\t ]+/ /g;
    $str =~ s/\n{3,}/\n\n/g;
    return $str;
}

sub encode {
    my $str = shift;
    my $encoding = shift || "UTF-8";
    return Encode::decode $encoding, $str;
}

sub decode {
    my $str = shift;
    my $encoding = shift || "UTF-8";
    return Encode::decode $encoding, $str;
}

# markdown
# lorem
# truncate String::Truncate

1;

=head1 NAME

autobox::Text - turns baubles into trinkets

=head1 SYNOPSIS

  use autobox::Text;

  my $text = "Some text";
  my $wrapped = $text->wrap(60);
  my $bullets = $text->bulletize('*');

=head1 DESCRIPTION

This module extends scalars and arrays with a set of convenient
text-processing methods using L<autobox>.

=head1 METHODS

=head2 SCALAR->wrap([$columns])

Wraps a long string into multiple lines. Defaults to 80 columns if
no column width is provided. Uses L<Text::Wrap>.

=head2 SCALAR->unwrap

Removes wrapping by joining each paragraph into a single line,
preserving paragraph breaks.

=head2 SCALAR->bulletize([$bullet, $format])

Adds bullet characters or numeric markers to each line. By default,
uses a hyphen C<->. If C<$bullet> contains digits, numeric bulleting
is applied using a format string (default: C<"%i. %s">). For non-numeric
bullets, format string defaults to C<"%s %s">.

=head2 SCALAR->unbulletize

Removes leading bullet characters (C<*>, C<->, C<_>) or numeric markers
from each line of a bulletized list. Does not impact numbered lists

=head2 SCALAR->trim

Removes leading and trailing whitespace from a string.

=head2 SCALAR->tidy

Performs multiple cleanup operations:

=over

=item * Strips leading and trailing whitespace.

=item * Collapses multiple tabs and spaces into one 

=item * Collapses three or more consecutive newlines into two.

=back

=head1 SEE ALSO

L<autobox>, L<Text::Wrap>, L<String::Truncate>

=head1 AUTHOR

<Your Name Here>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
