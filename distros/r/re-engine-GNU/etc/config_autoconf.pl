#!perl
use strict;
use diagnostics;
use Config::AutoConf 0.311;
use File::Temp qw/tempfile/;
use Capture::Tiny qw/capture/;
use POSIX qw/EXIT_SUCCESS/;
use File::Spec;
#
# config for gnu regex
#
do_config_GNU();

exit(EXIT_SUCCESS);

sub do_config_GNU {
    my $config = File::Spec->catfile('config_autoconf.h');
    my $log = File::Spec->catfile('config_autoconf.log');

    my $ac = Config::AutoConf->new(logfile => $log);

    print STDERR "...\n";
    print STDERR "... GNU REGEX configuration\n";
    print STDERR "... -----------------------\n";
    $ac->check_cc;
    $ac->check_default_headers;
    ac_c_inline($ac);
    ac_c_restrict($ac);
    ac_malloc_0_is_non_null($ac);
    $ac->check_func('malloc', { prologue => '#include <stdlib.h>' });
    $ac->check_func('realloc', { prologue => '#include <stdlib.h>' });
    $ac->check_type('mbstate_t', { prologue => "#include <stddef.h>\n#include <stdio.h>\n#include <time.h>\n#include <wchar.h>" });
    $ac->check_type('_Bool');
    $ac->check_header('assert.h');
    $ac->check_header('ctype.h');
    $ac->check_header('stdio.h');
    $ac->check_header('stdlib.h');
    $ac->check_header('string.h');
    $ac->check_header('wchar.h');
    $ac->check_header('wctype.h');
    $ac->check_header('stdbool.h');
    $ac->check_header('stdint.h');
    $ac->check_header('sys/int_types.h');
    #
    # No test on alloca -> HAVE_ALLOCA will be false, which is what we want
    #
    $ac->check_func('isblank', { prologue => '#include <ctype.h>' });
    $ac->check_func('iswctype', { prologue => '#include <wctype.h>' });
    $ac->check_decl('isblank', { action_on_true => sub { $ac->define_var('HAVE_DECL_ISBLANK', 1) }, prologue => '#include <ctype.h>' });
    $ac->define_var('_REGEX_INCLUDE_LIMITS_H', 1);
    $ac->define_var('_REGEX_LARGE_OFFSETS', 1);
    $ac->define_var('_PERL_I18N', 1);
    $ac->define_var('re_syntax_options', 'rpl_re_syntax_options');
    $ac->define_var('re_set_syntax', 'rpl_re_set_syntax');
    $ac->define_var('re_compile_pattern', 'rpl_re_compile_pattern');
    $ac->define_var('re_compile_fastmap', 'rpl_re_compile_fastmap');
    $ac->define_var('re_search', 'rpl_re_search');
    $ac->define_var('re_search_2', 'rpl_re_search_2');
    $ac->define_var('re_match', 'rpl_re_match');
    $ac->define_var('re_match_2', 'rpl_re_match_2');
    $ac->define_var('re_set_registers', 'rpl_re_set_registers');
    $ac->define_var('re_comp', 'rpl_re_comp');
    $ac->define_var('re_exec', 'rpl_re_exec');
    $ac->define_var('regcomp', 'rpl_regcomp');
    $ac->define_var('regexec', 'rpl_regexec');
    $ac->define_var('regerror', 'rpl_regerror');
    $ac->define_var('regfree', 'rpl_regfree');
    $ac->check_type('size_t');
    $ac->check_type('ssize_t');
    $ac->check_sizeof_type('char');
    $ac->check_sizeof_type('wchar_t');
    #
    # For ssize_t definition
    #
    $ac->check_sizeof_type('size_t');
    $ac->check_sizeof_type('short');
    $ac->check_sizeof_type('int');
    $ac->check_sizeof_type('long');
    $ac->check_sizeof_type('long long');
    $ac->write_config_h($config);
}

