# -*- perl -*-
#
# Fill in `templates'
#
# Copyright 1996, 1997, 1999, 2001, 2002, 2003, 2008 M-J. Dominus.
# You may copy and distribute this program under the
# same terms as Perl iteself
# If in doubt, write to mjd-perl-template+@plover.com for a license.
#
# This is a slightly enhanced version of M-J. Dominus' Text::Templates 1.45
# I have tried to reach M-J. to get my patches into Text::Template
# but never got an answer.
#
# Version 1.45

package Text::Template::Base;
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(fill_in_file fill_in_string TTerror);
use strict;

our $VERSION='1.45';

our $ERROR;

my %GLOBAL_PREPEND = ('Text::Template::Base' => '');

sub _param {
  my $kk;
  my ($k, %h) = @_;
  for $kk ($k, "\u$k", "\U$k", "-$k", "-\u$k", "-\U$k") {
    return $h{$kk} if exists $h{$kk};
  }
  return;
}

sub always_prepend
{
  my $pack = shift;
  my $old = $GLOBAL_PREPEND{$pack};
  $GLOBAL_PREPEND{$pack} = shift;
  $old;
}

{
  my %LEGAL_TYPE;
  BEGIN { 
    %LEGAL_TYPE = map {$_=>1} qw(FILE FILEHANDLE STRING ARRAY);
  }
  sub new {
    my $pack = shift;
    my %a = @_;
    my $stype = uc(_param('type', %a)) || 'FILE';
    my $source = _param('source', %a);
    my $untaint = _param('untaint', %a);
    my $prepend = _param('prepend', %a);
    my $alt_delim = _param('delimiters', %a);
    my $broken = _param('broken', %a);
    my $filename = _param('filename', %a);
    my $evalcache = _param('evalcache', %a);
    unless (defined $source) {
      require Carp;
      Carp::croak("Usage: $ {pack}::new(TYPE => ..., SOURCE => ...)");
    }
    unless ($LEGAL_TYPE{$stype}) {
      require Carp;
      Carp::croak("Illegal value `$stype' for TYPE parameter");
    }
    my $self = {TYPE => $stype,
		PREPEND => $prepend,
                UNTAINT => $untaint,
                BROKEN => $broken,
		FILENAME => $filename,
                EVALCACHE => $evalcache,
		(defined $alt_delim ? (DELIM => $alt_delim) : ()),
	       };
    # Under 5.005_03, if any of $stype, $prepend, $untaint, or $broken
    # are tainted, all the others become tainted too as a result of
    # sharing the expression with them.  We install $source separately
    # to prevent it from acquiring a spurious taint.
    $self->{SOURCE} = $source;

    bless $self => $pack;
    return unless $self->_acquire_data;
    
    $self;
  }
}

# Convert template objects of various types to type STRING,
# in which the template data is embedded in the object itself.
sub _acquire_data {
  my ($self) = @_;
  my $type = $self->{TYPE};
  if ($type eq 'STRING') {
    # nothing necessary    
  } elsif ($type eq 'FILE') {
    my $data = _load_text($self->{SOURCE});
    unless (defined $data) {
      # _load_text already set $ERROR
      return undef;
    }
    if ($self->{UNTAINT} && _is_clean($self->{SOURCE})) {
      _unconditionally_untaint($data);
    }
    $self->{TYPE} = 'STRING';
    $self->{FILENAME} = $self->{SOURCE};
    $self->{SOURCE} = $data;
  } elsif ($type eq 'ARRAY') {
    $self->{TYPE} = 'STRING';
    $self->{SOURCE} = join '', @{$self->{SOURCE}};
  } elsif ($type eq 'FILEHANDLE') {
    $self->{TYPE} = 'STRING';
    local $/;
    my $fh = $self->{SOURCE};
    my $data = <$fh>; # Extra assignment avoids bug in Solaris perl5.00[45].
    if ($self->{UNTAINT}) {
      _unconditionally_untaint($data);
    }
    $self->{SOURCE} = $data;
  } else {
    # This should have been caught long ago, so it represents a 
    # drastic `can't-happen' sort of failure
    my $pack = ref $self;
    die "Can only acquire data for $pack objects of subtype STRING, but this is $type; aborting";
  }
  $self->{DATA_ACQUIRED} = 1;
}

sub source {
  my ($self) = @_;
  $self->_acquire_data unless $self->{DATA_ACQUIRED};
  return $self->{SOURCE};
}

