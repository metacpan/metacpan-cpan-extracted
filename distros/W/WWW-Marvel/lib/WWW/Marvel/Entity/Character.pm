package WWW::Marvel::Entity::Character;
use strict;
use warnings;
use base qw/ Class::Accessor /;
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw/ id comics description events modified name resourceURI series stories thumbnail urls /);

my %IMAGE_VARIANTS = (
	'portrait_small'      => '50x75px',
	'portrait_medium'     => '100x150px',
	'portrait_xlarge'     => '150x225px',
	'portrait_fantastic'  => '168x252px',
	'portrait_uncanny'    => '300x450px',
	'portrait_incredible' => '216x324px',

	'standard_small'     => '65x45px',
	'standard_medium'    => '100x100px',
	'standard_large'     => '140x140px',
	'standard_xlarge'    => '200x200px',
	'standard_fantastic' => '250x250px',
	'standard_amazing'   => '180x180px',

	'landscape_small'     => '120x90px',
	'landscape_medium'    => '175x130px',
	'landscape_large'     => '190x140px',
	'landscape_xlarge'    => '270x200px',
	'landscape_amazing'   => '250x156px',
	'landscape_incredible' => '464x261px',
);

sub get_picture {
	my ($self, $variant) = @_;
	my $th = $self->get_thumbnail;
	my $path = $th->{path};
	return if !defined $path;
	$path .= "/$variant" if $variant && exists $IMAGE_VARIANTS{$variant};
	sprintf("%s.%s", $path, $th->{extension});
}

1;

