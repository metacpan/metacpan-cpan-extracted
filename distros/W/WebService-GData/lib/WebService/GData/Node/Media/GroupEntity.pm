package WebService::GData::Node::Media::GroupEntity;
use base 'WebService::GData::Node::AbstractEntity';
use WebService::GData::Node::Media::Group();
use WebService::GData::Node::Media::Category();
use WebService::GData::Node::Media::Content();
use WebService::GData::Node::Media::Credit();
use WebService::GData::Node::Media::Description();
use WebService::GData::Node::Media::Keywords();
use WebService::GData::Node::Media::Player();
use WebService::GData::Node::Media::Title();
use WebService::GData::Node::Media::Thumbnail();
use WebService::GData::Node::Media::Restriction();
use WebService::GData::Node::PointEntity();
use WebService::GData::Collection();

our $VERSION = 0.01_02;

my $collections  = [qw(category restriction thumbnail credit content)];
my $nodes        = [qw(player title description keywords)];

sub __init {
	my ($this,$params) = @_;

	$this->_entity(new WebService::GData::Node::Media::Group());
    foreach my $node (@$collections){
        $this->{'_'.$node}= $this->__node_factory($node,$params,1);
        $this->_entity->child($this->{'_'.$node});
    }	
    foreach my $node (@$nodes){
        $this->{'_'.$node}= $this->__node_factory($node,$params);
        $this->_entity->child($this->{'_'.$node});
    }
}

sub __node_factory {
    my($this,$node,$params,$collection)=@_;
    my $class = 'WebService::GData::Node::Media::'."\u$node";
    my $data  = $params->{'media$'.$node};
    if(ref($data) eq 'ARRAY' || $collection) {
        return new WebService::GData::Collection($data||[],undef,sub { 
        	my $elm=shift; 
        	$elm= $class->new($elm) if ref $elm ne $class; 
        	return $elm; 
        });
    }
    return $class->new($data);
}

sub _create_onget_init {
    my($class)=shift;
    my $sub = qq[sub { my \$elm=shift; return $class->new(\$elm) if ref \$elm ne '$class' }];
    return eval "$sub";
    
}



1;