sub set_source_data {
  my ($self, $newdata) = @_;
  $self->{SOURCE} = $newdata;
  $self->{DATA_ACQUIRED} = 1;
  $self->{TYPE} = 'STRING';
  1;
}

sub compile {
  my $self = shift;

  return 1 if $self->{TYPE} eq 'PREPARSED';

  return undef unless $self->_acquire_data;
  unless ($self->{TYPE} eq 'STRING') {
    my $pack = ref $self;
    # This should have been caught long ago, so it represents a 
    # drastic `can't-happen' sort of failure
    die "Can only compile $pack objects of subtype STRING, but this is $self->{TYPE}; aborting";
  }

  my @tokens;
  my $delim_pats = shift() || $self->{DELIM};

  

  my ($t_open, $t_close) = ('{', '}');
  my ($t_open_nl, $t_close_nl) = (0, 0);  # number of newlines per delimiter
  my $DELIM;			# Regex matches a delimiter if $delim_pats
  if (defined $delim_pats) {
    ($t_open, $t_close) = @$delim_pats;
    $DELIM = "(?:(?:\Q$t_open\E)|(?:\Q$t_close\E))";
    ($t_open_nl, $t_close_nl) = map {tr/\n//} $t_open, $t_close;
    @tokens = split /($DELIM|\n)/, $self->{SOURCE};
  } else {
    @tokens = split /(\\\\(?=\\*[{}])|\\[{}]|[{}\n])/, $self->{SOURCE};
  }
  my $state = 'TEXT';
  my $depth = 0;
  my $lineno = 1;
  my @content;
  my $cur_item = '';
  my $prog_start;
  while (@tokens) {
    my $t = shift @tokens;
    next if $t eq '';
    if ($t eq $t_open) {	# Brace or other opening delimiter
      if ($depth == 0) {
	push @content, [$state, $cur_item, $lineno] if $cur_item ne '';
	$lineno += $t_open_nl;
	$cur_item = '';
	$state = 'PROG';
	$prog_start = $lineno;
      } else {
	$lineno += $t_open_nl;
	$cur_item .= $t;
      }
      $depth++;
    } elsif ($t eq $t_close) {	# Brace or other closing delimiter
      $depth--;
      if ($depth < 0) {
	$ERROR = "Unmatched close brace at line $lineno";
	return undef;
      } elsif ($depth == 0) {
	$lineno += $t_close_nl;
	if ($cur_item =~ /^#line (\d+)$/) {
	  $lineno = $1;
	} elsif ($cur_item ne '') {
	  push @content, [$state, $cur_item, $prog_start];
	}
	$state = 'TEXT';
	$cur_item = '';
      } else {
	$cur_item .= $t;
      }
    } elsif (!$delim_pats && $t eq '\\\\') { # precedes \\\..\\\{ or \\\..\\\}
      $cur_item .= '\\';
    } elsif (!$delim_pats && $t =~ /^\\([{}])$/) { # Escaped (literal) brace?
	$cur_item .= $1;
    } elsif ($t eq "\n") {	# Newline
      $lineno++;
      $cur_item .= $t;
    } else {			# Anything else
      $cur_item .= $t;
    }
  }

  if ($state eq 'PROG') {
    $ERROR = "End of data inside program text that began at line $prog_start";
    return undef;
  } elsif ($state eq 'TEXT') {
    push @content, [$state, $cur_item, $lineno] if $cur_item ne '';
  } else {
    die "Can't happen error #1";
  }
  
  $self->{TYPE} = 'PREPARSED';
  $self->{SOURCE} = \@content;
  1;
}

sub prepend_text {
  my ($self) = @_;
  my $t = $self->{PREPEND};
  unless (defined $t) {
    $t = $GLOBAL_PREPEND{ref $self};
    unless (defined $t) {
      $t = $GLOBAL_PREPEND{'Text::Template::Base'};
    }
  }
  $self->{PREPEND} = $_[1] if $#_ >= 1;
  return $t;
}

sub fill_in {
  my $fi_self = shift;
  my %fi_a = @_;

  unless ($fi_self->{TYPE} eq 'PREPARSED') {
    my $delims = _param('delimiters', %fi_a);
    my @delim_arg = (defined $delims ? ($delims) : ());
    $fi_self->compile(@delim_arg)
      or return undef;
  }

  my $fi_varhash = _param('hash', %fi_a);
  my $fi_package = _param('package', %fi_a) ;
  my $fi_broken  = 
    _param('broken', %fi_a)  || $fi_self->{BROKEN} || \&_default_broken;
  my $fi_broken_arg = _param('broken_arg', %fi_a) || [];
  my $fi_safe = _param('safe', %fi_a);
  my $fi_ofh = _param('output', %fi_a);
  my $fi_eval_package;
  my $fi_scrub_package = 0;
  my $fi_filename = _param('filename', %fi_a) || $fi_self->{FILENAME} || 'template';
  my $fi_evalcache = _param('evalcache', %fi_a)  || $fi_self->{EVALCACHE};

  my $fi_prepend = _param('prepend', %fi_a);
  unless (defined $fi_prepend) {
    $fi_prepend = $fi_self->prepend_text;
  }

  if (defined $fi_safe) {
    $fi_eval_package = 'main';
  } elsif (defined $fi_package) {
    $fi_eval_package = $fi_package;
  } elsif (defined $fi_varhash) {
    $fi_eval_package = _gensym();
    $fi_scrub_package = 1;
  } else {
    $fi_eval_package = caller;
  }

  my $fi_install_package;
  if (defined $fi_varhash) {
    if (defined $fi_package) {
      $fi_install_package = $fi_package;
    } elsif (defined $fi_safe) {
      $fi_install_package = $fi_safe->root;
    } else {
      $fi_install_package = $fi_eval_package; # The gensymmed one
    }
    _install_hash($fi_varhash => $fi_install_package);
  }

  if (defined $fi_package && defined $fi_safe) {
    no strict 'refs';
    # Big fat magic here: Fix it so that the user-specified package
    # is the default one available in the safe compartment.
    *{$fi_safe->root . '::'} = \%{$fi_package . '::'};   # LOD
  }

  my $fi_r = '';
  my $fi_ofn;
  if(defined $fi_ofh) {
    if(ref $fi_ofh eq 'CODE') {
      $fi_ofn = sub {&$fi_ofh; return};
    } else {
      $fi_ofn = sub {print $fi_ofh $_[0]; return};
    }
  } else {
    $fi_ofn = sub {$fi_r .= $_[0]; return};
  }
  my $fi_item;
  foreach $fi_item (@{$fi_self->{SOURCE}}) {
    my ($fi_type, $fi_text, $fi_lineno) = @$fi_item;
    if ($fi_type eq 'TEXT') {
      &$fi_ofn($fi_text);
    } elsif ($fi_type eq 'PROG') {
      no strict;
      my $fi_lcomment = "#line $fi_lineno $fi_filename";
      my $fi_progtext = 
        "package $fi_eval_package; $fi_prepend;\n$fi_lcomment\n$fi_text;";
      my $fi_res;
      my $fi_eval_err = '';
      if ($fi_safe) {
        $fi_safe->reval(q{undef $OUT});
	$fi_res = $fi_safe->reval($fi_progtext);
	$fi_eval_err = $@;
	my $OUT = $fi_safe->reval('$OUT');
	$fi_res = $OUT if defined $OUT;
      } else {
	no warnings 'redefine';
	local *{$fi_eval_package.'::OUT'}=$fi_ofn;
	if( ref $fi_evalcache eq 'HASH' ) {
	  my $fn = $fi_evalcache->{$fi_progtext};
	  unless(defined $fn) {
	    $fn = $fi_evalcache->{$fi_progtext} =
	      eval "sub {my \$OUT;my \$x=do{\n$fi_progtext\n};".
		   "defined \$OUT ? \$OUT : \$x}";
	  }
	  $fi_res = eval {&$fn} if $fn;
	} else {
	  my $OUT;
	  $fi_res = eval $fi_progtext;
	  $fi_res = $OUT if defined $OUT;
	}
	$fi_eval_err = $@;
      }

      # If the value of the filled-in text really was undef,
      # change it to an explicit empty string to avoid undefined
      # value warnings later.
      $fi_res = '' unless defined $fi_res;

      if ($fi_eval_err) {
	$fi_res = $fi_broken->(text => $fi_text,
			       error => $fi_eval_err,
			       lineno => $fi_lineno,
			       arg => $fi_broken_arg,
			       );
	if (defined $fi_res) {
	  &$fi_ofn($fi_res);
	} else {
	  return $fi_res;		# Undefined means abort processing
	}
      } else {
	&$fi_ofn($fi_res);
      }
    } else {
      die "Can't happen error #2";
    }
  }

  _scrubpkg($fi_eval_package) if $fi_scrub_package;
  defined $fi_ofh ? 1 : $fi_r;
}

sub fill_this_in {
  my $pack = shift;
  my $text = shift;
  my $templ = $pack->new(TYPE => 'STRING', SOURCE => $text, @_)
    or return undef;
  $templ->compile or return undef;
  my $result = $templ->fill_in(@_);
  $result;
}

sub fill_in_string {
  my $string = shift;
  my $package = _param('package', @_);
  push @_, 'package' => scalar(caller) unless defined $package;
  Text::Template::Base->fill_this_in($string, @_);
}

sub fill_in_file {
  my $fn = shift;
  my $templ = Text::Template::Base->new(TYPE => 'FILE', SOURCE => $fn, @_)
    or return undef;
  $templ->compile or return undef;
  my $text = $templ->fill_in(@_);
  $text;
}

sub _default_broken {
  my %a = @_;
  my $prog_text = $a{text};
  my $err = $a{error};
  my $lineno = $a{lineno};
  chomp $err;
#  $err =~ s/\s+at .*//s;
  "Program fragment delivered error ``$err''";
}

sub _load_text {
  my $fn = shift;
  local *F;
  unless (open F, $fn) {
    $ERROR = "Couldn't open file $fn: $!";
    return undef;
  }
  local $/;
  <F>;
}

sub _is_clean {
  my $z;
  eval { ($z = join('', @_)), eval '#' . substr($z,0,0); 1 }   # LOD
}

sub _unconditionally_untaint {
  local $_;
  for (@_) {
    ($_) = /(.*)/s;
  }
}

{
  my $seqno = 0;
  sub _gensym {
    __PACKAGE__ . '::GEN' . $seqno++;
  }
  sub _scrubpkg {
    my $s = shift;
    $s =~ s/^Text::Template::Base:://;
    no strict 'refs';
    my $hash = $Text::Template::Base::{$s."::"};
    foreach my $key (keys %$hash) {
      undef $hash->{$key};
    }
  }
}

# Given a hashful of variables (or a list of such hashes)
# install the variables into the specified package,
# overwriting whatever variables were there before.
sub _install_hash {
  my $hashlist = shift;
  my $dest = shift;
  if (UNIVERSAL::isa($hashlist, 'HASH')) {
    $hashlist = [$hashlist];
  }
  my $hash;
  foreach $hash (@$hashlist) {
    my $name;
    foreach $name (keys %$hash) {
      my $val = $hash->{$name};
      no strict 'refs';
      local *SYM = *{"$ {dest}::$name"};
      if (! defined $val) {
	delete ${"$ {dest}::"}{$name};
      } elsif (ref $val) {
	*SYM = $val;
      } else {
 	*SYM = \$val;
      }
    }
  }
}

sub TTerror { $ERROR }

1;


=head1 NAME 

Text::Template::Base - Expand template text with embedded Perl

=head1 SYNOPSIS

 use Text::Template::Base;

=head1 DESCRIPTION

This module is an enhanced version of M-J. Dominus' L<Text::Template>
version 1.45.

I have tried to contact M-J. to get my patches (included in this distribution
in the C<patches/> directory) into L<Text::Template> but
never got an answer.

For usage information see L<Text::Template>.

=head1 DIFFERENCES COMPARED TO Text::Template 1.45

=head2 The C<OUT> function (to be used within templates)

The C<OUT> function serves a similar purpose as C<$OUT>. It is
automatically installed in the package the template is evaluated in.
Hence a template can look like this:

	Here is a list of the things I have got for you since 1907:
	{ foreach $i (@items) {
            OUT "  * $i\n";
          }
        }

The advantage of the function over C<$OUT> is that it wastes less memory.
Suppose you have a very long list of items. Using C<$OUT> it is first
accumulated in that variable and then appended to the resulting string.
That means it uses twice the memory (for a short time). With the C<OUT>
function each piece of generated text is immediately appended to the
resulting string.

But the main advantage lies in using the C<OUT> function in combination
with the C<OUTPUT> option to C<fill_in>. Now a piece of output is directly
put out and nothing at all accumulated.

There is also a drawback. C<$OUT> is an ordinary variable and can be used
as such. This template cannot be easily converted to using C<OUT>:

	Here is a list of the things I have got for you since 1907:
	{ foreach $i (@items) {
            $OUT .= "  * $i\n";
            if( some_error ) {
              # forget the output so far
              $OUT = "An error has occurred";
              last;
            }
          }
        }

NOTE, the C<OUT> function doesn't work with the L<C<SAFE>> option.

=head2 The C<OUTPUT> parameter to C<new()> and C<fill_in>

C<Text::Template> allows for a file handle to be passed as C<OUTPUT>
parameter. Each chunk of output will be written directly to this handle.

With this module a subroutine can be passed instead of the file handle.
Each chunk of output will be passed to this function as the only
parameter.

 $template->fill_in(OUTPUT => sub { print $_[0] }, ...);

=head2 The C<FILENAME> parameter to C<new()> and C<fill_in>

When C<Text::Template> generates error messages it tries to include
the file name and line number where the error has happened. But for some
template types the file name is not known. In such cases C<Text::Template>
simply uses the string C<template>. With the C<FILENAME> parameter this
string can be configured.

=head2 The C<EVALCACHE> parameter to C<new()> and C<fill_in>

Normally C<Text::Template> calls C<eval> each time to evaluate a piece
of Perl code. This can be a performance killer if the same piece is
evaluated over and over again.

One solution could be to wrap the piece of code into a subroutine, have
Perl compile that routine only once and use it many times.

If C<EVALCACHE> is given C<Text::Template> does exactly that. A piece of
perl code is wrapped as a subroutine, compiled and the resulting code
references are saved in the C<EVALCACHE> with the actual perl text as key.

C<EVALCACHE> does not currently work if the C<SAFE> option is used.

There are a few pitfalls with that method that have to be looked out by the
template programmer. Suppose you have that piece of code in a template:

	my $var = 5;
	sub function {
	  return $var++;
	}
	$OUT.=function() for( 1..3 );

That piece will producess the string C<567> in
C<$OUT> each time it is evaluated. But if it is wrapped into a subroutine
it looks like:

	sub {
	  my $var = 5;
	  sub function {
	    return $var++;
	  }
	  $OUT.=function() for( 1..3 );
	};

If that anonymous function is called several times it produces C<012>,
C<345> and so on. The problem is that named functions (like C<function>)
are created at compile time while anonymous functions (like the outer sub)
at run time. Hence, the C<$var> my-variable is not available in
C<function>. Perl solves thar conflict by creating a separate variable
C<$var> at compile time that is initially C<undef>. Evaluated in numerical
context is gives C<0>.

So, how can the code fragment be converted so that the function is created
at runtime. There are 2 ways. Firstly, you can use function references:

	sub {
	  my $var = 5;
	  my $function = sub {
	    return $var++;
	  };
	  $OUT.=$function->() for( 1..3 );
	};

Now both the inner and the outer functions are anomymous and both are created
at runtime. But calling C<function> as C<< $function->() >> may not be
convenient. So, the second way uses a C<local>ized symbol:

	sub {
	  my $var = 5;
	  local *function = sub {
	    return $var++;
	  };
	  $OUT.=function() for( 1..3 );
	};

For more information see L<http://perl.apache.org/docs/general/perl_reference/perl_reference.html#my____Scoped_Variable_in_Nested_Subroutines>

=head2 The C<#line> directive in templates

Correct line numbers are crucial for debugging. If a template is fetched
from a larger file and passed to C<Text::Template::Base> as string
C<Text::Template::Base> doesn't know at which line of the larger file the
template starts. Hence, it cannot produce correct error messages.

The solution is to prepend the template string (assuming default
delimiters are used) with

	{#line NUMBER}

where C<NUMBER> is the actual line number where the template starts.

If custom delimiters are used replace the braces by them. Assuming C<[%>
and C<%]> as delimiters that directive should look:

	[%#line NUMBER%]

Note that there must not be any other character between the opening
delimiter and the C<#line> and between the C<NUMBER> and the closing
delimiter not even spaces. Also, there must be only one space between
C<#line> and C<NUMBER>.

The C<#line> directive works not only at the beginning of a template.
Suppose you have a larger template and have cut out some parts prior
to passing it to C<Text::Template::Base> as a string. Replace these parts with
correct C<#line> directives and your error messages are correct.

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

Most of this module is borrowed from
L<Text::Template> by Mark-Jason Dominus, Plover Systems

=cut
