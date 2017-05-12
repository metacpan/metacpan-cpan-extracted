package WWW::Bleep;

use 5.008;
use strict;
use warnings;
use LWP::UserAgent;
use HTML::TokeParser;

require Exporter;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );

@EXPORT = qw(error album artists tracks);
@EXPORT_OK = qw();
@ISA = qw(Exporter);
$VERSION = '0.92';

sub new($);
sub album($);
sub artists($$);
sub tracks($$);
sub error($);
sub _cleanurldata($);

=head1 NAME

WWW::Bleep - Perl interface to Bleep.com

=head1 VERSION

Version 0.92

=head1 SYNOPSIS

use WWW::Bleep;

my $bleep = WWW::Bleep->new();

my @tracks = WWW::Bleep->tracks( artist => 'Aphex Twin' );

=head1 DESCRIPTION


A Perl interface to Bleep.com.  Specfically for searching artist,
album, and label data.  Current purpose is the help with cataloging
your personal (physical) album collection.

This has no shopping cart capability and it isn't planned.
(Less there is some dire need for it.)


=head1 FUNCTIONS

=head2 new

    Create a new WWW::Bleep object.

    Currently has no arguments.

=cut

sub new($) {
	my $class = shift;
	my $self = bless {
		_base_url => 'http://www.bleep.com/',
		_ua => LWP::UserAgent->new(),
		_parser => '',
		_response => '',
		_error => '',
	}, $class;
	$self->{'_ua'}->agent('');#"WWW::Bleep v$VERSION");
	return $self;
}


=head2 error

    Returns an error description or ''.

    Doesn't take or require any arguments.

    For the sake of your own sanity, check this ne '' after every call.
    The most you'd generally get from other routines as far as errors are
    concerned would be a null response.

=cut

sub error($) {
	my $self = shift;
	return $self->{_error};
}


=head2 album

    Gathers album data based on the arguments given.

    Requires one of the following arguments:

        cat
        (eventually title)

    Returns a hash containing relevant album and track data.
    Specifically artist, date, label, title, and tracks. artist,
    date, label, and title are all scalars.  date may always be
    returned.

   tracks contains the following array

        track_number => {
            'time'  => length_in_standard_time,
            'title' => track_title,
            'valid' => 1_=_downloadable__0_=_not
        }
        next_track_number => {
            'time'  => length_in_standard_time,
            'title' => track_title,
            'valid' => 1_=_downloadable__0_=_not
        }
        ...

=cut

sub album($) {
	my $self = shift;
	my %args = @_;

	my $album_url = $self->{'_base_url'}.'current_item.php';
	my $title;
	my $number;
	my %album;
	my $slimcat;
	my $token;

	if ( length($args{'cat'}) > 3 ) {
		$args{'cat'} = uc($args{'cat'});
		if ( $args{'cat'} !~ /_DM$/ ) {
			$args{'cat'} .= '_DM';
		}
		$slimcat = substr($args{'cat'},0,length($args{'cat'})-3);
		$album_url .= ('?selection='.$args{'cat'});
		$self->{_response} = $self->{_ua}->get( $album_url );
		if ( $self->{_response}->is_success ){
			$self->{_parser} = HTML::TokeParser->new(
				\$self->{_response}->content
			);
			while ( $token = $self->{_parser}->get_tag('div') ){
				if ($token->[1]{class} &&
						$token->[1]{class} eq 'bleep2selectionTitle') {
					while ( $token = $self->{_parser}->get_token() ){

						# Set album artist
						if ( !$album{artist} && $token->[3][0] &&
								$token->[3][0] eq 'href' ) {
							if ( $token->[2]{href} =~ /^search\.php/ ){
								$token = $self->{_parser}->get_token();
								$album{artist} = $token->[1];
							}
						}

						# Set album title and date if applicable
						if ( !$album{title} &&
								$token->[1] =~ /^(.+) \($slimcat\)$/ ){
							$album{title} = $1;							
							$self->{_parser}->get_token();
							$self->{_parser}->get_token();
							$self->{_parser}->get_token();
							$self->{_parser}->get_token();
							$token = $self->{_parser}->get_token();
							$album{label} = $token->[1];
							$self->{_parser}->get_token();
							$self->{_parser}->get_token();
							$token = $self->{_parser}->get_token();
							if ( $token->[0] eq 'T' &&
									$token->[1] =~ /(\d{1,2}) \/ (\d{1,4})/ ){
								$album{date} = "$1/$2";
							}
						}

						if ( $token->[0] eq 'S' && $token->[1] eq 'td'&&
								$token->[2]{width} &&
								$token->[2]{width} eq '24' ){

							$token = $self->{_parser}->get_token();
							$token->[1] =~ /(\d\d)/;
							$number = $1;

							#  There's got to be a better way to skip
							#  ahead tokens!
							$self->{_parser}->get_token();
							$self->{_parser}->get_token();
							$self->{_parser}->get_token();
							$token = $self->{_parser}->get_token();

							$token->[1] =~ /(.+) \((\d{1,2}:\d\d)\)/;
							if ( $2 ){
								$album{tracks}->{$number}{title} = $1;
								$album{tracks}->{$number}{time} = $2;
								
								# Is the track buyable?
								$album{tracks}->{$number}{valid} = 1;
							}
							else{
								$album{tracks}->{$number}{valid} = 0;
							}
						}
					}
				}
			}
			return %album;
		}

		# Page could not be loaded!
		else {
			$self->{_error} = $self->{_response}->status_line;
			return 0;
		}
	}	
	else {
		$self->{_error} = qq(Please use a catalog value with four or more characters.);
		return 0;
	}	
}


