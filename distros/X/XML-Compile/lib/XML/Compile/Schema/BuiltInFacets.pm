# Copyrights 2006-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::Schema::BuiltInFacets;
use vars '$VERSION';
$VERSION = '1.63';

use base 'Exporter';

use warnings;
use strict;
no warnings 'recursion';

our @EXPORT = qw/builtin_facet/;

use Log::Report        'xml-compile';

use Math::BigInt;
use Math::BigFloat;
use XML::LibXML;  # for ::RegExp
use XML::Compile::Util qw/SCHEMA2001 pack_type duration2secs/;

use POSIX              qw/DBL_MAX_10_EXP DBL_DIG/;

# depend on Perl's compile flags
use constant INT_MAX => int((sprintf"%u\n",-1)/2);
use constant INT_MIN => -1 - INT_MAX;


my %facets_simple =
  ( enumeration     => \&_enumeration
  , fractionDigits  => \&_s_fractionDigits
  , length          => \&_s_length
  , maxExclusive    => \&_s_maxExclusive
  , maxInclusive    => \&_s_maxInclusive
  , maxLength       => \&_s_maxLength
  , maxScale        => undef   # ignore
  , minExclusive    => \&_s_minExclusive
  , minInclusive    => \&_s_minInclusive
  , minLength       => \&_s_minLength
  , minScale        => undef   # ignore
  , pattern         => \&_pattern
  , totalDigits     => \&_s_totalDigits
  , whiteSpace      => \&_s_whiteSpace
  , _totalFracDigits=> \&_s_totalFracDigits
  );

my %facets_list =
  ( enumeration     => \&_enumeration
  , length          => \&_list_length
  , maxLength       => \&_list_maxLength
  , minLength       => \&_list_minLength
  , pattern         => \&_pattern
  , whiteSpace      => \&_list_whiteSpace
  );

my %facets_date =  # inclusive or exclusive times is rather useless.
  ( enumeration     => \&_enumeration
  , explicitTimeZone=> \&_date_expl_tz
  , maxExclusive    => \&_date_max
  , maxInclusive    => \&_date_max
  , minExclusive    => \&_date_min
  , minInclusive    => \&_date_min
  , pattern         => \&_pattern
  , whiteSpace      => \&_date_whiteSpace
  );

my %facets_duration =
  ( enumeration     => \&_enumeration
  , maxExclusive    => \&_dur_max_excl
  , maxInclusive    => \&_dur_max_incl
  , minExclusive    => \&_dur_min_excl
  , minInclusive    => \&_dur_min_incl
  , pattern         => \&_pattern
  , whiteSpace      => \&_s_whiteSpace
  );

my $date_time_type = pack_type SCHEMA2001, 'dateTime';
my $date_type      = pack_type SCHEMA2001, 'date';
my $duration_type  = pack_type SCHEMA2001, 'duration';

sub builtin_facet($$$$$$$$)
{   my ($path, $args, $facet, $value, $is_list, $type, $nss, $action) = @_;

    my $def
      = $is_list ? $facets_list{$facet}
      : $nss->doesExtend($type, $date_time_type) ? $facets_date{$facet}
      : $nss->doesExtend($type, $date_type)      ? $facets_date{$facet}
      : $nss->doesExtend($type, $duration_type)  ? $facets_duration{$facet}
      : $facets_simple{$facet};

    $def or error __x"facet {facet} not implemented at {where}"
        , facet => $facet, where => $path;

    $def->($path, $args, $value, $type, $nss, $action);
}

sub _list_whiteSpace($$$)
{   my ($path, undef, $ws) = @_;
    $ws eq 'collapse'
        or error __x"list whiteSpace facet fixed to 'collapse', not '{ws}' in {path}"
          , ws => $ws, path => $path;
    ();
}

sub _s_whiteSpace($$$)
{   my ($path, undef, $ws) = @_;
      $ws eq 'replace'  ? \&_whitespace_replace
    : $ws eq 'collapse' ? \&_whitespace_collapse
    : $ws eq 'preserve' ? ()
    : error __x"illegal whiteSpace facet '{ws}' in {path}"
          , ws => $ws, path => $path;
}

sub _date_whiteSpace($$$)
{   my ($path, undef, $ws) = @_;

    # whitespace processing already in the dateTime parser
    $ws eq 'collapse'
        or error __x"illegal whiteSpace facet '{ws}' in {path}"
          , ws => $ws, path => $path;
    ();
}

sub _whitespace_replace($)
{   my $value = ref $_[0] ? $_[0]->textContent : $_[0];
    $value =~ s/[\t\r\n]/ /gs;
    $value;
}

sub _whitespace_collapse($)
{   my $value = ref $_[0] ? $_[0]->textContent : $_[0];
    for($value)
    {   s/[\t\r\n ]+/ /gs;
        s/^ +//;
        s/ +$//;
    }
    $value;
}

