package WebService::GData::Node::GD;
use WebService::GData::Constants qw/:namespace/;
use WebService::GData::Node;

sub import {
    my $package = caller;
    return if($package->isa(__PACKAGE__)||$package eq 'main'|| $package!~m/GD::/);
    WebService::GData::Node->import($package);
{
	no strict 'refs';
	unshift @{$package.'::ISA'},__PACKAGE__;
}
}


sub namespace_prefix {GDATA_NAMESPACE_PREFIX}
sub namespace_uri {GDATA_NAMESPACE_URI}


1;