package WebService::GData::Node::Media;
use WebService::GData::Constants qw/:namespace/;
use WebService::GData::Node;


sub import {
    my $package = caller;
    return if($package->isa(__PACKAGE__)||$package eq 'main'||$package!~m/Media::/);
    WebService::GData::Node->import($package);
{
	no strict 'refs';
	unshift @{$package.'::ISA'},__PACKAGE__;
	
}
}


sub namespace_prefix {MEDIA_NAMESPACE_PREFIX};
sub namespace_uri { MEDIA_NAMESPACE_URI }

1;