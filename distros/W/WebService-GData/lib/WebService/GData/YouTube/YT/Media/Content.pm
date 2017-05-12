package WebService::GData::YouTube::YT::Media::Content;
use base 'WebService::GData::Node::Media::Content';
use WebService::GData::YouTube::YT();


sub attributes {
	my @array = @{WebService::GData::Node::Media::Content->attributes};
	push @array, 'yt:format';
  return \@array;
}

sub extra_namespaces {
    return {WebService::GData::YouTube::YT->root_name=>WebService::GData::YouTube::YT->namespace_uri};
}



1;
