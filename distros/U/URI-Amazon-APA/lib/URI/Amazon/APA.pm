package URI::Amazon::APA;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.5 $ =~ /(\d+)/g;
use Carp;
use Digest::SHA qw(hmac_sha256_base64);
use URI::Escape;
use Encode qw/decode_utf8/;
use base 'URI::http';

sub new{
    my $class = shift;
    my $self  = URI->new(@_);
    ref $self eq 'URI::http' or carp "must be http";
    bless $self, $class;
}

sub sign {
    my $self  = shift;
    my (%arg) = @_;
    my %eq    = map { split /=/, $_ } split /&/, $self->query();
    my %q     = map { $_ => decode_utf8( uri_unescape( $eq{$_} ) ) } keys %eq;
    $q{Keywords} =~ s/\+/ /g if $q{Keywords};
    $q{AWSAccessKeyId} = $arg{key};
    $q{Timestamp} ||= do {
        my ( $ss, $mm, $hh, $dd, $mo, $yy ) = gmtime();
        join '',
          sprintf( '%04d-%02d-%02d', $yy + 1900, $mo + 1, $dd ), 'T',
          sprintf( '%02d:%02d:%02d', $hh,        $mm,     $ss ), 'Z';
    };
    $q{Version} ||= '2010-09-01';
    my $sq = join '&',
      map { $_ . '=' . uri_escape_utf8( $q{$_}, "^A-Za-z0-9\-_.~" ) }
      sort keys %q;
    my $tosign = join "\n", 'GET', $self->host, $self->path, $sq;
    my $signature = hmac_sha256_base64( $tosign, $arg{secret} );
    $signature .= '=' while length($signature) % 4;    # padding required
    $q{Signature} = $signature;
    $self->query_form( \%q );
    $self;
}

sub signature {
    my $self  = shift;
    my (%arg) = @_;
    my %eq = map { split /=/, $_ } split /&/, $self->query();
    my %q = map { $_ => uri_unescape( $eq{$_} ) } keys %eq;
    $q{Signature};
}

1; # End of URI::Amazon::APA

=head1 NAME

URI::Amazon::APA - URI to access Amazon Product Advertising API

=head1 VERSION

$Id: APA.pm,v 0.5 2013/07/16 18:31:07 dankogai Exp $

=head1 SYNOPSIS

  # self-explanatory
  use strict;
  use warnings;
  use URI::Amazon::APA;
  use LWP::UserAgent;
  use XML::Simple;
  use YAML::Syck;

  use URI::Amazon::APA; # instead of URI
  my $u = URI::Amazon::APA->new('http://webservices.amazon.com/onca/xml');
  $u->query_form(
    Service     => 'AWSECommerceService',
    Operation   => 'ItemSearch',
    Title       => shift || 'Perl',
    SearchIndex => 'Books',
  );
  $u->sign(
    key    => $public_key,
    secret => $private_key,
  );

  my $ua = LWP::UserAgent->new;
  my $r  = $ua->get($u);
  if ( $r->is_success ) {
    print YAML::Syck::Dump( XMLin( $r->content ) );
  }
  else {
    print $r->status_line, $r->as_string;
  }

=head1 EXPORT

None.

=head1 METHODS

This adds the following methods to L<URI> object

=head2 sign

Sings the URI accordingly to the Amazon Product Advertising API.

  $u->sign(
    key    => $public_key,
    secret => $private_key,
  );

=head2 signature

Checks the signature within the URI;

  print "The signature is " : $u->signature;

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-uri-amazon-apa at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-Amazon-APA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::Amazon::APA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-Amazon-APA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-Amazon-APA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-Amazon-APA>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-Amazon-APA/>

=back

=head1 ACKNOWLEDGEMENTS

L<http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/index.html?rest-signature.html>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
