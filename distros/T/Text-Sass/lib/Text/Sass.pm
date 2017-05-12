# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-11-10 16:33:37 +0000 (Sat, 10 Nov 2012) $
# Id:            $Id: Sass.pm 75 2012-11-10 16:33:37Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/lib/Text/Sass.pm $
#
# Note to reader:
# Recursive regex processing can be very bad for your health.
# Sass & SCSS are both pretty cool. This module is not.
#
package Text::Sass;
use strict;
use warnings;
use Carp;
use English qw(-no_match_vars);
use Text::Sass::Expr;
use Text::Sass::Functions;
use Text::Sass::Token;
use Data::Dumper;
use Readonly;

our $VERSION = q[1.0.4];
our $DEBUG     = 0;
our $FUNCTIONS = [qw(Text::Sass::Functions)];

Readonly::Scalar our $DEBUG_SEPARATOR => 30;

sub import {
  my ($class, @args) = @_;

  if(!scalar @args % 2) {
    my $args = {@args};
    if($args->{Functions}) {
      for my $functions (@{$args->{Functions}}) {
        eval "require $functions" or carp qq[Could not require $functions: $EVAL_ERROR]; ## no critic (ProhibitStringyEval)

        push @{$FUNCTIONS}, $functions;
      }
    }
  }

  return 1;
}

sub new {
  my ($class, $ref) = @_;

  if(!$ref) {
    $ref = {};
  }

  bless $ref, $class;
  return $ref;
}

sub css2sass {
  my ($self, $str) = @_;

  if(!ref $self) {
    $self = $self->new;
  }

  my $symbols = {};
  my $stash   = [];
  $self->_parse_css($str, $stash, $symbols);
  return $self->_stash2sass($stash, $symbols);
}

sub sass2css {
  my ($self, $str) = @_;

  if(!ref $self) {
    $self = $self->new;
  }

  my $symbols = {};
  my $stash   = [];
  my $chain   = [];
  $self->{_sass_indent} = 0;
  $self->_parse_sass($str, $stash, $symbols, $chain);
  return $self->_stash2css($stash, $symbols);
}

sub scss2css {
  my ($self, $str) = @_;

  if(!ref $self) {
    $self = $self->new;
  }

  my $symbols = {};
  my $stash   = [];
  $self->_parse_css($str, $stash, $symbols);
  return $self->_stash2css($stash, $symbols);
}

sub _parse_sass {
  my ($self, $str, $substash, $symbols, $chain) = @_;
  $DEBUG and print {*STDERR} q[=]x$DEBUG_SEPARATOR, q[begin _parse_sass], q[=]x$DEBUG_SEPARATOR, "\n";

  #########
  # insert blank links after code2:
  # code1
  #  code2
  # code3
  #  code4
  #
  $str =~ s/\n(\S)/\n\n$1/smxg;

  #########
  # strip blank lines from:
  # <blank line>
  #   code
  #
  $str =~ s/^\s*\n(\s+)/$1/smxg;
  my $groups = [split /\n\s*?\n/smx, $str];
  for my $g (@{$groups}) {
    $self->_parse_sass_group($substash, $symbols, $chain, $g);
  }

  $DEBUG and print {*STDERR} q[=]x$DEBUG_SEPARATOR, q[ end _parse_sass ], q[=]x$DEBUG_SEPARATOR, "\n";

  return 1;
}

