package LiveGeez::URI;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.20';

	use URI;
	$URI::ABS_REMOTE_LEADING_DOTS = 1;
}


sub new
{
my $class = shift;
my $self = {};

	my $blessing = bless $self, $class;

	$self->{_uri} = new URI ( @_ );

	$self->{last_path}  = undef;
	$self->{file}       = undef;
	$self->{file_clean} = undef;
	$self->{dir}        = undef;
	$self->{dir_clean}  = undef;
	$self->{ext}        = undef;

	$blessing;
}



sub _set_dir_file
{
my ($self, $path) = @_;

	$path .= "/" unless ( ($path  =~ /\.(\w+)$/o) || ($path =~ /\/$/o) );
	$path =~ s|/+|/|g;
	my ($file, $dir) = split ( m#/#, reverse($path), 2 );
	$dir  = reverse($dir);
	$file = reverse($file);
	if ( ("/$file" eq $path) && $file !~ /\./ ) {
		$self->{dir}  = $path;
		$self->{file} = "";
	}
	else {
		$self->{dir}  = $dir;
		$self->{file} = $file;
	}
	$dir =~ s|/$||;
	$self->{last_path} = $path;
}



sub dir
{
my $self = shift;

	if ( @_ ) {
		$self->{dir} = shift;
	}
	elsif ( (my $path = $self->{_uri}->path) ne $self->{last_path} ) {
		$self->_set_dir_file ( $path );
	}

	$self->{dir};
}


sub dir_clean
{
my $self = shift;

	if ( @_ ) {
		$self->{dir_clean} = shift;
	}
	else {
		$self->{dir_clean} = $self->dir;
		$self->{dir_clean} =~ s/[ ()]/_/g;
	}

	$self->{dir_clean};
}


sub file
{
my $self = shift;

	if ( @_ ) {
		$self->{file} = shift;
	}
	elsif ( (my $path = $self->{_uri}->path) ne $self->{last_path} ) {
		$self->_set_dir_file ( $path );
	}

	$self->{file};

}


sub file_clean
{
my $self = shift;

	if ( @_ ) {
		$self->{file_clean} = shift;
	}
	else {
		$self->{file_clean} = $self->file;
		$self->{file_clean} =~ s/[ ()]/_/g;
	}

	$self->{file_clean};
}


sub file_base
{
my $self = shift;

	if ( @_ ) {
		$self->{file_base} = shift;
	}
	else {
		my $file = $self->file_clean;
		my $ext = $self->ext;
		$file =~ s/\.$ext$// if ( $ext );
		$self->{file_base} = $file;
	}

	$self->{file_base};
}


sub ext
{
my $self = shift;

	if ( @_ ) {
		$self->{ext} = shift;
	}
	elsif ( $self->{file} ) {
		($self->{ext}) = ( $self->{file} =~ /([^.]+)$/ );
	}

	$self->{ext};

}


sub scheme_authority
{
my $self = shift;

	if ( @_ ) {
		$self->{scheme_authority} = shift;
	}
	else {
		$self->{scheme_authority} = $self->{_uri}->scheme . "://" . $self->{_uri}->authority ;
	}

	$self->{scheme_authority};
}


sub doc_root
{
my $self = shift;

	if ( @_ ) {
		$self->{doc_root} = shift;
	}
	else {
		$self->{doc_root} = $self->scheme_authority . $self->dir_clean;
	}

	$self->{doc_root};
}



sub iscgi
{
my $self = shift;

	if ( @_ ) {
		$self->{iscgi} = shift;
	}
	else {
		$self->{iscgi} = ( $self->query || $self->path =~ /cgi/ || ($self->ext =~ /(pl)|(cgi)/i) ) ? 1 : 0 ;
	}

	$self->{iscgi};
}


sub DESTROY
{
1;
}


sub AUTOLOAD
{
	my($self) = shift;
	# my($arg) = shift;
	my($method) = ($AUTOLOAD =~ /::([^:]+)$/);
	return unless ($method);

	$self->{_uri}->$method ( @_ );
}

1;

__END__
