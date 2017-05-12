package Pee::Tokenizer;

use strict;
use vars qw($VERSION);

$VERSION = "2.02";

my @delimiters = ('<?', '?>');

# CONSTRUCTOR
sub new {
	my $self = {};
	$self->{BUFFER} = $_[1];	# get the buffer
	$self->{CURSOR} = 0;
	bless($self);
	return $self;
}

# getNextToken ($token)
# $token - reference to a variable into which we store the next token value
# returns 1 or 0 depending on whether this token is special, or -1 if no more
# token is to be read
sub getNextToken {
	my $self = $_[0];
	my $ret = $_[1];

	# first check if we've reached the end of the buffer
#print STDERR "1) File length = ".length($self->{BUFFER})."\n";
#print STDERR "2) Cursor = $self->{CURSOR}\n";
	if ($self->{CURSOR} == length($self->{BUFFER}) - 1 ) {
		$$ret = '';
		return -1;
	}

	# read until we find a special delimiter
#print STDERR "Looking for index in \"$self->{BUFFER}\", delimiter=$delimiters[0], cursor = $self->{CURSOR}";
#print STDERR "Cursor = $self->{CURSOR}\n";

	my $pos = index ($self->{BUFFER}, $delimiters[0], $self->{CURSOR});
#print STDERR "Found opening at $pos\n";

	if ($pos == -1) {
		# return the rest of the string as normal
		$$ret = substr ($self->{BUFFER}, $self->{CURSOR});
		$self->{CURSOR} = length($self->{BUFFER}) - 1;

#print STDERR "Returning normal block:\n$$ret\n__\n";
		return 0;
	}
	elsif ($pos > $self->{CURSOR}) {
		# then we'll read until $pos and return it, and say it's normal
		$$ret = substr ($self->{BUFFER}, $self->{CURSOR}, $pos - $self->{CURSOR});
		$self->{CURSOR} = $pos; # store cursor
#print STDERR "Returning normal block:\n$$ret\n__\n";
		return 0;
	}
	else {
		# we're right at the beginning of a special block, search til the end
		my $end = index ($self->{BUFFER}, $delimiters[1], $pos);
#print STDERR "Found closing at $end\n";

		if ($end == -1) {
#print STDERR "Compilation error: CANNOT find closing!!!\n";
			# Can't find closing delim, so return the rest as a special block
			$$ret = substr ($self->{BUFFER}, $self->{CURSOR});
			$self->{CURSOR} = length($self->{BUFFER}) - 1;

			return 1;
		}
		$$ret = substr ($self->{BUFFER}, $pos, ($end - $pos + length($delimiters[1])));
		$self->{CURSOR} = $end + length($delimiters[1]);
#print STDERR "Returning special block:\n$$ret\n__\n";
		return 1;
	}
}

1;
