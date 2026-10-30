# ABSTRACT: broken link checker for published sites


package byterazor::HiD::BrokenLink;

use Moose;
extends 'HiD::Plugin';

use 5.014; # strict
use autodie;
use warnings   qw/ FATAL         /;

use File::Find::Rule;
use File::Spec;
use HTML::Parser;
use Path::Tiny;

our $VERSION = '0.1';


sub after_publish {
  my( $self , $site ) = @_;

  my $cfg = $site->config->{brokenlink} || {};
  return 1 unless $cfg->{enabled} // 1;

  my $result = $self->scan( $site );
  my $broken = $result->{broken};

  for my $b ( @$broken ) {
    $site->WARN(
      "brokenlink: $b->{src}: $b->{link} -> missing $b->{resolved}"
      . ( $b->{reason} ? " ($b->{reason})" : '' )
    );
  }

  $site->INFO(
    sprintf(
      "brokenlink: checked %d reference(s) in %d file(s); %d broken" ,
      $result->{checked} , $result->{files_checked} , scalar @$broken
    )
  );

  $self->_write_report( $cfg->{report} , $result ) if $cfg->{report};

  if ( $cfg->{fail_on_broken} && @$broken ) {
    die "brokenlink: " . scalar( @$broken ) . " broken reference(s) found";
  }

  return 1;
}


sub scan {
  my( $self , $site ) = @_;

  my $dest = $site->destination;
  my $cfg  = $site->config->{brokenlink} || {};

  my $check_html    = $cfg->{check_html}    // 1;
  my $check_css     = $cfg->{check_css}     // 1;
  my $check_js      = $cfg->{check_js}      // 0;
  my $strip_baseurl = $cfg->{strip_baseurl} // 1;
  my $exclude       = $cfg->{exclude} || [];

  my $prefix = $strip_baseurl
    ? $self->_baseurl_prefix( $site->config->{baseurl} )
    : undef;

  my ( %files , @file_rels ) = ( () , () );
  my ( %dirs ,  @dir_rels  ) = ( () , () );

  if ( -d $dest ) {
    for my $f ( File::Find::Rule->file()->in( $dest ) ) {
      my $rel = _rel( $f , $dest );
      next if $rel eq '.';
      $files{$rel} = 1;
      push @file_rels , $rel;
    }

    for my $d ( File::Find::Rule->directory()->in( $dest ) ) {
      my $rel = _rel( $d , $dest );
      next if $rel eq '.';
      $dirs{$rel} = 1;
      push @dir_rels , $rel;
    }
  }

  my $files_checked = 0;
  my $checked       = 0;
  my @broken;

  for my $rel ( sort @file_rels ) {
    my $is_html = $rel =~ m{\A(?:[^/]+/)*[^/]*\.html?\z}i;
    my $is_css  = $rel =~ m{\A(?:[^/]+/)*[^/]*\.css\z}i;
    my $is_js   = $rel =~ m{\A(?:[^/]+/)*[^/]*\.js\z}i;

    next unless ( $is_html and $check_html )
              or ( $is_css  and $check_css  )
              or ( $is_js   and $check_js   );

    $files_checked++;

    my $content = path( $dest , $rel )->slurp_raw;

    my $source_dir = $rel;
    $source_dir =~ s{[^/]+\z}{};
    $source_dir =~ s{/+\z}{};

    my ( $refs , $base_href ) = ( [] , undef );

    if ( $is_html ) {
      ( $refs , $base_href ) = $self->_extract_html( $content );
    }
    elsif ( $is_css ) {
      $refs = $self->_extract_css_urls( $content );
    }
    else {
      $refs = $self->_extract_js_refs( $content );
    }

    my ( $resolve_dir , $skip_all ) = $self->_base_directories(
      $base_href , $source_dir , $prefix
    );

    for my $ref ( @$refs ) {
      next if @$exclude and grep { $ref =~ /$_/ } @$exclude;

      my $link = $ref;
      $link =~ s{\A\Q$prefix\E(?=[/?#]|\z)}{} if $prefix;

      my $target = $skip_all ? undef : $self->_classify( $link , $resolve_dir );
      next unless defined $target;

      $checked++;

      if ( $target->{escape} ) {
        push @broken , {
          src      => $rel ,
          link     => $ref ,
          resolved => $ref ,
          reason   => 'escapes destination' ,
        };
        next;
      }

      my $r  = $target->{rel};
      my $ok = $r eq ''
        ? 1
        : ( $target->{trailing}
            ? ( exists $dirs{$r} or exists $files{"$r/index.html"} )
            : ( exists $files{$r}
                or exists $dirs{$r}
                or exists $files{"$r/index.html"} ) );

      push @broken , {
        src      => $rel ,
        link     => $ref ,
        resolved => $r eq '' ? '/' : $r . ( $target->{trailing} ? '/' : '' ) ,
      } unless $ok;
    }
  }

  return {
    files         => [ sort keys %files ] ,
    dirs          => [ sort keys %dirs ] ,
    files_checked => $files_checked ,
    checked       => $checked ,
    broken        => \@broken ,
  };
}


sub _extract_html {
  my( $self , $content ) = @_;

  my @refs;
  my $base_href;
  my $style_depth = 0;
  my $style_buf   = '';

  my $parser = HTML::Parser->new(
    api_version => 3 ,
    handlers => {
      start => [
        sub {
          my( $p , $tag , $attr ) = @_;

          if ( $tag eq 'base' ) {
            $base_href = $attr->{href}
              if !defined $base_href
              and defined $attr->{href} and length $attr->{href};
            return;   # the base href itself is not a reference
          }

          push @refs , $attr->{$_}
            for grep { defined $attr->{$_} and length $attr->{$_} }
            qw/ href src data poster /;

          $style_depth++ if $tag eq 'style';
        } ,
        'self,tagname,attr' ,
      ],
      end => [
        sub {
          if ( $_[1] eq 'style' and $style_depth ) {
            $style_depth--;
            if ( !$style_depth ) {
              push @refs , @{ $self->_extract_css_urls( $style_buf ) };
              $style_buf = '';
            }
          }
        } ,
        'self,tagname' ,
      ],
      text  => [
        sub { $style_buf .= $_[1] if $style_depth; } ,
        'self,text,is_cdata' ,
      ],
    },
  );

  $parser->parse( $content );

  return \@refs , $base_href;
}


sub _extract_css_urls {
  my( $self , $content ) = @_;

  my @refs;

  while ( $content =~ m{
        url\s*\(\s*
      (?: "([^"]*)"
        | '([^']*)'
        | ([^\s)"']+) )
      \s*\)
    }gx ) {
    my $ref = $1 // $2 // $3;
    push @refs , $ref if defined $ref and length $ref;
  }

  while ( $content =~ m{
        @\s*import\s+
      (?: "([^"]*)"
        | '([^']*)'
        | (?!(?:url\s*)?\()([^\s;)"']+) )
    }gx ) {
    my $ref = $1 // $2 // $3;
    push @refs , $ref if defined $ref and length $ref;
  }

  return \@refs;
}


