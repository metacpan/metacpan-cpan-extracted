package WebService::GData::YouTube::YT::GroupEntity;
use base 'WebService::GData::Node::Media::GroupEntity';
use WebService::GData::YouTube::YT::Duration();
use WebService::GData::YouTube::YT::Uploaded();
use WebService::GData::YouTube::YT::Videoid();
use WebService::GData::YouTube::YT::AspectRatio();
use WebService::GData::YouTube::YT::Private();
use WebService::GData::YouTube::YT::Media::Content();
our $VERSION = 0.01_01;

sub __init {
	my ($this,$params) = @_;

	$this->SUPER::__init($params);
	
    $this->{'_duration'}     = new WebService::GData::YouTube::YT::Duration($params->{'yt$duration'});
    $this->{'_uploaded'}     = new WebService::GData::YouTube::YT::Uploaded($params->{'yt$uploaded'});  
    $this->{'_videoid'}      = new WebService::GData::YouTube::YT::Videoid($params->{'yt$videoid'});    
    $this->{'_aspect_ratio'}  = new WebService::GData::YouTube::YT::AspectRatio($params->{'yt$aspectRatio'}); 
     my $content =  new WebService::GData::Collection($params->{'media$content'},undef,sub { my $elm=shift; return WebService::GData::YouTube::YT::Media::Content->new($elm) if ref $elm ne 'WebService::GData::YouTube::YT::Media::Content';return $elm; });

    $this->{_content}=$content;
    if($params->{'yt$private'}){
        $this->{'_private'}  = new WebService::GData::YouTube::YT::Private($params->{'yt$private'});
        $this->_entity->child($this->{'_private'});  
    }
}


1;

