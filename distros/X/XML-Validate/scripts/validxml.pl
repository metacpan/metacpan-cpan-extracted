#!/usr/local/bin/perl -w

use strict;
use XML::Validate qw();
use Getopt::Long qw();
require Log::Trace;

use vars qw($VERSION);
($VERSION) = ('$Revision: 1.10 $' =~ /([\d\.]+)/ );

my $assert_invalid = 0;
my $help = 0;
my $tracing = 0;
my $deep_tracing = 0;
my $backend = 'BestAvailable';
Getopt::Long::GetOptions(
				't' => \$tracing,
				'T' => \$deep_tracing,
				'assert-invalid' => \$assert_invalid,
				'backend:s' => \$backend,
				'help' => \$help
			);

import Log::Trace 'print' if $tracing;
import Log::Trace 'print' => { Deep => 1 } if $deep_tracing;

my @files;
while (my $mask = shift) {
	push @files, glob($mask);
}
if ($help || @files < 1) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-verbose => 2);
}

my $validator = new XML::Validate(Type => $backend);

my %errors;

for my $file (@files) {
	open(FH,$file) || die "Unable to open file handle FH for file '$file': $!\n";
	local $/ = undef;
	my $xml = <FH>;
	close(FH) || warn "Unable to close file handle FH for file '$file': $!\n";

	if (my $tree = $validator->validate($xml)) {
		$errors{$file} = '';
	} else {
		if ($validator->last_error()->{message}) {
			$errors{$file} = sprintf("%s at %d:%d",@{$validator->last_error()}{'message','line','column'});
		} else{
			$errors{$file} = 'Unknown error';
		}
		if (length($errors{$file}) > 0) {
			$errors{$file} =~ s/(\n|\r|\cM)/  /gi;
		}
	}
}

print "1..".@files."\n";
for my $file (@files) {
	if ($errors{$file}) {
		print(($assert_invalid ? '' : 'not ').
				"ok - $file - $errors{$file}\n");
	} else {
		print(($assert_invalid ? 'not ' : '').
				"ok - $file\n");
	}
}


=pod

=head1 NAME

validxml - Command-line driver for XML::Validate.

=head1 SYNOPSIS

    validxml *.xml
    validxml --assert-invalid *.xml

=head1 DESCRIPTION

Command-line driver for XML::Validate using the 'BestAvailable' processing
type.

=head2 Commandline Options

=over 4

=item --assert-invalid

Swap the ok/not ok so invalid things are OK - still output the validation
error) - this is useful for schema "unit tests".

=item --backend [validator type]

Specify an C<XML::Validate> backend to use (e.g LibXML, Xerces). Defaults to
I<BestAvailable>.

=back

=head2 Output

Output is Test::Harness compatible.

    1..scalar @files
    ok - filename/not ok - filename - validation error

=head1 VERSION

$Revision: 1.10 $

$Id: validxml.pl,v 1.10 2006/04/07 09:43:10 johnl Exp $

=head1 AUTHOR

Nicola Worthington

$Author: johnl $

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut

__END__

