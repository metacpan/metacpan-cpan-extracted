package WebService::GData::YouTube::YT::Media::Credit;
use base 'WebService::GData::Node::Media::Credit';
use WebService::GData::YouTube::YT();


sub attributes {
	my @attrs = @{WebService::GData::Node::Media::Credit->attributes};
	push @attrs,'yt:type';
    return \@attrs;
}

sub extra_namespaces {
    return {WebService::GData::YouTube::YT->root_name=>WebService::GData::YouTube::YT->namespace_uri};
}



1;
