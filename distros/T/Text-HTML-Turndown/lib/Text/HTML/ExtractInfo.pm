package Text::HTML::ExtractInfo 0.10;
use 5.020;
use stable 'postderef';
use experimental 'signatures';
use Carp 'croak';

use Exporter 'import';

our @EXPORT_OK = (qw(extract_info));

=head1 SYNOPSIS

  use Text::HTML::ExtractInfo 'extract_info';

  my $tree = XML::LibXML->new->parse_html_string(
      $input,
      { recover => 2, encoding => 'UTF-8' }
  );
  say Dumper extract_info($tree, url => 'https://example.com' );
  # {
  #   title => '...',
  #   external => {
  #       image => [ 'https://example.com/img1.jpg', ... ],
  #   }
  # }

=cut

our %elements = (
    title => {
        single => 1,
        q => [
            '//title',
            '//meta[@property="og:title"]/@content',
            '//meta[@property="twitter:title"]/@content',
            '//h1[1]',
        ],
    },

    url => {
        default => 'url',
        single => 1,
        q => [
           '//link[@rel="canonical"]/@href',
           '//meta[@property="og:url"]/@content',
           '//meta[@property="twitter:url"]/@content',
        ],
    },

    image => {
        q => [
        '//meta[@property="og:image"]/@content',
        '//meta[@property="og:image:url"]/@content',
        '//meta[@property="og:image:secure_url"]/@content',
        '//meta[@property="twitter:image"]/@content',
        ],
    },

    authors =>{
        q => [
        ],
    },
);

sub _get_value( $node ) {
    if( my $c = $node->can( 'value' )) {
        return $c->($node)
    } elsif( $c = $node->can( 'textContent' )) {
        return $c->($node)
    } else {
        croak "Don't know how to handle " . $node->toString
    }
}

sub extract_info( $tree, %options ) {
    my %res;

    for my $k (keys( %elements )) {
        if( my $d = $elements{ $k }->{default} ) {
            $res{ $k } = $options{ $d }
                if exists $options{ $d };
        }
        for my $q ( $elements{ $k }->{q}->@* ) {
            my @nodes = $tree->findnodes($q);
            if( @nodes ) {
                if( $elements{ $k }->{single} ) {
                    $res{ $k } = _get_value( $nodes[0] )
                } else {
                    $res{ $k } = [ map { _get_value( $_ )} @nodes ];
                }
                last
            }
        }
    }

    return \%res,
}

1;

=head1 SEE ALSO

L<HTML::ExtractMeta> - extract information from C<< <META >> tags

=cut
