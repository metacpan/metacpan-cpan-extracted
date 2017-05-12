package Text::Placeholder::Group::URI;

use strict;
use warnings;
#use Carp qw();
#use Data::Dumper;
use URI;
use parent qw(
	Text::Placeholder::Group::_
	Object::By::Array);

sub THIS() { 0 }

sub ATR_PLACEHOLDERS() { 0 }
sub ATR_URI() { 1 }

my $PLACEHOLDERS = {
	'uri_scheme' => sub { return($_[THIS][ATR_URI]->scheme)},
	'uri_host' => sub { return($_[THIS][ATR_URI]->host)},
	'uri_path' => sub { return($_[THIS][ATR_URI]->path)},
	'uri_opaque' => sub { return($_[THIS][ATR_URI]->opaque)},
	'uri_full' => sub { return($_[THIS][ATR_URI])},
};

sub _init {
	$_[THIS][ATR_PLACEHOLDERS] = $PLACEHOLDERS;
	$_[THIS][ATR_URI] = undef;
	return;
}

sub P_URI() { 1 }
sub subject {
	if(exists($_[P_URI])) {
		$_[THIS][ATR_URI] = URI->new($_[P_URI]);
		return;
	} else {
		return($_[THIS][ATR_URI]);
	}
}

1;
