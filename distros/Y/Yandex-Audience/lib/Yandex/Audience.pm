=pod

=encoding utf-8

=head1 NAME

B<Yandex::Audience> - a simple API for Yandex.Audience

It contains very few number of API-calls now.

=head1 VERSION

version 0.01

=head1 SYNOPSYS

  use Yandex::Audience;

  my $Token = 'AgAAAAAAELGSBIXHdBAPDm-6sJ7Sbao7J-pmaU7'; #Auth token
  my $YaAudience= Yandex::Audience->new( -token => $Token);

  #Get list of existing segments
  my $Segments = $YaAudience->getListOfSegments();

  #Upload a content of String in CSV-fromat
  my $Segment = $YaAudience->uploadCSV($CSV);

  #Upload CSV-file
  my $Segment = $YaAudience->uploadCSV('real1500_md5.csv');

  #Save the uploaded content as a segment
  my $SegmentStatus = $YaAudience->saveSegment( segment => $Segment->{id},
                                                name => 'Litres'.$Segment->{id},
                                                hashed => 1,
                                               ) if exists $Segment->{id};

  #Delete a segment
  my $Result = $YaAudience->deleteSegment(9243581);

=head1 METHODS

=cut

package Yandex::Audience;
use strict;
use warnings;
use utf8;
use Carp qw(croak);
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use JSON::XS;
use File::Basename;

use constant APIVERSION => 1;
use constant BASEURL => 'https://api-audience.yandex.ru/v';

our $VERSION    = '0.01';

sub new {
  my $class = shift;
  my %opt = @_;
  my $self = {};
  $self->{token} = $opt{token} || croak "Specify token param";
  $self->{timeout} = 10; #For LWP::UserAgent

  my $ua = LWP::UserAgent->new();
  $ua->timeout($self->{timeout});
  $ua->default_header(Authorization  => 'OAuth ' . $self->{token});
  $ua->default_header('Content-Type' => 'application/json');
  $self->{ua} = $ua;

  bless $self, $class;
  return $self;
}

=head2 getListOfSegments()

Returns a list of existing segments available to the user.

  my $Segments = $YaAudience->get_list_of_segments();

=cut

sub getListOfSegments {
  my $self = shift;
  my $url = &BASEURL . &APIVERSION . '/management/segments';

  my $response = $self->{ua}->get($url);
  return undef unless $response->is_success && $response->content;
  
  my $json;
  eval {
    $json = JSON::XS->new->utf8->decode( $response->content );
  };
  return undef if $@;

  if (exists $json->{segments}) {
    for my $Segment (@{$json->{segments}}) {
      $self->_prepareJSON($Segment);
    }
  }
  return $json->{segments};
}

=head2 uploadCSV()

Upload a CSV-file with data and create a segment.
Returns Hash with Id of segment(s) and it's statuses.

  my $Segment = $YaAudience->uploadCSV('real1500_md5.csv');

=cut

sub uploadCSV {
  my $self = shift;
  my $file = shift;
  
  my $url = &BASEURL . &APIVERSION . '/management/segments/upload_csv_file';
  my $request;
  if (!chomp $file && -e $file) {
    $request = POST ($url, Content_Type  => 'form-data', Content => ['file', [$file]]);
  } else {
    $request = POST ($url, Content_Type  => 'form-data', Content => [file =>  [undef, 'crm.csv', Content=>$file, Content_Type => 'text/csv'] ]);
  }
  my $response = $self->{ua}->request($request);

  return undef unless $response->is_success && $response->content;

  my $json;
  eval {
    $json = JSON::XS->new->utf8->decode( $response->content );
  };
  return undef if $@;
  
  $self->_prepareJSON($json->{segment}) if exists $json->{segment};
  return $json->{segment};
}

=head2 saveSegment()

Saves a segment generated from a file with user data.

  my $SegmentStatus = $YaAudience->saveSegment( -segment => $Segment->{id},          #Id of a segment
                                                 -name   => 'Litres'.$Segment->{id}, #A name of a segment
                                                 -hashed => 1,                       #1 if data contains hashed fields
                                               ) if exists $Segment->{id};

