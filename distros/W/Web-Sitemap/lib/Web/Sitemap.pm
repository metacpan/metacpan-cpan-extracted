package Web::Sitemap;

our $VERSION = '0.902';

=head1 NAME
 
 Web::Sitemap - Simple way to generate sitemap files with paging support

=cut

=head1 SYNOPSIS
 
 Each instance of the class Web::Sitemap is manage of one index file.
 Now it always use Gzip compress.


 use Web::Sitemap;
 
 my $sm = Web::Sitemap->new(
	output_dir => '/path/for/sitemap',
	
	### Options ###

	temp_dir    => '/path/to/tmp',
	loc_prefix  => 'http://my_doamin.com',
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
	file_loc_prefix  => 'http://my_doamin.com',

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
 

 # If in the process of filling the file number of URL's will exceed the limit of 50 000 URL or the file size is larger than 10MB, the file will be rotate

 $sm->add(\@url_list3, tag => 'articles');

 
 # After calling finish() method will create an index file, which will link to files with URL's

 $sm->finish;

=cut

use strict;
use warnings;
use bytes;

use File::Temp;
use File::Copy;
use IO::Compress::Gzip qw/gzip $GzipError/;
use Encode;

use Web::Sitemap::Url;

use constant {
	URL_LIMIT           => 50000,
	FILE_SIZE_LIMIT     => 10 * 1024 * 1024,
	FILE_SIZE_LIMIT_MIN => 1024 * 1024,

	DEFAULT_FILE_PREFIX => 'sitemap.',
	DEFAULT_TAG         => 'tag',
	DEFAULT_INDEX_NAME  => 'sitemap',

	XML_HEAD             => '<?xml version="1.0" encoding="UTF-8"?>',
	XML_MAIN_NAMESPACE   => 'xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"',
	XML_MOBILE_NAMESPACE => 'xmlns:mobile="http://www.google.com/schemas/sitemap-mobile/1.0"',
	XML_IMAGES_NAMESPACE => 'xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"'

};


sub new {
	my ($class, %p) = @_;

	my $self = {
		output_dir      => $p{output_dir},
		temp_dir        => $p{temp_dir},
		
		loc_prefix      => $p{loc_prefix} || '',
		tags            => {},
		
		url_limit       => $p{url_limit}       || URL_LIMIT,
		file_size_limit => $p{file_size_limit} || FILE_SIZE_LIMIT,
		file_prefix     => $p{file_prefix}     || DEFAULT_FILE_PREFIX,
		file_loc_prefix => $p{file_loc_prefix} || $p{loc_prefix} || '',
		default_tag     => $p{default_tag}     || DEFAULT_TAG,
		index_name      => $p{index_name}      || DEFAULT_INDEX_NAME,
		mobile          => $p{mobile}          || 0,
		images          => $p{images}          || 0,
		namespace       => $p{namespace},
		charset         => $p{charset}         || 'utf8',

		move_from_temp_action => $p{move_from_temp_action}
	};

	if ($self->{file_size_limit} < FILE_SIZE_LIMIT_MIN) {
		$self->{file_size_limit} = FILE_SIZE_LIMIT_MIN;
	}

	if ($self->{namespace}) {
		if (ref $self->{namespace} eq '') {
			$self->{namespace} = [ $self->{namespace} ];
		}
		elsif (ref $self->{namespace} ne 'ARRAY') {
			die 'namespace must be scalar or array ref!';
		}
	}

	unless ($self->{output_dir}) {
		die 'output_dir expected!';
	}
	
	if ($self->{temp_dir} and not -w $self->{temp_dir}) {
		die sprintf "Can't write to temp_dir '%s' (error: %s)", $self->{temp_dir}, $!;
	}

	if ($self->{move_from_temp_action} and ref $self->{move_from_temp_action} ne 'CODE') {
		die 'move_from_temp_action must be code ref!';
	}

	return bless $self, $class;
}

sub add {
	my ($self, $url_list, %p) = @_;
	
	my $tag = $p{tag} || DEFAULT_TAG;

	if (ref $url_list ne 'ARRAY') {
		die __PACKAGE__.'::add($url_list): $url_list must be array ref';
	}

	for my $url (@$url_list) {
		my $data = (__PACKAGE__. '::Url')->new(	$url, 
			mobile     => $self->{mobile}, 
			loc_prefix => $self->{loc_prefix},
		)->to_xml_string;

		if ($self->_file_limit_near($tag, bytes::length $data)) {
			$self->_next_file($tag);
		}
		
		$self->_append_url($tag, $data);
	}
}

sub finish {
	my ($self, %p) = @_;

	return unless keys %{$self->{tags}};

	my $index_temp_file_name = $self->_temp_file->filename;
	open INDEX_FILE, '>' . $index_temp_file_name or die "Can't open file '$index_temp_file_name'! $!\n";

	print  INDEX_FILE XML_HEAD;
	printf INDEX_FILE "\n<sitemapindex %s>", XML_MAIN_NAMESPACE;

	while (my ($tag, $data) = each %{$self->{tags}}) {
		$self->_close_file($tag);
		for my $page (1 .. $data->{page}) {
			printf INDEX_FILE "\n<sitemap><loc>%s/%s</loc></sitemap>", $self->{file_loc_prefix}, $self->_file_name($tag, $page);
		}
	}

	print INDEX_FILE "\n</sitemapindex>";
	close INDEX_FILE;

	$self->_move_from_temp(
		$index_temp_file_name, 
		$self->{output_dir}. '/'. $self->{index_name}. '.xml'
	);
}

sub _move_from_temp {
	my ($self, $temp_file_name, $public_file_name) = @_;

	#printf "move %s -> %s\n", $temp_file_name, $public_file_name;

	if ($self->{move_from_temp_action}) {
		$self->{move_from_temp_action}($temp_file_name, $public_file_name);
	}
	else {
		File::Copy::move($temp_file_name, $public_file_name) 
			or die sprintf 'move %s -> %s error: %s', $temp_file_name, $public_file_name, $!;
	}
}

sub _file_limit_near {
	my ($self, $tag, $new_portion_size) = @_;

	return 0 unless defined $self->{tags}->{$tag};

	#printf("tag: %s.%d; url: %d; gzip_size: %d (%d)\n",
	#	$tag,
	#	$self->{tags}->{$tag}->{page},
	#	$self->{tags}->{$tag}->{url_count},
	#	$self->{tags}->{$tag}->{file_size},
	#	$self->{file_size_limit}
	#);

	return (
		$self->{tags}->{$tag}->{url_count} >= $self->{url_limit} 
		|| 
		($self->{tags}->{$tag}->{file_size} + $new_portion_size) >= ($self->{file_size_limit} - 200) # 200 - на закрывающие теги в конце файла (с запасом)
	);
}

sub _temp_file {
	my ($self) = @_;

	return File::Temp->new(
		UNLINK => 1, 
		$self->{temp_dir} 
			? ( DIR => $self->{temp_dir} ) 
			: ()
	);
}

sub _set_new_file {
	my ($self, $tag) = @_;
	
	my $temp_file = $self->_temp_file;

	$self->{tags}->{$tag}->{page}++;
	$self->{tags}->{$tag}->{url_count} = 0;
	$self->{tags}->{$tag}->{file_size} = 0;
	$self->{tags}->{$tag}->{file} = IO::Compress::Gzip->new($temp_file->filename) 
		or die "gzip failed: $GzipError\n";
	$self->{tags}->{$tag}->{file}->autoflush; 
	$self->{tags}->{$tag}->{temp_file} = $temp_file; 
	#
	# Не проверяем тут файл на превышение размера, потому что файл пустой,
	# и врядли начальные теги превысят хотябы 1Мб 
	#
	$self->_append(
		$tag, 
		sprintf(
			"%s\n<urlset %s>", 
				XML_HEAD, 
				join(' ', 
					XML_MAIN_NAMESPACE, 
					$self->{mobile}
						? XML_MOBILE_NAMESPACE
						: (),
					$self->{images}
						? XML_IMAGES_NAMESPACE
						: (),
					$self->{namespace} 
						? @{$self->{namespace}} 
						: ()
				)
		)
	);
}

sub _file_handle {
	my ($self, $tag) = @_;
	
	unless (exists $self->{tags}->{$tag}) {
		$self->_set_new_file($tag);
	}

	return $self->{tags}->{$tag}->{file};
}

sub _append {
	my ($self, $tag, $data) = @_;

	$self->_file_handle($tag)->print(Encode::encode($self->{charset}, $data));
	$self->{tags}->{$tag}->{file_size} += bytes::length $data;
}

sub _append_url {
	my ($self, $tag, $data) = @_;

	$self->_append($tag, $data);
	$self->{tags}->{$tag}->{url_count}++;
}

sub _next_file {
	my ($self, $tag) = @_;

	$self->_close_file($tag);
	$self->_set_new_file($tag);
}

sub _close_file {
	my ($self, $tag) = @_;

	$self->_append($tag, "\n</urlset>");
	$self->_file_handle($tag)->close;
	
	$self->_move_from_temp(
		$self->{tags}->{$tag}->{temp_file}->filename,
		$self->{output_dir}. '/'. $self->_file_name($tag)
	);
}

sub _file_name {
	my ($self, $tag, $page) = @_;
	return $self->{file_prefix}. $tag. '.'. ($page || $self->{tags}->{$tag}->{page}). '.xml.gz';
}

1;


=head1 DESCRIPTION

Also support for Google images format:

	my @img_urls = (
		
		# Foramt 1
		{ 
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
		},

		# Foramt 2
		{ 
			loc => 'http://test11.ru/', 
			images => { 
				caption_format_simple => 'Vasya - foto',
				loc_list => ['http://img11.ru/', 'http://img21.ru'] 
			} 
		},

		# Format 3
		{ 
			loc => 'http://test122.ru/', 
			images => { 
				loc_list => [
					{ loc => 'http://img122.ru/', caption => 'image #1' },
					{ loc => 'http://img133.ru/', caption => 'image #2' },
					{ loc => 'http://img144.ru/', caption => 'image #3' },
					{ loc => 'http://img222.ru', caption => 'image #4' }
				] 
			} 
		}
	);


	# Result:

	<?xml version="1.0" encoding="UTF-8"?>
	<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>http://test1.ru/</loc>
		<image:image>
			<loc>http://img1.ru/</loc>
			<caption><![CDATA[Vasya - foto 1]]></caption>
		</image:image>
		<image:image>
			<loc>http://img2.ru</loc>
			<caption><![CDATA[Vasya - foto 2]]></caption>
		</image:image>
	</url>
	<url>
		<loc>http://test11.ru/</loc>
		<image:image>
			<loc>http://img11.ru/</loc>
			<caption><![CDATA[Vasya - foto 1]]></caption>
		</image:image>
		<image:image>
			<loc>http://img21.ru</loc>
			<caption><![CDATA[Vasya - foto 2]]></caption>
		</image:image>
	</url>
	<url>
		<loc>http://test122.ru/</loc>
		<image:image>
			<loc>http://img122.ru/</loc>
			<caption><![CDATA[image #1]]></caption>
		</image:image>
		<image:image>
			<loc>http://img133.ru/</loc>
			<caption><![CDATA[image #2]]></caption>
		</image:image>
		<image:image>
			<loc>http://img144.ru/</loc>
			<caption><![CDATA[image #3]]></caption>
		</image:image>
		<image:image>
			<loc>http://img222.ru</loc>
			<caption><![CDATA[image #4]]></caption>
		</image:image>
	</url>
	</urlset>

=cut

=head1 AUTHOR

Mikhail N Bogdanov C<< <mbogdanov at cpan.org > >>

=cut

