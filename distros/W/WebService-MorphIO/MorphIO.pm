package WebService::MorphIO;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Encode qw(encode_utf8);
use Error::Pure qw(err);
use IO::Barf qw(barf);
use LWP::Simple qw(get);
use URI;
use URI::Escape qw(uri_escape);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Morph.io API key.
	$self->{'api_key'} = undef;

	# Project.
	$self->{'project'} = undef;

	# Select.
	$self->{'select'} = 'SELECT * FROM data';

	# Web URI of service.
	$self->{'web_uri'} = 'https://morph.io/';

	# Process params.
	set_params($self, @params);

	# Check API key.
	if (! defined $self->{'api_key'}) {
		err "Parameter 'api_key' is required.";
	}

	# Check project.
	if (! defined $self->{'project'}) {
		err "Parameter 'project' is required.";
	}
	if ($self->{'project'} !~ m/\/$/ms) {
		$self->{'project'} .= '/';
	}

	# Web URI.
	if ($self->{'web_uri'} !~ m/\/$/ms) {
		$self->{'web_uri'} .= '/';
	}

	# Object.
	return $self;
}

# Get CSV file.
sub csv {
	my ($self, $output_file) = @_;
	my $uri = URI->new($self->{'web_uri'}.$self->{'project'}.
		'data.csv?key='.$self->{'api_key'}.'&query='.
		uri_escape($self->{'select'}));
	return $self->_save($uri, $output_file);
}

# Get sqlite file.
sub sqlite {
	my ($self, $output_file) = @_;
	my $uri = URI->new($self->{'web_uri'}.$self->{'project'}.
		'data.sqlite?key='.$self->{'api_key'});
	return $self->_save($uri, $output_file);
}

# Save file.
sub _save {
	my ($self, $uri, $output_file) = @_;
	my $content = get($uri->as_string);
	if (! $content) {
		err "Cannot get '".$uri->as_string."'.";
	}
	barf($output_file, encode_utf8($content));
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::MorphIO - Perl class to communication with morph.io.

=head1 SYNOPSIS

 use WebService::MorphIO;

 my $obj = WebService::MorphIO->new(%parameters);
 $obj->csv('output.csv');
 $obj->sqlite('output.sqlite');

=head1 METHODS

=over 8

=item C<new(%parameters)>

Constructor.

=over 8

=item * C<api_key>

 Morph.io API key.
 It is required.
 Default value is undef.

=item * C<project>

 Project.
 It is required.
 Default value is undef.

=item * C<select>

 Select.
 It is usable for csv() method.
 Default value is 'SELECT * FROM data'.

=item * C<web_uri>

 Web URI of service.
 Default value is 'https://morph.io/'.

=back

=item C<csv($output_file)>

 Get CSV file and save to output file.
 It is affected by 'select' parameter.
 Returns undef.

=item C<sqlite($output_file)>

 Get sqlite file and save to output file.
 Returns undef.

=back

=head1 ERRORS

 new():
         Parameter 'api_key' is required.
         Parameter 'project' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 csv():
         Cannot get '%s'.

 sqlite():
         Cannot get '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use File::Temp qw(tempfile);
 use Perl6::Slurp qw(slurp);
 use WebService::MorphIO;

 # Arguments.
 if (@ARGV < 2) {
         print STDERR "Usage: $0 api_key project\n";
         exit 1;
 }
 my $api_key = $ARGV[0];
 my $project = $ARGV[1];

 # Temp file.
 my (undef, $temp_file) = tempfile();

 # Object.
 my $obj = WebService::MorphIO->new(
         'api_key' => $api_key,
         'project' => $project,
 );

 # Save CSV file.
 $obj->csv($temp_file);

 # Print to output.
 print slurp($temp_file);

 # Clean.
 unlink $temp_file;

 # Output:
 # Usage: ./examples/ex1.pl api_key project

=head1 DEPENDENCIES

L<Class::Utils>,
L<Encode>,
L<Error::Pure>,
L<IO::Barf>,
L<LWP::Simple>,
L<URI>,
L<URI::Escape>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WebService-MorphIO>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
