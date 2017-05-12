package WebService::GData::YouTube::YT;

use WebService::GData::Node;

our $VERSION = 0.01_01;

sub import {
    my $package = caller;
    return if($package->isa(__PACKAGE__)||$package eq 'main'||$package!~m/YT::/);
    WebService::GData::Node->import($package);
{
	no strict 'refs';
	unshift @{$package.'::ISA'},__PACKAGE__;
	
}
}

sub namespace_prefix {'yt'}
sub namespace_uri {'http://gdata.youtube.com/schemas/2007'}

1;