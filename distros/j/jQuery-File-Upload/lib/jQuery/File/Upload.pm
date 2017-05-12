package jQuery::File::Upload;

use 5.008008;
use strict;
#use warnings;

use CGI;
use JSON::XS;
use JSON;
use Net::SSH2;
use Net::SSH2::SFTP;
use Image::Magick;
use Cwd 'abs_path';
use URI;
use Data::GUID;

#use LWP::UserAgent;
#use LWP::Protocol::https;

our $VERSION = '0.30';

my %errors =  (
	'_validate_max_file_size' => 'File is too big',
	'_validate_min_file_size' => 'File is too small',
	'_validate_accept_file_types' => 'Filetype not allowed',
	'_validate_reject_file_types' => 'Filetype not allowed',
	'_validate_max_number_of_files' => 'Maximum number of files exceeded',
	'_validate_max_width' => 'Image exceeds maximum width',
	'_validate_min_width' => 'Image requires a minimum width',
	'_validate_max_height' => 'Image exceeds maximum height',
	'_validate_min_height' => 'Image requires a minimum height'
);

#GETTERS/SETTERS
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
		field_name => 'files[]',
		ctx => undef,
		cgi	=> undef,
		thumbnail_width => 80,
		thumbnail_height => 80,
		thumbnail_quality => 70,
		thumbnail_format => 'jpg',
		thumbnail_density => undef,
		format => 'jpg',
		quality => 70,

		process_images => 1,
		thumbnail_filename => undef,
		thumbnail_prefix => 'thumb_',
		thumbnail_postfix => '',
		filename => undef,
		client_filename => undef,
		show_client_filename => 1,
		use_client_filename => undef,
		filename_salt => '',
		copy_file => 0,
		script_url => undef,
		tmp_dir => '/tmp',
		should_delete => 1,

		absolute_filename => undef,
		absolute_thumbnail_filename => undef,

		delete_params => [],

		upload_dir => undef,
		thumbnail_upload_dir => undef,
		upload_url_base => undef,
		thumbnail_url_base => undef,
		relative_url_path => '/files',
		thumbnail_relative_url_path => undef,
		relative_to_host => undef,
		delete_url => undef,

		data => {},

		#callbacks
		post_delete => sub {},
		post_post => sub {},
		post_get => sub {},

		#pre calls
		pre_delete => sub {},
		pre_post => sub {},
		pre_get => sub {},

		#scp/rcp login info
		scp => [],

		#user validation specifications
		max_file_size => undef,
		min_file_size => 1,
		accept_file_types => [],
		reject_file_types => [],
		require_image => undef,
		max_width => undef,
		max_height => undef,
		min_width => 1,
		min_height => 1,
		max_number_of_files => undef,

		#not to be used by users
		output => undef,
		handle => undef,
		tmp_filename => undef,
		fh => undef,
		error => undef,
		upload => undef,
		file_type => undef,
		is_image => undef,
		image_magick => undef,
		width => undef,
		height => undef,
		num_files_in_dir => undef,
		user_error => undef,
        @_,                 # Override previous attributes
    };
    return bless $self, $class;
}

sub upload_dir {
	my $self = shift;

  if (@_) {
 		$self->{upload_dir} = shift;
  }

	#set upload_dir to directory of this script if not provided
	if(!(defined $self->{upload_dir})) {
		$self->{upload_dir} = abs_path($0);
		$self->{upload_dir} =~ s/(.*)\/.*/$1/;
		$self->{upload_dir} .= '/files';
	}

	return $self->{upload_dir};
}

sub thumbnail_upload_dir {
	my $self = shift;

  if (@_) {
	  $self->{thumbnail_upload_dir} = shift;
  }

	#set upload_dir to directory of this script if not provided
	if(!(defined $self->{thumbnail_upload_dir})) {
			$self->{thumbnail_upload_dir} = $self->upload_dir;
	}

	return $self->{thumbnail_upload_dir};
}

sub upload_url_base {
	my $self = shift;

  if (@_) {
  	$self->{upload_url_base} = shift;
  }

	if(!(defined $self->{upload_url_base})) {
		$self->{upload_url_base} = $self->_url_base . $self->relative_url_path;
	}

	return $self->{upload_url_base};
}

sub _url_base {
	my $self = shift;
	my $url;

	if($self->relative_to_host) {
		$url = $self->{uri}->scheme . '://' . $self->{uri}->host;
	}
	else {
		$url = $self->script_url;
		$url =~ s/(.*)\/.*/$1/;
	}

	return $url;
}

sub thumbnail_url_base {
	my $self = shift;

	if (@_) {
 	 $self->{thumbnail_url_base} = shift;
  }

	if(!(defined $self->{thumbnail_url_base})) {
		if(defined $self->thumbnail_relative_url_path) {
			$self->{thumbnail_url_base} = $self->_url_base . $self->thumbnail_relative_url_path;
		}
		else {
			$self->{thumbnail_url_base} = $self->upload_url_base;
		}
	}

	return $self->{thumbnail_url_base};
}


sub relative_url_path {
	my $self = shift;

	if(@_) {
		$self->{relative_url_path} = shift;
	}

	return $self->{relative_url_path};
}

sub thumbnail_relative_url_path {
	my $self = shift;

	if(@_) {
		$self->{thumbnail_relative_url_path} = shift;
	}

	return $self->{thumbnail_relative_url_path};
}

sub relative_to_host {
	my $self = shift;

	if(@_) {
		$self->{relative_to_host} = shift;
	}

	return $self->{relative_to_host};
}



sub field_name {
	my $self = shift;

    if (@_) {
        $self->{field_name} = shift;
    }

	return $self->{field_name};
}

sub ctx {
	my $self = shift;

    if (@_) {
        $self->{ctx} = shift;
    }

	return $self->{ctx};
}

sub cgi {
	my $self = shift;

    if (@_) {
	    $self->{cgi} = shift;
    }
	$self->{cgi} = CGI->new unless defined $self->{cgi};

	return $self->{cgi};
}

sub should_delete {
	my $self = shift;

    if (@_) {
        $self->{should_delete} = shift;
    }

	return $self->{should_delete};
}

sub scp {
	my $self = shift;

    if (@_) {
        $self->{scp} = shift;
    }

	return $self->{scp};
}

sub max_file_size {
	my $self = shift;

    if (@_) {
        $self->{max_file_size} = shift;
    }

	return $self->{max_file_size};
}

sub min_file_size {
	my $self = shift;

    if (@_) {
        $self->{min_file_size} = shift;
    }

	return $self->{min_file_size};
}

sub accept_file_types {
	my $self = shift;

  if (@_) {
	my $a_ref = shift;
	die "accept_file_types must be an array ref" unless UNIVERSAL::isa($a_ref,'ARRAY');
   	$self->{accept_file_types} = $a_ref;
  }

	if(scalar(@{$self->{accept_file_types}}) == 0 and $self->require_image) {
		$self->{accept_file_types} = ['image/jpeg','image/jpg','image/png','image/gif'];
	}

	return $self->{accept_file_types};
}

sub reject_file_types {
	my $self = shift;

	if (@_) {
		my $a_ref = shift;
		die "reject_file_types must be an array ref" unless UNIVERSAL::isa($a_ref,'ARRAY');
		$self->{reject_file_types} = $a_ref;
	}

	return $self->{reject_file_types};
}

sub require_image {
	my $self = shift;

  if (@_) {
   	$self->{require_image} = shift;
  }

	return $self->{require_image};
}

sub delete_params {
	my $self = shift;

    if (@_) {
		my $a_ref = shift;
		die "delete_params must be an array ref" unless UNIVERSAL::isa($a_ref,'ARRAY');
        $self->{delete_params} = $a_ref;
    }

	return $self->{delete_params};
}

sub delete_url {
	my $self = shift;

	if(@_) {
		$self->{delete_url} = shift;
	}

	return $self->{delete_url};
}

sub thumbnail_width {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_width} = shift;
    }

	return $self->{thumbnail_width};
}

sub thumbnail_height {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_height} = shift;
    }

	return $self->{thumbnail_height};
}

sub thumbnail_quality {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_quality} = shift;
    }

	return $self->{thumbnail_quality};
}

sub thumbnail_format {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_format} = shift;
    }

	return $self->{thumbnail_format};
}

sub thumbnail_density {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_density} = shift;
    }

	return $self->{thumbnail_density};
}

sub thumbnail_prefix {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_prefix} = shift;
    }

	return $self->{thumbnail_prefix};
}

sub thumbnail_postfix {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_postfix} = shift;
    }

	return $self->{thumbnail_postfix};
}

