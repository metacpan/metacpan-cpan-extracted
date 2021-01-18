package Web::Sitemap;

our $VERSION = '0.903';

use strict;
use warnings;
use bytes;

use File::Temp;
use File::Copy;
use IO::Compress::Gzip qw/gzip $GzipError/;
use Encode;
use Carp;

use Web::Sitemap::Url;

use constant {
	URL_LIMIT => 50000,
	FILE_SIZE_LIMIT => 50 * 1024 * 1024,
	FILE_SIZE_LIMIT_MIN => 1024 * 1024,

	DEFAULT_FILE_PREFIX => 'sitemap.',
	DEFAULT_TAG => 'pages',
	DEFAULT_INDEX_NAME => 'sitemap',

	XML_HEAD => '<?xml version="1.0" encoding="UTF-8"?>',
	XML_MAIN_NAMESPACE => 'xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"',
	XML_MOBILE_NAMESPACE => 'xmlns:mobile="http://www.google.com/schemas/sitemap-mobile/1.0"',
	XML_IMAGES_NAMESPACE => 'xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"'

};

sub new
{
	my ($class, %p) = @_;

	my %allowed_keys = map { $_ => 1 } qw(
		output_dir      temp_dir              loc_prefix
		url_limit       file_size_limit       file_prefix
		file_loc_prefix default_tag           index_name
		mobile          images                namespace
		charset         move_from_temp_action
	);

	my @bad_keys = grep { !exists $allowed_keys{$_} } keys %p;
	croak "Unknown parameters: @bad_keys" if @bad_keys;

	my $self = {
		loc_prefix => '',
		tags => {},

		url_limit => URL_LIMIT,
		file_size_limit => FILE_SIZE_LIMIT,
		file_prefix => DEFAULT_FILE_PREFIX,
		file_loc_prefix => '',
		default_tag => DEFAULT_TAG,
		index_name => DEFAULT_INDEX_NAME,
		mobile => 0,
		images => 0,
		charset => 'utf8',

		%p,    # actual input values
	};

	$self->{file_loc_prefix} ||= $self->{loc_prefix};

	if ($self->{file_size_limit} < FILE_SIZE_LIMIT_MIN) {
		$self->{file_size_limit} = FILE_SIZE_LIMIT_MIN;
	}

	if ($self->{namespace}) {

		$self->{namespace} = [$self->{namespace}]
			if !ref $self->{namespace};

		croak 'namespace must be scalar or array ref!'
			if ref $self->{namespace} ne 'ARRAY';
	}

	unless ($self->{output_dir}) {
		croak 'output_dir expected!';
	}

	if ($self->{temp_dir} and not -w $self->{temp_dir}) {
		croak sprintf "Can't write to temp_dir '%s' (error: %s)", $self->{temp_dir}, $!;
	}

	if ($self->{move_from_temp_action} and ref $self->{move_from_temp_action} ne 'CODE') {
		croak 'move_from_temp_action must be code ref!';
	}

	return bless $self, $class;
}

sub add
{
	my ($self, $url_list, %p) = @_;

	my $tag = $p{tag} || $self->{default_tag};

	if (ref $url_list ne 'ARRAY') {
		croak 'The list of sitemap URLs must be array ref';
	}

	for my $url (@$url_list) {
		my $data = Web::Sitemap::Url->new(
			$url,
			mobile => $self->{mobile},
			loc_prefix => $self->{loc_prefix},
		)->to_xml_string;

		if ($self->_file_limit_near($tag, bytes::length $data)) {
			$self->_next_file($tag);
		}

		$self->_append_url($tag, $data);
	}
}

sub finish
{
	my ($self, %p) = @_;

	return unless keys %{$self->{tags}};

	my $index_temp_file_name = $self->_temp_file->filename;
	open my $index_file, '>' . $index_temp_file_name or croak "Can't open file '$index_temp_file_name'! $!\n";

	print {$index_file} XML_HEAD;
	printf {$index_file} "\n<sitemapindex %s>", XML_MAIN_NAMESPACE;

	for my $tag (sort keys %{$self->{tags}}) {
		my $data = $self->{tags}{$tag};

		$self->_close_file($tag);
		for my $page (1 .. $data->{page}) {
			printf {$index_file} "\n<sitemap><loc>%s/%s</loc></sitemap>", $self->{file_loc_prefix},
				$self->_file_name($tag, $page);
		}
	}

	print {$index_file} "\n</sitemapindex>";
	close $index_file;

	$self->_move_from_temp(
		$index_temp_file_name,
		$self->{output_dir} . '/' . $self->{index_name} . '.xml'
	);
}

sub _move_from_temp
{
	my ($self, $temp_file_name, $public_file_name) = @_;

	#printf "move %s -> %s\n", $temp_file_name, $public_file_name;

	if ($self->{move_from_temp_action}) {
		$self->{move_from_temp_action}($temp_file_name, $public_file_name);
	}
	else {
		File::Copy::move($temp_file_name, $public_file_name)
			or croak sprintf 'move %s -> %s error: %s', $temp_file_name, $public_file_name, $!;
	}
}

