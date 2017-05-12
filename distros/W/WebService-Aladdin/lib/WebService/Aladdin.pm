package WebService::Aladdin;

use strict;
use warnings;
use LWP::UserAgent;
use URI;
use Carp;
use WebService::Aladdin::Parser;

use vars qw($VERSION);
$VERSION = '0.08';

my $api_url_search = "http://www.aladdin.co.kr/ttb/api/search.aspx";
my $api_url_product = "http://www.aladdin.co.kr/ttb/api/ItemLookUp.aspx";

sub new {
    my ($class, $ttbkey) = @_;

    $ttbkey ||= 'ttbjeen1333001';
    my $ua = LWP::UserAgent->new;
    $ua->agent('WebService::Aladdin / '.$VERSION);
    bless {
        TTBKey => $ttbkey,
        ua     => $ua,
    }, $class;
}

sub product {
    my ($self, $id, $args) = @_;

    my $uri = URI->new($api_url_product);

    croak 'ItemId is required' unless $id;

    $uri->query_form( TTBKey => $self->{TTBKey},
              ItemId => $id,
              Output  => 'OS',
    );
    my $res = $self->{ua}->get($uri);
    WebService::Aladdin::Parser->parse_product($res);
}

sub search {
    my ($self, $keyword, $args) = @_;

    my $uri = URI->new($api_url_search);

    croak 'Query is required' unless $keyword;

    $uri->query_form( Query => $keyword,
                      TTBKey => $self->{TTBKey},
                      QueryType => $args->{QueryType},
                      SearchTarget => $args->{SearchTarget},
                      Start => $args->{Start},
                      MaxResults => $args->{MaxResults},
                      Sort => $args->{Sort},
                      Cover => $args->{Cover},
                      TitleCut => $args->{TitleCut},
                      CategoryId => $args->{CategoryId},
                      Partner => $args->{Partner},
    );

    my $res = $self->{ua}->get($uri); 
    WebService::Aladdin::Parser->parse_search($res);
}

1;
__END__

=encoding utf8

=head1 NAME

WebService::Aladdin - Aladdin WebService API Module

=head1 SYNOPSIS

  use WebService::Aladdin;

  my $p = WebService::Aladdin->new( TTBKey => 'Your TTBKey' );
  my $data = $p->search('Perl');
  for my $item (@{ $data }) {
      print $item->title, "\n";
  }

=head1 DESCRIPTION

WebService::Aladdin is Aladdin WebService API Module.
Aladdin(http://www.aladdin.co.kr) is a Korean electronic commerce company in Seoul, Korea.
They mainly sell books and Gift and DVD and etc. 

=head1 FUNCTIONS

=head2 new( TTBKey => 'Your TTBKey' )

Returns an instance of this module. If you don't enter TTBKey parameter, It's ok. 
Because default TTBKey is mine. :-)

=head2 search( $keyword, \%options )

Returns search results.

  my $data = $p->search('Perl', { 
      SearchTarget => $SearchTarget, # (?:Book|Music|DVD|Beauty|Gift)
      QueryType => $QueryType,       # (?:Title|Author|Publisher)
      Start => $Start,               # search result start page
      MaxResults => $MaxResults,     # max number of a page
      Sort => $Sort,                 # (?:PublishTime|Title|SalesPoint|CustomerRating|MyReviewCount)
      Cover => $Cover,               # (?:Mid|Small|Big|Mini|None)
      TitleCut => $TitleCut,         # truncate
      CategoryId => $CategoryId, 
      Partner => $Partner,  
 });

=head2 product( $keyword, \%options )

Returns product information.

  my $data = $p->product($ISBN, {
    ItemIdType => $args->{ItemIdType}, # (?:ISBN|ItemId)
    Cover  => $args->{Cover},          # (?:Mid|Small|Big|Mini|None)
    Partner => $args->{Partner},
});

=head1 AUTHOR

JEEN E<lt>jeen@perk_dot_krE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.aladdin.co.kr/ttb/wguide.aspx?pn=apiguide>

L<http://blog.aladdin.co.kr/ttb/category/16526941?communitytype=MyPaper>

=cut