sub thumbnail_final_width {
	my $self = shift;

	if(@_) {
		$self->{thumbnail_final_width} = shift;
	}

	return $self->{thumbnail_final_width};
}

sub thumbnail_final_height {
	my $self = shift;

	if(@_) {
		$self->{thumbnail_final_height} = shift;
	}

	return $self->{thumbnail_final_height};
}

sub quality {
	my $self = shift;

    if (@_) {
        $self->{quality} = shift;
    }

	return $self->{quality};
}

sub format {
	my $self = shift;

    if (@_) {
        $self->{format} = shift;
    }

	return $self->{format};
}

sub final_width {
	my $self = shift;

	if(@_) {
		$self->{final_width} = shift;
	}

	return $self->{final_width};
}

sub final_height {
	my $self = shift;

	if(@_) {
		$self->{final_height} = shift;
	}

	return $self->{final_height};
}

sub max_width {
	my $self = shift;

    if (@_) {
        $self->{max_width} = shift;
    }

	return $self->{max_width};
}

sub max_height {
	my $self = shift;

    if (@_) {
        $self->{max_height} = shift;
    }

	return $self->{max_height};
}

sub min_width {
	my $self = shift;

    if (@_) {
        $self->{min_width} = shift;
    }

	return $self->{min_width};
}

sub min_height {
	my $self = shift;

    if (@_) {
        $self->{min_height} = shift;
    }

	return $self->{min_height};
}

sub max_number_of_files {
	my $self = shift;

    if (@_) {
        $self->{max_number_of_files} = shift;
    }

	return $self->{max_number_of_files};
}

sub filename {
	my $self = shift;

    if (@_) {
        $self->{filename} = shift;
    }

	return $self->{filename};
}

sub absolute_filename {
	my $self = shift;

    if (@_) {
        $self->{absolute_filename} = shift;
    }

	return $self->{absolute_filename};
}

sub thumbnail_filename {
	my $self = shift;

    if (@_) {
        $self->{thumbnail_filename} = shift;
    }

	return $self->{thumbnail_filename};
}

sub absolute_thumbnail_filename {
	my $self = shift;

    if (@_) {
        $self->{absolute_thumbnail_filename} = shift;
    }

	return $self->{absolute_thumbnail_filename};
}

sub client_filename {
	my $self = shift;

    if (@_) {
        $self->{client_filename} = shift;
    }

	return $self->{client_filename};
}

sub show_client_filename {
	my $self = shift;

    if (@_) {
        $self->{show_client_filename} = shift;
    }

	return $self->{show_client_filename};
}

sub use_client_filename {
	my $self = shift;

    if (@_) {
        $self->{use_client_filename} = shift;
    }

	return $self->{use_client_filename};
}

sub filename_salt {
	my $self = shift;

    if (@_) {
        $self->{filename_salt} = shift;
    }

	return $self->{filename_salt};
}

sub tmp_dir {
	my $self = shift;

    if (@_) {
        $self->{tmp_dir} = shift;
    }

	return $self->{tmp_dir};
}

sub script_url {
	my $self = shift;

    if (@_) {
        $self->{script_url} = shift;
    }

	if(!(defined $self->{script_url})) {
		if(defined $self->ctx) {
			$self->{script_url} = $self->ctx->request->uri;
		}
		else {
			$self->{script_url} = $ENV{SCRIPT_URI};
		}
	}

	return $self->{script_url};
}

sub data {
	my $self = shift;

	if(@_) {
		$self->{data} = shift;
	}

	return $self->{data};
}

sub process_images {
	my $self = shift;

    if (@_) {
        $self->{process_images} = shift;
    }

	return $self->{process_images};
}

sub copy_file {
	my $self = shift;

    if (@_) {
        $self->{copy_file} = shift;
    }

	return $self->{copy_file};
}

#GETTERS
sub output { shift->{output} }
sub url { shift->{url} }
sub thumbnail_url { shift->{thumbnail_url} }
sub is_image { shift->{is_image} }
sub size { shift->{file_size} }

#OTHER METHODS
sub print_response {
	my $self = shift;

	my $content_type = 'text/plain';
	if(defined $self->ctx) {

		#thanks to Lukas Rampa for this suggestion
  		if ($self->ctx->req->headers->header('Accept') =~ qr(application/json) ) {
	  		$content_type = 'application/json';
  		}

		$self->ctx->stash->{current_view} = '';
		$self->ctx->res->content_type("$content_type; charset=utf-8");
		$self->ctx->res->body($self->output . ""); #concatenate "" for when there is no output
	}
	else {
		print "Content-type: $content_type\n\n";
		print $self->output;
	}
}

sub handle_request {
	my $self = shift;
	my ($print) = @_;

	my $method = $self->_get_request_method;

	if($method eq 'GET') {
		&{$self->pre_get}($self);
		&{$self->post_get}($self);
	}
	elsif($method eq 'PATCH' or $method eq 'POST' or $method eq 'PUT') {
		$self->{user_error} = &{$self->pre_post}($self);
		unless($self->{user_error}) {
			$self->_post;
			&{$self->post_post}($self);
		}
		else { $self->_generate_output }
	}
	elsif($method eq 'DELETE') {
		$self->{user_error} = &{$self->pre_delete}($self); #even though we may not delete, we should give user option to still run code
		if(not $self->{user_error} and $self->should_delete) {
			$self->_delete;
			&{$self->post_delete}($self);
		}
		else { $self->_generate_output }
	}
	else {
		$self->_set_status(405);
	}

	$self->print_response if $print;
	$self->_clear;
}

sub generate_output {
	my $self = shift;
	my ($arr_ref) = @_;

	#necessary if we are going to use _url_base via thumbnail_url_base and upload_url_base
	$self->_set_uri;

	my @arr;
	for(@$arr_ref) {
		my %h;
		die "Must provide a filename in generate_output" unless exists $_->{filename};
		die "Must provide a size in generate_output" unless exists $_->{size};
		$self->{is_image} = $self->process_images && $_->{image} eq 'y' ? 1 : 0;
		$h{size} = $_->{size};
		$h{error} = $_->{error};

		if(exists $_->{'name'}) {
			$h{name} = $_->{name}
		}
		else {
			$h{name} = $_->{filename};
		}

		if($_->{filename}) {
			$self->filename($_->{filename});
		}

		if(exists $_->{thumbnail_filename}) {
			$self->thumbnail_filename($_->{thumbnail_filename});
		}
		else {
			my $no_ext = $self->_no_ext;
			$self->thumbnail_filename($self->thumbnail_prefix . $no_ext . $self->thumbnail_postfix . '.' . $self->thumbnail_format);
		}

		$self->_set_urls;
		$h{url} = $_->{url} eq '' ? $self->url : $_->{url};
		$h{thumbnailUrl} = $_->{thumbnailUrl} eq '' ? $self->thumbnail_url : $_->{thumbnailUrl};

		$h{deleteUrl} = $_->{'deleteUrl'} eq '' ? $self->_delete_url($_->{delete_params}) : $_->{'deleteUrl'};
		$h{deleteType} = 'DELETE';
		push @arr, \%h;

		#reset for the next time around
		$self->delete_url('');
	}

	#they should provide image=y or image=n if image
	my $json = JSON::XS->new->ascii->pretty->allow_nonref;
	$self->{output} = $json->encode({files => \@arr});
}

sub _no_ext {
	my $self = shift;
	$self->filename($_->{filename});
	my ($no_ext) = $self->filename =~ qr/(.*)\.(.*)/;
	return $no_ext;
}

#PRE/POST METHODS
sub pre_delete {
	my $self = shift;

    if (@_) {
        $self->{pre_delete} = shift;
    }

	return $self->{pre_delete};
}

sub post_delete {
	my $self = shift;

    if (@_) {
        $self->{post_delete} = shift;
    }

	return $self->{post_delete};
}

sub pre_post {
	my $self = shift;

    if (@_) {
        $self->{pre_post} = shift;
    }

	return $self->{pre_post};
}

sub post_post {
	my $self = shift;

    if (@_) {
        $self->{post_post} = shift;
    }

	return $self->{post_post};
}

sub pre_get {
	my $self = shift;

    if (@_) {
        $self->{pre_get} = shift;
    }

	return $self->{pre_get};
}

sub post_get {
	my $self = shift;

    if (@_) {
        $self->{post_get} = shift;
    }

	return $self->{post_get};
}