sub _file_limit_near
{
	my ($self, $tag, $new_portion_size) = @_;

	return 0 unless defined $self->{tags}{$tag};

	# printf("tag: %s.%d; url: %d; gzip_size: %d (%d)\n",
	# 	$tag,
	# 	$self->{tags}->{$tag}->{page},
	# 	$self->{tags}->{$tag}->{url_count},
	# 	$self->{tags}->{$tag}->{file_size},
	# 	$self->{file_size_limit}
	# );

	return (
		$self->{tags}{$tag}{url_count} >= $self->{url_limit}
			||

			# 200 bytes should be well enough for the closing tags at the end of the file
			($self->{tags}{$tag}{file_size} + $new_portion_size) >= ($self->{file_size_limit} - 200)
	);
}

sub _temp_file
{
	my ($self) = @_;

	return File::Temp->new(
		UNLINK => 1,
		$self->{temp_dir} ? (DIR => $self->{temp_dir}) : ()
	);
}

sub _set_new_file
{
	my ($self, $tag) = @_;

	my $temp_file = $self->_temp_file;

	$self->{tags}{$tag}{page}++;
	$self->{tags}{$tag}{url_count} = 0;
	$self->{tags}{$tag}{file_size} = 0;
	$self->{tags}{$tag}{file} = IO::Compress::Gzip->new($temp_file->filename)
		or croak "gzip failed: $GzipError\n";
	$self->{tags}{$tag}{file}->autoflush;
	$self->{tags}{$tag}{temp_file} = $temp_file;

	# Do not check the file for oversize because it is empty and will likely
	# not exceed 1MB with initial tags alone

	my @namespaces = (XML_MAIN_NAMESPACE);
	push @namespaces, XML_MOBILE_NAMESPACE
		if $self->{mobile};
	push @namespaces, XML_IMAGES_NAMESPACE
		if $self->{images};
	push @namespaces, @{$self->{namespace}}
		if $self->{namespace};

	$self->_append(
		$tag,
		sprintf("%s\n<urlset %s>", XML_HEAD, join(' ', @namespaces))
	);
}

sub _file_handle
{
	my ($self, $tag) = @_;

	unless (exists $self->{tags}{$tag}) {
		$self->_set_new_file($tag);
	}

	return $self->{tags}{$tag}{file};
}

sub _append
{
	my ($self, $tag, $data) = @_;

	$self->_file_handle($tag)->print(Encode::encode($self->{charset}, $data));
	$self->{tags}{$tag}{file_size} += bytes::length $data;
}

sub _append_url
{
	my ($self, $tag, $data) = @_;

	$self->_append($tag, $data);
	$self->{tags}{$tag}{url_count}++;
}

sub _next_file
{
	my ($self, $tag) = @_;

	$self->_close_file($tag);
	$self->_set_new_file($tag);
}

sub _close_file
{
	my ($self, $tag) = @_;

	$self->_append($tag, "\n</urlset>");
	$self->_file_handle($tag)->close;

	$self->_move_from_temp(
		$self->{tags}{$tag}{temp_file}->filename,
		$self->{output_dir} . '/' . $self->_file_name($tag)
	);
}

