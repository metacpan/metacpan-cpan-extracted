package YATT::Lite::RegexpNames;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use Exporter qw/import/;
use YATT::Lite::Util qw/globref symtab/;

#========================================

sub wrap {
  my ($re, $partial) = @_;
  $partial ? $re : qq!^$re\\z!;
}

# $this->re_name     returns ^\w+$  -- Total pattern, usually for user input.
# $this->re_name(1)  returns  \w+   -- Partial pattern.

sub re_name     { wrap(qr{\w+}, $_[1]) }

sub re_digit    { wrap(qr{(?:[0-9]+)}, $_[1]) }

sub re_integer  { wrap(qr{(?:0|[1-9]\d*)}, $_[1]) }

# Mainly for untainting.
sub re_any      { wrap(qr{.*}s, $_[1]) }

# 'nonempty'-check should not complain about surrounding white spaces.
sub re_nonempty { qr{\S.*}s }

# aliases
*re_word = *re_name; *re_word = *re_name;
*re_int = *re_integer; *re_int = *re_integer;
*re_digits = *re_digit; *re_digits = *re_digit;


#========================================

__PACKAGE__->build_exports(\ our(@EXPORT, @EXPORT_OK));

sub build_exports {
  my ($pack, @vars) = @_;
  my $symtab = symtab($pack);
  foreach my $name (grep {/^re_/} keys %$symtab) {
    my $glob = $symtab->{$name};
    next unless *{$glob}{CODE};
    push @$_, $name for @vars;
  }
}

1;
