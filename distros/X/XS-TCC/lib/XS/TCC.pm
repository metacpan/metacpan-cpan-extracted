package XS::TCC;
use 5.10.1;
use strict;
use warnings;

our $VERSION = '0.05';

use constant {
  TCC_OUTPUT_MEMORY     => 0,
  TCC_OUTPUT_EXE        => 1,
  TCC_OUTPUT_DLL        => 2,
  TCC_OUTPUT_OBJ        => 3,
  TCC_OUTPUT_PREPROCESS => 4,
};

use Carp ();
use Exporter 'import';
use XSLoader;

use ExtUtils::Embed ();
use ExtUtils::Typemaps;
use ExtUtils::ParseXS::Eval;
use File::Spec;
use File::ShareDir;
use Alien::TinyCC;
use Config;

# Needed for typemap_func.h:
our $RuntimeIncludeDir = File::ShareDir::dist_dir('XS-TCC');
our $PerlCoreDir = File::Spec->catfile($Config{archlib}, 'CORE');

use XS::TCC::Typemaps;
use XS::TCC::Parser;

XSLoader::load('XS::TCC', $VERSION);

our @EXPORT_OK = qw(
  tcc_inline
  TCC_OUTPUT_MEMORY
  TCC_OUTPUT_EXE
  TCC_OUTPUT_DLL
  TCC_OUTPUT_OBJ
  TCC_OUTPUT_PREPROCESS
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $CCOPTS;
{
  local $0 = "NOT A -e LINE!"; # ExtUtils::Embed is daft
  $CCOPTS = ExtUtils::Embed::ccopts;

  # -DDEBUGGING causes some 'interesting' corner cases for tcc and
  # some people/systems, see:
  # https://rt.perl.org/Public/Bug/Display.html?id=130046
  # So remove -DDEBUGGING from the tcc invocation by default.
  $CCOPTS =~ s/\b-DDEBUGGING\b//g;
}

my $CodeHeader = <<'HERE';
#ifndef XS_TCC_INIT
#define XS_TCC_INIT
/* #define PERL_NO_GET_CONTEXT */

#ifdef __XS_TCC_DARWIN__
/* http://comments.gmane.org/gmane.comp.compilers.tinycc.devel/325 */
typedef unsigned short __uint16_t, uint16_t;
typedef unsigned int __uint32_t, uint32_t;
typedef unsigned long __uint64_t, uint64_t;
#endif

#ifdef __XS_TCC_WIN__
#define __C89_NAMELESS
#define __MINGW_EXTENSION
typedef long __int64;
typedef int uid_t;
typedef int gid_t;
#endif

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef HAS_BUILTIN_EXPECT
#  undef HAS_BUILTIN_EXPECT
#  ifdef EXPECT
#    undef EXPECT
#    define EXPECT(expr, val) (expr)
#  endif
#endif

#include <typemap_func.h>

/* The XS_EXTERNAL macro is used for functions that must not be static
 * like the boot XSUB of a module. If perl didn't have an XS_EXTERNAL
 * macro defined, the best we can do is assume XS is the same.
 * Dito for XS_INTERNAL.
 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) XS(name)
#endif

#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#ifndef dVAR
#  define dVAR		dNOOP
#endif


#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)

/* prototype to pass -Wmissing-prototypes */
STATIC void
S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params);

STATIC void
S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params)
{
    const GV *const gv = CvGV(cv);

    PERL_ARGS_ASSERT_CROAK_XS_USAGE;

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
            Perl_croak(aTHX_ "Usage: %s::%s(%s)", hvname, gvname, params);
        else
            Perl_croak(aTHX_ "Usage: %s(%s)", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
        Perl_croak(aTHX_ "Usage: CODE(0x%"UVxf")(%s)", PTR2UV(cv), params);
    }
}
#undef  PERL_ARGS_ASSERT_CROAK_XS_USAGE

