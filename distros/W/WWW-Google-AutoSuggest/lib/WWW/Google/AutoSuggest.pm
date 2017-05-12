package WWW::Google::AutoSuggest;
use WWW::Google::AutoSuggest::Obj -base;
use LWP::UserAgent;
use URI;
use JSON;
use Encode;

our $VERSION = '0.04';

=encoding utf-8

=head1 NAME

WWW::Google::AutoSuggest - Query the Google services to retrieve the query suggestions

=head1 SYNOPSIS

  use WWW::Google::AutoSuggest;
  my $AutoSuggest=WWW::Google::AutoSuggest->new();
  my @Suggestions = $AutoSuggest->search("perl");
  ###### or
  use WWW::Google::AutoSuggest;
  my $AutoSuggest=WWW::Google::AutoSuggest->new(domain=> "it" ,json=>1); #uses www.google.it instead of .com
  my $result = $AutoSuggest->search("perl");
  # $result now is a decoded JSON arrayref
  ###### or with the html tags
  use WWW::Google::AutoSuggest;
  my $AutoSuggest=WWW::Google::AutoSuggest->new(strip_html=>0);
  my @Suggestions = $AutoSuggest->search("perl");

=head1 DESCRIPTION

WWW::Google::AutoSuggest allows you to use Google Suggest in a quick and easy way and returning it as decoded JSON for further inspection

=head1 ARGUMENTS

=over 4

=item json

  my $AutoSuggest=WWW::Google::AutoSuggest->new(json=>1);

or

  $AutoSuggest->json(1);

Explicitally enable the return of the decoded L<JSON> object when calling C<search("term")>

=item strip_html

  my $AutoSuggest=WWW::Google::AutoSuggest->new(strip_html=>0);

or

  $AutoSuggest->strip_html(0);

Explicitally disable the stripping of the HTML contained in the google responses

=item raw


  my $AutoSuggest=WWW::Google::AutoSuggest->new(raw=>1);

or

  $AutoSuggest->raw(1);

Explicitally enable the return of the response content when calling C<search("term")>

=item domain

  my $AutoSuggest=WWW::Google::AutoSuggest->new(domain=>"it");

or

  $AutoSuggest->domain("it");

Explicitally use the Google domain name in the request


=back


=head1 METHODS

=over 4

=item new

  my $AutoSuggest=WWW::Google::AutoSuggest->new();

Creates a new WWW::Google::AutoSuggest object

=item search

  my @Suggestions = $AutoSuggest->search($query);

Sends your C<$query> to Google web server and fetches and parse suggestions for the given query.
Default returns an array of that form

  @Suggestions = ( 'foo bar' , 'baar foo',..);

Setting
  $AutoSuggest->json(1);

will return the L<JSON> object

=back

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014 mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://metacpan.org/pod/WebService::Google::Suggest>


=cut

has 'domain'     => sub {"com"};
has 'UA'         => sub {"Mozilla/5.0"};    #eheh
has 'base_url'   => sub {"/s"};
has 'strip_html' => sub {1};                #typically you want enable that
has 'raw'        => sub {0};
has 'json'       => sub {0};
has 'url'        => sub {"https://www.google." . $_[0]->domain . $_[0]->base_url};

sub search {
    my $self = shift;
    my $term = shift;
    my $ua   = LWP::UserAgent->new;
    $ua->agent( $self->UA );
    my $url = URI->new( $self->url );   # makes an object representing the URL
    $url->query_form(                   # And here the form data pairs:
        'q'     => $term,
        'gs_ri' => 'psy-ab',
    );
    my $res = $ua->get($url);
    if ( $res->is_success ) {
        return $res->content if ( $self->raw == 1 );
        my $Response = decode_json( $res->content );
        return $Response if ( $self->json == 1 );
        return map {
            $_ = encode( 'utf8', $_->[0] );
            s|<.+?>||g if $self->strip_html == 1;
            $_;
            ##Strips basic HTML tags, i don't think it's needed to load another module
        } @{ $Response->[1] };
    }
    else {
        die( $res->status_line );
    }
}

1;

__END__
