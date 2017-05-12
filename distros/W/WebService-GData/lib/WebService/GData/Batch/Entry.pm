package WebService::GData::Batch::Entry;
use base WebService::GData::Batch;

	sub batchId {
		my $this = shift;
		$this->{_batchId}=$_[0] if(@_==1);
		$this->{_batchId};
	}

	sub update {
		my $this = shift;
		$this->{_update}= $_[0] if(@_==1);
		return $this->{_update};
	}
 
	sub _serialize {
		my $this = shift;
		my $xml= '<entry>';
		   $xml.= q[<batch:operation type="].$this->operation.q["/>];
		   $xml.= q[<id>].$this->id.q[</id>];
		   if($this->operation=~m/query|update|delete/) {
				$xml.= q[<link rel='edit' type='application/atom+xml' href='].$this->link.q['/>];
				if($this->operation eq 'update'){
					$xml.= $this->update;
				}
		   }
		   $xml.= q[<batch:id>].$this->batchId.q[</batch:id>] if($this->batchId);	
		   $xml.= '</entry>';
		return $xml;

	}


1;