sub _maybe_big($$$)
{   my ($path, $args, $value) = @_;
    return $value if $args->{sloppy_integers};

    # modules Math::Big* loaded by Schema::Spec when not sloppy

    $value =~ s/\s//g;
    if($value =~ m/[.eE]/)
    {   my $c   = $value;
        my $exp = $c =~ s/[eE][+-]?([0-9]+)// ? $1 : 0;
        my $pre = $c =~ /^[-+]?([0-9]*)/ ? length($1) : 0;
        return Math::BigFloat->new($value)
            if $pre >= DBL_DIG || $pre+$exp >= DBL_MAX_10_EXP;
    }
    # compare ints as strings, because they will overflow!!
    elsif(substr($value, 0, 1) eq '-')
    {   return Math::BigInt->new($value)
            if length($value) > length(INT_MIN)
            || (length($value)==length(INT_MIN) && $value gt INT_MIN);
    }
    else
    {   return Math::BigInt->new($value)
           if length($value) > length(INT_MAX)
           || (length($value)==length(INT_MAX) && $value gt INT_MAX);
    }

    $value;
}

sub _s_minInclusive($$$)
{   my ($path, $args, $min) = @_;
    $min = _maybe_big $path, $args, $min;
    sub { return $_[0] if $_[0] >= $min;
          error __x"too small inclusive {value}, min {min} at {where}"
            , value => $_[0], min => $min, where => $path;
    };
}

sub _s_minExclusive($$$)
{   my ($path, $args, $min) = @_;
    $min = _maybe_big $path, $args, $min;
    sub { return $_[0] if $_[0] > $min;
          error __x"too small exclusive {value}, larger {min} at {where}"
             , value => $_[0], min => $min, where => $path;
    };
}

sub _s_maxInclusive($$$)
{   my ($path, $args, $max) = @_;
    $max = _maybe_big $path, $args, $max;
    sub { return $_[0] if $_[0] <= $max;
        error __x"too large inclusive {value}, max {max} at {where}"
          , value => $_[0], max => $max, where => $path;
    };
}

sub _s_maxExclusive($$$)
{   my ($path, $args, $max) = @_;
    $max = _maybe_big $path, $args, $max;
    sub { return $_[0] if $_[0] < $max;
        error __x"too large exclusive {value}, smaller {max} at {where}"
          , value => $_[0], max => $max, where => $path;
    };
}

my $qname = pack_type SCHEMA2001, 'QName';
sub _enumeration($$$$$$)
{   my ($path, $args, $enums, $type, $nss, $action) = @_;

    my %enum = map +($_ => 1), @$enums;
    sub { my $v = ref $_[0] eq 'ARRAY' ? join(' ', @{$_[0]}) : $_[0];
        return $v if exists $enum{$v};
        error __x"invalid enumerate `{string}' at {where}"
          , string => $v, where => $path;
    };
}

