package WebService::GData::Node::GML;
use WebService::GData::Constants qw/:namespace/;
use WebService::GData::Node;

sub import {
    my $package = caller;
    return if($package->isa(__PACKAGE__)||$package eq 'main'||$package!~m/GML::/);
    WebService::GData::Node->import($package);
{
	no strict 'refs';
	unshift @{$package.'::ISA'},__PACKAGE__;
	
}
}

sub namespace_prefix {GML_NAMESPACE_PREFIX}
sub namespace_uri { GML_NAMESPACE_URI }


1;