sub _clear {
	my $self = shift;

	#clear cgi object so we get a new one for new request
	$self->{cgi} = undef;
	$self->{handle} = undef;
	$self->{tmp_filename} = undef;
	$self->{upload} = undef;
	$self->{fh} = undef;
	$self->{file_size} = undef;
	$self->{error} = undef;
	$self->{file_type} = undef;
	$self->{is_image} = 0;
	$self->{width} = undef;
	$self->{height} = undef;
	$self->{num_files_in_dir} = undef;
	$self->{output} = undef;
	$self->{client_filename} = undef;
	$self->{tmp_thumb_path} = undef;
	$self->{tmp_file_path} = undef;
	$self->{user_error} = undef;
}

sub _post {
	my $self = shift;

	if($self->_prepare_file_attrs and $self->_validate_file) {
		if($self->is_image) {
			$self->_create_thumbnail;
			$self->_create_tmp_image
		}
		$self->_save;
	}

	#delete temporary files
	if($self->is_image) {
		unlink ($self->{tmp_thumb_path}, $self->{tmp_file_path});
	}

	#generate json output
	$self->_generate_output;
}

sub _generate_output {
	my $self = shift;

	my $method = $self->_get_request_method;
	my $obj;

	if($method eq 'POST') {
		my %hash;
		unless($self->{user_error}) {
			$hash{'url'} = $self->url;
			$hash{'thumbnailUrl'} = $self->thumbnail_url;
			$hash{'deleteUrl'} = $self->_delete_url;
			$hash{'deleteType'} = 'DELETE';
			$hash{error} = $self->_generate_error;
		}
		else {
			$self->_prepare_file_basics;
			$hash{error} = $self->{user_error};
		}

		$hash{'name'} = $self->show_client_filename ? $self->client_filename . "" : $self->filename;
		$hash{'size'} = $self->{file_size};
		$obj->{files} = [\%hash];
	}
	elsif($method eq 'DELETE') {
		unless($self->{user_error}) {
			$obj->{$self->_get_param('filename')} = JSON::true;
		}
		else {
			$obj->{error} = $self->{user_error};
		}
	}

	my $json = JSON::XS->new->ascii->pretty->allow_nonref;
	$self->{output} = $json->encode($obj);
}

sub _delete {
	my $self = shift;

	my $filename = $self->_get_param('filename');
	my $thumbnail_filename = $self->_get_param('thumbnail_filename');
	my $image_yn = $self->_get_param('image');

	if(@{$self->scp}) {
		for(@{$self->scp}) {

			my $ssh2 = $self->_auth_user($_);
			$_->{thumbnail_upload_dir} = $_->{upload_dir} if $_->{thumbnail_upload_dir} eq '';

			my $sftp = $ssh2->sftp;
			$sftp->unlink($_->{upload_dir} . '/' . $filename);
			$sftp->unlink($_->{thumbnail_upload_dir} . '/' . $thumbnail_filename) if $image_yn eq 'y';
		}
	}
	else {
		my $no_ext = $self->_no_ext;
		unlink $self->upload_dir . '/' . $filename;
		unlink($self->thumbnail_upload_dir . '/' . $thumbnail_filename) if $image_yn eq 'y';
	}

	$self->_generate_output;
}

sub _get_param {
	my $self = shift;
	my ($param) = @_;

	if(defined $self->ctx) {
		return $self->ctx->req->params->{$param};
	}
	else {
		return $self->cgi->param($param);
	}
}

sub _delete_url {
	my $self = shift;
	return if $self->delete_url ne '';
	my ($delete_params) = @_;

	my $url = $self->script_url;
	my $uri = $self->{uri}->clone;

	my $image_yn = $self->is_image ? 'y' : 'n';

	unless(defined $delete_params and scalar(@$delete_params)) {
		$delete_params = [];
	}

	push @$delete_params, @{$self->delete_params} if @{$self->delete_params};
	push @$delete_params, ('filename',$self->filename,'image',$image_yn);
	push @$delete_params, ('thumbnail_filename',$self->thumbnail_filename) if $self->is_image;

	$uri->query_form($delete_params);

	$self->delete_url($uri->as_string);

	return $self->delete_url;
}

sub _script_url {
	my $self = shift;

	if(defined $self->ctx) {
		return $self->ctx->request->uri;
	}
	else {
		return $ENV{'SCRIPT_URI'};
	}
}

sub _prepare_file_attrs {
	my $self = shift;

	#ORDER MATTERS
	return unless $self->_prepare_file_basics;
	$self->_set_tmp_filename;
	$self->_set_file_type;
	$self->_set_is_image;
	$self->_set_filename;
	$self->_set_absolute_filenames;
	$self->_set_image_magick;
	$self->_set_width;
	$self->_set_height;
	$self->_set_num_files_in_dir;
	$self->_set_uri;
	$self->_set_urls;

	return 1;
}

sub _prepare_file_basics {
	my ($self) = @_;

	return undef unless $self->_set_upload_obj;
	$self->_set_fh;
	$self->_set_file_size;
	$self->_set_client_filename;

	return 1;
}

sub _set_urls {
	my $self = shift;

	if($self->is_image) {
		$self->{thumbnail_url} = $self->thumbnail_url_base . '/' . $self->thumbnail_filename;
	}
	$self->{url} = $self->upload_url_base . '/' . $self->filename;
}

sub _set_uri {
	my $self = shift;
	#if catalyst, use URI already made?
	if(defined $self->ctx) {
		$self->{uri} = $self->ctx->req->uri;
	}
	else {
		$self->{uri} = URI->new($self->script_url);
	}
}

sub _generate_error {
	my $self = shift;
	return undef unless defined $self->{error} and @{$self->{error}};

	my $restrictions = join ',', @{$self->{error}->[1]};
	return $errors{$self->{error}->[0]} . " Restriction: $restrictions Provided: " . $self->{error}->[2];
}

sub _validate_file {
	my $self = shift;
	return undef unless
	$self->_validate_max_file_size and
	$self->_validate_min_file_size and
	$self->_validate_accept_file_types and
	$self->_validate_reject_file_types and
	$self->_validate_max_width and
	$self->_validate_min_width and
	$self->_validate_max_height and
	$self->_validate_min_height and
	$self->_validate_max_number_of_files;

	return 1;
}

sub _save {
	my $self = shift;

	if(@{$self->scp}) {
		$self->_save_scp;
	}
	else {
		$self->_save_local;
	}
}

sub _save_scp {
	my $self = shift;

	for(@{$self->scp}) {
		die "Must provide a host to scp" if $_->{host} eq '';

		$_->{thumbnail_upload_dir} = $_->{upload_dir} if $_->{thumbnail_upload_dir} eq '';

		my $path = $_->{upload_dir} . '/' . $self->filename;
		my $thumb_path = $_->{thumbnail_upload_dir} . '/' . $self->thumbnail_filename;

		if(($_->{user} ne '' and $_->{public_key} ne '' and $_->{private_key} ne '') or ($_->{user} ne '' and $_->{password} ne '')) {
			my $ssh2 = $self->_auth_user($_);

			#if it is an image, scp both file and thumbnail
			if($self->is_image) {
				$ssh2->scp_put($self->{tmp_file_path}, $path);
				$ssh2->scp_put($self->{tmp_thumb_path}, $thumb_path);
			}
			else {
				$ssh2->scp_put($self->{tmp_filename}, $path);
			}

			$ssh2->disconnect;
		}
		else {
			die "Must provide a user and password or user and identity file for connecting to host";
		}

	}
}

sub _auth_user {
	my $self = shift;
	my ($auth) = @_;

	my $ssh2 = Net::SSH2->new;

	$ssh2->connect($auth->{host}) or die $!;

	#authenticate
	if($auth->{user} ne '' and $auth->{public_key} ne '' and $auth->{private_key} ne '') {
		$ssh2->auth_publickey($auth->{user},$auth->{public_key},$auth->{private_key});
	}
	else {
		$ssh2->auth_password($auth->{user},$auth->{password});
	}

	unless($ssh2->auth_ok) {
		die "error authenticating with remote server";
	}

	die "upload directory must be provided with scp hash" if $auth->{upload_dir} eq '';

	return $ssh2;
}

sub _save_local {
	my $self = shift;

	#if image
	if($self->is_image) {
		rename $self->{tmp_file_path}, $self->absolute_filename;
		rename $self->{tmp_thumb_path}, $self->absolute_thumbnail_filename;
	}
	#if non-image with catalyst
	elsif(defined $self->ctx) {
		if ($self->copy_file) {
			$self->{upload}->copy_to($self->absolute_filename);
		} else {
			$self->{upload}->link_to($self->absolute_filename);
		}
	}
	#if non-image with regular CGI perl
	else {
		my $io_handle = $self->{fh}->handle;

		my $buffer;
		open (OUTFILE,'>', $self->absolute_filename);
		while (my $bytesread = $io_handle->read($buffer,1024)) {
			print OUTFILE $buffer;
		}

		close OUTFILE;
	}
}

