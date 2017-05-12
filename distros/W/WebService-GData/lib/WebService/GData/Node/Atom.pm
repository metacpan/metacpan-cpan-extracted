package WebService::GData::Node::Atom;
use WebService::GData::Constants qw/:namespace/;
use WebService::GData::Node;


sub import {
    my $package = caller;
    return if($package->isa(__PACKAGE__)||$package eq 'main'||$package!~m/Atom::/);
    WebService::GData::Node->import($package);
{
	no strict 'refs';
	unshift @{$package.'::ISA'},__PACKAGE__;
}
}


sub namespace_prefix {ATOM_NAMESPACE_PREFIX};
sub namespace_uri {ATOM_NAMESPACE_URI};

1;