sub ac_execute_if_else {
  my ($self, $src) = @_;
  my $options = {};
  scalar @_ > 2 and ref $_[-1] eq "HASH" and $options = pop @_;

  my $builder = $self->_get_builder();

  my ($fh, $filename) = tempfile( "testXXXXXX", SUFFIX => '.c' );
  print {$fh} $src;
  close $fh;

  my ( $obj_file, $outbuf, $errbuf, $exception );
  ( $outbuf, $errbuf ) = capture
    {
      eval {
        $obj_file = $builder->compile(
                                      source               => $filename,
                                      include_dirs         => $self->{extra_include_dirs},
                                      extra_compiler_flags => $self->_get_extra_compiler_flags()
                                     );
      };

      $exception = $@;
    };
  if ( $exception || !$obj_file )
    {
      $self->_add_log_lines( "compile stage failed" . ( $exception ? " - " . $exception : "" ) );
      $errbuf
        and $self->_add_log_lines($errbuf);
      $self->_add_log_lines( "failing program is:\n" . $src );
      $outbuf
        and $self->_add_log_lines( "stdout was :\n" . $outbuf );

      unlink $filename;
      unlink $obj_file if $obj_file;

      $options->{action_on_false}
        and ref $options->{action_on_false} eq "CODE"
          and $options->{action_on_false}->();

      return 0;
    }

  my $exe_file;
  ( $outbuf, $errbuf ) = capture
    {
      eval {
        $exe_file = $builder->link_executable(
                                              objects            => $obj_file,
                                              extra_linker_flags => $self->_get_extra_linker_flags()
                                             );
      };

      $exception = $@;
    };
  unlink $filename;
  unlink $obj_file if $obj_file;

  if ( $exception || !$exe_file )
    {
      $self->_add_log_lines( "link stage failed" . ( $exception ? " - " . $exception : "" ) );
      $errbuf
        and $self->_add_log_lines($errbuf);
      $self->_add_log_lines( "failing program is:\n" . $src );
      $outbuf
        and $self->_add_log_lines( "stdout was :\n" . $outbuf );

      $options->{action_on_false}
        and ref $options->{action_on_false} eq "CODE"
          and $options->{action_on_false}->();

      return 0;
    }

  #
  # In case curdir is not in the system path
  #
  if (! File::Spec->file_name_is_absolute( $exe_file )) {
    $exe_file = File::Spec->catfile( File::Spec->curdir, $exe_file );
  }

  my ( $stdout, $stderr, $exit ) =
    capture { system( $exe_file ); };
  if ( $exit != EXIT_SUCCESS )
    {
      $self->_add_log_lines( "execute stage failed" . ( $stderr ? " - " . $stderr : "" ) );
      $self->_add_log_lines( "failing program is:\n" . $src );
      $stdout
        and $self->_add_log_lines( "stdout was :\n" . $stdout );

      $options->{action_on_false}
        and ref $options->{action_on_false} eq "CODE"
          and $options->{action_on_false}->();

      return 0;
    }

  $options->{action_on_true}
    and ref $options->{action_on_true} eq "CODE"
      and $options->{action_on_true}->();

  unlink $exe_file;

  1;
}

sub ac_malloc_0_is_non_null {
  my ($ac) = @_;

  $ac->msg_checking("GNU libc compatible malloc");
  my $src = $ac->lang_build_program("
#if defined STDC_HEADERS || defined HAVE_STDLIB_H
# include <stdlib.h>
#else
char *malloc ();
#endif
",
"return (! malloc(0)) ? 1 : 0;");
  my $rc = ac_execute_if_else($ac, $src);
  $ac->msg_result($rc ? 'yes' : 'no');
  if ($rc) {
    $ac->define_var('MALLOC_0_IS_NONNULL', 1);
  }
}

sub ac_c_inline {
  my ($ac) = @_;

  my $inline = ' ';
  foreach (qw/inline __inline__ __inline/) {
    my $candidate = $_;
    $ac->msg_checking("keyword $candidate");
    my $program = $ac->lang_build_program("
$candidate int testinline() {
  return 1;
}
", 'testinline');
    my $rc = $ac->compile_if_else($program);
    $ac->msg_result($rc ? 'yes' : 'no');
    if ($rc) {
      $inline = $candidate;
      last;
    }
  }
  if ($inline ne 'inline') {
    #
    # This will handle the case where inline is not supported -;
    #
    $ac->define_var('inline', $inline);
  }
}

sub ac_c_restrict {
  my ($ac) = @_;

  my $restrict = ' ';
  foreach (qw/restrict __restrict __restrict__ _Restrict/) {
    my $candidate = $_;
    $ac->msg_checking("keyword $candidate");
    my $program = $ac->lang_build_program("
typedef int * int_ptr;
int foo (int_ptr ${candidate} ip) {
  return ip[0];
}
int testrestrict() {
  int s[1];
  int * ${candidate} t = s;
  t[0] = 0;
  return foo(t);
}
", 'testrestrict');
    my $rc = $ac->compile_if_else($program);
    $ac->msg_result($rc ? 'yes' : 'no');
    if ($rc) {
      $restrict = $candidate;
      last;
    }
  }
  if ($restrict ne 'restrict') {
    #
    # This will handle the case where restrict is not supported -;
    #
    $ac->define_var('restrict', $restrict);
  }
}