sub _parse_sass_group {
  my ($self, $substash, $symbols, $chain, $group) = @_;

  my @lines = split /\n/smx, $group;

  while(my $line = shift @lines) {
    #########
    # /* comment */
    # /* comment
    #
    $line =~ s{/[*].*?[*]/\s*}{}smx;
    $line =~ s{/[*].*$}{}smx;

    #########
    # !x = y   variable declarations
    #
    $line =~ s{^\!(\S+)\s*=\s*(.*?)$}{
      $symbols->{variables}->{$1} = $2;
      $DEBUG and carp qq[VARIABLE $1 = $2];
      q[];
    }smxegi;

    #########
    # $x : y   variable declarations
    #
    $line =~ s{^\$(\S+)\s*:\s*(.*?)$}{
      $symbols->{variables}->{$1} = $2;
      $DEBUG and carp qq[VARIABLE $1 = $2];
      q[];
    }smxegi;

    #########
    # =x              |      =x(!var)
    #   bla           |        bla
    #
    # mixin declaration
    #
    $line =~ s{^=(.*?)$}{
      my $mixin_stash = {};
      my $remaining   = join "\n", @lines;
      @lines          = ();
      my $proto       = $1;
      my ($func)      = $1 =~ /^([^(]+)/smx;

      #########
      # mixins are interpolated later, so we just store the string here
      #
      $symbols->{mixins}->{$func} = "$proto\n$remaining\n";
      $DEBUG and carp qq[MIXIN $func];
      q[];
    }smxegi;

    #########
    # @include
    #
    # mixin usage
    #
    $line =~ s{^\@include\s*(.*?)(?:[(](.*?)[)])?$}{
      my ($func, $argstr) = ($1, $2);
      my $mixin_str  = $symbols->{mixins}->{$func};

      my $subsymbols = $symbols; # todo: correct scoping - is better as {%{$symbols}}
      my $values     = $argstr ? [split /\s*,\s*/smx, $argstr] : [];
      my ($varstr)   = $mixin_str =~ /^.*?[(](.*?)[)]/smx;
      my $vars       = $varstr ? [split /\s*,\s*/smx, $varstr] : [];

      for my $var (@{$vars}) {
        $var =~ s/^[\!\$]//smx;
        $subsymbols->{variables}->{$var} = shift @{$values};
      }

      $mixin_str    =~ s/^.*?\n//smx;
      my $result    = [];

      $self->_parse_sass($mixin_str, $result, $subsymbols, [@{$chain}]);
      push @{$substash}, {"+$func" => $result};

      $DEBUG and carp qq[DYNAMIC MIXIN $func];
      q[];
    }smxegi;

    #########
    # @mixin name
    #   bla
    #
    # mixin declaration
    #
    $line =~ s{^\@mixin\s+(.*?)$}{
      my $mixin_stash = {};
      my $remaining   = join "\n", @lines;
      @lines          = ();
      my $proto       = $1;
      my ($func)      = $1 =~ /^([^(]+)/smx;

      #########
      # mixins are interpolated later, so we just store the string here
      #
      $symbols->{mixins}->{$func} = "$proto\n$remaining\n";
      $DEBUG and carp qq[MIXIN $func];
      q[];
    }smxegi;

    #########
    # static +mixin
    #
    $line =~ s{^[+]([^(]+)$}{
      my $func      = $1;
      my $mixin_str = $symbols->{mixins}->{$func};
      $mixin_str    =~ s/^.*?\n//smx;
      my $result    = [];

      $self->_parse_sass($mixin_str, $result, $symbols, [@{$chain}]);

      my $mixin_tag = (keys %{$result->[0]})[0];
      push @{$substash}, {$mixin_tag => (values %{$result->[0]})[0]};
      $DEBUG and carp qq[STATIC MIXIN $func / $mixin_tag];
      q[];
    }smxegi;

    #########
    # interpolated +mixin(value)
    #
    $line =~ s{^[+](.*?)[(](.*?)[)]$}{
      my ($func, $argstr) = ($1, $2);
      my $mixin_str  = $symbols->{mixins}->{$func};

      my $subsymbols = $symbols; # todo: correct scoping - is better as {%{$symbols}}
      my $values     = [split /\s*,\s*/smx, $argstr];
      my ($varstr)   = $mixin_str =~ /^.*?[(](.*?)[)]/smx;
      my $vars       = [split /\s*,\s*/smx, $varstr];

      for my $var (@{$vars}) {
        $var =~ s/^[\!\$]//smx;
        $subsymbols->{variables}->{$var} = shift @{$values};
      }

      $mixin_str    =~ s/^.*?\n//smx;
      my $result    = [];

      $self->_parse_sass($mixin_str, $result, $subsymbols, [@{$chain}]);
      push @{$substash}, {"+$func" => $result};

      $DEBUG and carp qq[DYNAMIC MIXIN $func];
      q[];
    }smxegi;

    #########
    # parent ref
    #
    # tag
    #   attribute: value
    #   &:pseudoclass
    #     attribute: value2
    #
    $line =~ s{^(&\s*.*?)$}{$self->_parse_sass_parentref($substash, $symbols, $chain, \@lines, $1)}smxegi;

    #########
    # static and dynamic attr: value
    # color: #aaa
    #
    $line =~ s{^(\S+)\s*[:=]\s*(.*?)$}{
      my $key = $1;
      my $val = $2;

      $DEBUG and carp qq[ATTR $key = $val];

      if($val =~ /^\s*$/smx) {
        my $remaining = join "\n", @lines;
        @lines        = ();
        my $ssubstash = [];
        $self->_parse_sass($remaining, $ssubstash, $symbols, [@{$chain}]);
        push @{$substash}, { "$key:" => $ssubstash };
      } else {
        push @{$substash}, { $key => $val };
      }
      q[];
    }smxegi;

    #########
    #   <x-space indented sub-content>
    #
    if ($line =~ /^([ ]+)(\S.*)$/smx) {
      my $indent = $1;
      # Indented
      if (!$self->{_sass_indent}) {
        $self->{_sass_indent} = length $1;
      }

      if ($line =~ /^[ ]{$self->{_sass_indent}}(\S.*)$/smx) {
        my $process = [];
        while (my $l = shift @lines) {
          if($l =~ /^[ ]{$self->{_sass_indent}}(.*)$/smx) {
            push @{$process}, $1;
          } elsif ($l !~ /^\s*$/xms) {
            #########
            # put it back where it came from
            #
            unshift @lines, $l;
            last;
          }
        }

        my $remaining = join "\n", $1, @{$process};

        $DEBUG and carp qq[INDENTED $line CALLING DOWN REMAINING=$remaining ].Dumper($substash);
        $self->_parse_sass($remaining, $substash, $symbols, [@{$chain}]);
        $line = q[];

      } else {
        croak qq[Illegal indent @{[length $indent]} we're using @{[$self->{_sass_indent}]}  ($line)];
      }
    }

    #########
    # .class
    # #id
    # element
    # element2, element2
    #   <following content>
    #
    $line =~ s{^(\S+.*?)$}{
      my $one = $1;
      $one    =~ s/\s+/ /smxg;

      my $remaining     = join "\n", @lines;
      @lines            = ();
      my $subsubstash   = [];

      $DEBUG and carp qq[ELEMENT $one descending with REMAINING=$remaining];
      $DEBUG and carp Dumper($substash);
      $self->_parse_sass($remaining, $subsubstash, $symbols, [@{$chain}, $one]);
      push @{$substash}, { $one => $subsubstash };
      $DEBUG and carp qq[ELEMENT $one returned];
      $DEBUG and carp Dumper($substash);
      q[];
    }smxegi;

    $DEBUG and $line and carp qq[REMAINING $line];
  }

  return 1;
}

sub _parse_sass_parentref { ## no critic (ProhibitManyArgs) # todo: tidy this up!
  my ($self, $substash, $symbols, $chain, $lines, $pseudo) = @_;

  my $remaining = join "\n", @{$lines};
  @{$lines}     = ();
  my $newkey    = join q[ ], @{$chain};
  $pseudo       =~ s/&/&$newkey/smx;

  my $subsubstash = [];
  $self->_parse_sass($remaining, $subsubstash, $symbols, ['TBD']);
  push @{$substash}, {$pseudo => $subsubstash};

  return q[];
}

sub _css_nestedgroups {
  my ($self, $str) = @_;

  my $groups   = [];
  my $groupstr = q[];
  my $indent   = 0;

  for my $i (0..length $str ) {
    my $char   = substr $str, $i, 1;
    $groupstr .= $char;

    if ($char eq '{') {
      $indent++;
    }

    if ($char eq '}') {
      $indent--;
      if ($indent == 0) {
        push @{$groups}, $groupstr;
        $groupstr = q[];
      }
    }
  }

  return $groups;
}

sub _css_kvs {
  my ($self, $str) = @_;

  my $groups   = [];
  my $groupstr = q[];
  my $indent   = 0;

  for my $i (0..length $str) {
    my $char = substr $str, $i, 1;

    if ($char eq q[;] and $indent == 0) {
      push @{$groups}, $groupstr;
      $groupstr = q[];

    } else {
      $groupstr .= $char;
    }

    if ($char eq '{') {
      $indent++;
    }

    if ($char eq '}') {
      $indent--;
      if ($indent == 0) {
        push @{$groups}, $groupstr;
        $groupstr = q[];
      }
    }
  }

  return $groups;
}

sub _parse_css {
  my ($self, $str, $substash, $symbols) = @_;

  #########
  # /* comment */
  # // comment
  #
  $str =~ s{$Text::Sass::Token::COMMENT}{}smxg;
  $str =~ s{$Text::Sass::Token::SINGLE_LINE_COMMENT}{}smxg;

  # Normalize line breaks
  $str =~ s/\n//sg; ## no critic (RegularExpressions)
  $str =~ s/;/;\n/sg; ## no critic (RegularExpressions)
  $str =~ s/{/{\n/sg; ## no critic (RegularExpressions)
  $str =~ s/}/}\n/sg; ## no critic (RegularExpressions)

  #########
  # scss definitions
  #
  $str =~ s{^\s*\$(\S+)\s*:\s*(.*?)\s*\;}{
    $symbols->{variables}->{$1} = $2;
    $DEBUG and carp qq[VARIABLE $1 = $2];
   q[];
  }smxegi;

  my $groups = $self->_css_nestedgroups($str);

  for my $g (@{$groups}) {
    my ($tokens, $block) = $g =~ m/([^{]*)[{](.*)[}]/smxg;
    $tokens =~ s/^\s+//smx;
    $tokens =~ s/\s+$//smx;
    $tokens =~ s/\n\s+/\n/smx;
    $tokens =~ s/\s+\n/\n/smx;

    if ($tokens =~ /^\s*\@mixin\s+(.*)$/smx) {
      my $proto       = $1;
      my ($func)      = $1 =~ /^([^(]+)/smx;
      $symbols->{mixins}->{$func} = "$proto {\n$block\n}\n";
      $DEBUG and carp qq[MIXIN $func];
      next;
    }

    my $kvs       = $self->_css_kvs($block);
    my $ssubstash = [];

    for my $kv (@{$kvs}) {
      $kv =~ s/^\s+//smx;
      $kv =~ s/\s+$//smx;

      if(!$kv) {
        next;
      }

      if ($kv =~ /[{].*[}]/smx) {
        $self->_parse_css( $kv, $ssubstash, $symbols );
        next;
      }

      if ($kv =~ /^\s*\@include\s+(.*?)(?:[(](.*?)[)])?$/xms) {
        my ($func, $argstr) = ($1, $2);
        my $mixin_str  = $symbols->{mixins}->{$func};

        my $subsymbols = $symbols; # todo: correct scoping - is better as {%{$symbols}}
        my $values     = $argstr ? [split /\s*,\s*/smx, $argstr] : [];
        my ($varstr)   = $mixin_str =~ /^.*?[(](.*?)[)]/smx;
        my ($proto)    = $mixin_str =~ /^\s*([^{]*\S)\s*[{]/smx;
        my $vars       = $varstr ? [split /\s*,\s*/smx, $varstr] : [];

        for my $var (@{$vars}) {
          $var =~ s/^[\!\$]//smx;
          $subsymbols->{variables}->{$var} = shift @{$values};
        }

        my $result    = [];
        $self->_parse_css($mixin_str, $result, $subsymbols);
        push @{$ssubstash}, @{$result->[0]->{$proto}};

        $DEBUG and carp qq[DYNAMIC MIXIN $func];
        next;
      }

      if ($kv =~ /^\s*\@extend\s+(.*?)$/xms) {
        my ($selector) = ($1, $2);
        carp q[@extend not yet implemented]; ## no critic (RequireInterpolationOfMetachars)
        next;
      }

      my ($key, $value) = split /:/smx, $kv, 2;
      $key   =~ s/^\s+//smx;
      $key   =~ s/\s+$//smx;
      $value =~ s/^\s+//smx;
      $value =~ s/\s+$//smx;
      push @{$ssubstash}, { $key => $value };
    }

    #########
    # post-process parent references '&'
    #
    my $parent_processed = [];
#carp qq[SUBSTASH=].Dumper($substash);
    for my $child (@{$ssubstash}) {
#carp qq[CHILD=].Dumper($child);
      my ($k) = keys %{$child};
      my ($v) = $child->{$k};
#carp qq[post-process k=$k v=$v tokens=$tokens];
      $k      =~ s{(.*)&}{&$1$tokens}smx;
#carp qq[post-process kafter=$k];
      push @{$parent_processed}, { $k => $v };
#carp Dumper($substash);
#carp Dumper({$tokens => $parent_processed});
    }

    push @{$substash}, { $tokens => $parent_processed };
  }
  return 1;
}

sub _stash2css {
  my ($self, $stash, $symbols) = @_;
  my $groups  = [];
  my $delayed = [];
#carp qq[STASH2CSS: ].Dumper($stash);
  for my $stash_line (@{$stash}) {
    for my $k (keys %{$stash_line}) {
      my $vk = $k;
      $vk    =~ s/\s+/ /smx;

      if($k =~ /&/smx) {
        ($vk) = $k =~ /&(.*)$/smx;

	$stash_line->{$vk} = $stash_line->{$k};
	delete $stash_line->{$k};
	$k = $vk;
      }

      my $str = "$vk {\n";
      if(!ref $stash_line->{$k}) {
	$str .= sprintf q[ %s: %s], $vk, $stash_line->{$k};

      } else {

	for my $attr_line (@{$stash_line->{$k}}) {
	  for my $attr (sort keys %{$attr_line}) {
	    my $val = $attr_line->{$attr};

	    if($attr =~ /^[+]/smx) {
	      $attr = q[];
	    }

	    if($attr =~ /:$/smx) {
	      #########
	      # font:
	      #   family: foo;
	      #   size: bar;
	      #
	      my $rattr = $attr;
	      $rattr    =~ s/:$//smx;
	      for my $val_line (@{$val}) {
		for my $k2 (sort keys %{$val_line}) {
		  $str .= sprintf qq[  %s-%s: %s;\n], $rattr, $k2, $self->_expr($stash, $symbols, $val_line->{$k2});
		}
	      }
	      next;
	    }

	    if(ref $val) {
	      if($attr) {
		$attr = sprintf q[ %s], $attr;
	      }
	      my $rattr = $k . ($attr ? $attr : q[]);

	      if($k =~ /,/smx) {
		$rattr = join q[, ], map { "$_$attr" } split /\s*,\s*/smx, $k;
	      }

	      if($attr =~ /,/smx) {
		$attr =~ s/^\s//smx;
		$rattr = join q[, ], map { "$k $_" } split /\s*,\s*/smx, $attr;
	      }

	      # TODO: What if both have ,?

	      push @{$delayed}, $self->_stash2css([{$rattr => $val}], $symbols);
	      next;
	    }

	    $str .= sprintf qq[  %s: %s;\n], $attr, $self->_expr($stash, $symbols, $val);
	  }
	}
      }

      $str .= "}\n";
      if($str !~ /[{]\s*[}]/smx) {
	push @{$groups}, $str;
      }

      push @{$groups}, @{$delayed};
      $delayed = [];
    }
  }

  return join "\n", @{$groups};
}

sub _expr {
  my ($self, $stash, $symbols, $expr) = @_;
  my $vars = $symbols->{variables} || {};

  #########
  # Do variable expansion
  #
  $expr =~ s/\!($Text::Sass::Token::IDENT)/{$vars->{$1}||"\!$1"}/smxeg;
  $expr =~ s/\$($Text::Sass::Token::IDENT)/{$vars->{$1}||"\$$1"}/smxeg;

  # TODO: should have lwp, so that url() will work

  {
    # Functions

    while ($expr =~ /^(.*?)((\S+)\s*[(]([^)]+)[)](.*)$)/smx) {
      my $start  = $1;
      my $mstr   = $2;
      my $func   = $3;
      my $varstr = $4;
      my $end    = $5;

      #########
      # We want hyphenated 'adjust-hue' to work
      #
      $func =~ s/\-/_/gsmx;
      my ($implementor) = [grep { $_->can($func); } @{$FUNCTIONS}]->[0];

      if (!$implementor) {
        $start = $self->_expr($stash, $symbols, $start);
        $end   = $self->_expr($stash, $symbols, $end);

        #########
        # not happy with this here. It probably at least belongs in Expr
        # - and should include any other CSS stop-words
        #
        if($end =~ /repeat|left|top|right|bottom/smx) { ## no-repeat, repeat-x, repeat-y
          $end = q[];
        }

        $expr  = $start . $mstr . $end;
        last;
      }

      #########
      # TODO: Should support darken(#323, something(4+5, 5))
      #
      my @vars = split /,/smx, $varstr;
      for my $var (@vars) {
	$var =~ s/^\s//smx;
	$var = $self->_expr($stash, $symbols, $var);
      }

      my $res = $implementor->$func(@vars);
      $expr =~ s/\Q$mstr\E/$res/smx;
      last;
    }
  }

  my @parts = split /\s+/smx, $expr;

  Readonly::Scalar my $BINARY_OP_PARTS => 3;
  if(scalar @parts == $BINARY_OP_PARTS) {
    my $ret = Text::Sass::Expr->expr(@parts);
    if (defined $ret) {
      return $ret;
    }
  }

  return $expr;
}

sub _stash2sass {
  my ($self, $stash, $symbols) = @_;
  my $groups = [];

  # TODO: Write symbols

  for my $stashline (@{$stash}) {
    for my $k (keys %{$stashline}) {
      my $str = "$k\n";

      for my $attrline (@{$stashline->{$k}}){
        for my $attr (sort keys %{$attrline}) {
          my $val = $attrline->{$attr};
          $str   .= sprintf qq[  %s: %s\n], $attr, $val;
        }
      }
      push @{$groups}, $str;
    }
  }

  return join "\n", @{$groups};
}

1;
__END__

=encoding utf8

=head1 NAME

Text::Sass - A Naieve Perl implementation of Sass & SCSS.

=head1 VERSION

See Text/Sass.pm

=head1 SYNOPSIS

  use Text::Sass;

  my $sass = Text::Sass->new();

  print $sass->sass2css(<<'EOF');
  $font-stack:    Helvetica, sans-serif
  $primary-color: #333

  body
    font: 100% $font-stack
    color: $primary-color
  EOF

  print $sass->scss2css(<<'EOF');
  $font-stack:    Helvetica, sans-serif;
  $primary-color: #333;

  body {
    font: 100% $font-stack;
    color: $primary-color;
  }
  EOF

=head1 DESCRIPTION

This is a pure perl implementation of Sass and SCSS languages.
Currently it implements only a subset of the specification.

L<Sass project page|http://sass-lang.com>

=head1 SUBROUTINES/METHODS

=head2 new - Constructor - nothing special

  my $oSass = Text::Sass->new;

=head2 css2sass - Translate CSS to Sass

  my $sSass = $oSass->css2sass($sCSS);

=head2 sass2css - Translate Sass to CSS

  my $sCSS = $oSass->sass2css($sSass);

=head2 scss2css - Translate Scss to CSS

  my $sCSS = $oSass->scss2css($sScss);

=head1 DEPENDENCIES

=over

=item L<Readonly|Readonly>

=item L<Convert::Color|Convert::Color>

=back

=head1 INCOMPATIBILITIES

All variables are currently global. This can be quite unpleasant.

=head1 BUGS AND LIMITATIONS

See README

=head1 SEE ALSO

L<Text::Sass::XS|Text::Sass::XS> - Perl binding for libsass. Consider using it if
you need higher level of language conformance and/or faster execution.

L<CSS::Sass|CSS::Sass> - Yet another libsass binding.

L<Plack::Middleware::File::Sass|Plack::Middleware::File::Sass> - Sass and SCSS support for all
Plack frameworks. Can use this module as one of its backends.

=head1 AUTHOR

Roger Pettett E<lt>rmp@psyphi.netE<gt>

=head1 DIAGNOSTICS

 Set $Text::Sass::DEBUG = 1;

=head1 CONFIGURATION AND ENVIRONMENT

Nothing required beyond $DEBUG

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
