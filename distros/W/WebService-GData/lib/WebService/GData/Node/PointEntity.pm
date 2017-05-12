package WebService::GData::Node::PointEntity;
use base 'WebService::GData::Node::AbstractEntity';
use WebService::GData::Node::GeoRSS::Where;
use WebService::GData::Node::GML::Point;
use WebService::GData::Node::GML::Pos;

our $VERSION = 0.01_01;

sub __init {
	my ($this,$params) = @_;
    $this->SUPER::__init($params);	
	$this->_entity(new WebService::GData::Node::GeoRSS::Where());
	$this->{_point}  = new WebService::GData::Node::GML::Point();
	$this->{_pos}    = new WebService::GData::Node::GML::Pos($params);
	$this->{_point}->child($this->{_pos});
	$this->_entity->child($this->{_point});
}


1;