sub _file_name
{
	my ($self, $tag, $page) = @_;
	return
		$self->{file_prefix}
		. $tag
		. '.'
		. ($page || $self->{tags}{$tag}{page})
		. '.xml.gz'
		;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Web::Sitemap - Simple way to generate sitemap files with paging support

=head1 SYNOPSIS

	use Web::Sitemap;

	my $sm = Web::Sitemap->new(
		output_dir => '/path/for/sitemap',

		### Options ###

		temp_dir    => '/path/to/tmp',
		loc_prefix  => 'http://my_domain.com',
		index_name  => 'sitemap',
		file_prefix => 'sitemap.',

		# mark for grouping urls
		default_tag => 'my_tag',


		# add <mobile:mobile/> inside <url>, and appropriate namespace (Google standard)
		mobile      => 1,

		# add appropriate namespace (Google standard)
		images      => 1,

		# additional namespaces (scalar or array ref) for <urlset>
		namespace   => 'xmlns:some_namespace_name="..."',

		# location prefix for files-parts of the sitemap (default is loc_prefix value)
		file_loc_prefix  => 'http://my_domain.com',

		# specify data input charset
		charset => 'utf8',

		move_from_temp_action => sub {
			my ($temp_file_name, $public_file_name) = @_;

			# ...some action...
			#
			# default behavior is
			# File::Copy::move($temp_file_name, $public_file_name);
		}

	);

	$sm->add(\@url_list);


	# When adding a new portion of URL, you can specify a label for the file in which these will be URL

	$sm->add(\@url_list1, tag => 'articles');
	$sm->add(\@url_list2, tag => 'users');


	# If in the process of filling the file number of URL's will exceed the limit of 50 000 URL or the file size is larger than 50MB, the file will be rotate

	$sm->add(\@url_list3, tag => 'articles');


	# After calling finish() method will create an index file, which will link to files with URL's

	$sm->finish;

=head1 DESCRIPTION

This module is an utility for generating indexed sitemaps.

Each sitemap file can have up to 50 000 URLs or up to 50MB in size (after decompression) according to L<sitemaps.org|https://www.sitemaps.org/faq.html#faq_sitemap_size>. Any page that exceeds that limit must use L<sitemap index files|https://www.sitemaps.org/protocol.html#index> instead.

Web::Sitemap generates a single sitemap index with links to multiple sitemap pages. The pages are automatically split when they reach the limit and are always gzip compressed. Files are created in form of temporary files and copied over to the destination directory, but the copy action can be hooked into to change that behavior.

=head1 INTERFACE

Web::Sitemap only provides OO interface.

=head2 Methods

=head3 new

	my $sitemap = Web::Sitemap->new(output_dir => $dirname, %options);

Constructs a new Web::Sitemap object that will generate the sitemap.

Files will be put into I<output_dir>. This argument is required.

Other optional arguments include:

=over

=item * C<temp_dir>

Path to a temporary directory. Must already exist and be
writable. If not specified, a new temporary directory will be created using
L<File::Temp>.

=item * C<loc_prefix>

A location prefix for all the urls in the sitemap, like
I<'http://my_domain.com'>. Defaults to an empty string.

=item * C<index_name>

Name of the sitemap index (basename without the extension).
Defaults to I<'sitemap'>.

=item * C<file_prefix>

Prefix for all sitemap files containing URLs. Defaults to
I<'sitemap.'>.

=item * C<default_tag>

A default tag that will be used for grouping URLs in files
when they are added without an explicit tag. Defaults to I<'pages'>.

=item * C<mobile>

Will add a mobile namespace to the sitemap files, and each URL will
contain C<< <mobile:mobile/> >>. This is a Google standard. Disabled by
default.

=item * C<images>

Will add images namespace to the sitemap files. This is a Google
standard. Disabled by default.

=item * C<namespace>

Additional namespaces to be added to the sitemap files. This can
be a string or an array reference containing strings. Empty by default.

=item * C<file_loc_prefix>

A prefix that will be put before the filenames in the
sitemap index. This will not cause files to be put in a different directory,
will only affect the sitemap index. Defaults to the value of C<loc_prefix>.

=item * C<charset>

Encoding to be used for writing the files. Defaults to I<'utf8'>.

=item * C<move_from_temp_action>

A coderef that will change how the files are handled
after successful generation. Will be called once for each generated file and be
passed these arguments: C<$temporary_file_path, $destination_file_path>.

By default it will copy the files using I<File::Copy::move>.

=back

=head3 add

	$sitemap->add(\@links, tag => $tagname);

Adds more links to the sitemap under I<$tagname> (can be ommited - defaults to
C<pages> or the one specified in the constructor).

Links can be simple scalars (URL strings) or a hashref. See
L<Web::Sitemap::Url/new> for a list of possible hashref arguments.

Can be called multiple times.

=head3 finish

	$sitemap->finish;

Finalizes the sitemap creation and calls the function to move temporary files
to the output directory.

=head1 EXAMPLES

=head2 Support for Google images format

=head3 Format 1

	$sitemap->add([{
		loc => 'http://test1.ru/',
		images => {
			caption_format => sub {
				my ($iterator_value) = @_;
				return sprintf('Vasya - foto %d', $iterator_value);
			},
			loc_list => [
				'http://img1.ru/',
				'http://img2.ru'
			]
		}
	}]);

=head3 Format 2

	$sitemap->add([{
		loc => 'http://test11.ru/',
		images => {
			caption_format_simple => 'Vasya - foto',
			loc_list => ['http://img11.ru/', 'http://img21.ru']
		}
	}]);

=head3 Format 3

	$sitemap->add([{
		loc => 'http://test122.ru/',
		images => {
			loc_list => [
				{ loc => 'http://img122.ru/', caption => 'image #1' },
				{ loc => 'http://img133.ru/', caption => 'image #2' },
				{ loc => 'http://img144.ru/', caption => 'image #3' },
				{ loc => 'http://img222.ru', caption => 'image #4' }
			]
		}
	}]);
);

=head1 AUTHOR

Mikhail N Bogdanov C<< <mbogdanov at cpan.org > >>

=head1 CONTRIBUTORS

In no particular order:

Ivan Bessarabov

Bartosz Jarzyna (@brtastic)

=head1 LICENSE

This module and all the packages in this module are governed by the same license as Perl itself.

=cut

