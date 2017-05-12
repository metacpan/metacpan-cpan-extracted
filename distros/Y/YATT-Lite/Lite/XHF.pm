package YATT::Lite::XHF; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use utf8;

our $VERSION = "0.03";

use base qw(YATT::Lite::Object);
use fields qw(cf_FH cf_filename cf_string cf_tokens
	      fh_configured
	      cf_allow_empty_name
	      cf_encoding cf_crlf
	      cf_nocr cf_subst
	      cf_skip_comment cf_bytes);

use Exporter qw(import);
our @EXPORT = qw(read_file_xhf);
our @EXPORT_OK = (@EXPORT, qw(parse_xhf $cc_name));

use YATT::Lite::Util;
use YATT::Lite::Util::Enum _ => [qw(NAME SIGIL VALUE)];

our $cc_name  = qr{[0-9A-Za-z_\.\-/~!]};
our $re_suffix= qr{\[$cc_name*\]};
our $cc_sigil = qr{[:\#,\-=\[\]\{\}]};
our $cc_tabsp = qr{[\ \t]};

our %OPN = ('[' => \&organize_array, '{' => \&organize_hash
	    , '=' => \&organize_expr);
our %CLO = (']' => '[', '}' => '{');
our %NAME_LESS = (%CLO, '-' => 1);
our %ALLOW_EMPTY_NAME = (':' => 1);

sub after_new {
  (my MY $self) = @_;
  $self->{cf_skip_comment} //= 1;
}

sub read_file_xhf {
  my ($pack, $fn, @rest) = @_;
  MY->new(filename => $fn, encoding => 'utf8', @rest)->read;
}

sub parse_xhf {
  MY->new(string => @_)->read;
}

*configure_file = \&configure_filename;
*configure_file = \&configure_filename;
sub configure_filename {
  (my MY $self, my ($fn)) = @_;
  open $self->{cf_FH}, '<', $fn
    or croak "Can't open file '$fn': $!";
  $self->{fh_configured} = 0;
  $self->{cf_filename} = $fn;
  $self;
}

# To accept in-stream encoding spec.
# (See YATT::Lite::Test::XHFTest::load and t/lite_xhf.t)
sub configure_encoding {
  (my MY $self, my $value) = @_;
  $self->{fh_configured} = 0;
  $self->{cf_encoding} = $value;
}

sub configure_binary {
  (my MY $self, my $value) = @_;
  warnings::warnif(deprecated =>
		   "XHF option 'binary' is deprecated, use 'bytes' instead");
  $self->{cf_bytes} = $value;
}

sub configure_string {
  my MY $self = shift;
  ($self->{cf_string}) = @_;
  open $self->{cf_FH}, '<', \ $self->{cf_string}
    or croak "Can't create string stream: $!";
  $self;
}

# XXX: Should I rename this to read_one()?
sub read {
  my MY $self = shift;
  $self->cf_let(\@_, sub {
		  if (my @tokens = $self->tokenize) {
		    $self->organize(@tokens);
		  } else {
		    return;
		  }
		});
}

sub tokenize {
  (my MY $self) = @_;
  local $/ = "";
  my $fh = $$self{cf_FH};
  unless ($self->{fh_configured}++) {
    if (not $self->{cf_bytes} and not $self->{cf_string}
	and $self->{cf_encoding}) {
      binmode $fh, ":encoding($self->{cf_encoding})";
    }
    if ($self->{cf_crlf}) {
      binmode $fh, ":crlf";
    }
  }

  my @tokens;
 LOOP: {
    do {
      defined (my $para = <$fh>) or last LOOP;
      $para = untaint_unless_tainted
	($self->{cf_filename} // $self->{cf_string}
	 , $para);
      @tokens = $self->tokenize_1($para);
    } until (not $self->{cf_skip_comment} or @tokens);
  }
  @tokens;
}

sub tokenize_1 {
  my MY $reader = shift;
  $_[0] =~ s{\n+$}{\n}s;
  $_[0] =~ s{\r+}{}g if $reader->{cf_nocr};
  if (my $sub = $reader->{cf_subst}) {
    local $_;
    *_ =  \ $_[0];
    $sub->($_);
  }
  my ($pos, $ncomments, @tokens, @result);
  foreach my $token (@tokens = split /(?<=\n)(?=[^\ \t])/, $_[0]) {
    $pos++;
    if ($token =~ s{^(?:\#[^\n]*(?:\n|$))+}{}) {
      $ncomments++;
      next if $token eq '';
    }

    unless ($token =~ s{^($cc_name*$re_suffix*) ($cc_sigil) (?:($cc_tabsp)|(\n|$))}{}x) {
      croak "Invalid XHF token '$token': line " . token_lineno(\@tokens, $pos);
    }
    my ($name, $sigil, $tabsp, $eol) = ($1, $2, $3, $4);

    if ($name eq '') {
      croak "Invalid XHF token(name is empty for '$token')"
	if $sigil eq ':' and not $reader->{cf_allow_empty_name};
    } elsif ($NAME_LESS{$sigil}) {
      croak "Invalid XHF token('$sigil' should not be prefixed by name '$name')"
    }

    # Comment fields are ignored.
    $ncomments++, next if $sigil eq "#";

    if ($CLO{$sigil}) {
      undef $name;
    }

    # Line continuation.
    $token =~ s/\n[\ \t]/\n/g;

    unless (defined $eol) {
      # Values are trimmed unless $eol
      $token =~ s/^\s+|\s+$//gs;
    } else {
      # Deny:  name{ foo
      # Allow: name[ foo
      croak "Invalid XHF token(container with value): "
	. join("", grep {defined $_} $name, $sigil, $tabsp, $token)
	  if $sigil eq '{' and $token ne "";

      # Trim leading space for $tabsp eq "\n".
      $token =~ s/^[\ \t]//;
    }
    push @result, [$name, $sigil, $token];
  }

  # Comment only paragraph should return nothing.
  return if $ncomments && !@result;

  wantarray ? @result : \@result;
}

sub token_lineno {
  my ($tokens, $pos) = @_;
  my $lineno = 1;
  $lineno += tr|\n|| for grep {defined} @$tokens[0 .. $pos];
  $lineno;
}

sub organize {
  my MY $reader = shift;
  my @result;
  while (@_) {
    my $desc = shift;
    unless (defined $desc->[_NAME]) {
      croak "Invalid XHF: Field close '$desc->[_SIGIL]' without open!";
    }
    push @result, $desc->[_NAME] if $desc->[_NAME] ne ''
      or $ALLOW_EMPTY_NAME{$desc->[_SIGIL]};
    if (my $sub = $OPN{$desc->[_SIGIL]}) {
      # sigil がある時、value を無視して、良いのか?
      push @result, $sub->($reader, \@_, $desc);
    } else {
      push @result, $desc->[_VALUE];
    }
  }
  if (wantarray) {
    @result
  } else {
    my %hash = @result;
    \%hash;
  }
}

# '[' block
sub organize_array {
  (my MY $reader, my ($tokens, $first)) = @_;
  my @result;
  push @result, $first->[_VALUE] if defined $first and $first->[_VALUE] ne '';
  while (@$tokens) {
    my $desc = shift @$tokens;
    # NAME
    unless (defined $desc->[_NAME]) {
      if ($desc->[_SIGIL] ne ']') {
	croak "Invalid XHF: paren mismatch. '[' is closed by '$desc->[_SIGIL]'";
      }
      return \@result;
    }
    elsif ($desc->[_NAME] ne '') {
      push @result, $desc->[_NAME];
    }
    # VALUE
    if (my $sub = $OPN{$desc->[_SIGIL]}) {
      # sigil がある時、value があったらどうするかは、子供次第。
      push @result, $sub->($reader, $tokens, $desc);
    }
    else {
      push @result, $desc->[_VALUE];
    }
  }
  croak "Invalid XHF: Missing close ']'";
}

# '{' block.
sub organize_hash {
  (my MY $reader, my ($tokens, $first)) = @_;
  die "Invalid XHF hash block beginning! ". join("", @$first)
    if defined $first and $first->[_VALUE] ne '';
  my %result;
  while (@$tokens) {
    my $desc = shift @$tokens;
    # NAME
    unless (defined $desc->[_NAME]) {
      if ($desc->[_SIGIL] ne '}') {
	croak "Invalid XHF: paren mismatch. '{' is closed by '$desc->[_SIGIL]'";
      }
      return \%result;
    }
    elsif ($desc->[_SIGIL] eq '-') {
      # Should treat two lines as one key value pair.
      unless (@$tokens) {
	croak "Invalid XHF hash:"
	  ." key '- $desc->[_VALUE]' doesn't have value!";
      }
      my $valdesc = shift @$tokens;
      my $value = do {
	if (my $sub = $OPN{$valdesc->[_SIGIL]}) {
	  $sub->($reader, $tokens, $valdesc);
	} elsif ($valdesc->[_SIGIL] eq '-') {
	  $valdesc->[_VALUE];
	} else {
	  croak "Invalid XHF hash value:"
	    . " key '$desc->[_VALUE]' has invalid sigil '$valdesc->[_SIGIL]'";
	}
      };
      $reader->add_value($result{$desc->[_VALUE]}, $value);
    } else {
      if (my $sub = $OPN{$desc->[_SIGIL]}) {
	# sigil がある時、value を無視して、良いのか?
	$desc->[_VALUE] = $sub->($reader, $tokens, $desc);
      }
      $reader->add_value($result{$desc->[_NAME]}, $desc->[_VALUE]);
    }
  }
  croak "Invalid XHF: Missing close '}'";
}

# '=' value
sub _undef {undef}
our %EXPR = (null => \&_undef, 'undef' => \&_undef);
sub organize_expr {
  (my MY $reader, my ($tokens, $first)) = @_;
  if ((my $val = $first->[_VALUE]) =~ s/^\#(\w+)\s*//) {
    my $sub = $EXPR{$1}
      or croak "Invalid XHF keyword: '= #$1'";
    $sub->($reader, $val, $tokens);
  } else {
    croak "Not yet implemented XHF token: '@$first'";
  }
}

sub add_value {
  my MY $reader = shift;
  unless (defined $_[0]) {
    $_[0] = $_[1];
  } elsif (ref $_[0] ne 'ARRAY') {
    $_[0] = [$_[0], $_[1]];
  } else {
    push @{$_[0]}, $_[1];
  }
}

use YATT::Lite::Breakpoint;
YATT::Lite::Breakpoint::break_load_xhf();

1;

__END__

=head1 NAME

YATT::Lite::XHF - Loader for XHF format

=for code perl

=head1 SYNOPSIS

  require YATT::Lite::XHF;

  my $parser1 = YATT::Lite::XHF->new(FH => \*STDIN);

  # or
  my $parser2 = YATT::Lite::XHF->new(filename => $filename);

  # or
  my $parser = YATT::Lite::XHF->new(string => <<'END');
  foo: 1
  bar: 2

  foo{
  wibble: wobble
  }
  bar[
  - foo
  - bar
  - baz
  ]

  END
  
  # read() returns one set of parsed result by one paragraph, separated by \n\n+.
  # In array context, you will get a flattened list of items in one paragraph.
  # (It may usually be a list of key-value pairs, but you can write other types)
  # In scalar context, you will get a hash struct.
  while (my %hash = $parser->read) {
    print Dumper(\%hash), "\n";
  }

  {
    # You can use YATT::Lite::XHF as mixin for read_file_xhf() and parse_xhf()
    package MyPackage {
      use YATT::Lite::XHF;
      ...
    }
    # XXX: currently, both only reads first paragraph. This may be confusing.
    my %hash2 = MyPackage->read_file_xhf($filename);
    my %hash3 = MyPackage->parse_xhf($string);
  }

=head1 DESCRIPTION

This is a parser/loader for B<Extended Header Fields format (XHF)>.
For XHF definition, see L<YATT::Lite::XHF::Syntax>.

=head1 METHODS

=head2 new(@OPTS)

=head2 configure(@OPTS)

=head2 read(@OPTS)

=head1 EXPORTED FUNCTIONS

=head2 ->read_file_xhf($filename)

=head2 ->parse_xhf($string)


=head1 OPTIONS

=over 4

=item FH => $filehandle

=item filename => $filename

=item string => $xh_string

=item skip_comment => $bool

=item bytes => $bool

=back

=head1 AUTHOR

"KOBAYASI, Hiroaki" <hkoba@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

