package Web::Dispatch::Parser;

sub DEBUG () { 0 }

BEGIN {
  if ($ENV{WEB_DISPATCH_PARSER_DEBUG}) {
    no warnings 'redefine';
    *DEBUG = sub () { 1 }
  }
}

use Sub::Quote;
use Web::Dispatch::Predicates;
use Moo;

has _cache => (
  is => 'lazy', default => quote_sub q{ {} }
);

sub diag { if (DEBUG) { warn $_[0] } }

sub _wtf {
  my ($self, $error) = @_;
  my $hat = (' ' x (pos||0)).'^';
  warn "Warning parsing dispatch specification: ${error}\n
${_}
${hat} here\n";
}

sub _blam {
  my ($self, $error) = @_;
  my $hat = (' ' x (pos||0)).'^';
  die "Error parsing dispatch specification: ${error}\n
${_}
${hat} here\n";
}

sub parse {
  my ($self, $spec) = @_;
  $spec =~ s/\s+//g; # whitespace is not valid
  return $self->_cache->{$spec} ||= $self->_parse_spec($spec);
}

sub _parse_spec {
  my ($self, $spec, $nested) = @_;
  return match_true() unless length($spec);
  for ($_[1]) {
    my @match;
    my $close;
    PARSE: { do {
      push @match, $self->_parse_spec_section($_)
        or $self->_blam("Unable to work out what the next section is");
      if (/\G\)/gc) {
        $self->_blam("Found closing ) with no opening (") unless $nested;
        $close = 1;
        last PARSE;
      }
      last PARSE if (pos == length);
      $match[-1] = $self->_parse_spec_combinator($_, $match[-1])
        or $self->_blam('No valid combinator - expected + or |');
    } until (pos == length) }; # accept trailing whitespace
    if (!$close and $nested and pos == length) {
      pos = $nested - 1;
      $self->_blam("No closing ) found for opening (");
    }
    return $match[0] if (@match == 1);
    return match_and(@match);
  }
}

sub _parse_spec_combinator {
  my ($self, $spec, $match) = @_;
  for ($_[1]) {

    /\G\+/gc and
      return $match;

    /\G\|/gc and
      return do {
        my @match = $match;
        PARSE: { do {
          push @match, $self->_parse_spec_section($_)
            or $self->_blam("Unable to work out what the next section is");
          last PARSE if (pos == length);
          last PARSE unless /\G\|/gc; # give up when next thing isn't |
        } until (pos == length) }; # accept trailing whitespace
        return match_or(@match);
      };
  }
  return;
}

sub _parse_spec_section {
  my ($self) = @_;
  for ($_[1]) {

    # ~

    /\G~/gc and
      return match_path('^$');

    # GET POST PUT HEAD ...

    /\G([A-Z]+)/gc and
      return match_method($1);

    # /...

    /\G(?=\/)/gc and
      return $self->_url_path_match($_);

    # .* and .html

    /\G\.(\*|\w+)/gc and
      return match_extension($1);

    # (...)

    /\G\(/gc and
      return $self->_parse_spec($_, pos);

    # !something

    /\G!/gc and
      return match_not($self->_parse_spec_section($_));

    # ?<param spec>
    /\G\?/gc and
      return $self->_parse_param_handler($_, 'query');

    # %<param spec>
    /\G\%/gc and
      return $self->_parse_param_handler($_, 'body');

    # *<param spec>
    /\G\*/gc and
      return $self->_parse_param_handler($_, 'uploads');
  }
  return; # () will trigger the blam in our caller
}

sub _url_path_match {
  my ($self) = @_;
  for ($_[1]) {
    my (@path, @names, $seen_nameless);
    my $end = '';
    my $keep_dot;
    PATH: while (/\G\//gc) {
      /\G\.\.\./gc
        and do {
          $end = '(/.*)';
          last PATH;
        };

      my ($segment) = $self->_url_path_segment_match($_)
        or $self->_blam("Couldn't parse path match segment");

      if (ref($segment)) {
        ($segment, $keep_dot, my $name) = @$segment;
        if (defined($name)) {
          $self->_blam("Can't mix positional and named captures in path match")
            if $seen_nameless;
          push @names, $name;
        } else {
          $self->_blam("Can't mix positional and named captures in path match")
            if @names;
          $seen_nameless = 1;
        }
      }
      push @path, $segment;

      /\G\.\.\./gc
        and do {
          $end = '(|/.*)';
          last PATH;
        };
      /\G\.\*/gc
        and $keep_dot = 1;

      last PATH if $keep_dot;
    }
    if (@path && !$end && !$keep_dot) {
      length and $_ .= '(?:\.\w+)?' for $path[-1];
    }
    my $re = '^('.join('/','',@path).')'.$end.'$';
    $re = qr/$re/;
    if ($end) {
      return match_path_strip($re, @names ? \@names : ());
    } else {
      return match_path($re, @names ? \@names : ());
    }
  }
  return;
}

sub _url_path_segment_match {
  my ($self) = @_;
  for ($_[1]) {
    # trailing / -> require / on end of URL
    /\G(?:(?=[+|\)])|$)/gc and
      return '';
    # word chars only -> exact path part match
    /
        \G(
            (?:             # start matching at a space followed by:
                    [\w\-]  # word chars or dashes
                |           # OR
                    \.      # a period
                    (?!\.)  # not followed by another period
            )
            +               # then grab as far as possible
        )
    /gcx and
      return "\Q$1";
    # ** -> capture unlimited path parts
    /\G\*\*(?:(\.\*)?\:(\w+))?/gc and
      return [ '(.*?[^/])', $1, $2 ];
    # * -> capture path part
    # *:name -> capture named path part
    /\G\*(?:(\.\*)?\:(\w+))?/gc and
      return [ '([^/]+?)', $1, $2 ];

    # :name -> capture named path part
    /\G\:(\w+)/gc and
      return [ '([^/]+?)', 0, $1 ];
  }
  return ();
}

sub _parse_param_handler {
  my ($self, $spec, $type) = @_;

  for ($_[1]) {
    my (@required, @single, %multi, $star, $multistar, %positional, $have_kw);
    my %spec;
    my $pos_idx = 0;
    PARAM: { do {

      # ?:foo or ?@:foo

      my $is_kw = /\G\:/gc;

      # ?@foo or ?@*

      my $multi = /\G\@/gc;

      # @* or *

      if (/\G\*/gc) {

        $self->_blam("* is always named; no need to supply :") if $is_kw;

        if ($star) {
          $self->_blam("Can only use one * or \@* in a parameter match");
        }

        $spec{star} = { multi => $multi };
      } else {

        # @foo= or foo= or @foo~ or foo~

        /\G([\w.]*)/gc or $self->_blam('Expected parameter name');

        my $name = $1;

        # check for = or ~ on the end

        /\G\=/gc
          ? push(@{$spec{required}||=[]}, $name)
          : (/\G\~/gc or $self->_blam('Expected = or ~ after parameter name'));

        # record positional or keyword

        push @{$spec{$is_kw ? 'named' : 'positional'}||=[]},
          { name => $name, multi => $multi };
      }
    } while (/\G\&/gc) }

    return Web::Dispatch::Predicates->can("match_${type}")->(\%spec);
  }
}

1;
