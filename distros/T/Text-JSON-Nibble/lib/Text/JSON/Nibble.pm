package Text::JSON::Nibble;

=encoding utf8

=cut 

use 5.006;
use strict;
use warnings;

use Data::Dumper;

=head1 NAME

Text::JSON::Nibble - Nibble complete JSON objects from buffers

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 WARNING

This module should be used with caution, it will not handle 'badly formed' json well, its entire purpose was because I was experiencing 
segfaults with Cpanel::XS's decode_prefix when dealing with a streaming socket buffer.

=head1 DESCRIPTION

This module is a 'character' crawling JSON extractor for plain TEXT, usable in both a 'streaming' or 'block' method, for when you need something that is not XS.

It is particularly handy for when you want to deal with JSON without decoding it.

=head1 SYNOPSIS 

	use Text::JSON::Nibble;

	my $json = '{"lol":{"a":[1,2,3],"b":"lol"}}';
	my $item = Text::JSON::Nibble->new();

	my @results = @{ $item->digest($json) };

=head1 EXAMPLES

=head2 Example1 (Basic usage)

	use Text::JSON::Nibble;

	my $json = '{"lol":{"a":[1,2,3],"b":"lol"}}{"lol":{"a":[1,2,3],"b":"lol"}}';
	my $item = Text::JSON::Nibble->new();

	foreach my $jsonBlock ( @{ $item->digest($json) } ) {
		print "Found: $jsonBlock\n";
	}

	# Will display the following:
	# Found: {"lol":{"a":[1,2,3],"b":"lol"}}
	# Found: {"lol":{"a":[1,2,3],"b":"lol"}}
	

=head2 Example2 (Basic usage - mangled JSON)

	use Text::JSON::Nibble;

	my $json = '\cxa4GL<A{"lol":{"a":[1,2,3],"b":"lol"}}He Random Stuf${"lol":{"a":[1,2,3],"b":"lol"}}\cxa4GL<A';
	my $item = Text::JSON::Nibble->new();

	foreach my $jsonBlock ( @{ $item->digest($json) } ) {
		print "Found: $jsonBlock\n";
	}

	# Will display the following:
	# Found: {"lol":{"a":[1,2,3],"b":"lol"}}
	# Found: {"lol":{"a":[1,2,3],"b":"lol"}}

=head2 Example3 (Streaming usage for POE and others)

	use Text::JSON::Nibble;
	
	my @jsonStream = qw( {"test":1} {"moreTest":2} {"part ial":3} );
	my $item = Text::JSON::Nibble->new();
	
	$item->process( shift @jsonStream );

	while( $item->stack ) {
		my $jsonBlock = $item->pull;
		print "Found $jsonBlock\n";

		while ( my $newJSON = shift @jsonStream ) {
			$item->process($newJSON);
		}
	}

=head1 Generic callers

=head2 new

Generate a new JSON Nibble object

=cut

sub new {
	my $class = shift;

	# Some private stuff for ourself
	my $self = { 
		jsonqueue => [],
		buffer => "",
		iChar => [],
	};
	
	# We are interested in characters of this code
	$self->{iChar}->[91] = 1;
	$self->{iChar}->[93] = 1;
	$self->{iChar}->[123] = 1;
	$self->{iChar}->[125] = 1;

	# Go with god my son
	bless $self, $class;
	return $self;
}

=head1 Block functions

=head2 digest

Digest the text that is fed in and attempt to return a complete an array of JSON object from it, returns either a blank array or an array of text-encoded-json.

Note you can call and use this at any time, even if you are using streaming functionality.

=cut

sub digest {
	my $self = shift;
	my $data = shift;

	# A place for our return
	my $return = [];
	
	# If we got passed a blank data scalar just return failure
	return $return if (!$data);

	# Save the current state for if we are dealing with a stream elsewhere.
	my $stateBackup = $self->{state} if ($self->{state});
	
	# Start with a fresh state
	$self->reset;
	
	# Load the digest data into the processor
	$self->process($data);
	
	# Generate our results
	while ($self->stack) { push @{$return},$self->pull }

	# Restore the previous state
	$self->{state} = $stateBackup if ($stateBackup);

	# Process the data and return the result
	return $return;
}