#ifdef PERL_IMPLICIT_CONTEXT
#  define croak_xs_usage(a,b)    S_croak_xs_usage(aTHX_ a,b)
#else
#  define croak_xs_usage        S_croak_xs_usage
#endif

#endif

#endif /* XS_TCC_INIT */
HERE

SCOPE: {
  my @compilers; # never die...
  #my $compiler;
  sub _get_compiler {
    #return $compiler if $compiler;
    my $compiler = XS::TCC::TCCState->new;
    $compiler->add_sysinclude_path($RuntimeIncludeDir);
	$compiler->add_sysinclude_path($PerlCoreDir);
    if ($^O eq 'darwin') {
        $compiler->define_symbol("__XS_TCC_DARWIN__", 1);
    }
	elsif ($^O =~ /MSWin/) {
		$compiler->define_symbol("__XS_TCC_WIN__", 1);
	}
    #push @compilers, $compiler;
    return $compiler;
  } # end _get_compiler
} # end SCOPE


SCOPE: {
  my $core_typemap;
  sub _get_core_typemap {
    return $core_typemap if $core_typemap;

    my @tm;
    foreach my $dir (@INC) {
      my $file = File::Spec->catfile($dir, ExtUtils => 'typemap');
      unshift @tm, $file if -e $file;
    }

    $core_typemap = ExtUtils::Typemaps->new();
    foreach my $typemap_loc (@tm) {
      next unless -f $typemap_loc;
      # skip directories, binary files etc.
      warn("Warning: ignoring non-text typemap file '$typemap_loc'\n"), next
        unless -T $typemap_loc;

      $core_typemap->merge(file => $typemap_loc, replace => 1);
    }

    # Override core typemaps with custom function-based replacements.
    # This is because GCC compiled functions are likely faster than inlined code in TCC.
    $core_typemap->merge(replace => 1, typemap => $XS::TCC::Typemaps::Typemap);

    return $core_typemap;
  } # end _get_core_typemap
} # end SCOPE

