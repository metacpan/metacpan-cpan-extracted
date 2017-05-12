package WWW::Mixi::Scraper::Plugin;

use strict;
use warnings;
use Web::Scraper;
use String::CamelCase qw( decamelize );
use WWW::Mixi::Scraper::Utils qw( _force_arrayref _uri _datetime );

sub import {
  my $class = shift;
  my $pkg = caller;

  my @subs = qw(
    new parse
    scraper process process_first result
    get_content post_process
    validator build_uri
    html_or_text _extract_name
  );

  no strict   'refs';
  no warnings 'redefine';
  foreach my $sub ( @subs ) {
    *{"$pkg\::$sub"} = *{"$class\::$sub"};
  }
}

sub new {
  my ($class, %options) = @_;

  bless \%options, $class;
}

sub html_or_text { shift->{mode} || 'HTML' }

sub parse {
  my $self = shift;

  my $res = $self->scrape($self->get_content(@_));

  return ( wantarray and ref $res eq 'ARRAY' )
    ? @{ $res || [] }
    : $res;
}

sub get_content {
  my ($self, %options) = @_;

  my $content = delete $options{html};

  unless ( $content ) {
    $content = $self->{mech}->get_content($self->build_uri(%options));
  }
  die "no content" unless $content;

  # XXX: preserve some tags like <br>?
  # $content =~ s/<br(\s[^>]*)?>/\n/g; # at least preserve as a space
  $content =~ s/&nbsp;/ /g;          # as it'd be converted as '?'

  return $content;
}

sub build_uri {
  my ($self, %query) = @_;

  my ($name) = (ref $self) =~ /::(\w+)$/;
  my $path = sprintf '/%s.pl', decamelize($name);
  my $uri = URI->new($path);

  foreach my $key ( keys %query ) {
    if ( $self->_is_valid( $key, $query{$key} ) ) {
      $uri->query_param( $key => $query{$key} );
    }
  }

  $uri = $self->tweak_uri($uri) if $self->can('tweak_uri');

  $self->{uri} = $uri;  # preserve for later use.

  return $uri;
}

sub validator ($) {
  my $hashref = shift;
  my $pkg = caller;

  my %rules;
  foreach my $key ( keys %{ $hashref } ) {
    my $rule = $hashref->{$key};
    if ( $rule eq 'is_number' ) {
      $rules{$key} = sub {
        my $value = shift;
        $value && $value =~ /^\d+$/ ? 1 : 0;
      };
    }
    if ( $rule eq 'is_number_or_all' ) {
      $rules{$key} = sub {
        my $value = shift;
        $value && $value =~ /^(?:\d+|all)$/ ? 1 : 0;
      };
    }
    if ( $rule eq 'is_anything' ) {
      $rules{$key} = sub { 1 };
    }
  }

  no strict   'refs';
  no warnings 'redefine';
  *{"$pkg\::_is_valid"} = sub { return $rules{$_[1]} && $rules{$_[1]}->($_[2]) };
}

sub post_process {
  my ($self, $data, $callback) = @_;

  my $arrayref = _force_arrayref($data);

  foreach my $item ( @{ $arrayref } ) {
    if ( ref $callback eq 'CODE' ) {
      $callback->($item);
    }
    foreach my $key ( keys %{ $item } ) {
      next unless $item->{$key};
      if ( $key =~ /time$/ ) {
        $item->{$key} = _datetime($item->{$key})
      }
      elsif ( $key =~ /(?:link|envelope|image|background|src|icon)$/ ) {
        $item->{$key} = _uri($item->{$key});
      }
      elsif ( $key eq 'images' ) {
        $item->{$key} = _images($item->{$key});
      }
    }
  }

  $arrayref = [ grep { %{ $_ } && !$_->{_delete} } @{ $arrayref } ];

  return $arrayref;
}

sub _images {
  my $item = shift;

  $item = [ $item ] unless ref $item;  # a thumbnail

  my @images;
  foreach my $i ( @{ $item || [] } ) {
    next unless $item;
    push @images, __images($i);
  }
  return \@images;
}

sub __images {
  my $item = shift;
  my ($link, $thumb);
  unless ( ref $item eq 'HASH' ) {
    $link = $thumb = $item;
    $link  =~ s/s\.jpg$/\.jpg/;
    $thumb =~ s/(?:[^s])\.jpg$/s\.jpg/;
  }
  else { 
    $link  = $item->{link} || '';
    $thumb = $item->{thumb_link};

    if ( $link =~ /MM_openBrWindow\(\s*'([^']+)'/ ) { $link = $1; }
  }
  return { link => _uri($link), thumb_link => _uri($thumb) };
}

sub _extract_name {
  my $item = shift;

  return unless defined $item->{string} && defined $item->{subject};

  my $name = substr( delete $item->{string}, length $item->{subject} );
     $name =~ s/^\s*\(//;
     $name =~ s/\)\s*$//;
  $item->{name} = $name;
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin - base class for plugins

=head1 SYNOPSIS

    package WWW::Mixi::Scraper::Plugin::<SamplePlugin>

    use strict;
    use warnings;
    use WWW::Mixi::Scraper::Plugin;

    validator {qw( id is_number )};

    sub scrape {
      my ($self, $html) = @_;

      my %scraper;
      $scraper{...} = scraper {
        process '...',
          text => 'TEXT';  # always plain text
        process '...',
          text => 'HTML';  # always HTML
        process '...',
          depends => $self->html_or_text; # HTML or TEXT
        result qw( text depends );
      };

      return $self->post_process($scraper{...}->scrape(\$html));

      return $arrayref;
    }

    1;

=head1 DESCRIPTION

This is a base class for WWW::Mixi::Scraper plugins. You don't need to C<use base qw( WWW::Mixi::Scraper::Plugin )>; just C<use> it. This exports Web::Scraper functions and several public and private methods/functions of its own.

=head1 METHODS

=head2 new

creates an object.

=head2 html_or_text

returns the rendering mode of choice ('TEXT' or 'HTML').

=head2 parse

gets content from a uri, scrapes, and returns an array (or a hash reference, etc) of data.

=head2 build_uri

used internally to build uri from query paramters (and optional hash). If you want to tweak the uri (e.g. to change authority from 'mixi.jp' to 'video.mixi.jp', etc), provide C<tweak_uri()> in your plugin.

=head2 get_content

gets content from the uri specified or from an optional html data.

=head2 post_process

does some common tasks such as to make sure the result be an array reference, remove some temporary data to extract exact information, objectify link data (and maybe datetime data in the future?).

=head2 validator

prepares some simple validator for query parameters, though I'm not sure if this is really useful.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