sub _extract_js_refs {
  my( $self , $content ) = @_;

  my @refs;

  while ( $content =~ m{
        ["']
        ( /(?:[^/"'\n]+/)*[^/"'\n]*
          \.(?:css|js|mjs|json|png|jpe?g|gif|svg|webp|avif|ico
               |woff2?|ttf|otf|eot|mp4|webm|mp3|ogg) )
        ["']
      }gx ) {
    push @refs , $1;
  }

  return \@refs;
}


sub _base_directories {
  my( $self , $base_href , $source_dir , $prefix ) = @_;

  return ( $source_dir , 0 )
    unless defined $base_href and length $base_href;

  my $href = $base_href;
  $href =~ s{\A\Q$prefix\E(?=[/?#]|\z)}{} if $prefix;
  $href =~ s{\#.*}{};
  $href =~ s{\?.*}{};

  if ( $href =~ m{\A//} or $href =~ m{\A[a-zA-Z][a-zA-Z0-9+.\-]*:} ) {
    return ( undef , 1 );
  }

  $href =~ s{/+\z}{};

  my $resolve_dir = $source_dir;
  if ( $href =~ m{\A/} ) {
    $href =~ s{\A/}{};
    $resolve_dir = $href;
  }
  elsif ( length $href ) {
    $resolve_dir = $source_dir ne '' ? $source_dir . '/' . $href : $href;
  }

  return ( $resolve_dir , 0 );
}


sub _classify {
  my( $self , $link , $resolve_dir ) = @_;

  $link =~ s{\#.*}{};
  $link =~ s{\?.*}{};
  return unless length $link;

  return if $link =~ m{\A//};
  return if $link =~ m{\A[a-zA-Z][a-zA-Z0-9+.\-]*:};

  my $trailing = $link =~ m{/+\z} ? 1 : 0;
  $link =~ s{/+\z}{};

  if ( $link =~ m{\A/} ) {
    $link =~ s{\A/}{};
    return { rel => $link , trailing => $trailing };
  }

  return $self->_clean_rel( $resolve_dir , $link , $trailing );
}

sub _clean_rel {
  my( $self , $dir , $link , $trailing ) = @_;

  my @parts = $dir ne '' ? split( m{/} , $dir ) : ();

  for my $seg ( split( m{/} , $link ) ) {
    next if $seg eq '' or $seg eq '.';
    if ( $seg eq '..' ) {
      if ( @parts ) { pop @parts; }
      else          { return { escape => 1 }; }
    }
    else {
      push @parts , $seg;
    }
  }

  return { rel => join( '/' , @parts ) , trailing => $trailing };
}

sub _baseurl_prefix {
  my( $self , $baseurl ) = @_;

  return unless defined $baseurl and $baseurl =~ m{\Ahttps?://}i;

  $baseurl =~ s{[?#].*$}{};
  $baseurl =~ s{/+\z}{};

  return length $baseurl ? $baseurl : undef;
}


sub _write_report {
  my( $self , $path , $result ) = @_;

  my $text = "brokenlink: checked $result->{checked} reference(s) "
    . "in $result->{files_checked} file(s); "
    . scalar( @{ $result->{broken} } ) . " broken\n\n";

  for my $b ( @{ $result->{broken} } ) {
    $text .= "- $b->{src}: $b->{link} -> missing $b->{resolved}"
      . ( $b->{reason} ? " ($b->{reason})" : '' )
      . "\n";
  }

  my $file = path( $path );
  $file->parent->mkpath;
  $file->spew( $text );

  return $file->stringify;
}

sub _rel {
  my( $path , $base ) = @_;

  my $rel = File::Spec->abs2rel( $path , $base );
  $rel =~ s{^/+}{};
  $rel =~ s{/+\z}{};

  return $rel;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

byterazor::HiD::BrokenLink - broken link checker for published sites

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This plugin checks, after the site has been published, that every local
file reference in the published output points to an existing file.

It scans

=over 4

=item * HTML files - the C<href>, C<src>, C<data> and C<poster> attributes
of any element, plus C<url()> references in inline C<< <style> >> blocks.

=item * CSS files - C<url()> references and C<@import> statements.

=item * JavaScript files (opt-in) - quoted root-relative references to
known asset types.

=back

External URLs (other schemes and other hosts), pure fragments and
protocol-relative URLs are skipped. Query strings and fragments are
stripped from the remaining links before they are checked. If the site
has a C<baseurl>, absolute URLs matching it are treated as local. A
C<< <base href> >> element is respected when resolving relative
references; a file with an external base URL is not checked at all.

Enable it by adding C<+byterazor::HiD::BrokenLink> to the C<plugins> key
in your config:

    plugins:
      - '+byterazor::HiD::BrokenLink'

You may set the following C<brokenlink.*> config keys:

=over 4

=item C<brokenlink.enabled>

Run the check. Defaults to 1.

=item C<brokenlink.check_html>

Check HTML files. Defaults to 1.

=item C<brokenlink.check_css>

Check CSS files. Defaults to 1.

=item C<brokenlink.check_js>

Check JavaScript files. Defaults to 0.

=item C<brokenlink.strip_baseurl>

Treat absolute URLs matching the site C<baseurl> as local. Defaults to 1.

=item C<brokenlink.exclude>

Arrayref of regexes; references matching any of them are not checked.

=item C<brokenlink.report>

Path of a text report listing the broken references. The path is
interpreted relative to the current working directory, B<not> relative
to the site destination. Only written when set.

=item C<brokenlink.fail_on_broken>

Die, failing the build, when broken references are found. Defaults to 0.

=back

A link is considered OK if it matches an existing file or directory. A
link with a trailing slash matches an existing directory or an
C<index.html> inside it; a link without a trailing slash also matches
an C<index.html> inside a directory of the same name.

=head1 METHODS

=head2 after_publish

Checks the published site for broken local references, reports each of
them via C<$site->WARN>, emits a summary via C<$site->INFO>, optionally
writes a report file, and dies when C<brokenlink.fail_on_broken> is set
and broken references were found.

=head2 scan

Walks the site destination, extracts every reference from the scannable
files and checks the local ones for existence. Returns a result
hashref with the keys C<files>, C<dirs>, C<files_checked>, C<checked>
and C<broken> (an arrayref of C<< { src , link , resolved , reason? } >>).

=head2 _extract_html

Extracts references from an HTML document using HTML::Parser. Returns
an arrayref of reference values and the value of the first
C<< <base href> >> element (or undef). Contents of C<< <style> >>
elements are collected and scanned for CSS C<url()> references.

=head2 _extract_css_urls

Extracts the reference values of C<url()> and C<@import> statements
from CSS text.

=head2 _extract_js_refs

Best-effort extraction of root-relative asset references from
JavaScript: quoted strings starting at the site root that end with a
known asset extension.

=head2 _base_directories

Given a C<< <base href> >> value (or undef), the directory the source
file lives in, and the site baseurl prefix, returns the directory
relative links must be resolved against and a flag that is true when
the base URL is external (in which case nothing can be resolved
locally).

=head2 _classify

Classifies a reference. Returns undef for external references and for
references that are empty once fragment and query string are stripped.
Returns C<< { escape => 1 } >> when a relative reference resolves
outside the destination, and otherwise C<< { rel => $path , trailing => $bool } >>.

=head2 _write_report

Writes a plain-text report of the broken references to the given path,
which is interpreted relative to the current working directory (or
taken as absolute), not relative to the site destination.

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
