
package Xmldoom::Schema::SAXHandler;
use base qw(XML::SAX::Base);

use strict;

our $DATABASE_NS      = "http://gna.org/projects/xmldoom/database";
our $DATABASE_PERL_NS = "http://gna.org/projects/xmldoom/database-perl";

sub _bool
{
	my $text = shift;
	if ( $text eq '1' or $text eq 'true' )
	{
		return 1;
	}
	elsif ( $text eq '0' or $text eq 'false' )
	{
		return 0;
	}

	return undef;
}

sub new
{
	my $class = shift;
	my $args = shift;

	my $parser;

	if ( ref($args) eq 'HASH' )
	{
		$parser = $args->{parser};
	}
	else
	{
		$parser = $args;
	}

	my $self = {
		parser        => $parser,
		table         => undef,
		foreign_table => undef,

		# state-ness
		column_args   => undef,
		in_option     => 0,
		buffer        => "",
	};

	bless  $self, $class;
	return $self;
}

sub start_document 
{
	my ($self, $doc) = @_;
}

sub end_document 
{
	my ($self, $doc) = @_;
}

sub start_element 
{
	my ($self, $el) = @_;

	# simple aliases
	my $name = $el->{'LocalName'};
	my $attrs = $el->{'Attributes'};

	if ( $name eq "database" )
	{
		my $args = { };

		if ( defined $attrs->{'{}name'} )
		{
			$args->{name} = $attrs->{'{}name'}->{Value};
		}
		if ( defined $attrs->{'{}defaultIdMethod'} )
		{
			$args->{defaultIdMethod} = $attrs->{'{}defaultIdMethod'}->{Value};
		}

		$self->{parser}->setup_database($args);
	}
	elsif ( $name eq "table" )
	{
		if ( defined $self->{table} )
		{
			die "Cannot nest table declarations";
		}

		my $args = {
			name => $attrs->{'{}name'}->{Value}
		};

		if ( defined $attrs->{'{}description'} )
		{
			$args->{description} = $attrs->{'{}description'}->{Value};
		}

		# store for column adding hot action
		$self->{table} = $self->{parser}->add_table($args);
	}
	elsif ( $name eq "column" )
	{
		if ( not defined $self->{table} )
		{
			die "Column must be defined inside of a <table/> tag.";
		}

		my $args = { };

		if ( defined $attrs->{'{}name'} )
		{
			$args->{name} = $attrs->{'{}name'}->{Value};
		}
		if ( defined $attrs->{'{}required'} )
		{
			$args->{required} = _bool( $attrs->{'{}required'}->{Value} );
		}
		if ( defined $attrs->{'{}primaryKey'} )
		{
			$args->{primary_key} = _bool( $attrs->{'{}primaryKey'}->{Value} );
		}
		if ( defined $attrs->{'{}auto_increment'} )
		{
			$args->{auto_increment} = _bool( $attrs->{'{}auto_increment'}->{Value} );
		}
		if ( defined $attrs->{"{$DATABASE_PERL_NS}idGenerator"} )
		{
			$args->{id_generator} = $attrs->{"{$DATABASE_PERL_NS}idGenerator"}->{Value};
		}
		if ( defined $attrs->{'{}type'} )
		{
			$args->{type} = $attrs->{'{}type'}->{Value};
		}
		if ( defined $attrs->{'{}size'} )
		{
			$args->{size} = $attrs->{'{}size'}->{Value};
		}
		if ( defined $attrs->{'{}description'} )
		{
			$args->{description} = $attrs->{'{}description'}->{Value};
		}
		if ( defined $attrs->{'{}default'} )
		{
			$args->{default} = $attrs->{'{}default'}->{Value};
		}
		if ( defined $attrs->{'{}timestamp'} )
		{
			$args->{timestamp} = $attrs->{'{}timestamp'}->{Value};
		}

		$self->{column_args} = $args;
	}
	elsif ( $name eq 'options' )
	{
		if ( not defined $self->{column_args} or defined $self->{column_args}->{options} )
		{
			die "<options/> can be defined once only inside of <column/>";
		}

		$self->{column_args}->{options} = [ ];
	}
	elsif ( $name eq 'option' )
	{
		$self->{in_option} = 1;
	}
	elsif ( $name eq 'foreign-key' )
	{
		if ( not defined $self->{table} or defined $self->{foreign_key} )
		{
			die "<foreign-key/> can only be defined inside of <table/>";
		}

		$self->{foreign_key} = {
			local_columns   => [ ],
			foreign_columns => [ ],
			foreign_table   => $attrs->{'{}foreignTable'}->{Value},
		};
	}
	elsif ( $name eq 'reference' )
	{
		if ( not defined $self->{foreign_key} )
		{
			die "<reference/> tag must be inside of a <foreign-key> tag with a valid foreignTable attribute";
		}

		# store these new values
		push @{$self->{foreign_key}->{local_columns}},   $attrs->{'{}local'}->{Value};
		push @{$self->{foreign_key}->{foreign_columns}}, $attrs->{'{}foreign'}->{Value};
	}
}

sub characters 
{
	my ($self, $h) = @_;

	# simple alias
	my $text = $h->{'Data'};

	if ( $self->{in_option} )
	{
		$self->{buffer} .= $text;
	}
}

sub end_element 
{
	my ($self, $el) = @_;

	# simple alias
	my $name = $el->{'LocalName'};

	if ( $name eq "table" )
	{
		# mark that we have left the table
		$self->{parser}->finish_table($self->{table});
		$self->{table} = undef;
	}
	elsif ( $name eq 'column' )
	{
		# add it
		$self->{parser}->add_column($self->{table}, $self->{column_args});

		# clear state
		$self->{column_args} = undef;
	}
	elsif ( $name eq 'option' )
	{
		my $option = $self->{buffer};

		# strip the blank space from the string
		$option =~ s/^\s*//;
		$option =~ s/\s*$//; 

		# add it.
		push @{$self->{column_args}->{options}}, $option;

		# clear the buffer.
		$self->{buffer} = '';
	}
	elsif ( $name eq 'foreign-key' )
	{
		$self->{parser}->add_foreign_key($self->{table}, $self->{foreign_key});
		
		# mark that we have left the foreign key
		$self->{foreign_key} = undef;
	}
}

1;

