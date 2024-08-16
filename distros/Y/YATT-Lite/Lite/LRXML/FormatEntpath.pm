package YATT::Lite::LRXML::FormatEntpath;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use Exporter qw/import/;

our @EXPORT_OK = qw/format_entpath/;

use YATT::Lite::Constants;
use YATT::Lite::LRXML::ParseEntpath;
*close_ch = *YATT::Lite::LRXML::ParseEntpath::close_ch;
*close_ch = *YATT::Lite::LRXML::ParseEntpath::close_ch;

sub inverse_hash {
  my ($fromHash, $toHash) = @_;
  $toHash //= {};
  $toHash->{$fromHash->{$_}} = $_ for keys %$fromHash;
}

our (%name2sym);
BEGIN {
  inverse_hash(\%name2sym, \%YATT::Lite::LRXML::ParseEntpath::open_head);
  inverse_hash(\%name2sym, \%YATT::Lite::LRXML::ParseEntpath::open_rest);
}

sub ME () {__PACKAGE__}
sub format_entpath {
  join("", map {
    my ($type, @rest) = @{lxnest($_)};
    my $sub = ME->can("format__$type")
      or Carp::croak "Unknown entpath type: ".YATT::Lite::Util::terse_dump($type);
    $sub->(@rest);
  } @_);
}

sub format__call {
  my ($name, @args) = @_;
  my @items = map {format_entpath(lxnest($_))} @args;
  $items[-1] .= "," if @items and $items[-1] eq '';
  sprintf(":%s(%s)", $name, join(",", @items));
}

*format__invoke = *format__call; *format__invoke = *format__call;

sub format__var {
  my ($name) = @_;
  ":$name";
}

*format__prop = *format__var; *format__prop = *format__var;

sub format__href {
  my (@args) = @_;
  "{".join(",", map {format_entpath(lxnest($_))} @args)."}"
}

*format__hash = *format__href; *format__hash = *format__href;

sub format__aref {
  my (@args) = @_;
  "[".join(",", map {format_entpath(lxnest($_))} @args)."]"
}

*format__array = *format__aref; *format__array = *format__aref;

sub format__text {
  my ($name) = @_;
  if ($name eq '') {
    "";
  } elsif ($name =~ m{^[-\+\*/<>!\w\|\@\$%][-\+\*/<>!\w\|\@\$%=]*\z}) {
    # XXX: matching paren {..}
    $name
  } else {
    "($name)"
  }
}

sub format__expr {
  my ($name) = @_;
  "=$name"
}

1;
