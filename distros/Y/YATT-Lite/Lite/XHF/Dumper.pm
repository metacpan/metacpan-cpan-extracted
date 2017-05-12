package YATT::Lite::XHF::Dumper;
use strict;
use warnings qw(FATAL all NONFATAL misc);
our $VERSION = "0.02";

use Exporter qw(import);
our @EXPORT_OK = qw(dump_xhf);
our @EXPORT = @EXPORT_OK;

use 5.010;
use Carp;

use YATT::Lite::XHF qw($cc_name);

sub dump_xhf {
  shift;
  _dump_pairs(@_);
}

sub _dump_pairs {
  my @buffer;
  while (@_) {
    if (@_ == 1 or not defined $_[0] or ref $_[0]) {
      push @buffer, _dump_value(shift, '-');
    } elsif ($_[0] =~ m{^$cc_name+$}) {
      push @buffer, shift() . _dump_value(shift, ':');
    } else {
      # ('', undef) => "-\n= #null"
      push @buffer, '-' . escape(shift), _dump_value(shift, '-');
    }
  }
  join "\n", @buffer;
}

sub _dump_value {
    # value part.
  unless (defined $_[0]) {
    "= #null";
  } elsif (not ref $_[0]) {
    $_[1] . escape(shift);
  } elsif (ref $_[0] eq 'ARRAY') {
    dump_array(shift);
  } elsif (ref $_[0] eq 'HASH') {
    dump_hash(shift);
  } else {
    croak "Can't dump ref(@{[ref $_[0]]}) as XHF: $_[0]";
  }
}

sub escape {
  my ($str) = @_;
  my $sep = do {
    if ($str =~ s/\n$// or $str =~ /^\s+|\s+$/s) {
      "\n "
    } else {
      " "
    }
  };
  $str =~ s/\n/\n /g;
  $sep . $str;
}

sub dump_array {
  my ($item) = @_;
  "[\n" . join("\n", do {
    if (@$item and @$item % 2 == 0 and looks_like_hash($item)) {
      _dump_pairs(@$item);
    } else {
      map {_dump_value($_, '-')} @$item
    }
  }) . "\n]";
}

sub looks_like_hash {
  my ($item) = @_;
  for (my $i = 0; $i < @$item; $i += 2) {
    return 0 if ref($item->[$i]) or $item->[$i] !~ m{^$cc_name+$};
  }
  return 1;
}

sub dump_hash {
  my ($item) = @_;
  "{\n" . _dump_pairs(map {$_, $item->{$_}} sort keys %$item) . "\n}";
}

__END__

=head1 NAME

YATT::Lite::XHF::Dumper - Serializer for XHF format

=for code perl

=head1 SYNOPSIS

  require YATT::Lite::XHF::Dumper;
  print YATT::Lite::XHF::Dumper->dump_xhf(foo => [1..3], bar => {baz => "qux"});

  # or use this as mixin:
  use YATT::Lite::XHF::Dumper;
  print __PACKAGE__->dump_xhf(foo => [1..3], bar => {baz => "qux"});


Then you will get a xhf-block:

  foo[
  - 1
  - 2
  - 3
  ]
  bar{
  baz: qux
  }


=head1 DESCRIPTION

This is a serializer for L<XHF|YATT::Lite::XHF::Syntax>.

=head1 AUTHOR

"KOBAYASI, Hiroaki" <hkoba@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

