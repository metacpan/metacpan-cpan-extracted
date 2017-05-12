package WebService::GData::Node::Atom::AtomEntity;
use base 'WebService::GData::Node::AbstractEntity';

use WebService::GData::Node::Atom::AuthorEntity();
use WebService::GData::Node::Atom::Category();
use WebService::GData::Node::Atom::Id();
use WebService::GData::Node::Atom::Link();
use WebService::GData::Node::Atom::Title();
use WebService::GData::Node::Atom::Updated();
use WebService::GData::Collection;

our $VERSION = 0.01_02;
my $BASE = 'WebService::GData::Node::Atom::';
sub __init {
	my ( $this, $params ) = @_;

	$this->{_feed} = {};

	if ( ref($params) eq 'HASH' ) {
		$this->{_feed} = $params->{feed} || $params;
	}

	$this->_set_tag  ( $BASE, 'AuthorEntity'    , 'author',1 );
	$this->_init_tags( $BASE, undef             , (qw(id title updated)) );

	$this->_init_tags( $BASE, 'force_collection' , (qw(category link)) );
}

sub set_children {
	my $this = shift;

	$this->_entity->child( $this->{ '_' . $_ } )
	  foreach ( (qw(author category id link title updated)) );
}

private _set_tag => sub {
	my ( $this, $package, $class, $node, $collection ) = @_;
	
    $class = $package . "\u$class";
    
	if ( ref( $this->{_feed}->{$node} ) eq 'ARRAY' ) {

		$this->{ '_' . $node } =
		  _create_collection( $this->{_feed}->{$node}, $class );
	}
	else {

		if ($collection) {
			my $data;
			$data = $class->new( $this->{_feed}->{$node} )
			  if $this->{_feed}->{$node};
			$this->{ '_' . $node } =
			  _create_collection( $data ? [$data] : [], $class );
		}
		else {
			$this->{ '_' . $node } = $class->new( $this->{_feed}->{$node} );
		}
	}
};


private _init_tags => sub {
	my ( $this, $package, $collection, @nodes ) = @_;
	foreach my $node (@nodes) {
		$this->_set_tag( $package, "\u$node", $node, $collection );
	}
};

private _create_collection => sub {
    my ( $data, $class ) = @_;
    return new WebService::GData::Collection(
        $data, 
        undef,
        sub {
            my $val = shift;
            return $class->new($val) if ref $val ne $class;
            $val;
        }
    );

};

sub links {
	my $this = shift;
	$this->link;
}

sub get_link {
	my ( $this, $search ) = @_;
	my $link = $this->link->rel($search)->[0];
	return $link->href if ($link);
}

"The earth is blue like an orange.";