sub _validate_max_file_size {
	my $self = shift;
	return 1 unless $self->max_file_size;

	if($self->{file_size} > $self->max_file_size) {
		$self->{error} = ['_validate_max_file_size',[$self->max_file_size],$self->{file_size}];
		return undef;
	}
	else {
		return 1;
	}
}

sub _validate_min_file_size {
	my $self = shift;
	return 1 unless $self->min_file_size;

	if($self->{file_size} < $self->min_file_size) {
		$self->{error} = ['_validate_min_file_size',[$self->min_file_size],$self->{file_size}];
		return undef;
	}
	else {
		return 1;
	}
}

sub _validate_accept_file_types {
	my $self = shift;

	#if accept_file_types is empty, we except all types
	#so return true
	return 1 unless @{$self->accept_file_types};

	if(grep { $_ eq $self->{file_type} } @{$self->{accept_file_types}}) {
		return 1;
	}
	else {
		my $types = join ",", @{$self->accept_file_types};
		$self->{error} = ['_validate_accept_file_types',[$types],$self->{file_type}];
		return undef;
	}
}

sub _validate_reject_file_types {
	my $self = shift;

	#if reject_file_types is empty, we except all types
	#so return true
	return 1 unless @{$self->reject_file_types};

	unless(grep { $_ eq $self->{file_type} } @{$self->{reject_file_types}}) {
		return 1;
	}
	else {
		my $types = join ",", @{$self->reject_file_types};
		$self->{error} = ['_validate_reject_file_types',[$types],$self->{file_type}];
		return undef;
	}
}

sub _validate_max_width {
	my $self = shift;
	return 1 unless $self->is_image;

	#if set to undef, there's no max_width
	return 1 unless $self->max_width;

	if($self->{width} > $self->max_width) {
		$self->{error} = ['_validate_max_width',[$self->max_width],$self->{width}];
		return undef;
	}
	else {
		return 1;
	}
}

sub _validate_min_width {
	my $self = shift;
	return 1 unless $self->is_image;

	#if set to undef, there's no min_width
	return 1 unless $self->min_width;

	if($self->{width} < $self->min_width) {
		$self->{error} = ['_validate_min_width',[$self->min_width],$self->{width}];
		return undef;
	}
	else {
		return 1;
	}
}

sub _validate_max_height {
	my $self = shift;
	return 1 unless $self->is_image;

	#if set to undef, there's no max_height
	return 1 unless $self->max_height;

	if($self->{height} > $self->max_height) {
		$self->{error} = ['_validate_max_height',[$self->max_height],$self->{height}];
		return undef;
	}
	else {
		return 1;
	}
}

sub _validate_min_height {
	my $self = shift;
	return 1 unless $self->is_image;

	#if set to undef, there's no max_height
	return 1 unless $self->min_height;

	if($self->{height} < $self->min_height) {
		$self->{error} = ['_validate_min_height',[$self->min_height],$self->{height}];
		return undef;
	}
	else {
		return 1;
	}
}

sub _validate_max_number_of_files {
	my $self = shift;
	return 1 unless $self->max_number_of_files;

	if($self->{num_files_in_dir} > $self->max_number_of_files) {
		$self->{error} = ['_validate_max_number_of_files',[$self->max_number_of_files],$self->{num_files_in_dir}];
		return undef;
	}
	else {
		return 1;
	}
}

sub _set_file_size {
	my $self = shift;

	if(defined $self->ctx) {
		$self->{file_size} = $self->{upload}->size;
	}
	else {
		$self->{file_size} = -s $self->{upload};
	}

	return $self->{file_size};
}

sub _set_client_filename {
	my $self = shift;
	return if defined $self->client_filename;

	if(defined $self->ctx) {
		$self->client_filename($self->{upload}->filename);
	}
	else {
		$self->client_filename($self->cgi->param($self->field_name));
	}

	return $self->client_filename;
}

sub _set_filename {
	my $self = shift;
	return if defined $self->filename;

	if($self->use_client_filename) {
		$self->filename($self->client_filename);
	}
	else {
		my $filename = Data::GUID->new->as_string . $self->filename_salt;
		$self->thumbnail_filename($self->thumbnail_prefix . $filename . $self->thumbnail_postfix . '.' . $self->thumbnail_format) unless $self->thumbnail_filename;

		if($self->is_image) {
			$filename .= '.' . $self->format;
		}
		else {
			#add extension if present
			if($self->client_filename =~ qr/.*\.(.*)/) {
				$filename .= '.' . $1;
			}
		}
		$self->filename($filename) unless $self->filename;
	}

	return $self->filename;
}

sub _set_absolute_filenames {
	my $self = shift;

	$self->absolute_filename($self->upload_dir . '/' . $self->filename) unless $self->absolute_filename;
	$self->absolute_thumbnail_filename($self->thumbnail_upload_dir . '/' . $self->thumbnail_filename) unless $self->absolute_thumbnail_filename;
}

sub _set_file_type {
	my $self = shift;

	if(defined $self->ctx) {
		$self->{file_type} = $self->{upload}->type;
	}
	else {
		$self->{file_type} = $self->cgi->uploadInfo($self->client_filename)->{'Content-Type'};
	}

	return $self->{file_type};
}

sub _set_is_image {
	my $self = shift;

	if($self->process_images and ($self->process_images and ($self->{file_type} eq 'image/jpeg' or $self->{file_type} eq 'image/jpg' or $self->{file_type} eq 'image/png' or $self->{file_type} eq 'image/gif'))) {
		$self->{is_image} = 1;
	}
	else {
		$self->{is_image} = 0;
	}

	return $self->is_image;
}

sub _set_image_magick {
	my $self = shift;
	return unless $self->is_image;

	#if used in persistent setting, don't recreate object
	$self->{image_magick} = Image::Magick->new unless defined $self->{image_magick};

	$self->{image_magick}->Read(file => $self->{fh});

	return $self->{image_magick};
}

sub _set_width {
	my $self = shift;
	return unless $self->is_image;

	$self->{width} = $self->{image_magick}->Get('width');
}

sub _set_height {
	my $self = shift;
	return unless $self->is_image;

	$self->{height} = $self->{image_magick}->Get('height');
}

sub _set_tmp_filename {
	my $self = shift;

	my $tmp_filename;
	if(defined $self->ctx) {
		$self->{tmp_filename} = $self->{upload}->tempname;
	}
	else {
		$self->{tmp_filename} = $self->cgi->tmpFileName($self->client_filename);
	}
}

sub _set_upload_obj {
	my $self = shift;

	if(defined $self->ctx) {
		$self->{upload} = $self->ctx->request->upload($self->field_name);
	}
	else {
		$self->{upload} = $self->cgi->upload($self->field_name);
	}

	return defined $self->{upload};
}

sub _set_fh {
	my $self = shift;

	if(defined $self->ctx) {
		$self->{fh} = $self->{upload}->fh;
	}
	else {
		$self->{fh} = $self->{upload};
	}

	return $self->{fh};
}

