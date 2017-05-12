package YATT::XHF;

=head1 NAME

YATT::XHF - Extended Header Fields format.

=cut

use strict;
use warnings qw(FATAL all NONFATAL misc);

use base qw(YATT::Class::Configurable);
use YATT::Fields qw(cf_FH cf_filename cf_tokens);
use Carp;

use YATT::Util::Enum -prefix => '_', qw(NAME VALUE SIGIL);

our $cc_name  = qr{\w|[\.\-%/]};
our $cc_sigil = qr{[:\#,\-\[\]\{\}]};
our $cc_tabsp = qr{[\ \t]};

our %OPN = qw([ array { hash);

sub configure_filename {
  (my MY $self, my ($fn)) = @_;
  open $self->{cf_FH}, '<', $fn
    or croak "Can't open file '$fn': $!";
  $self->{cf_filename} = $fn;
  $self;
}

sub configure_string {
  (my MY $self, my ($string)) = @_;
  open $self->{cf_FH}, '<', \$string
    or croak "Can't create string stream: $!";
  $self;
}

sub read_as_hashlist {
  my MY $reader = shift;
  local $/ = "";
  my $fh = $$reader{cf_FH};
  my @result;
  while (defined (my $paragraph = <$fh>)) {
    @{$$reader{cf_tokens}} = $reader->tokenize($paragraph)
      or next;
    push @result, $reader->organize_as_hash($reader->{cf_tokens});

  }
  wantarray ? @result : \@result;
}

sub read_as_hash {
  shift->read_as(hash => @_);
}

sub read_as {
  (my MY $reader, my ($type)) = @_;
  my $sub = $reader->can("organize_as_$type")
    or croak "Unknown read_as type: $type";

  local $/ = "";
  my $fh = $$reader{cf_FH};
  until ($$reader{cf_tokens} && @{$$reader{cf_tokens}}) {
    defined (my $paragraph = <$fh>) or last;
    @{$$reader{cf_tokens}} = $reader->tokenize($paragraph)
  }
  return unless $$reader{cf_tokens} && @{$$reader{cf_tokens}};
  $sub->($reader, $reader->{cf_tokens});
}

sub organize_as_pairlist {
  (my MY $reader, my ($tokens)) = @_;
  my $hash = $reader->organize_as_hash($tokens);
  %$hash;
}

sub organize_as_hash {
  (my MY $reader, my ($tokens)) = @_;
  my %result;
  while (@$tokens) {
    my $desc = shift @$tokens;
    my $sigil = pop @$desc;
    if (my $type = $OPN{$sigil}) {
      $desc->[_VALUE] = $reader->can("organize_as_$type")
	->($reader, $tokens);
    } elsif ($sigil eq '}') {
      last;
    }
    $reader->add_value($result{$reader->decode_name($desc->[_NAME])}
		       , $desc->[_VALUE]);
  }
  \%result;
}

sub organize_as_array {
  (my MY $reader, my ($tokens)) = @_;
  my @result;
  while (@$tokens) {
    my $desc = shift @$tokens;
    my $sigil = pop @$desc;
    unless ($desc->[_NAME] eq '') {
      croak "Array can not have name: $desc->[_NAME]";
    } elsif (my $type = $OPN{$sigil}) {
      $desc->[_VALUE] = $reader->can("organize_as_$type")
	->($reader, $tokens);
    } elsif ($sigil eq ']') {
      last;
    }
    push @result, $desc->[_VALUE];
  }
  \@result;
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

sub tokenize {
  my MY $reader = shift;
  my ($ncomments, @result);
  foreach my $token ($reader->split(my $record = shift)) {
    if ($token =~ s{^(?:\#[^\n]*(?:\n|$))+}{}) {
      $ncomments++;
      next if $token eq '';
    }

    unless ($token =~ s{^($cc_name*) ($cc_sigil) (?:($cc_tabsp)|(\n|$))}{}x) {
      croak "Invalid XHF token: $token"
	. (defined $reader->{cf_filename} ? " in $reader->{cf_filename}" : "");
    }
    my ($name, $sigil, $tabsp, $eol) = ($1, $2, $3, $4);

    # Comment fields are ignored.
    $ncomments++, next if $sigil eq "#";

    # Line continuation.
    $token =~ s/\n[\ \t]/\n/g;

    unless (defined $eol) {
      # Values are trimmed unless $eol
      $token =~ s/^\s+|\s+$//gs;
    } elsif ($OPN{$sigil}) {
      # Prohibit:
      # name{ foo
      # name[ foo
      croak "Invalid XHF token(container with value): "
	. join("", grep {defined $_} $name, $sigil, $tabsp, $token)
	  if $token ne "";
    } else {
      # Trim leading space for $tabsp eq "\n".
      $token =~ s/^[\ \t]//;
    }
    push @result, [$name, $token, $sigil];
  }

  # Comment only paragraph should return nothing.
  return if $ncomments && !@result;

  wantarray ? @result : \@result;
}

sub split {
  (my MY $reader, my ($record)) = @_;
  # XXX: Can avoid copy.
  $record =~ s{\n+$}{\n}s;
  split /(?<=\n)(?=[^\ \t])/, $record;
}

sub decode_name {
  (my MY $reader, my ($name)) = @_;
  $name =~ s{%([\da-f]{2})}{pack("C", hex($1))}egxi;
  $name;
}

1;
__END__

=head1 SYNOPSIS

  require YATT::XHF
  my $reader = YATT::XHF->new(filename => 'file');
  while (my $rec = $reader->read_as_hash) {
    print $rec->{'foo'}
  }

=head1 DESCRIPTION

Extended Header Fields (XHF) is a data format based on Email header
(and HTTP header), with extension to hold hierarchical data.

Mainly, XHF is designed for writing test cases.
Of course, for data serialization, YAML is well known.
But YAML imposes too much syntax to content(value) field.
To write tests in YAML, many escaping is required.

XHF is designed to avoid this escaping. XHF relies only on
field header at line-beginning, and escapes only newline on
trailing contents.

To achieve this, resulting syntax is somewhat odd for you than YAML.
So, if readability of nesting structure is your interest than
maintainability of verbatim contents, XHF is not for you.

=head1 AUTHOR

"KOBAYASI, Hiroaki", C<< <hkoba at cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, "KOBAYASI, Hiroaki" C<< <hkoba@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

