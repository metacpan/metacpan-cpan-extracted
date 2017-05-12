#!/usr/bin/perl

=head1 NAME

wl-scanner.pl - Generate Perl bindings for Wayland protocol

=head1 SYNOPSIS

B<wl-draw.pl>
[<protocol.xml>]
[<output_dir>/]

=head1 DESCRIPTION

This tool processes Wayland protocol specification and generates L<WL::Base>
subclasses with wrappers for requests, event processing and constants for enums.

Output is to STDOUT or specified directory.

=cut

use strict;
use warnings;

use XML::Smart;

our $package_name;
our $output_file;

# Output routines
sub op
{
	if ($output_file) {
		print $output_file @_;
	} else {
		print @_;
	}
}

sub opf
{
	op sprintf shift, @_;
}

# Information for type marshalling/unmarshalling:
# [ <routine returning pack string and code for fetching the value from
#   argument stack>, <routine returning pack string and code that obtains
#   the actual value given unpacked data on an argument stack >], ...
my %typemap = (
	int	=> [
		sub { 'l' => 'shift' },
		sub { 'l' => 'shift' }],
	uint	=> [
		sub { 'L' => 'shift' },
		sub { 'L' => 'shift' }],
	fixed	=> [
		sub { 'l' => '$self->nv2fixed ($_)' },
		sub { 'L' => '$self->fixed2nv (shift)' }],
	string	=> [
		sub { 'L/ax!4' => 'shift."\x00"' },
		sub { 'L/ax!4' => '[shift =~ /(.*)./]->[0]' }],
	object	=> [
		sub { 'L' => 'shift->{id}' },
		sub { 'L' => 'new WL::'.(shift->{interface} || 'Base').' ($self->{conn}, shift)' },
	],
	new_id	=> [
		sub { my $interface = shift->{interface}; $interface
			? ('L' => '($retval = new WL::'.$interface.' ($self->{conn}))->{id}')
			: ('L/ax!4 L L' => '$_[0]."\x00", delete $_[1], ($retval = ("WL::".shift)->new ($self->{conn}))->{id}') },
		sub { 'L' => 'new WL::'.shift->{interface}.' ($self->{conn})' }],
	array	=> [
		sub { 'L/ax!4' => 'shift' },
		sub { 'L/ax!4' => 'shift' }],
	fd	=> [
		sub { '' => '($file = shift, ())' },
		sub { '' => 'shift' }]
);

sub process_request
{
	my $request = shift;

	op "sub $request->{name}\n";
	op "{\n";
	op "\tmy \$self = shift;\n";
	op "\tmy \$file;\n";
	op "\tmy \$retval;\n";
	op "\n";

	my @pack;
	my @map;
	foreach my $arg ($request->{arg}('@')) {
		my ($pack, $map) = $typemap{$arg->{type}}[0]->($arg);
		push @pack, $pack if $pack;
		push @map, $map;
	}
	my $pack = join ' ', @pack;
	my $map = join ",\n\t\t", @map;

	opf "\t\$self->call (REQUEST_%s, pack ('%s',\n\t\t%s), \$file);\n",
		uc ($request->{name}), $pack, $map;
	op "\n";

	op "\treturn \$retval;\n";
	op "}\n";
	op "\n";
}

sub process_event
{
	my $event = shift;

	my @pack;
	my @map;
	foreach my $arg ($event->{arg}('@')) {
		my ($pack, $map) = $typemap{$arg->{type}}[1]->($arg);
		push @pack, $pack if $pack;
		push @map, $map;
	}
	my $pack = join ' ', @pack;
	my $map = join ",\n\t\t\t", @map;

	op "\t\t\@_ = unpack ('$pack', shift);\n" if $pack;
	op "\t\treturn \$self->$event->{name} ($map);\n";
}

sub process_enum
{
	my $enum = shift;

	foreach my $entry ($enum->{entry}('@')) {
		opf "use constant %s => %s;\n",
			uc ($enum->{name}.'_'.$entry->{name}),
			$entry->{value};
	}
}

