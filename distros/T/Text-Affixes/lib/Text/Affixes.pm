package Text::Affixes;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	get_prefixes
	get_suffixes
);

our $VERSION = '0.09';

=head1 NAME

Text::Affixes - Prefixes and suffixes analysis of text

=head1 SYNOPSIS

  use Text::Affixes;
  my $text = "Hello, world. Hello, big world.";
  my $prefixes = get_prefixes($text);

  # $prefixes now holds
  # {
  # 	3 => {
  # 		'Hel' => 2,
  # 		'wor' => 2,
  # 	}
  # }

  # or

  $prefixes = get_prefixes({min => 1, max => 2},$text);

  # $prefixes now holds
  # {
  # 	1 => {
  # 		'H' => 2,
  # 		'w' => 2,
  # 		'b' => 1,
  # 	},
  # 	2 => {
  # 		'He' => 2,
  # 		'wo' => 2,
  # 		'bi' => 1,
  # 	}
  # }

  # the use for get_suffixes is similar

=head1 DESCRIPTION

Provides methods for prefix and suffix analysis of text.

=head1 METHODS

=head2 get_prefixes

Extracts prefixes from text. You can specify the minimum and maximum
number of characters of prefixes you want.

Returns a reference to a hash, where the specified limits are mapped
in hashes; each of those hashes maps every prefix in the text into the
number of times it was found.

By default, both minimum and maximum limits are 3. If the minimum
limit is greater than the lower one, an empty hash is returned.

A prefix is considered to be a sequence of word characters (\w) in
the beginning of a word (that is, after a word boundary) that does not
reach the end of the word ("regular expressionly", a prefix is the $1
of /\b(\w+)\w/).

  # extracting prefixes of size 3
  $prefixes = get_prefixes( $text );

  # extracting prefixes of sizes 2 and 3
  $prefixes = get_prefixes( {min => 2}, $text );

  # extracting prefixes of sizes 3 and 4
  $prefixes = get_prefixes( {max => 4}, $text );

  # extracting prefixes of sizes 2, 3 and 4
  $prefixes = get_prefixes( {min => 2, max=> 4}, $text);

=cut

sub get_prefixes {
	return _get_elements(1,@_);
}

=head2 get_suffixes

The get_suffixes function is similar to the get_prefixes one. You
should read the documentation for that one and than come back to this
point.

A suffix is considered to be a sequence of word characters (\w) in
the end of a word (that is, before a word boundary) that does not start
at the beginning of the word ("regular expressionly" speaking, a
suffix is the $1 of /\w(\w+)\b/).

  # extracting suffixes of size 3
  $suffixes = get_suffixes( $text );

  # extracting suffixes of sizes 2 and 3
  $suffixes = get_suffixes( {min => 2}, $text );

  # extracting suffixes of sizes 3 and 4
  $suffixes = get_suffixes( {max => 4}, $text );

  # extracting suffixes of sizes 2, 3 and 4
  $suffixes = get_suffixes( {min => 2, max=> 4}, $text);

=cut

sub get_suffixes {
	return _get_elements(0,@_);
}

sub _get_elements {
	my $task = shift;

=head1 OPTIONS

Apart from deciding on a minimum and maximum size for prefixes or suffixes, you
can also decide on some configuration options.

=cut

	# configuration
	my %conf = (	min             => 3,
			max             => 3,
			exclude_numbers => 1,
			lowercase       => 0,
		);
	if (ref $_[0] eq 'HASH') {
		%conf = (%conf, %{+shift});
	}
	return {} if $conf{max} < $conf{min};

	# get the elements
	my %elements;
	my $text = shift || return undef;
	$conf{min} = 1 if $conf{min} < 1;
	for ($conf{min} .. $conf{max}) {

		my $regex = $task ? qr/\b(\w{$_})\w/ :	# prefixes
                                    qr/\w(\w{$_})\b/ ;	# suffixes

		while ($text =~ /$regex/g) {
			$elements{$_}{$1}++;
		}

	}

=head2 exclude_numbers

Set to 0 if you consider numbers as part of words. Default value is 1.

  # this
  get_suffixes( {min => 1, max => 1, exclude_numbers => 0}, "Hello, but w8" );

  # returns this:
    {
      1 => {
             'o' => 1,
             't' => 1,
             '8' => 1
           }
    }

=cut

	# exclude elements containing numbers
	if ($conf{exclude_numbers}) {
		for my $s (keys %elements) {
			for (keys %{$elements{$s}}) {
				delete ${$elements{$s}}{$_} if /\d/;
			}
		}
	}

=head2 lowercase

Set to 1 to extract all prefixes in lowercase mode. Default value is 0.

ATTENTION: This does not mean that prefixes with uppercased characters won't be
extracted. It means they will be extracted after being lowercased.

  # this...
  get_prefixes( {min => 2, max => 2, lowercase => 1}, "Hello, hello");

  # returns this:
    {
      2 => {
             'he' => 2
           }
    }

=cut

	# elements containing uppercased characters become lowercased ones
	if ($conf{lowercase}) {
		for my $s (keys %elements) {
			for (keys %{$elements{$s}}) {
				if (/[[:upper:]]/) {
					${$elements{$s}}{lc $_} +=
						delete ${$elements{$s}}{$_};
				}
			}
		}
	}

	return \%elements;
}

1;
__END__

=head1 TO DO

=over 6

=item * Make it more efficient (use C for that)

=back

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
