package Mojolicious::Plugin::PageNavigator;
use Mojo::Base 'Mojolicious::Plugin';
use POSIX( qw/ceil/ );
use Mojo::ByteStream 'b';

use strict;
use warnings;

our $VERSION = 0.01;

# Homer: Well basically, I just copied the plant we have now.
#        Then, I added some fins to lower wind resistance.  
#        And this racing stripe here I feel is pretty sharp.
# Burns: Agreed.  First prize!
sub  register{
  my ( $self, $app, $args ) = @_;
  $args ||= {};

  $app->helper( page_navigator => sub{
      my ( $self, $actual, $count, $opts ) = @_;
      $count = ceil($count);
      return "" unless $count > 1;
      $opts = {} unless $opts;
      my $round = $opts->{round} || 4;
      my $class = $opts->{class} || "number";
      my $param = $opts->{param} || "page";
      my $outer = $opts->{outer} || 2;
      my @current = ( $actual - $round .. $actual + $round );
      my @first   = ( $round > $actual ? (1..$round * 3 ) : (1..$outer) );
      my @tail    = ( $count - $round < $actual ? ( $count - $round * 2 + 1 .. $count ) : 
          ( $count - $outer + 1 .. $count ) );
      my @ret = ();
      my $last = undef;
      foreach my $number( sort { $a <=> $b } @current, @first, @tail ){
        next if $last && $last == $number;
        next if $number <= 0 ;
        last if $number > $count;
        push @ret, ".." if( $last && $last + 1 != $number );
        push @ret, $number;
        $last = $number;
      }
      
      my $html = "<div>";
      if( $actual == 1 ){
        $html .= "<span class=\"$class\">&lt;&lt;</span>";
      } else {
        $html .= "<a href=\"" . $self->url_for->query( $param => $actual - 1 ) . "\" class=\"$class\">&lt;&lt;</a>";
      }
      foreach my $number( @ret ){
        if( $number eq ".." ){
          $html .= "<span class=\"$class\">..</span>";
        } elsif( $number == $actual ) {
        $html .= "<span class=\"$class\">$number</span>";
        } else {
          $html .= "<a href=\"" . $self->url_for->query( $param => $number ) ."\" class=\"$class\">$number</a>";
        }
      }
      if( $actual == $count ){
        $html .= "<span class=\"$class\">&gt;&gt;</span>";
      } else {
        $html .= "<a href=\"" . $self->url_for->query( $param => $actual + 1 ) . "\" class=\"$class\">&gt;&gt;</a>"
      }
      $html .= "<span style=\"clear: left; width: 1px;\">&nbsp;</span></div>";
      return b( $html );
    } );

}

1;
__END__

=head1 NAME

Mojolicious::Plugin::PageNavigator - Page Navigator plugin for Mojolicious

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'page_navigator'

  # Mojolicious
  $self->plugin( 'page_navigator' );

=head1 DESCRIPTION

L<Mojolicious::Plugin::PageNavigator> generates standard page navigation bar, like 
  
<<  1  2 ... 11 12 13 14 15 ... 85 86 >>

=head1 HELPERS

=head2 page_navigator

  %= page_navigator( $current_page, $total_pages, $opts );

=head3 Options

Options is a optional ref hash.

  %= page_navigator( $current_page, $total_pages, {
      round => 4,
      outer => 2,
      class => 'number',
      param => 'page' } );

=over 1

=item round

Number of pages arround the current page. Default: 4.

=item outer

Number of outer window pages (first and last pages). Default 2.

=item class

Class for each page number element. Default: 'number'

=item param

Name of param for query url. Default: 'page'

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 DEVELOPMENT

=head2 Repository

    https://github.com/silvioq/mojolicious-page-navigator

=head1 COPYRIGHT

Copyright (C) 2011, Silvio Quadri

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

