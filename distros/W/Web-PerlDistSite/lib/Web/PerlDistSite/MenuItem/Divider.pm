package Web::PerlDistSite::MenuItem::Divider;

our $VERSION = '0.001011';

use Moo;
use Web::PerlDistSite::Common -lexical, -all;

extends 'Web::PerlDistSite::MenuItem';

has '+name' => (
	required => false,
);

has '+title' => (
	required => false,
);

sub nav_item ( $self, $active_item ) {
	return '<li class="nav-item">·</li>',
}

sub dropdown_item ( $self, $active_item ) {
	return '<li><hr class="dropdown-divider" /></li>';
}

1;