=head2 artists

    Returns an array of artists from Bleep.com.  An optional argument
    must be a valid record label name.

        # Returns all artists (Be careful with this one,
        #                      the list is very large!)
        @artists = $bleep->artists();  

        # Returns only artists on Warp
        @artists = $bleep->artists( 'Warp' );
        
        # Returns null (not a valid record label)
        @artists = $bleep->artists( 'foo1234' );

    Due to the size of the artist list, it may take a minute to
    populate.

=cut

sub artists($$) {
	my $self = shift;
	my %args = @_;
	undef $self->{artists};

	my $artists_url = $self->{'_base_url'}.'browse_artists.php?label=';
	$artists_url .= _cleanurldata( uc($args{'label'}) );

	$self->{_response} = $self->{_ua}->get( $artists_url );

	if ( $self->{_response}->is_success ){
		$self->{_parser} = HTML::TokeParser->new(\$self->{_response}->content);
		
		while( my $token = $self->{_parser}->get_tag("a") ){
			my $url = $token->[1]{href} || '-';		
			my $text = $self->{_parser}->get_trimmed_text("/a");
			unless ( $url eq 'javascript:void(0);' ){
				push @{$self->{_artists}}, $text;
			}
		}
		if( $self->{_artists} ){
			return @{$self->{_artists}};
		}
		else {
			 $self->{error} = qq(No artists could be found!);
		}
	}
	else {
		$self->{error} = qq(No response from url!\nDo you have an active internet connection and is bleep.com up?);
		return 0;
	}
}


=head2 tracks

    Gathers the tracks based on the arguments given.  

    Requires one or of the following arguments:

        artist
        label
        album*

    Returns an array of hashes of track names, track numbers and album
    catalog numbers.  *Currently, 'album' dies off, as it uses a 
    different method that hasn't been configured.

=cut

sub tracks($$) {
	my $self = shift;
	my %args = @_;
	my $tracks_url = $self->{'_base_url'}.'browse_results.php?';

	undef $self->{_tracks};
	undef $self->{hastracks};

	if ($args{artist} || $args{label} || $args{album}) {
		if ($args{artist}) {
			$tracks_url .= ('artist='._cleanurldata($args{artist}).'&');
		}
		if ($args{label}){
			$tracks_url .= ('label='._cleanurldata($args{label}).'&');
		}
		if ($args{album}) {
			die "Option \"album\" not yet supported!";
		}

		$self->{_response} = $self->{_ua}->get( $tracks_url );

		if ($self->{_response}->is_success) {

			$self->{_parser} = HTML::TokeParser->new(\$self->{_response}->content);
		
			#  Move the offset so it does not include albums
			while (my $token = $self->{_parser}->get_tag('td')) {
				if ($self->{_parser}->get_trimmed_text('/td') eq 'TRACKS') {
					while (my $token = $self->{_parser}->get_tag("a")) {
						my $url = $token->[1]{href} || '-';		
						my $text = $self->{_parser}->get_trimmed_text("/a");
						unless ( !$url || $url eq 'javascript:void(0);' ){
							$url =~ /\?id=(\w+)-(\d\d)/;
							push @{$self->{_tracks}}, {title=>$text,cat=>$1,number=>$2};
						}
					}
					if ($self->{_tracks}) {
						return @{$self->{_tracks}};
					}
					else {
						$self->{error} = qq(Artist exists, but no tracks can be found... Sorry!);
						return 0;
					}
				}
			}
		}
		else {
			$self->{error} = qq(No response from url!  Do you have an active internet connection and is bleep.com up?);
			return 0;
		}
	}
	else {
		$self->{error} = qq(This function requires one or more arguments!);
		return 0;
	}
	1;
}



# Internal routine to fix any obscure characters
sub _cleanurldata($) {
	if ($_[0]) {
		my @data = split //, shift;
		my $val;

		foreach my $char (@data) {
			$val = ord($char);
			if ($val < 48 || ($val > 57 && $val < 65) || $val > 90) {
				$val = unpack('H*',chr($val));
				$char = ('%'.$val);
			}
		}

		$val = join '', @data;
		return $val;
	}
	else {
		return $_[0];
	}
}

=head1 SEE ALSO

L<http://www.bleep.com>

=head1 AUTHOR

Clif Bratcher, E<lt>snevine@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE


Copyright (C) 2006 - 2009 by Clif Bratcher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
