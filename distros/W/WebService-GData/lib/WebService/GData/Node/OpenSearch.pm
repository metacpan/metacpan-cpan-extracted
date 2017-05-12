package WebService::GData::Node::OpenSearch;
use WebService::GData::Node;
use WebService::GData::Constants qw/:namespace/;

sub import {
    my $package = caller;
    return if($package->isa(__PACKAGE__)||$package eq 'main'||$package!~m/::OpenSearch/);
    WebService::GData::Node->import($package);
{
	no strict 'refs';
	unshift @{$package.'::ISA'},__PACKAGE__;
	
}
}

sub namespace_prefix {OPENSEARCH_NAMESPACE_PREFIX }
sub namespace_uri { OPENSEARCH_NAMESPACE_URI }


1;