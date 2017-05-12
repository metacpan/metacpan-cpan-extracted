package Wiktionary::Parser::Section::Pronunciation::Audio;

use MediaWiki::API;
use File::Path;

# keys:
#  file: name of the audio file
#  text: text label for this file
#  context: e.g. en(US), en(UK)
sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;
	return $self;
}

sub get_file {
	my $self = shift;
	return $self->{file};
}

sub get_text {
	my $self = shift;
	return $self->{text};
}

sub get_context {
	my $self = shift;
	return $self->{context};
}

sub download_file {
	my $self = shift;
	my %args = @_;
	my $directory = $args{directory} or die 'you need to specify a directory to download to';
	my $filename = $self->{file};

	return unless $filename;	

	my $api = MediaWiki::API->new({ 
		api_url => 'http://en.wiktionary.org/w/api.php',
	});

	my $file_content = $api->download({title => "File:$filename"});

	if ($api->{error}->{code}) {
		print STDERR $api->{error}->{code} . ': ' . $api->{error}->{details};
	}

	unless (defined $file_content && bytes::length($file_content)) {
		print STDERR "'$filename' doesn't exist or failed to download";
		return;
	}

	# create local directory if it doesn't exist
	unless (-e $directory) {
		File::Path::make_path($directory);
	}

	# also verify directory is writable
	unless (-w $directory) {
		die "unable to write to '$directory'";
	}
	my $download_location = "$directory/$filename";
	open (my $fh, ">",$download_location) or die $!;
	print $fh $file_content;
	close $fh;

	return $download_location;
}

1;
