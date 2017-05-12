package Text::CSV::Simple::__::Base;

use Class::Trigger;

__PACKAGE__->add_trigger(on_failure => sub { 
	my ($self, $csv) = @_;
	warn "Failed on " . $csv->error_input . "\n";
});

package Text::CSV::Simple;

use base 'Text::CSV::Simple::__::Base';

$VERSION = '1.00';

use strict;

use Text::CSV_XS;
use File::Slurp ();

=head1 NAME

Text::CSV::Simple - Simpler parsing of CSV files

=head1 SYNOPSIS

	my $parser = Text::CSV::Simple->new;
	my @data = $parser->read_file($datafile);
	print @$_ foreach @data;

	# Only want certain fields?
	my $parser = Text::CSV::Simple->new;
	$parser->want_fields(1, 2, 4, 8);
	my @data = $parser->read_file($datafile);

	# Map the fields to a hash?
	my $parser = Text::CSV::Simple->new;
	$parser->field_map(qw/id name null town/);
	my @data = $parser->read_file($datafile);

=head1 DESCRIPTION

Parsing CSV files is nasty. It seems so simple, but it usually isn't.
Thankfully Text::CSV_XS takes care of most of that nastiness for us.

Like many modules which have to deal with all manner of nastiness and
edge cases, however, it can be clumsy to work with in the simple case.

Thus this module.

We simply provide a little wrapper around Text::CSV_XS to streamline the
common case scenario. (Or at least B<my> common case scenario; feel free
to write your own wrapper if this one doesn't do what you want).

=head1 METHODS

=head2 new

	my $parser = Text::CSV::Simple->new(\%options);

Construct a new parser. This takes all the same options as Text::CSV_XS.

=head2 read_file

	my @data = $parser->read_file($filename);

Read the data in the given file, parse it, and return it as a list of
data.

Each entry in the returned list will be a listref of parsed CSV data.

=head2 want_fields

	$parser->want_fields(1, 2, 4, 8);

If you only want to extract certain fields from the CSV, you can set up
the list of fields you want, and, hey presto, those are the only ones
that will be returned in each listref. The fields, as with Perl arrays,
are zero based (i.e. the above example returns the second, third, fifth
and ninth entries for each line)

=head2 field_map

	$parser->field_map(qw/id name null town null postcode/);

Rather than getting back a listref for each entry in your CSV file, you
often want a hash of data with meaningful names. If you set up a field_map
giving the name you'd like for each field, then we do the right thing
for you! Fields named 'null' vanish into the ether.

=head1 TRIGGER POINTS

To enable you to make this module do things that I haven't dreamed off
(without you having to bother me with requests to extend the
functionality), we use Class::Trigger to provide a variety of points at
which you can hook in and do what you need. In general these should be
attached to the $parser object you've already created, although you
could also subclass this module and set these up as class data.

Each time we call a trigger we wrap it in an eval block. If the eval
block catches an error we simply call 'next' on the loop. These can
therefore be used for short-circuiting.on certain conditions.

=head2 before_parse

  $parser->add_trigger(before_parse => sub {
    my ($self, $line) = @_;
    die unless $line =~ /wanted/i;
  });

Before we call Text::CSV_XS 'parse' on each line of input text, we call
the before_parse trigger with that line of text.

=head2 after_parse

  $parser->add_trigger(after_parse => sub {
    my ($self, $data) = @_;
    die unless $wanted{$data->[0]};
  });

After we sucessfully call Text::CSV_XS 'parse' on each line of input text,
we call the after_parse trigger with a list ref of the values 

=head2 error

Currenly, for each line that we can't parse, we call the 'failure'
trigger (with the Text::CSV_XS parser object), which emits a warning
and moves on. This happens in an invisible superclass, so you can supply
your own behaviour here:

	$parser->add_trigger(on_failure => sub { 
		my ($self, $csv) = @_;
		warn "Failed on " . $csv->error_input . "\n";
	});

=cut

sub new {
	my $class = shift;
	return bless { _parser => Text::CSV_XS->new(@_), } => $class;
}

sub _parser { shift->{_parser} }

sub _file {
	my $self = shift;
	$self->{_file} = shift if @_;
	return $self->{_file};
}

sub _contents {
	my $self  = shift;
	my @lines = File::Slurp::read_file($self->_file)
		or die "Can't read " . $self->_file;
	return @lines;
}

sub want_fields {
	my $self = shift;
	if (@_) {
		$self->{_wanted} = [@_];
	}
	return @{ $self->{_wanted} || [] };
}

sub field_map {
	my $self = shift;
	if (@_) {
		$self->{_map} = [@_];
	}
	return @{ $self->{_map} || [] };
}

sub read_file {
	my ($self, $file) = @_;
	$self->_file($file);
	my @lines = $self->_contents;
	my @return;
	my $csv = $self->_parser;
	foreach my $line (@lines) {
		eval { $self->call_trigger(before_parse => $line) };
		next if $@;
		next unless $line;
		unless ($csv->parse($line)) {
			$self->call_trigger(on_failure => $csv);
			next;
		}
		my @fields = $csv->fields;
		eval { $self->call_trigger(after_parse => \@fields) };
		next if $@;
		if (my @wanted = $self->want_fields) {
			@fields = @fields[ $self->want_fields ];
		}
		my $addition = [ @fields ];
		if (my @map = $self->field_map) {
			my $hash = { map { $_ => shift @fields } @map };
			delete $hash->{null};
			$addition = $hash;
		} 
		eval { $self->call_trigger(after_processing => $addition) };
		next if $@;
		push @return, $addition;
	}
	return @return;
}

=head1 AUTHOR

Tony Bowden

=head1 BUGS

This doesn't cope with multi-line fields. Technically the CSV format
allows this, but this is meant to be a ::Simple module, and coping with
that is currently outside the cope of this module.

=head1 SEE ALSO

Text::CSV_XS

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Text-CSV-Simple@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

