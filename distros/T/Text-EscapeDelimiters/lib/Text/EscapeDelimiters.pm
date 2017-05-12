###############################################################################
# Purpose : Escape delimiter characters within strings
# Author  : John Alden
# Created : Jan 2005
# CVS     : $Id: EscapeDelimiters.pm,v 1.4 2005/03/20 23:10:53 aldenj20 Exp $
###############################################################################

package Text::EscapeDelimiters;

use strict;
use Carp;
use vars qw($VERSION);
$VERSION = sprintf "%d.%03d", (q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/);

sub new {
	my ($class, $options) = @_;
	my $self = {
		'EscapeSequence' => exists $options->{EscapeSequence}? $options->{EscapeSequence} : "\\"
	};
	return bless($self, $class);
}

sub escape {
	my($self, $string, $delim) = @_;
	my $eseq = $self->{EscapeSequence};
	return $string unless($eseq); #no-op
	
	unless(ref $delim eq 'ARRAY') {
		if(!defined $delim) {$delim = []}
		elsif(ref $delim) {croak("Delimiter should be scalar or an arrayref")}
		else {$delim = [$delim]}
	}
	
	foreach my $char($eseq, @$delim) {
		next unless(defined $char && length($char));
		$string =~ s/\Q$char\E/$eseq$char/sg;	
	}
	
	return $string;
}

sub regex {
	my($self, $delim) = @_;

	TRACE($delim);

	unless(ref $delim eq 'ARRAY') {
		if(!defined $delim) {$delim = []}
		elsif(ref $delim) {croak("Delimiter should be scalar or an arrayref")}
		else {$delim = [$delim]}
	}

	my $regexp = join("|", map {'(?:' . quotemeta($_) . ')'} @$delim);
	$regexp = '(?:' . $regexp . ')' if(scalar @$delim > 1);
	if($self->{EscapeSequence}) { 
		$regexp = '(?<!'.quotemeta($self->{EscapeSequence}).')'.$regexp; #Use negative look behind
	} 

	TRACE("regex = ".$regexp);	
	return qr/$regexp/;	
}

sub split {
	my($self, $string, $delim) = @_;
	my $regexp = $self->regex($delim);
	TRACE("regex = ".$regexp);	
	return split($regexp, $string);
}

sub unescape {
	my($self, $string) = @_;
	my $eseq = $self->{EscapeSequence};
	return $string unless($eseq); #no-op
	
	#Remove escape characters apart from double-escapes
	$string =~ s/\Q$eseq\E(?!\Q$eseq\E)//gs;

	#Fold double-escapes down to single escapes
	$string =~ s/\Q$eseq$eseq\E/$eseq/gs;

	return $string;
}

#Tracing stubs compatible with Log::Trace
sub TRACE{}
sub DUMP{}

1;

=head1 NAME

Text::EscapeDelimiters - escape delimiter characters within strings

=head1 SYNOPSIS

	my $obj = new Text::EscapeDelimiters();

	#Convert a list of lists into a string using tab and newline as field and record delimiters
	#Escape any delimiters occurring in the strings first
	my $stringified = join("\n", map {
		join("\t", map {$obj->escape($_, ["\t", "\n"])} @$_)
	} @records);

	#Convert the string back, respecting the escapes
	@records = map {
		[ map {$obj->unescape($_)} $obj->split($_, "\t") ]
	} $obj->split($stringified, "\n");

	#Pick off the first 5 records
	my $delim_regex = $obj->regex("\n");
	my @first_five;
	for(1..5) {
		$stringified =~ /(.*?)$delim_regex/g;
		push @first_five, [ map {$obj->unescape($_)} $obj->split($1, "\t") ];
	}

=head1 DESCRIPTION

When joining strings with a delimiter (aka separator), you need to worry about escaping occurences of that delimiter in the values you are joining.
When splitting on the delimiter, you need to respect the escape sequences so you don't split on escaped delimiters.

This module provides a solution to that problem allowing you to escape values before you join,
split the values whilst respecting escaped delimiters, and finally unescape the data.

Escaping is achieved by placing an escape sequence in front of delimiter characters.
The default escape sequence is a backslash but you can change this.

=over 4

=item $obj = new Text::EscapeDelimiters(\%options)

Valid options are:

=over 4

=item EscapeSequence

One or more characters that will be used as an escape sequence in front of delimiter characters.
If not supplied, defaults to a backslash.  
An undef or empty string of this key can be used to specify a null escape sequence.

=back

=item $escaped = $obj->escape($string, $delimiters)

Escapes one or more delimiter characters in a string ($delimiters can be a scalar or an an arrayref)

=item @list = $obj->split($escaped_and_joined, $delimiter)

Splits an escaped string on a delimiter (respecting escaped delimiters)

=item $regex = $obj->regex($delimiters)

Creates a regular expression that will match delimiters (but not escaped delimiters).  $delimiters can be a scalar or an an arrayref.

=item $string = $obj->unescape($escaped)

Inverse of escape()

=back

=head1 VERSION

See $Text::EscapeDelimiters::VERSION.
Last edit: $Revision: 1.4 $ on $Date: 2005/03/20 23:10:53 $

=head1 BUGS

None known.  This module has not yet been used heavily in production so it's not impossible a bug may have slipped through the unit tests.
Bug reports are welcome, particularly with patches & test cases.

=head1 AUTHOR

John Alden <johna@cpan.org>

=head1 SEE ALSO

=over 4

=item URI::Escape

Escapes/unescapes strings using URI encoding

=item Tie::Scalar::Escaped

Similar to URI::Escape, but provides a C<tie> interface.

=item String::Escape

Routines for backslash escaping strings

=item Regex::Common::delimited

Provides regexes for extracting values between PAIRED delimiters (e.g. quotes).

=item Text::DelimMatch

Module for extracting values between PAIRED delimiters (e.g. quotes).
Handles escaped delimiter characters etc.

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by John Alden

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