sub _s_totalDigits($$$)
{   my ($path, undef, $total) = @_;

    # this accidentally also works correctly for NaN +INF -INF
    sub
      { my $v = $_[0];
        $v =~ s/[eE].*//;
        $v =~ s/^[+-]?0*//;
        return $_[0] if $total >= ($v =~ tr/0-9//);

        error __x"decimal too long, got {length} digits max {max} at {where}"
          , length => ($v =~ tr/0-9//), max => $total, where => $path;
      };
}

sub _s_fractionDigits($$$)
{   my $frac = $_[2];
    # can be result from Math::BigFloat, so too long to use %f  But rounding
    # is very hard to implement. If you need this accuracy, then format your
    # value yourself!
    sub
      { my $v = $_[0];
        $v =~ s/(\.[0-9]{$frac}).*/$1/;
        $v;
      };
}

sub _s_totalFracDigits($$$)
{   my ($path, undef, $dig) = @_;
    my ($total, $frac) = @$dig;
    sub
      { my $w = $_[0];

        my $v = $w;   # total is checking length
        $v =~ s/[eE].*//;
        $v =~ s/^[+-]?0*//;

        if( $v !~ /^(?:[+-]?)(?:[0-9]*)(?:\.([0-9]*))?$/ )
        {   error __x"Invalid numeric format, got {value} at {where}"
              , value => $w, where => $path;
        }

        if($1 && length($1) > $frac)
        {   error __x"fractional part for {value} too long, got {l} digits max {max} at {where}"
              , value => $w, l => length($1), max => $frac, where => $path;
        }

        return $w if $total >= ($v =~ tr/0-9//);
        error __x"decimal too long, got {length} digits max {max} at {where}"
          , length => ($v =~ tr/0-9//), max => $total, where => $path;
      };
}

sub _s_length($$$$$$)
{   my ($path, $args, $len, $type, $nss, $action) = @_;

    sub { return $_[0] if defined $_[0] && length($_[0])==$len;
      error __x"string `{string}' does not have required length {len} but {size} at {where}"
          , string => $_[0], len => $len, size => length($_[0]), where => $path;
    };
}

sub _list_length($$$)
{   my ($path, $args, $len) = @_;
    sub { return $_[0] if defined $_[0] && @{$_[0]}==$len;
        error __x"list `{list}' does not have required length {len} at {where}"
          , list => $_[0], len => $len, where => $path;
    };
}

sub _s_minLength($$$)
{   my ($path, $args, $len, $type, $nss, $action) = @_;

    sub { return $_[0] if defined $_[0] && length($_[0]) >=$len;
        error __x"string `{string}' does not have minimum length {len} at {where}"
          , string => $_[0], len => $len, where => $path;
    };
}

sub _list_minLength($$$)
{   my ($path, $args, $len) = @_;
    sub { return $_[0] if defined $_[0] && @{$_[0]} >=$len;
        error __x"list `{list}' does not have minimum length {len} at {where}"
          , list => $_[0], len => $len, where => $path;
    };
}

sub _s_maxLength($$$)
{   my ($path, $args, $len, $type, $nss, $action) = @_;

    sub { return $_[0] if defined $_[0] && length $_[0] <= $len;
        error __x"string `{string}' longer than maximum length {len} at {where}"
          , string => $_[0], len => $len, where => $path;
    };
}

sub _list_maxLength($$$)
{   my ($path, $args, $len) = @_;
    sub { return $_[0] if defined $_[0] && @{$_[0]} <= $len;
        error __x"list `{list}' longer than maximum length {len} at {where}"
          , list => $_[0], len => $len, where => $path;
    };
}

sub _pattern($$$)
{   my ($path, $args, $pats) = @_;
    @$pats or return ();
    my $regex    = @$pats==1 ? $pats->[0] : "(".join(')|(', @$pats).")";
    my $compiled = XML::LibXML::RegExp->new($regex);

    sub {
use Carp 'cluck';
defined $_[0] or cluck "PATTERN";
		my $v = ref $_[0] ? $_[0]->textContent : $_[0];
        return $_[0] if $compiled->matches($v);
        error __x"string `{string}' does not match pattern `{pat}' at {where}"
          , string => $v, pat => $regex, where => $path;
    };
}

sub _date_min($$$)
{   my ($path, $args, $min) = @_;
    sub { return $_[0] if $_[0] gt $min;
        error __x"too small inclusive {value}, min {min} at {where}"
          , value => $_[0], min => $min, where => $path;
    };
}

sub _date_max($$$)
{   my ($path, $args, $max) = @_;
    sub { return $_[0] if $_[0] lt $max;
        error __x"too large inclusive {value}, max {max} at {where}"
          , value => $_[0], max => $max, where => $path;
    };
}

sub _date_expl_tz($$$)
{   my ($path, $args, $enum) = @_;
    my $tz = qr/Z$ | [+-](?:(?:0[0-9]|1[0-3])\:[0-5][0-9] | 14\:00)$/x;

      $enum eq 'optional'   ? ()
    : $enum eq 'prohibited'
    ? sub {   $_[0] !~ $tz
                 or error __x"timezone forbidden on {date} at {where}"
                    , date => $_[0], where => $path;
          }
    : $enum eq 'required'
    ? sub {   $_[0] =~ $tz
                 or error __x"timezone required on {date} at {where}"
                    , date => $_[0], where => $path;
          }
    : error __x"illegal explicitTimeZone facet '{enum}' in {path}"
          , enum => $enum, path => $path;
}

sub _dur_min_incl($$$)
{   my ($path, $args, $min) = @_;
    my $secs = duration2secs $min;

    sub { return $_[0] if duration2secs $_[0] >= $secs;
       error __x"too small minInclusive duration {value}, min {min} at {where}"
          , value => $_[0], min => $min, where => $path;
    };
}


sub _dur_min_excl($$$)
{   my ($path, $args, $min) = @_;
    my $secs = duration2secs $min;

    sub { return $_[0] if duration2secs $_[0] > $secs;
       error __x"too small minExclusive duration {value}, min {min} at {where}"
          , value => $_[0], min => $min, where => $path;
    };
}


sub _dur_max_incl($$$)
{   my ($path, $args, $max) = @_;
    my $secs = duration2secs $max;

    sub { return $_[0] if duration2secs $_[0] <= $secs;
       error __x"too large maxInclusive duration {value}, max {max} at {where}"
          , value => $_[0], max => $max, where => $path;
    };
}


sub _dur_max_excl($$$)
{   my ($path, $args, $max) = @_;
    my $secs = duration2secs $max;

    sub { return $_[0] if duration2secs $_[0] < $secs;
       error __x"too large maxExclusive duration {value}, max {max} at {where}"
          , value => $_[0], max => $max, where => $path;
    };
}

1;
