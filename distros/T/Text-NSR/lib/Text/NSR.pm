package Text::NSR;

use warnings;
use strict;

use Path::Tiny;

our $VERSION   = '0.10';


sub new {
	my ($class, %arg) = @_;
	my $self = bless {
		filepath	=> $arg{filepath},
		fieldspec	=> $arg{fieldspec},
	}, $class;

	die "Text::NSR: no filepath given!" if !$self->{filepath};

	die "Text::NSR: filepath '". $self->{filepath} ."' not found!" if !-f $self->{filepath};

	return $self;
}

sub read {
	my $self = shift;

	my $lines = path($self->{filepath})->slurp_utf8;

	$lines =~ s/^\n+//; # delete leading newlines
	$lines =~ s/\n+$//; # delete trailing newlines

	my @arr = split(/\n\n/, $lines);

	my @records;
	# each "stanza"
	for my $elem (@arr){
		my $cnt =()= $elem =~ /\n/g; # zero based; count newlines to see how many lines are in one "stanza"

		my @fieldvalues = split(/\n/, $elem);

		if($self->{fieldspec}){
			# my %hash = map { $self->{fieldspec}->[$_] => $fieldvalues[$_] } (0 .. $#{$self->{fieldspec}});
			my %hash;
			for(0 .. $cnt){
				$hash{ $self->{fieldspec}->[$_] || $_ } = $fieldvalues[$_];
			}
			push(@records, \%hash);
		}else{
			push(@records, \@fieldvalues);
		}
	}

	$self->{records} = \@records;

	return \@records;
}


=pod

=head1 NAME

Text::NSR - Read "newline separated records" (NSR) structured text files

=head1 SYNOPSIS

	use Text::NSR;
	my $nsr = Text::NSR->new(
		filepath  => 't/test.nsr',
		fieldspec => ['f1','f2','f3','f4']
	);
	my $records = $nsr->read();

=head1 DESCRIPTION

There are a number of data exchange formats out there that strive to be structured in a way that is both,
easily and intuitively editable by humans and reliably parseable by machines. This module here adds yet another
structured file format, a file composed of "newline separated records".

The guiding principal here is that each line in a file represents a value. And that multiple lines form a
single record. Multiple records then are separated by one empty line. Exactly one empty line. A second empty
line will be interpreted as the first line of the next record. The only exception to this rule are leading or
trailing newlines on the "whole file" scope. They are considered "padding" and are dropped.

NSR files can be used to hold very simple human editable databases.

This module here helps with reading and parsing of such files.

=head1 FUNCTIONS

=head2 new()

filepath is mandatory. fieldspec is optional, an array of hash key names.

=head2 read()

Returns an array of arrayrefs when no fieldspec was given upon construction. Each element of the referenced array
will hold a record's lines in the order they were found in the file.

When a fieldspec was provided to new(), read() will try to coerce record lines into a hash according to fieldspec.
In case a record does not follow fieldspec and has more lines than expected, read() will add those lines with their
zero-based line number as key to the resulting hashref. Fewer lines than in fieldspec will not create empty elements.

=head1 EXPORT

Nothing by default.

=head1 CAVEATS

Currently files are slurped completely and not streamed or read incrementally, so be careful with really large files.

As stated above, trailing newlines on the "whole file" scope are considered "padding" and are dropped. Having a fieldspec
should probably allow to have an empty last line as part of a record but the current implementation would drop an empty
last record line.

=head1 SEE ALSO

Any other file format that contains well readable (mostly) textual data in a structured manner. This here shares the
L<"stanza"|StanzaFile::Grub> idea with, for example, L<Config::INI>, and the readable approach with L<YAML> and the line
by line aspect with L<Text::FrontMatter::YAML>. Give a shout if you can name another one.

=head1 AUTHOR

Clipland GmbH L<https://www.clipland.com/>

This module was developed for L<live streaming|https://instream.de/> infotainment website L<InStream.de|https://instream.de/>.

=head1 COPYRIGHT & LICENSE

Copyright 2022 Clipland GmbH. All rights reserved.

This library is free software, dual-licensed under L<GPLv3|http://www.gnu.org/licenses/gpl>/L<AL2|http://opensource.org/licenses/Artistic-2.0>.
You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