=cut

sub saveSegment {
  my $self = shift;
  my %opt = @_;
  my $SegmentID = $opt{segment} || Carp::carp('id of a segment must be defined');
  my $SegmentName = exists $opt{name} ? $opt{name} : 'Segment' . $SegmentID;
  my $SegmentType = exists $opt{type} ? $opt{type} : 'crm';
  my $IsHashed = exists $opt{hashed} && $opt{hashed} ? 1 : 0;
  
  my $url = &BASEURL . &APIVERSION . '/management/segment/' . $SegmentID . '/confirm';

  my %JSON = (
    segment => {
      id           => $SegmentID,
      name         => $SegmentName,
      hashed       => $IsHashed,
      content_type => $SegmentType,
    }
  );

  my $response = $self->{ua}->post( $url, Content => encode_json(\%JSON) );

  return undef unless $response->is_success && $response->content;

  my $json;
  eval {
    $json = JSON::XS->new->utf8->decode( $response->content );
  };
  return undef if $@;
  
  $self->_prepareJSON($json->{segment}) if exists $json->{segment};
  return $json->{segment};

  return 1;
}

=head2 deleteSegment()

Deletes the specified segment (or segments)
Returns arrayref to scalars: 1 if success, 0 otherwise.

  my $Result = $YaAudience->deleteSegment($SegmentID); #$SegmentID - can be scalar or arrayref to scalars, or arrayref to hashes with id of segment(s).
or
  my $Result = $YaAudience->deleteSegment( [9254200, 9254215] );
=cut

sub deleteSegment {
  my $self = shift;
  my $SegmentID = shift // Carp::carp('id of the segment must be defined');
  my @Result;
  
  if (ref $SegmentID eq 'ARRAY') {
    if (ref $SegmentID->[0] eq 'HASH' && exists $SegmentID->[0]->{id}) { #Perhaps it's array with structures of `yandex.segment` type
      for (@$SegmentID) {
        push @Result, $self->_deleteSegment($_->{id});
      }
    } else { #It must be array of scalars
      for (@$SegmentID) {
        push @Result, $self->_deleteSegment($_);
      }
    }
  } else { #It must be scalar
    return $self->_deleteSegment($SegmentID);
  }
  return \@Result;
}

=head2 _deleteSegment()

The internal method. Deletes a segment.
Returns scalar: 1 if success, 0 otherwise.

  my $Result = $YaAudience->_deleteSegment($SegmentID); #$SegmentID - scalar, contains id of segment.
  
=cut
  
sub _deleteSegment {
  my $self = shift;
  my $SegmentID = shift // Carp::carp('id of the segment must be defined');

  my $url = &BASEURL . &APIVERSION . '/management/segment/' . $SegmentID;
  my $response = $self->{ua}->delete($url);
  
  return 0 unless $response->is_success && $response->content;
  
  my $json;
  eval {
    $json = JSON::XS->new->utf8->decode( $response->content );
  };
  return undef if $@;
  return $json->{success} eq JSON::XS::true ? 1 : 0;
}

=head2 _prepareJSON()

The internal method. Returns hash with values of type JSON::Boolean changed to Scalars (1 and 0).

=cut

sub _prepareJSON {
  my $self = shift;
  my $json = shift;
  
  for (keys %{$json}) {
    if (JSON::XS::is_bool($json->{$_})) {
      $json->{$_} = ($json->{$_} eq JSON::XS::true) ? 1 : 0;
    }
  }
  return $json;
}

=head1 AUTHOR

Dmitry Marin, C<< <mcorvax at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-yandex-audience at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Yandex-Audience>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yandex::Audience


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Yandex-Audience>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Yandex-Audience>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Yandex-Audience>

=item * Search CPAN

L<https://metacpan.org/release/Yandex-Audience>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Dmitry Marin.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Yandex::Audience