sub process_interface
{
	my $interface = shift;
	my $opcode;

	opf "package WL::$interface->{name};\n";
	op "\n";
	op "our \@ISA = qw/WL::Base/;\n";
	op "our \$VERSION = $interface->{version};\n";
	op "our \$INTERFACE = '$interface->{name}';\n";
	op "\n";

	my @requests = $interface->{request}('@');
	if (@requests) {
		$opcode = 0;
		op "# Requests\n";
		foreach my $request (@requests) {
			opf "use constant REQUEST_%s => %d;\n",
				uc ($request->{name}), $opcode++;
		}
		op "\n";
		foreach my $request (@requests) {
			process_request ($request);
		}
	}

	my @events = $interface->{event}('@');
	if (@events) {
		$opcode = 0;
		op "# Events\n";
		foreach my $event (@events) {
			opf "use constant EVENT_%s => %d;\n",
				uc ($event->{name}), $opcode++;
		}

		op "\n";
		op "sub callback\n";
		op "{\n";
		op "\tmy \$self = shift;\n";
		op "\tmy \$opcode = shift;\n";
		op "\n";

		op "\t";
		foreach my $event (@events) {
			opf "if (\$opcode == EVENT_%s) {\n", uc ($event->{name});
			process_event ($event);
			op "\t} els";
		}
		op "e {\n";
		op "\t\tdie 'Bad opcode';\n";
		op "\t}\n";

		op "}\n";
		op "\n";
	}

	my @enums = $interface->{enum}('@');
	if (@enums) {
		op "# Enums\n";
		foreach my $enum (@enums) {
			process_enum ($enum);
		}
		op "\n";
	}
}

sub process_protocol
{
	my $protocol = shift;

	op "package $package_name;\n";
	op "\n";
	op "our \$VERSION = 0.92;\n";
	op "\n";

	foreach my $interface ($protocol->{interface}('@')) {
		process_interface ($interface);
	}
}

my $file = shift @ARGV;
my $dir = shift @ARGV || '.';
open (my $source, '<', $file || 'wayland.xml')
	or die "Cannot open input file: $!";
my $spec = new XML::Smart ($source);
my $protocol_name = $spec->{protocol}{name};
if ($protocol_name eq 'wayland') {
	$package_name = 'WL';
} else {
	$package_name = 'WL::'.$spec->{protocol}{name};
}

if ($dir) {
	my $fname = "$dir/$package_name.pm";
	$fname =~ s/::/\//g;
	open ($output_file, '>', $fname)
		or die "$fname: $!";
}

op "# DO NOT EDIT, PRETTY PLEASE!\n";
op "# This file is automatically generated by wl-scanner.pl\n";
op "#\n";
op "\n";
op "use strict;\n";
op "use warnings;\n";
op "use utf8;\n";
op "\n";
op "=encoding utf8\n";
op "=cut\n";

# Trick POD parser so that it does not consider this to be a documentation for
# the tool itself.
my $P = '=';

op <<POD;

${P}head1 NAME

$package_name - Perl binding for $protocol_name protocol

${P}head1 SYNOPSIS

  use $package_name;

${P}head1 DESCRIPTION

B<$package_name> is a package generated from Wayland protocol definition
using L<wl-scanner.pl>. It implements L<WL::Base> subclasses with wrappers
for requests, event processing and constants for enums.

It is not indended to be used directly. Instead, see L<WL::Connection> to see
how to obtain the object instances.

To see how to attach event callbacks and issue requests, please refer to
L<WL::Base> base class.

Until proper documentation is finished, please refer to documentation of C
bindings of the generated code (it is intended to be readable) to see what
arguments to give to requests and expect from events.

Please consider this an alpha quality code, whose API can change at any time,
until we reach version 1.0.

${P}cut

POD

process_protocol ($spec->{protocol});

op <<POD;

${P}head1 BUGS

The interface documentation for the bindings is lacking.

Only client part implemented, not server.

${P}head1 SEE ALSO

${P}over

${P}item *

L<http://wayland.freedesktop.org/> -- Wayland project web site

${P}item *

L<wl-draw.pl> -- Example Wayland client

${P}item *

L<wl-scanner.pl> -- Tool that generated this module

${P}item *

L<WL::Base> -- Base class for Wayland objects

${P}item *

L<WL::Connection> -- Estabilish a Wayland connection

${P}back

${P}head1 COPYRIGHT

Copyright 2013, 2014 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
POD

# XML::Smart recodes this to ISO-8859 for some weird reason,
# therefore we won't use $spec->{protocol}{copyright} here.
seek $source, 0, 0;
my @copyright = map { /<copyright>/ .. /<\/copyright>/ ? $_ : () } <$source>;
shift @copyright;
pop @copyright;
map { s/\s*(.*\S?)\s*/  $1\n/ } @copyright;

if (@copyright) {
	op "\nCopyright notice from the protocol definition file:\n\n";
	op @copyright;
}

op <<POD;

${P}head1 AUTHORS

Lubomir Rintel C<lkundrak\@v3.sk>

${P}cut

POD

=head1 SEE ALSO

=over

=item *

L<http://wayland.freedesktop.org/> -- Wayland project web site

=item *

L<WL> -- Perl Wayland protocol binding

=back

=head1 COPYRIGHT

Copyright 2013, 2014 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel C<lkundrak@v3.sk>

=cut
