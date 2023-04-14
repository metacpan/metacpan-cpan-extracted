package Web::PerlDistSite::MenuItem::PodFile;

our $VERSION = '0.001010';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

extends 'Web::PerlDistSite::MenuItem::File';
with 'Web::PerlDistSite::MenuItem::_PodCommon';

sub body_class {
	return 'page from-pod';
}

1;
