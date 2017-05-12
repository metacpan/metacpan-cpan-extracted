package WebService::GData::Batch::Response;
use base WebService::GData;

	sub __init {
		my ($this,$response) = @_;
		$this->{_response} = $response;
		$this->{_content}  = $this->parse();
	}

	#to do : failure due to an xml entry error (which shall not arrive anyway but...) 
	#<batch:interrupted reason= success= failures= parsed= />
 
	sub parse {
		my $this    = shift;
		my @entries = $this->{_response}=~m/<entry.+?>(.+?)<\/entry>/gs;
		my @results = ();
		foreach my $entry (@entries) {
			my @states = $entry=~m/<batch:status code='([0-9]+)' reason='(.+?)'/;
			$this->{_failure}=1 if($states[0]!~m/^2/);
			push @results,\@states;
		}
		return \@results;
	}

	sub content {
		my $this = shift;
		return $this->{_content};
	}

	sub is_success {
		my $this = shift;
		return ($this->{_failure}) ? 0: 1;
	}

1;