package WWW::Amazon::BestSeller;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use HTML::TreeBuilder;
use WWW::UserAgent::Random;

use Exporter; # 'import';
use vars qw/@EXPORT @EXPORT_OK @ISA $DEBUG $ua/;
@ISA = qw/Exporter/;

@EXPORT = qw/get_top_category get_sub_category/;  # symbols to export on request
@EXPORT_OK = @EXPORT;  # symbols to export on request

=head1 NAME

WWW::Amazon::BestSeller - The great new WWW::Amazon::BestSeller!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

抓取 Amazon Best Seller 类别列表, 默认是 com 站,
可以通过指定完整的url去获得其它网站的 Best Seller


    use WWW::Amazon::BestSeller;

    my $top_categorys = get_top_category();
    my $top_sub_categorys = get_sub_category( $up_level_url );

=head1 EXPORT

默认导出 get_top_category 和 get_sub_category 函数

=head1 SUBROUTINES/METHODS

=head2 get_top_category

如果不指定 url, 则默认去取 US 的 Top Selles

=cut

sub get_top_category {
  my $top_url = shift;
  $top_url ||= 'http://www.amazon.com/Best-Sellers/zgbs/ref=zg_bs_unv_la_0_la_1';

  return _get_with_retry( $top_url );
}

=head2 get_sub_category

获得指定 url 类别的子类别

=cut

sub get_sub_category {
  my $sub_url = shift;
  return [] unless $sub_url;

  return _get_with_retry( $sub_url );
}

sub _get_ua {
  return $ua if $ua;
  $ua = LWP::UserAgent->new( agent => rand_ua("") );
  return $ua;
}

sub _get_with_retry {
  my ( $url, $retry ) = @_;
  $retry ||= 20;

  my $ua = _get_ua();
  $ua->default_header( referer => $url );

  my @cs; # 保存得到的 sub category

  while ( $retry > 0 ) {
    print "GETING: $url\n" if $DEBUG;
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
      my $t = HTML::TreeBuilder->new_from_content( $res->content );

      my @cates = $t->look_down( _tag => 'ul', id => 'zg_browseRoot' );
      @cates = map { $_->look_down( _tag => 'a' ) } @cates;

      my $index = 1;
      foreach ( @cates ) {
        push @cs, {
          index => $index,
          name => $_->as_trimmed_text,
          url => $_->attr( 'href' )
        };
        $index++;
      }
      last;
    } else {
      print "Retry: $retry\tGet fails: " . $res->code. "\n" if $DEBUG;
      $ua->default_header( agent => rand_ua("") );
      sleep( 2 );
      $retry--;
    }
  }
  return \@cs;
}


=head1 AUTHOR

MC Cheung, C<< <mc.cheung at aol.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-amazon-bestseller at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Amazon-BestSeller>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

    perldoc WWW::Amazon::BestSeller

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Amazon-BestSeller>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Amazon-BestSeller>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Amazon-BestSeller>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Amazon-BestSeller/>

=back

=cut

1; # End of WWW::Amazon::BestSeller
