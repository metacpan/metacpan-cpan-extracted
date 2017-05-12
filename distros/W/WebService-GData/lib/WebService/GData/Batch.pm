package WebService::GData::Batch;
use base WebService::GData;
use WebService::GData::Batch::Response;

	my  $AVAILABLE_OPERATIONS = ['insert','update','delete','query'];
	my  $DEFAULT_OPERATION    = $AVAILABLE_OPERATIONS->[0];
	my  $MAX_BATCH_OPERATIONS = 50;

	sub __init {
		my ($this,$dbh) = @_;
		$this->{_dbh}   = $dbh;
		$this->{_entry}   = [];
	}

	sub link {
		my $this= shift;
		$this->{_link} = $_[0] if(@_==1);
		return $this->{_link};
	}

	sub id {
		my $this= shift;
		$this->{_id} = $_[0] if(@_==1);
		return $this->{_id};
	}

	sub operation {
		my $this = shift;
		if(@_==1){
			my $op= $_[0];
			$op = (grep($op,@$AVAILABLE_OPERATIONS)) ? $op : $DEFAULT_OPERATION;
			$this->{_operation}=$op;
		}
		return ($this->{_operation})? $this->{_operation} : $DEFAULT_OPERATION;
	}

	sub addEntry {
		my $this = shift;

		if($_[0]){
			push @{$this->{_entry}},$_[0];
		}
	}

	sub hasEntries {
		my $this = shift;
		return (@{$this->{_entry}}>0) ?1:0;
	}

	sub _serialize {
		my $this = shift;

		my $xml=<<XML;
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns='http://www.w3.org/2005/Atom' 
      xmlns:media='http://search.yahoo.com/mrss/'
      xmlns:batch='http://schemas.google.com/gdata/batch'
      xmlns:yt='http://gdata.youtube.com/schemas/2007'>
XML

	 my $i=0;
	 foreach my $entry (@{$this->{_entry}}) {
		$xml.= $entry->_serialize();
		$i++;	
		next if($i>=50);
	 }

	 $xml.=q[</feed>];
	 return $xml;
	}

	sub execute {
		my $this = shift;
		if(@{$this->{_entry}}>0){
			return new GData::Batch::Response( $this->{_dbh}->post($this->link,$this->_serialize,1) );
		}
	}

1;