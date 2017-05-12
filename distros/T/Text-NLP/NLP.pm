package Text::NLP;

$VERSION = '0.1';

use strict;


sub new
{
	my $class = shift;

	my $self = {
		_wordsObj	=> Text::NLP::Words->new,
	};
	bless $self, $class;

	return( $self );
};


sub addSeeding
{
	my $self = shift;
	my $args = shift;

	foreach ( keys %{$args} ) {
		$self->{_wordsObj}->addCategory( $_, $args->{$_} );
	};

	return;
};


sub process
{
	my $self = shift;
	my $string = lc(shift);

	# Clean the string
	$string =~ s/[,;:!\?\.\"\']{1,}//g;
	$string =~ s/\s+/ /g;

	my $words = $self->{_wordsObj}->translateString( $string );

	my $max = $self->_weightWords( $words );

	return( $max );
};


sub _weightWords
{
	my $self = shift;
	my $words = shift;

	my $weight = Text::NLP::Weight->new;

	foreach ( @{$words} ) {
		$weight->add( $_ );
	};

	my $max = $weight->getMax;

	return( $max );
};



package Text::NLP::Words;

use strict;


sub new
{
	my $class = shift;
	
	my $self = {
		_emph	=> {
			NEG	=> [ 'definately not', 'not' ],
			POS	=> [ 'definately' ],
		},
		_data	=> {},
	};
	bless $self, $class;

	return( $self );
};


sub addCategory 
{
	my $self = shift;
	my $cat = shift;
	my $words = shift;

	$self->{_data}->{$cat} = $words;

	return;
};


sub translateString
{
	my $self = shift;
	my $string = shift;

	my $neg = [];
	my $pos = [];
	my $words = [];

	study( $string );

	foreach ( @{$self->{_emph}->{NEG}} ) {
		if( $string =~ /$_/ ) {
			push @{$neg}, $_;
		};
	};

	foreach ( @{$self->{_emph}->{POS}} ) {
		if( $string =~ /$_/ ) {
			push @{$pos}, $_;
		};
	};


	foreach my $key ( keys %{$self->{_data}} ) {
ITERATION:
		foreach ( @{$self->{_data}->{$key}} ) {
			foreach my $bob ( @{$neg} ) {
				if( $string =~ /(^$bob $_ | $bob $_ | $bob $_$)/ ) {
					next ITERATION;
				};
			};
			foreach my $bob ( @{$pos} ) {
				if( $string =~ /(^$bob $_ | $bob $_ | $bob $_$)/ ) {
					push @{$words}, ( $key, $key );
					next ITERATION;
				};
			};
		
			my @temp = $string =~ /(^$_ | $_ | $_$)/g;
			foreach( @temp ) {
				push @{$words}, $key;
			};
		};
	};

	return( $words );
};



package Text::NLP::Weight;

use strict;

sub new 
{
	my $class = shift;

	my $self = {
		_words		=> {},
	};
	bless $self, $class;
	
	return( $self );
};

sub add
{
	my $self = shift;
	my $word = shift;

	if( defined($self->{_words}->{$word}) ) {
		$self->{_words}->{$word}++;
	}
	else {
		$self->{_words}->{$word} = 1;
	};

	return;
};


sub getMax 
{
	my $self = shift;
	
	my $max = [];
	my $updated = 1;

use Data::Dumper; print Dumper( $self->{_words} );

	foreach ( keys %{$self->{_words}} ) {
		push @{$max}, $_;
	};

	while( $updated ) {
		$updated = 0;

		for ( my $count = 0; $count < (@{$max} - 1); $count++ ) {
			my $priority_a = $self->{_words}->{$max->[$count]};
			my $priority_b = $self->{_words}->{$max->[$count+1]};

			if( $priority_a < $priority_b ) {
				my $temp = $max->[$count];
				$max->[$count] = $max->[$count+1];
				$max->[$count+1] = $temp;
				$updated = 1;
			};
		};
	};

	return( $max );
};

1;

=pod

=head1 NAME

Text::NLP - Perl module for Natural Language Processing
    
=head1 DESCRIPTION

Initial release, documentation and updates will follow.

=head1 SYNOPSIS

  use Text::NLP;
    
  my $talker = Text::NLP->new;

  # setup the seeding
  my $args = {
    HELLO   => [ 'hi', 'hello', 'good day' ],
    BYE     => [ 'bye', 'goodbye', 'laters' ],
  }

  $talker->addSeeding( $args );

  my $string = 'Should I say goodbye or hello? I\'ll just say good day';

  # process the string
  my $words = $talker->process( $string );
    
  # do some post-processing

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 AUTHOR

Alistair Francis, <cpan@alizta.com>

=cut