=head1 Streaming functions

=head2 process

Load data into the buffer for json extraction, can be called at any point.

This function will return the buffer length remaining after extraction has been attempted.

This function takes 1 optional argument, text to be added to the buffer.

=cut

sub process {
	my $self = shift;
	my $data = shift;

	# Add any data present to the buffer, elsewhere return the length of what we have.
	if ($data) { $self->{buffer} .= $data }
	else { return length($self->{buffer}) }
	
	# If we have no buffer return 0.
	if (!$self->{buffer}) { return 0 }
	
	# Load our state or establish a new one
	my $state;
	if ( $self->{state} ) {
		$state = $self->{state};
	} else {
		$state = {
			'typeAOpen' => 0,
			'typeBOpen' => 0,
			'arrayPlace' => 0,
			'prevChar' => 32
		};
	}
	
	# Extract the new information into an array split by char
	my @jsonText = split(//,$data);
	
	# Where to shorten the buffer to if we make extractions
	my $breakPoint;

	# Loop over the text looking for json objects
	foreach my $chr ( @jsonText ) {
		# Find the code for the current character
		my $charCode = ord($chr);

		# Check if this character is an escape \, if not check if its [ { } or ]
		if ( $state->{prevChar} != 92 && $self->{iChar}->[$charCode] ) {
			# Handle { } type brackets
			if ( $charCode == 123 )  { $state->{typeAOpen}++ }
			elsif ( $charCode == 125 ) { $state->{typeAOpen}-- }

			# Handle [ ] type brackets
			elsif ( $charCode == 91 ) { $state->{typeBOpen}++ }
			elsif ( $charCode == 93 ) { $state->{typeBOpen}-- }
			
			# Mark we have found something to start with
			if (!defined $state->{arrayStart}) { $state->{arrayStart} = $state->{arrayPlace} }
		}

		# If we have a complete object then leave
		if ( defined $state->{arrayStart} && !$state->{typeAOpen} && !$state->{typeBOpen} ) { 
			# Ok we had a JSON object fully open and closed.
			# push it into a return
			push @{$self->{jsonqueue}},substr($self->{buffer},$state->{arrayStart},$state->{arrayPlace}+1-$state->{arrayStart});
			delete $state->{arrayStart};
			$breakPoint = $state->{arrayPlace};
		}
		
		# Increment our arrayplace
		$state->{arrayPlace}++;
		
		# Remember the last char
		$state->{prevChar} = $charCode;
	}
	
	# Clean up the arrayPlace and save state
	if ($breakPoint) {
		$self->{buffer} = substr($self->{buffer},$breakPoint+1);
		$state->{arrayPlace} -= $breakPoint+1;
	}
	
	# Save our state
	$self->{state} = $state;
	
	# Return the remaining buffer size
	return length($self->{buffer});
}

=head2 stack 

Return the amount of succesfully extracted JSON blocks ready to be pulled.

If no JSON blocks are ready, returns 0.

This function takes no arguments.

=cut

sub stack {
	my $self = shift;
	return scalar( @{ $self->{jsonqueue} } );
}

=head2 pull

Pull an item from the stack, shortening the stack by 1.

This function will return "" if the stack is empty.

This function takes no arguments.

=cut

sub pull {
	my $self = shift;
	
	if ( $self->stack == 0 ) { return "" }
	return shift @{ $self->{jsonqueue} };
}

=head2 reset

Effectively flushs the objects buffers, giving you a clean object, this can be handy when you want to start processing from another stream.

This function returns nothing.

This function takes no arguments.

=cut 

sub reset {
	my $self = shift;
	
	$self->{jsonqueue} = [];
	$self->{buffer} => "";
}

=head1 AUTHOR

Paul G Webster, C<< <daemon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-json-nibble at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-JSON-Nibble>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::JSON::Nibble


You can also look for information at:

=over 4

=item * The author publishs this module to GitLab (Please report bugs here)

L<https://gitlab.com/paul-g-webster/PL-Text-JSON-Nibble>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-JSON-Nibble>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-JSON-Nibble>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-JSON-Nibble>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-JSON-Nibble/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Paul G Webster.

This program is released under the following license: BSD


=cut

1; # End of Text::JSON::Nibble
