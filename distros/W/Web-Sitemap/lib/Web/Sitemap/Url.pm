package Web::Sitemap::Url;

our $VERSION = '0.903';

use strict;
use warnings;
use utf8;

use Carp;

sub new
{
	my ($class, $data, %p) = @_;

	my %allowed_keys = map { $_ => 1 } qw(
		mobile loc_prefix
	);

	my @bad_keys = grep { !exists $allowed_keys{$_} } keys %p;
	croak "Unknown parameters: @bad_keys" if @bad_keys;

	my $self = {
		mobile => 0,
		loc_prefix => '',
		%p,    # actual input values
	};

	if (not ref $data) {
		croak 'Web::Sitemap::Url first argument must be defined'
			unless defined $data;
		$self->{loc} = $data;
	}
	elsif (ref $data eq 'HASH') {
		unless (defined $data->{loc}) {
			croak 'Web::Sitemap::Url first argument hash must have `loc` key defined';
		}
		$self = {%$self, %$data};
	}
	else {
		croak 'Web::Sitemap::Url first argument must be a string or a hash reference';
	}

	return bless $self, $class;
}

sub to_xml_string
{
	my ($self, %p) = @_;

	return sprintf(
		"\n<url><loc>%s%s</loc>%s%s%s</url>",
		$self->{loc_prefix},
		$self->{loc},
		$self->{changefreq} ? sprintf('<changefreq>%s</changefreq>', $self->{changefreq}) : '',
		$self->{mobile} ? '<mobile:mobile/>' : '',
		$self->_images_xml_string
	);
}

sub _images_xml_string
{
	my ($self) = @_;

	my $result = '';

	if (defined $self->{images}) {
		my $i = 1;
		for my $image (@{$self->{images}{loc_list}}) {
			my $loc = ref $image eq 'HASH' ? $image->{loc} : $image;

			my $caption = '';
			if (ref $image eq 'HASH' and defined $image->{caption}) {
				$caption = $image->{caption};
			}
			elsif (defined $self->{images}{caption_format_simple}) {
				$caption = $self->{images}{caption_format_simple} . " $i";
			}
			elsif (defined $self->{images}{caption_format}) {
				$caption = &{$self->{images}{caption_format}}($i);
			}

			$result .= sprintf(
				"\n<image:image><loc>%s</loc><caption><![CDATA[%s]]></caption></image:image>",
				$loc, $caption
			);

			$i++;
		}
	}

	return $result;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Web::Sitemap::Url - Sitemap URL representation

=head1 SYNOPSIS

	use Web::Sitemap;

	$sm = Web::Sitemap->new(%args);

	# will produce Web::Sitemap::Url objects from strings
	$sm->add(['/blog/1', '/blog/2']);

	# will produce Web::Sitemap::Url objects from hashes (more configurable)
	$sm->add([
		{
			loc => '/blog/3',
			changefreq => 'daily',
		},
		{
			loc => '/blog/4',
			mobile => 1,
		}
	]);

=head1 DESCRIPTION

This is a simple representation of a sitemap URL. It's used internally by
L<Web::Sitemap> and is not meant to be used explcitly. It is what each entry of
C<< $sitemap->add >> will be turned into for the XML generation.

=head2 Hash configuration in Web::Sitemap::add

If a sitemap entry is specified as a string, it inherits as much as possible from Web::Sitemap.

Passing a hash allows for overriding global sitemap settings and adding a couple more.

=over

=item * C<loc>

URL location, just like the one that would be passed in a string version. Required.

=item * C<loc_prefix>

Same as in L<Web::Sitemap/new>

=item * C<mobile>

Same as in L<Web::Sitemap/new>

=item * C<changefreq>

Will be inserted into C<< <changefreq> >> XML node.

=item * C<images>

A list of images. See L<Web::Sitemap/Support for Google images format> for details.

=back

=cut
