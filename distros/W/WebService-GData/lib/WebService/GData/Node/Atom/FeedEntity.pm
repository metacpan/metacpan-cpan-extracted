package WebService::GData::Node::Atom::FeedEntity;
use base 'WebService::GData::Node::Atom::AtomEntity';

use WebService::GData::Node::Atom::Feed();
use WebService::GData::Node::Atom::Logo();
use WebService::GData::Node::Atom::Generator();
our $VERSION = 0.01_01;

sub __init {
	my ($this,$params) = @_;
	
	$this->SUPER::__init($params);
	
    $this->_entity(new WebService::GData::Node::Atom::Feed('gd:etag'=>$this->{_feed}->{'gd$etag'}));
    $this->{_logo}=new WebService::GData::Node::Atom::Logo($this->{_feed}->{logo});
    $this->_entity->child($this->{_logo});
    $this->{_generator}=new WebService::GData::Node::Atom::Generator($this->{_feed}->{generator});
    $this->_entity->child($this->{_generator});
    $this->set_children;
}

"The earth is blue like an orange.";