# current options:
# code, warn_code, package, typemap, add_files, ccopts
sub tcc_inline (@) {
  my $code;

  $code = pop @_ if @_ % 2;
  my %args = @_;

  if (defined $code and defined $args{code}) {
    Carp::croak("Can't specify code both as a named and as a positional parameter");
  }
  $code //= $args{code};
  Carp::croak("Need code to compile") if not defined $code;

  my $package = $args{package} // (caller())[0];

  # Set up the typemap object if any (defaulting to core typemaps)
  my $typemap;
  my $typemap_arg = $args{typemap};
  if (not defined($typemap_arg)) {
    $typemap = _get_core_typemap();
  }
  elsif (ref($typemap_arg)) {
    $typemap = _get_core_typemap()->clone(shallow => 1);
    $typemap->merge(typemap => $typemap_arg);
  }
  else {
    $typemap = _get_core_typemap()->clone(shallow => 1);
    $typemap->add_string(string => $typemap_arg);
  }

  # Function signature parsing
  my $parse_result = XS::TCC::Parser::extract_function_metadata($code);
  return
    if not $parse_result
    or not @{$parse_result->{function_names}};

  # eval the typemaps for the function sig
  my @code = ($CodeHeader, $code);
  foreach my $cfun_name (@{$parse_result->{function_names}}) {
    my $fun_info = $parse_result->{functions}{$cfun_name};
    my $xs_fun = _gen_single_function_xs_wrapper($package, $cfun_name, $fun_info, $typemap, \@code);
    $fun_info->{xs_function_name} = $xs_fun;
  }

  my $final_code = join "\n", @code;

  warn _add_line_nums($final_code) if $args{warn_code};

  my $compiler = _get_compiler();

  # Code to catch compile errors
  my $errmsg;
  my $err_hook = sub { $errmsg = $_[0] };

  $compiler->set_error_callback($err_hook);

  # Add user-specified files
  my @add_files;
  @add_files = ref($args{add_files}) ? @{$args{add_files}} : $args{add_files}
    if defined $args{add_files};
  $compiler->add_file($_) for @add_files;

  # Do the compilation
  $compiler->set_options(($args{ccopts} // $CCOPTS));
  # compile_string() returns 0 if succeeded, -1 otherwise.
  my $fatal = $compiler->compile_string($final_code);
  $compiler->relocate();

  if (defined $errmsg) {
    $errmsg = _build_compile_error_msg($errmsg, 1);
    if ($fatal) {
      Carp::croak($errmsg);
    } else {
      Carp::carp($errmsg);
    }
  }

  # install the XSUBs
  foreach my $cfun_name (@{$parse_result->{function_names}}) {
    my $fun_info = $parse_result->{functions}{$cfun_name};
    my $sym = $compiler->get_symbol($fun_info->{xs_function_name});
    my $perl_name = $package . "::" . $cfun_name;
    my $sub = $sym->as_xsub();
    no strict 'refs';
    *{"$perl_name"} = $sub;
  }

}


sub _build_compile_error_msg {
  my ($msg, $caller_level) = @_;
  $caller_level++;
  # TODO write code to emit file/line info
  return $msg;
}

sub _gen_single_function_xs_wrapper {
  my ($package, $cfun_name, $fun_info, $typemap, $code_ary) = @_;

  my $arg_names = $fun_info->{arg_names};
  my $nparams = scalar(@$arg_names);
  my $arg_names_str = join ", ", map {s/\W/_/; $_} @$arg_names;

  # Return type and output typemap preparation
  my $ret_type = $fun_info->{return_type};
  my $is_void_function = $ret_type eq 'void';
  my $retval_decl = $is_void_function ? '' : "$ret_type RETVAL;";

  my $out_typemap;
  my $outputmap;
  my $dxstarg = "";
  if (not $is_void_function) {
    $out_typemap = $typemap->get_typemap(ctype => $ret_type);
    $outputmap = $out_typemap
                 ? $typemap->get_outputmap(xstype => $out_typemap->xstype)
                 : undef;
    Carp::croak("No output typemap found for return type '$ret_type'")
      if not $outputmap;
    # TODO implement TARG optimization below
    #$dxstarg = $outputmap->targetable ? " dXSTARG;" : "";
  }

  # Emit function header and declarations
  (my $xs_pkg_name = $package) =~ s/:+/_/g;
  my $xs_fun_name = "XS_${xs_pkg_name}_$cfun_name";
  push @$code_ary, <<FUN_HEADER;
XS_EXTERNAL($xs_fun_name); /* prototype to pass -Wmissing-prototypes */
XS_EXTERNAL($xs_fun_name)
{
  dVAR; dXSARGS;$dxstarg
  if (items != $nparams)
    croak_xs_usage(cv,  "$arg_names_str");
  /* PERL_UNUSED_VAR(ax); */ /* -Wall */
  /* SP -= items; */
  {
    $retval_decl


FUN_HEADER

  my $do_pass_threading_context = $fun_info->{need_threading_context};

  # emit input typemaps
  my @input_decl;
  my @input_assign;
  for my $argno (0..$#{$fun_info->{arg_names}}) {
    my $aname = $fun_info->{arg_names}[$argno];
    my $atype = $fun_info->{arg_types}[$argno];
    (my $decl_type = $atype) =~ s/^\s*const\b\s*//;

    my $tm = $typemap->get_typemap(ctype => $atype);
    my $im = !$tm ? undef : $typemap->get_inputmap(xstype => $tm->xstype);

    Carp::croak("No input typemap found for type '$atype'")
      if not $im;
    my $imcode = $im->cleaned_code;

    my $vars = {
      Package => $package,
      ALIAS => $cfun_name,
      func_name => $cfun_name,
      Full_func_name => $cfun_name,
      pname => $package . "::" . $cfun_name,
      type => $decl_type,
      ntype => $decl_type,
      arg => "ST($argno)",
      var => $aname,
      init => undef,
      # FIXME some of these are guesses at their true meaning. Validate in EU::PXS
      num => $argno,
      printed_name => $aname,
      argoff => $argno,
    };

    # FIXME do we want to support the obscure ARRAY/Ptr logic (subtype, ntype)?
    my $out = ExtUtils::ParseXS::Eval::eval_input_typemap_code(
      $vars, qq{"$imcode"}, $vars
    );

    $out =~ s/;\s*$//;
    if ($out =~ /^\s*\Q$aname\E\s*=/) {
      push @input_decl, "    $decl_type $out;";
    }
    else {
      push @input_decl, "    $decl_type $aname;";
      push @input_assign, "    $out;";
    }
  }
  push @$code_ary, @input_decl, @input_assign;

  # emit function call
  my $fun_call_assignment = $is_void_function ? "" : "RETVAL = ";
  my $arglist = join ", ",  @{ $fun_info->{arg_names} };
  my $threading_context = "";
  if ($do_pass_threading_context) {
     $threading_context = scalar(@{ $fun_info->{arg_names} }) == 0
                          ? "aTHX " : "aTHX_ ";
  }
  push @$code_ary, "    ${fun_call_assignment}$cfun_name($threading_context$arglist);\n";

  # emit output typemap
  if (not $is_void_function) {
    my $omcode = $outputmap->cleaned_code;
    my $vars = {
      Package => $package,
      ALIAS => $cfun_name,
      func_name => $cfun_name,
      Full_func_name => $cfun_name,
      pname => $package . "::" . $cfun_name,
      type => $ret_type,
      ntype => $ret_type,
      arg => "ST(0)",
      var => "RETVAL",
    };

    # FIXME do we want to support the obscure ARRAY/Ptr logic (subtype, ntype)?

    # TODO TARG ($om->targetable) optimization!
    my $out = ExtUtils::ParseXS::Eval::eval_output_typemap_code(
      $vars, qq{"$omcode"}, $vars
    );
    push @$code_ary, "    ST(0) = sv_newmortal();";
    push @$code_ary, "    " . $out;
  }


  my $nreturnvalues = $is_void_function ? 0 : 1;
  push @$code_ary, <<FUN_FOOTER;
  }
  XSRETURN($nreturnvalues);
}
FUN_FOOTER

  return($xs_fun_name);
}

# just for debugging
sub _add_line_nums {
  my $code = shift;
  my $i = shift || 1;
  my @l = split /\n/, $code;
  my $n = @l + $i - 1;
  my $len = length($n);
  return join("\n", map sprintf("% ${len}u: %s", $i++, $_), @l);
}

1;

__END__

=head1 NAME

XS::TCC - Embed, wrap & compile C code in Perl without going to disk

=head1 SYNOPSIS

  use XS::TCC qw(tcc_inline);
  
  tcc_inline q{
    int foo(int bar) {
      return bar * 2;
    }
  };
  
  print foo(3), "\n"; # prints 6
  # more elaborate functions involving Perl types work as well

=head1 DESCRIPTION

B<Before you consider adopting this module, please have a look at the
L<C::Blocks> module.> C<C::Blocks> is a more powerful, more lovingly
maintained piece of software. Due to current (as of early 2017) scarcity
of spare time on my part, you can't expect to get a lot of support for
C<XS::TCC> from me. This being said, C<XS::TCC> should work reliably
at least on reasonably standard Linux systems. I<--Steffen>

C<XS::TCC> allows you to embed C code into your Perl that is compiled
and linked on the fly, in memory, without ever touching your disk
except to read the Perl code in the first place. This amazing feat
actually has very little to do with this module's code but rather
with TCC (TinyCC, see tinycc.org) which allows compilation and linking
in memory.

On my first-gen core i5 laptop, making two small-medium size functions
available to Perl takes around 30ms including parse, wrapper code generation,
typemapping, compilation, linking, and XSUB installation. Wrapping more code
is bound to be relatively faster.

The output of TCC is slower than the equivalent function compiled with GCC,
but both beat regular Perl by a wide margin {citation required}.

=head1 FUNCTIONS

=head2 tcc_inline

The optionally exported F<tcc_inline> function is the main end user interface for
C<XS::TCC>. In its simplest form, it simply takes a string of C code as its first
parameter. The C code will be compiled with TCC on the fly (and in memory rather than
on disk as with C<Inline>), and any C functions in that string will be bound
under the same name as XS functions. The argument and return types will be mapped
with Perl's standard C<typemap> functionality, see also the L<perlxstypemap> man page.

Optionally, you can provide named parameters to C<tcc_inline> as key-value pairs preceding the code string:

  tcc_inline(
    option => 'value',
    option2 => 'value2',
    q{ int foo() {return 42;} }
  );

Valid options are:

=over 2

=item package

The Perl package to put the XS functions into instead of your current
package.

=item typemap

The value for this option can be either a string of typemap code
(ie. what you would put in a C<TYPEMAP> block in XS or a typemap
file in a Perl XS distribution) or an L<ExtUtils::Typemap> object.

In either case, the given typemap will be merged with the core perl
typemaps (your custom ones will supercede the core ones where applicable)
and the resulting merged typemap will be used for the compilation.

=item ccopts

Any compiler flags you want to pass. By default, C<XS::TCC> will use
L<ExtUtils::Embed> to intuit your CC options. If you pass a C<ccopts>
value, those options will replace the default options from
C<ExtUtils::Embed::ccopts>.

=item add_files

Can be a single path/file name or an array ref containing one or multiple.
These additional C code-containing files will be passed to TCC to compile.

They will B<NOT> be parsed for function signatures by C<XS::TCC>. That is to say,
functions in these files will B<NOT> be exposed as XSUBs.

=item code

The C code to compile. You can use this form instead of the trailing
code string. (But not both.)

=item warn_code

Debugging: If this is set to a true value, the generated XS code will be
passed to C<warn> before compiling it.

=back

=head1 ADVANCED NOTES

This is a very incomplete section with notes on advanced usage.

=head2 Perl Context

In XS, it's very common to pass a pointer to the I<currently active Perl
interpreter>, also known as C<THX> around. Many Perl API functions need to have
such a context around to function properly. For convenience, one can
find the currently active Perl interpreter without passing it around as a
function parameter, but this comes at the cost of performance.

C<XS::TCC> allows you to include the standard C<pTHX> and C<pTHX_> macros in your
function signatures to get the Perl context as an argument in your C function.
To wit, the following to functions are equivalent in that they return the type
of context that the function is called in (as the Perl internal integer ids
corresponding to void/scalar/list contexts). This is a very useless thing to do, of course, this is for demonstration purposes only):

  /* efficient */
  int which_context(pTHX) {
    return (int)GIMME_V;
  }

  /* less efficient */
  int which_context_slow() {
    dTHX;
    return (int)GIMME_V;
  }

Testing this with a simple script gives on a threaded perl:

  $ perl -Mblib author_tools/dthx_benchmark.pl 
                  Rate  pTHX   dTHX
  pTHX  1860.2+-0.31/s    -- -12.5%
  dTHX 2124.91+-0.14/s 14.2%     --

On a perl compiled without multi-threading support, the timings are
equal between the two variants.

=head1 SEE ALSO

=over

=item * L<Alien::TinyCC>

=item * L<C::Blocks>

=item * L<C::TinyCompiler>

=item * L<C::TCC>

=item * L<Inline> and L<Inline::C>

=item * L<ExtUtils::ParseXS> and L<ExtUtils::Typemaps>

=back

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

With much appreciated contributions from:

Tokuhiro Matsuno

David Mertens

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, 2014, 2016, 2017 by Steffen Mueller

  XS::TCC is distributed under the GNU Lesser General Public License
  (see COPYING file).

=cut