sub _set_num_files_in_dir {
	my $self = shift;
	return unless $self->max_number_of_files;

	#DO SCP VERSION
	if(@{$self->{scp}}) {
		my $max = 0;
		for(@{$self->{scp}}) {
			my $ssh2 = $self->_auth_user($_);
			my $chan = $ssh2->channel();
			$chan->exec('ls -rt ' . $_->{upload_dir} . ' | wc -l');
			my $buffer;
			$chan->read($buffer,1024);
			($self->{num_files_in_dir}) = $buffer =~ qr/(\d+)/;
			$max = $self->{num_files_in_dir} if $self->{num_files_in_dir} > $max;
		}

		#set to maximum of hosts because we know if one's over that's too many
		$self->{num_files_in_dir} = $max;
	}
	else {
		my $dir = $self->upload_dir;
		my @files = <$dir/*>;
	   	$self->{num_files_in_dir} = @files;
	}

	return $self->{num_files_in_dir};
}

sub _get_request_method {
	my $self = shift;

	my $method = '';
	if(defined $self->ctx) {
		$method = $self->ctx->req->method;
	}
	else {
		$method = $self->cgi->request_method;
	}

	return $method;
}

sub _set_status {
	my $self = shift;
	my ($response) = @_;

	if(defined $self->ctx) {
		$self->ctx->response->status($response);
	}
	else {
		print $self->cgi->header(-status=>$response);
	}
}

sub _set_header {
	my $self = shift;
	my ($key,$val) = @_;

	if(defined $self->ctx) {
		$self->ctx->response->header($key => $val);
	}
	else {
		print $self->cgi->header($key,$val);
	}
}

sub _create_thumbnail {
  my $self = shift;

  my $im = $self->{image_magick}->Clone;

	#thumb is added at beginning of tmp_thumb_path as to not clash with the original image file path
  my $output  = $self->{tmp_thumb_path} = $self->tmp_dir . '/thumb_' . $self->thumbnail_filename;
  my $width   = $self->thumbnail_width;
  my $height  = $self->thumbnail_height;

  my $density = $self->thumbnail_density || $width . "x" . $height;
  my $quality = $self->thumbnail_quality;
  my $format  = $self->thumbnail_format;

  # source image dimensions
  my ($o_width, $o_height) = $im->Get('width','height');

  # calculate image dimensions required to fit onto thumbnail
  my ($t_width, $t_height, $ratio);
  # wider than tall (seems to work...) needs testing
  if( $o_width > $o_height ){
    $ratio = $o_width / $o_height;
    $t_width = $width;
    $t_height = $width / $ratio;

    # still won't fit, find the smallest size.
    while($t_height > $height){
      $t_height -= $ratio;
      $t_width -= 1;
    }
  }
  # taller than wide
  elsif( $o_height > $o_width ){
    $ratio = $o_height / $o_width;
    $t_height = $height;
    $t_width = $height / $ratio;

    # still won't fit, find the smallest size.
    while($t_width > $width){
      $t_width -= $ratio;
      $t_height -= 1;
    }
  }
  # square (fixed suggested by Philip Munt phil@savvyshopper.net.au)
  elsif( $o_width == $o_height){
    $ratio = 1;
    $t_height = $width;
    $t_width  = $width;
     while (($t_width > $width) or ($t_height > $height)){
       $t_width -= 1;
       $t_height -= 1;
     }
  }

  # Create thumbnail
  if( defined $im ){
    $im->Resize( width => $t_width, height => $t_height );
    $im->Set( quality => $quality );
    $im->Set( density => $density );

	$self->final_width($t_width);
	$self->final_height($t_height);

	$im->Write("$format:$output");
  }
}

sub _create_tmp_image {
  my $self = shift;
  my $im = $self->{image_magick};

	#main_ is added as to not clash with thumbnail tmp path if thumbnail_prefix = '' and they have the same name
  my $output  = $self->{tmp_file_path} = $self->tmp_dir . '/main_' . $self->filename;
  my $quality = $self->thumbnail_quality;
  my $format  = $self->thumbnail_format;

  if( defined $im ){
    $im->Set( quality => $quality );

	$im->Write("$format:$output");

	$self->final_width($im->Get('width'));
	$self->final_height($im->Get('height'));
  }
}

#sub _save_cloud {
#	my $self = shift;
#	my $io_handle = $self->{fh}->handle;
#
#	#IF IS IMAGE, MUST UPLOAD BOTH IMAGES
#
#  my $s_contents;
#	while (my $bytesread = $io_handle->read($buffer,1024)) {
#		print OUTFILE $buffer;
##	}
#
#
##   while(<FILE>)
#    {
#     $s_contents .= $_;
##    }
#
##   ### we will call this resource whatever comes after the last /
#    my $s_resourceName;
#
##    if($param->{'path'} =~ /^.*\/(.*)$/)
#    {
#     $s_resourceName = $1;
##    }
#    else
#    {
#     return('fail', "could not parse path: $param->{'path'}");
##    }
#
#    ### should we pass these vars ... or look them up?
#   my $s_user = '';
#    my $s_key = '';
##    my $s_cdn_uri ='';
#
#    my $ua = LWP::UserAgent->new;
#   my $req = HTTP::Request->new(GET => 'https://auth.api.rackspacecloud.com/v1.0');
##    $req->header('X-Auth-User' => $s_user);
#    $req->header('X-Auth-Key' => $s_key);
#
##    my $res = $ua->request($req);
#
#   if ($res->is_success)
##    {
#      my $s_url = $res->header('X-Storage-Url') . "/container/" . $s_resourceName;
#
##      my $reqPUT = HTTP::Request->new(PUT => $s_url);
#      $reqPUT->header('X-Auth-Token' => $res->header('X-Auth-Token'));
#
##      $reqPUT->content( $s_contents );
#
#     my $resPUT = $ua->request($reqPUT);
##
#      if($resPUT->is_success)
#     {
##        my $s_returnURI = $s_cdn_uri . "/" . $s_resourceName;
#        return('pass','passed afaict', $s_returnURI);
#     }
##      else
#      {
#       my $s_temp = $resPUT->as_string;
#        $s_temp =~ s/'/\\'/g;
##        return('fail',"PUT failed with response:$s_temp")
#      }
#   }
##    else
#    {
#     my $s_temp = $res->as_string;
##      $s_temp =~ s/'/\\'/g;
#      return('fail',"failed with response:$s_temp")
#   }
##  }
#  else
# {
##    return("fail","sorry no file found at $param->{'path'}");
#  }
#}
#
##sub _delete_cloud {
#	my $self    = shift;
#  my $request = HTTP::Request->new( 'DELETE', $self->_url,
#Q					        [ 'X-Auth-Token' => $self->cloudfiles->token ] );
#	my $response = $self->cloudfiles->_request($request);
#  confess 'Object ' . $self->name . ' not found' if $response->code == 404;
#  confess 'Unknown error' if $response->code != 204;
#}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

jQuery::File::Upload - Server-side solution for the L<jQuery File Upload|https://github.com/blueimp/jQuery-File-Upload/> plugin.

=head1 SYNOPSIS

  use jQuery::File::Upload;

  #simplest implementation
  my $j_fu = jQuery::File::Upload->new;
  $j_fu->handle_request;
  $j_fu->print_response;

  #alternatively you can call $j_fu->handle_request(1) and this will call print_response for you.
  my $j_fu = jQuery::File::Upload->new;
  $j_fu->handle_request(1);

The above example is the simplest one possible, however it assumes a lot of defaults.

=head2 Assumptions

=over 4

=item default upload directory

It is assumed that your files are being uploaded to the current directory of the script that's running, plus '/files'.
So if your script is in /home/user/public_html, your files will be uploaded to /home/user/public_html/files.

=item default url

It is also assumed that the files will be hosted one directory above the running script, plus '/files'. So if the
script is located at the url http://www.mydomain.com/upload.cgi, then all files will be assumed to be at the url
http://www.mydomain.com/files/file_name.

=item default filename

Uploaded files are given a name at run time unless you specifically set the filename in the jQuery::File::Upload object.

=item same server upload

By default, jQuery::File::Upload also assumes that you're meaning to have the uploaded file uploaded to the same server
that the script is running on. jQuery::File::Upload also has the ability to SCP files to remote servers, but this is not the default.

=item CGI environment

By default, jQuery::File::Upload assumes that the script is running in a regular CGI-type environment. However, jQuery::File::Upload
also has the ability to work with L<Catalyst> by being passed the context object.

=item all files

This implementation accepts all types of files.

=back

=head2 A more complicated example

  use jQuery::File::Upload;

  my $j_fu = jQuery::File::Upload->new(
		scp => [{
			user => 'user', #remote user
			public_key => '/home/user/.ssh/id_rsa.pub',	#also possible to use password instead of keys
			private_key => '/home/user/.ssh/id_rsa',
			host => 'mydomain.com',
			upload_dir => '/var/www/html/files', #directory that files will be uploaded to
		}],

		#user validation specifications
		max_file_size => 5242880, #max file size is 5mb
		min_file_size => 1,
		accept_file_types => ['image/jpeg','image/png','image/gif','text/html'], #uploads restricted to these filetypes
		max_width => 40000, #max width for images
		max_height => 50000, #max height for images
		min_width => 1,
		min_height => 1,
		max_number_of_files => 40, #maximum number of files we can have in our upload directory
	  );


  $j_fu->handle_request;
  $j_fu->print_response;

=head2 Getting fancy

  use jQuery::File::Upload;

  my $j_fu = jQuery::File::Upload->new(
			pre_get => sub {
				my $j = shift; #jQuery::File::Upload object for current request
				#any code in here will be executed before any get requests are handled
				#jQuery File Upload makes Get request when the page first loads, so this
				#can be useful for prefilling jQuery File Upload with files if you're using
				#jQuery File upload with saved data to view/delete/upload more

				#generate starting files for jQuery File Upload
				$j->generate_output(
					[
						{
							size => 500000,
							filename =>	'my_image.jpeg',
							image => 'y', #need to let jQuery::File::Upload know this is an image
   								      #or else thumbnails won't be deleted
						},
						{
							size => 500000,
							filename =>	'my_other_image.jpeg',
							image => 'y',
						},
					]
				);

  				#The above makes assumptions yet again. It generates the url based on the defaults, unless
  				#you provide below the upload_url_base.
			},
			pre_delete => sub {
				my $j = shift;

				#here you can do something with the information in the params of the delete_url
				#you can set your own meaningful delete_params (see below)
				#NOTE: delete_urls always have the 'filename' param, so that might be enough for your needs
				my $id = param->('id')

				#DELETE FROM table WHERE id=$id
				#etc.
			},
			post_post => sub {
				my $j = shift;
				#do some stuff here after post (image is uploaded)
				#possibly save information about image in a database to keep track of it?
				#you can call any methods now to get useful info:

				#INSERT INTO table (name,is_image,width,height) VALUES($j->filename,$j->is_image,$j->final_width,$j->final_height)
				#etc
			},
			delete_params => ['key1','val1','key2','val2'],
                                                            #this will add these key value pairs as
                                                            #params on the delete_url that is generated
                                                            #for each image. This could be useful if you
                                                            #kept track of these files in a database and wanted to
                                                            #delete them from the database when they are deleted.
                                                            #then delete_params could be ['id',unique_db_identifier]
                                                            #then you could check for the param 'id' in pre_delete
                                                            #and delete the file from your DB
  		);


  #N.B. All of the above can also be set with the getter/setter methods

  $j_fu->handle_request(1); #when passed a one, will call print_response for you

=head1 DESCRIPTION

jQuery::File::Upload makes integrating server-side with the L<jQuery File Upload|https://github.com/blueimp/jQuery-File-Upload/> plugin simple.
It provides many features, such as:

=over 4

=item 1

the ability to SCP file uploads to remote servers

=item 2

the ability to provide your own functions to add to how each request is handled before the request and after the request

=item 3

options to validate the uploaded files server-side

=item 4

automatically generates thumbnails if the file is an image

=item 5

see below for everything you can do with jQuery::File::Upload

=back

The location of the script should be where L<jQuery File Upload|https://github.com/blueimp/jQuery-File-Upload/> is
told to upload to.

=head1 METHODS

=head2 Getters/Setters

=head3 new

Any of the below getters/setters can be passed into new as options.

  my $j_fu = jQuery::File::Upload->new(option=>val,option2=>val2,...);

=head3 upload_dir

  $j_fu->upload_dir('/home/user/public_html/files');

Sets the upload directory if saving files locally. Should not end with a slash.
The default is the current directory of the running script with '/files' added to
the end:

  /home/user/public_html/upload.cgi

yields:

  /home/user/public_html/files

When using jQuery::File::Upload under normal CGI, it should have
no problem generating this default upload directory if that's what you want.
However, if you are using L<Catalyst>, depending on how you're running L<Catalyst>
(i.e. mod_perl, fastcgi, etc.) the generated default might be kind of strange.
So if you are using L<Catalyst> and you want to upload to the same server
that jQuery::File::Upload is running on, it's best to just manually set this.
Make sure that the user running your script can write to the directory you
specify.

=head3 thumbnail_upload_dir

  $j_fu->thumbnail_upload_dir('/home/user/public_html/files/thumbs');

This can be used to set the upload directory form thumbnails. The default
is L<upload_dir|/"upload_dir">. If you change this, that will make thumbnails
have a different base url than L<upload_url_base|/"upload_url_base">. Make
sure to change L<thumbnail_url_base|/"thumbnail_url_base"> to match this accordingly.
If you would like images and thumbnails to have the same name but just be in
different directories, make sure you set L<thumbnail_prefix|/"thumbnail_prefix">
to ''. This should not end with a slash.
Make sure that the user running your script can write to the directory you
specify.

=head3 upload_url_base

  $j_fu->upload_url_base('http://www.mydomain.com/files');

Sets the url base for files. Should not end with a slash.
The default is the current directory of the running script
with '/files' added to the end:

  http://www.mydomain.com/upload.cgi

yields:

  http://www.mydomain.com/files

Which means that a file url would look like this:

  http://www.mydomain.com/files/file.txt

=head3 thumbnail_url_base

  $j_fu->thumbnail_url_base('http://www.mydomain.com/files/thumbs');

Sets the url base for thumbnails. Should not end with a slash.
The default is L<upload_url_base|/"upload_url_base">.
Resulting thumbnail urls would look like:

  http://www.mydomain.com/files/thumbs/thumb_image.jpg

However, if L<thumbnail_relative_url_base|/"thumbnail_relative_url_base">
is set, the default will be the current url with the thumbnail
relative base at the end.

=head3 relative_url_path

  $j_fu->relative_url_path('/files');

This sets the relative url path for your files relative to the directory
your script is currently running in. For example:

  http://www.mydomain.com/upload.cgi

yields:

  http://www.mydomain.com/files

and then all files will go after /files. The default for this is /files,
which is why upload_url_base has the default /files at the end. If
your location for the images is not relative, i.e. it is located
at a different domain, then just set L<upload_url_base|/"upload_url_base">
to get the url_base you want. There should not be
a slash at the end.

=head3 thumbnail_relative_url_path

  $j_fu->thumbnail_relative_url_path('/files/thumbs');

This sets the thumbnail relative url path for your files relative to the directory
your script is currently running in. For example:

  http://www.mydomain.com/upload.cgi

yields:

  http://www.mydomain.com/files/thumbs

and then all thumbnails will go after /files/thumbs. The default for this is nothing,
so then the thumbnail_url will just fall back on whatever the value of
L<upload_url_base|/"upload_url_base"> is.
If your location for thumbnail images is not relative, i.e. it is located
at a different domain, then just set L<thumbnail_url_base|/"thumbnail_url_base">
to get the url_base you want. There should not be
a slash at the end.

=head3 relative_to_host

  $j_fu->relative_to_host(1);

If set to 1, this will make L<relative_url_path|/"relative_url_path"> and
L<thumbnail_relative_url_path|/"thumbnail_relative_url_path"> be relative to
the host of the script url. For example:

  http://www.mydomain.com/folder/upload.cgi

With a L<relative_url_path|/"relative_url_path"> '/files' would yield:

  http://www.mydomain.com/files

Whereas by default L<relative_url_path|/"relative_url_path"> and
L<thumbnail_relative_url_path|/"thumbnail_relative_url_path"> are
relative to the folder the upload script is running in.

If you use this option, make sure to set L<upload_dir|/"upload_dir">
(and/or L<thumbnail_upload_dir|/"thumbnail_upload_dir"> if necessary)
since jQuery::File::Upload can no longer do a relative path
for saving the file.

Default is undef.

=head3 field_name

  $j_fu->field_name('files[]');

This is the name of the jQuery File Uploader client side.
The default is files[], as this is the jQuery File Upload
plugin's default.

=head3 ctx

  $j_fu->ctx($c);

This is meant to set the L<Catalyst> context object if you are using
this plugin with L<Catalyst>. The default is to not use this.

=head3 cgi

  $j_fu->cgi(CGI->new);

This should be used mostly internally by jQuery::File::Upload
(assuming you haven't passed in ctx).
It is just the CGI object that the module uses, however if you already
have one you could pass it in.

=head3 should_delete

  $j_fu->should_delete(1)

This is used to decide whether to actually delete the files when jQuery::File::Upload
receives a DELETE request. The default is to delete, however this could be useful
if you wanted to maybe just mark the field as deleted in your database (using L<pre_delete|/"pre_delete">)
and then actually physically
remove it with your own clean up script later. The benefit to this could be that
if you are SCPing the files to a remote server, perhaps issuing the remote commands
to delete these files is something that seems to costly to you.

=head3 scp

  $j_fu->scp([{
			host => 'media.mydomain.com',
			user => 'user',
		  	public_key => '/home/user/.ssh/id_rsa.pub',
		  	private_key => '/home/user/.ssh/id_rsa',
			password => 'pass', #if keys are present, you do not need password
			upload_dir => '/my/remote/dir',
		}]);

This method takes in an arrayref of hashrefs, where each hashref is a remote host you would like to SCP the files to.
SCPing the uploaded files to remote hosts could be useful if say you hosted your images on a different server
than the one doing the uploading.

=head4 SCP OPTIONS

=over 4

=item

host (REQUIRED) - the remote host you want to scp the files to, i.e. 127.0.0.1 or media.mydomain.com

=item

user (REQUIRED) - used to identify the user to remote server

=item

public_key & private_key - used to make secure connection. Not needed if password is given.

=item

password - used along with user to authenticate with remote server. Not needed if keys are supplied.

=item

upload_dir (REQUIRED) - the directory you want to scp to on the remote server. Should not end with a slash

=item

thumbnail_upload_dir - Will default to upload_dir. You only need to provide this if your thumbnails are stored in a different directory than regular images. Should not end with a slash

=back

You can check L<Net::SSH2> for more information on connecting to the remote server.

=head3 max_file_size

  $j_fu->max_file_size(1024);

Sets the max file size in bytes. By default there is no max file size.

=head3 min_file_size

  $j_fu->min_file_size(1);

Sets the minimum file size in bytes. Default minimum is 1 byte. to disable a minimum file size, you can set this to undef or 0.

=head3 accept_file_types

  $j_fu->accept_file_types(['image/jpeg','image/png','image/gif','text/html']);

Sets what file types are allowed to be uploaded. By default, all file types are allowed.
File types should be in the format of the Content-Type header sent on requests.

=head3 reject_file_types

  #None of these types are allowed.
  $j_fu->reject_file_types(['image/jpeg','image/png','image/gif','text/html']);

Sets what file types are NOT allowed to be uploaded. By default, all file types are allowed.
File types should be in the format of the Content-Type header sent on requests.

=head3 require_image

  $j_fu->require_image(1);

If set to 1, it requires that all uploads must be an image. Setting this is equivalent
to calling:

  $j_fu->accept_file_types(['image/jpeg','image/jpg','image/png','image/gif']);

Default is undef.

=head3 delete_params

  $j_fu->delete_params(['key1','val1','key2','val2']);

Sets the keys and values of the params added to the delete_url.
This can be useful when used with L<pre_delete|/"pre_delete">,
because if you are keeping track of these files in a database,
you can add unique identifiers to the params so that in L<pre_delete|/"pre_delete">
you can get these unique identifiers and use them to remove or edit the file
in the databse. By default filename will also be a param unless you
set the delete_url manually.

=head3 delete_url

  $j_fu->delete_url('http://www.mydomain.com/upload.cgi?filename=file.jpg');

This can be used to set the delete_url that will be requested when
a user deletes a file. However, it is recommended that you do not
set this manually and rather use L<delete_params|/"delete_params">
if you want to add your own params to the delete_url.

=head3 thumbnail_width

  $j_fu->thumbnail_width(80);

This sets the width for the thumbnail that will be created if the
file is an image. Default is 80.

=head3 thumbnail_height

  $j_fu->thumbnail_height(80);

This sets the height for the thumbnail that will be created if the
file is an image. Default is 80.

=head3 thumbnail_quality

  $j_fu->thumbnail_quality(70);

This sets the quality of the thumbnail image. Default is 70 and it
can be on a scale of 0-100. See L<Image::Magick> for more information.

=head3 thumbnail_format

  $j_fu->thumbnail_format('jpg');

Sets the format for the generated thumbnail. Can be jpg, png, or gif.
See L<Image::Magick> for more information. Defaults to jpg.

=head3 thumbnail_density

  $j_fu->thumbnail_density('80x80');

Sets the density for the generated thumbnail. Default is width x height.
See L<Image::Magick> for more information.

=head3 thumbnail_prefix

  $j_fu->thumbnail_prefix('thumb_');

Added before the image filename to create the thumbnail unique filename.
Default is 'thumb_'.

=head3 thumbnail_postfix

  $j_fu->thumbnail_postfix('_thumb');

Added after the image filename to create the thumbnail unique filename.
Default is ''.

=head3 thumbnail_final_width

  my $final_width = $j_fu->thumbnail_final_width;

Because the thumbnails are scaled proportionally, the thumbnail width
may not be what you orignally suggested. This gets you the final width.

=head3 thumbnail_final_height

  my $final_height = $j_fu->thumbnail_final_height;

Because the thumbnails are scaled proportionally, the thumbnail height
may not be what you orignally suggested. This gets you the final height.

=head3 quality

  $j_fu->quality(70);

This sets the quality of the uploaded image. Default is 70 and it
can be on a scale of 0-100. See L<Image::Magick> for more information.

=head3 process_images

  $j_fu->process_images(1);

Create thumbnails for uploaded image files when set to 1. When set to undef, L<jQuery::File::Upload> will skip creating
thumbnails even when the uploaded file is an image. Images are simply treated like any other file. The default is 1.

=head3 format

  $j_fu->format('jpg');

Sets the format for the generated thumbnail. Can be jpg,png, or gif.
See L<Image::Magick> for more information. Defaults to jpg.

=head3 final_width

  my $final_width = $j_fu->final_width;

Returns the final width of the uploaded image.

=head3 final_height

  my $final_height = $j_fu->final_height;

Returns the final height of the uploaded image.

=head3 max_width

  $j_fu->max_width(10000);

Sets the maximum width of uploaded images. Will return an error to browser if not
valid. Default is any width.

=head3 max_height

  $j_fu->max_height(10000);

Sets the maximum height of uploaded images. Will return an error to browser if not
valid. Default is any height.

=head3 min_width

  $j_fu->min_width(10000);

Sets the minimum width of uploaded images. Will return an error to browser if not
valid. Default is 1.

=head3 min_height

  $j_fu->min_height(10000);

Sets the minimum height of uploaded images. Will return an error to browser if not
valid. Default is 1.

=head3 max_number_of_files

  $j_fu->max_number_of_files(20);

Sets the maximum number of files the upload directory can contain. Returns an error
to the browser if number is reached. Default is any number of files. If you have
listed multiple remote directories, the maximum file count out of all of these directories
is what will be used.

=head3 filename

  my $filename = $j_fu->filename;

Returns the resulting filename after processing the request.

  $j_fu->filename('my_name.txt');

You can also set the filename to use for this request before you call
L<handle_request|/"handle_request">. However, unless you're sure
that you are going to give the file a unique name, you should
just let jQuery::File::Upload generate the filename. Please note
that if you choose your own filename, you do have to manually set
L<thumbnail_filename|/"thumbnail_filename">

=head3 absolute_filename

  my $absolute_filename = $j_fu->absolute_filename;

Returns the absolute filename of the file on the server.
You can also set this manually if you would like, or jQuery::File::Upload
will generate it for you.

=head3 thumbnail_filename

  $j_fu->filename('my_name.txt');

You can also set the thumbnail_filename to use for this request before you call
L<handle_request|/"handle_request">. However, unless you're sure
that you are going to give the file a unique name, you should
just let jQuery::File::Upload generate the filename.

=head3 absolute_thumbnail_filename

  my $absolute_filename = $j_fu->absolute_thumbnail_filename;

Returns the absolute filename of the thumbnail image on the server.
You can also set this manually if you would like, or jQuery::File::Upload
will generate it for you.

=head3 client_filename

  my $client_filename = $j_fu->client_filename;

Returns the filename of the file as it was named by the user.

=head3 show_client_filename

  $j_fu->show_client_filename(1);

This can be used to set whether jQuery::File::Upload shows the user the name
of the file as it looked when they uploaded, or the new name of the file.
When set to true, the user will see the file as it was named on their computer.
The default is true, and this is recommended because typically the user's
filename will look better than the unique one that jQuery::File::Upload generates
for you.

=head3 use_client_filename

  $j_fu->use_client_filename(0);

If this is set to true, jQuery::File::Upload will use
the user's name for the file when saving it. However, this
is not recommended because the user could have two files named
the same thing that could overwrite one another, and same scenario
between two different users. It is best to let jQuery::File::Upload
generate the filenames to save with because these are much more
likely to be unique. Another reason not to use client filenames
is that it is possible that they could have invalid characters in them
such as spaces which will prevent a url from loading.

=head3 filename_salt

  $j_fu->filename_salt('_i_love_the_circus');

Anything added here will be appended to the end of the filename.
This is meant to be used if you want to guarantee uniqueness of image
names, i.e. you could use a user id at the end to greatly lessen the chance
of duplicate filenames. Default is nothing.

=head3 copy_file

  $j_fu->copy_file(undef);

Performs a copy instead of a link from the temporary directory to the upload directory. 
This might be useful if you are using Windows share that can't handle links. 
The default is undef and thus L<jQuery::File::Upload> will use links.

=head3 tmp_dir

  $j_fu->tmp_dir('/tmp');

The provided directory will be used to store temporary files such as images.
Make sure that the user the script is running under has permission to create
and write to files in the tmp_dir. Also, there should be no slash at the end.
Default is /tmp.

=head3 script_url

  $j_fu->script_url('http://www.mydomain.com/upload.cgi');

This can be used to set the url of the script that jQuery::File::Upload is
running under. jQuery::File::Upload then uses this value to generate
other parts of the output. jQuery::File::Upload in most cases is able
to figure this out on its own, however if you are experiencing issues
with things such as url generation, try setting this manually.

=head3 data

  $j_fu->data({
            dbh => $dbh,
            my_var = $var,
            arr = [],
            self => $self, #maybe useful for Catalyst
        });

This method can be populated with whatever you like. Its purpose is
if you need to get access to other data in one of your
L</PRE/POST REQUEST METHODS>. This way you
can access any outside data you need by calling L<data|/"data"> on
the jQuery::File::Upload object that you are passed. However, keep in mind
that if you are using L<Catalyst>, you will have access to the context
object via the jQuery::File::Upload object that is passed in, and this
would be an equally good place to store/retrieve data that you need.

=head2 JUST GETTERS

=head3 output

  my $output = $j_fu->output;

Returns the JSON output that will be printed to the browser.
Unless you really feel you need the JSON, it's usually just easier to
call L<print_response|/"print_response"> as this prints out
the header and the JSON for you (or alternatively call L<handle_response|/"handle_response>
and pass it a 1 so that it will call L<print_response|/"print_response"> for you.

=head3 url

  my $file_url = $j_fu->url;

This returns the resulting url of the file.

=head3 thumbnail_url

  my $thumbnail_url = $j_fu->thumbnail_url;

This returns the resulting thumbnail url of the image.

=head3 is_image

  my $is_image = $j_fu->is_image;

Returns whether or not the uploaded file was an image.
This should be called after handle_request or in
L<post_post|/"post_post">.

=head3 size

  my $size = $j_fu->size;

Returns the size of the uploaded file.
This should be called after handle_request or in
L<post_post|/"post_post">.


=head2 OTHER METHODS

=head3 print_response

  $j_fu->print_response;

Should be called after L<handle_request|/"handle_request">.
Prints out header and JSON back to browser. Called for
convenience by L<handle_request|/"handle_request"> if
L<handle_request|/"handle_request"> is passed a 1.

=head3 handle_request

  $j_fu->handle_request;

Called to handle one of 'GET','POST', or 'DELETE' requests.
If passed a 1, will also call L<print_response|/"print_response">
after it's finished.

=head3 generate_output

  $j_fu->generate_output([{
			image => 'y', #or 'n'
			filename => 'my_cool_pic.jpg',
			size => 1024,
		  }]);

This should be used in conjuction with L<pre_get|/"pre_get">
to populate jQuery File Upload with files on page load. It takes in
an arrayref of hashrefs, where each hashref is a file. After this
method is called, you will need to call L<print_response|/"print_response">
or L<handle_request|/"handle_request"> with a 1 to print out the JSON.

=head4 GENERATE_OUTPUT OPTIONS

=over 4

=item

filename (REQUIRED) - name of the file

=item

size (REQUIRED) - size in bytes

=item

image - 'y' or 'n'. Necessary if file is image and you would like thumbnail to be deleted with file. Also, needed if you want thumbnail to be displayed by jQuery File Upload

=item

name - name that will be displayed to client as the filename. If not provided, defaults to filename. Can be
used well with client_filename to make filename's look prettier client-side.

=item

thumbnail_filename - filename for thumbnail. jQuery::File::Upload will generate the thumbnail_filename based
on the filename and other factors (such as L<upload_url_base|/"upload_url_base">) if you don't set this.

=item

url - url used for file. If not provided, will be generated with filename and other defaults.

=item

thumbnail_url - url used for thumbnail. If not provided, will be generated with other defaults.

=item

delete_url - url that will be called by L<jQuery File Upload|https://github.com/blueimp/jQuery-File-Upload/> to
delete the file. It's better to just let jQuery::File::Upload generate this and use L<delete_params|/"delete_params">
if you want to set your own parameters for the delete url.

=item

delete_params - The format of this is just like L<delete_params|/"delete_params">. It takes [key,value] pairs.
Any values here will be added in addition to any global L<delete_params|/"delete_params"> that you set.

=item

error - can be used to supply an error for a file (although I don't really know why you would use this...)

=back

Note that jQuery::File::Upload will generate urls and such
based upon things given here (like filename) and other
options such as L<upload_url_base|/"upload_url_base">.

=head2 PRE/POST REQUEST METHODS

N.B. The following functions are all passed a jQuery::File::Upload object. And they
can be passed into L<new|/"new"> as options.

Also, note that since all of these user-defined methods are passed the jQuery::File::Upload object,
if you are using L<Catalyst> you can just call the L<ctx|/"ctx"> method to get anything
stored via your context object. For L<Catalyst> users, this makes this a practical (and possibly better)
alternative to the provided L<data|/"data"> method.

=head3 pre_delete

  $j_fu->pre_delete(sub { my $j_fu = shift });

or

  $j_fu->pre_delete(\&mysub);

pre_delete will be called before a delete request is handled.
This can be useful if you want to mark a file as deleted in your
database. Also, you can use this along with L<delete_params|/"delete_params">
to set unique identifiers (such as an id for the file or the primary key) so that you can
find the file in your database easier to perform whatever operations
you want to on it. B<Note:> This will be called even if
L<should_delete|/"should_delete"> is set to false.
If your pre_delete returns a value, this will be interpreted as an error
message and the delete call will be terminated and will return the error.
For example:

  $j_fu->pre_delete(sub {
    return 'You cannot delete this file.'; #file will not be deleted
  });

=head3 post_delete

  $j_fu->post_delete(sub { my $j_fu = shift });

or

  $j_fu->post_delete(\&mysub);

post_delete will be called after a delete request is handled.
B<Note:> This will not be called if
L<should_delete|/"should_delete"> is set to false.

=head3 pre_post

  $j_fu->pre_post(sub { my $j_fu = shift });

or

  $j_fu->pre_post(\&mysub);

pre_post will be called before a post request is handled.
POST requests are what happen when jQuery File Upload uploads your file.
If your pre_post returns a value, this will be interpreted as an error
message and the post call will be terminated and will return the error.
For example:

  $j_fu->pre_post(sub {
    return 'You have too many files.'; #file will not be uploaded
  });

=head3 post_post

  $j_fu->post_post(sub { my $j_fu = shift });

or

  $j_fu->post_post(\&mysub);

post_post will be called after a post request is handled.
This can be useful if you want to keep track of the file
that was just uploaded by recording it in a database.
You can use the jQuery::File::Upload object that
is passed in to get information about the file that you would like
to store in the databse. Later on you can use this stored
information about the files to prepopulate a jQuery File Upload
form with files you already have by preloading the form by using
L<pre_get|/"pre_get">.

=head3 pre_get

  $j_fu->pre_get(sub { my $j_fu = shift });

or

  $j_fu->pre_get(\&mysub);

pre_get will be called before a get request is handled.
Get requests happen on page load to see if there are any
files to prepopulate the form with. This method can
be useful to prepopulate the jQuery File Upload form
by combining saved information about the files you want to
load and using L<generate_output|/"generate_output"> to
prepare the output that you would like to send to the
jQuery File Upload form.

=head3 post_get

  $j_fu->post_get(sub { my $j_fu = shift });

or

  $j_fu->post_get(\&mysub);

post_get will be called after a get request is handled.

=head2 EXPORT

None by default.

=head1 Catalyst Performance - Persistent jQuery::File::Upload

A jQuery::File::Upload object shouldn't be too expensive to create, however
if you'd like to only create the object once you could create it as an
L<Moose> attribute to the class:

  use jQuery::File::Upload;
  has 'j_uf' => (isa => 'jQuery::File::Upload', is => 'rw',
		  lazy => 0, default => sub { jQuery::File::Upload->new } );

However, if you do this it is possible that you could run into issues
with values of the jQuery::File::Upload object that were not cleared
messing with the current request. The _clear method is called before
every L<handle_request|/"handle_request"> which clears the values of
the jQuery::File::Upload object, but it's possible I may have
missed something.

=head1 SEE ALSO

=over 4

=item

L<CGI>

=item

L<JSON::XS>

=item

L<Net::SSH2>

=item

L<Net::SSH2::SFTP>

=item

L<Image::Magick>

=item

L<Cwd>

=item

L<Digest::MD5>

=item

L<URI>

=item

L<jQuery File Upload|https://github.com/blueimp/jQuery-File-Upload/>

=back

=head1 AUTHOR

Adam Hopkins, E<lt>srchulo@cpan.org>

=head1 Bugs

I haven't tested this too thoroughly beyond my needs, so it is possible
that I have missed something. If I have, please feel free to submit a bug
to the bug tracker, and you can send me an email letting me know that you
submitted a bug if you want me to see it sooner :)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Adam Hopkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
