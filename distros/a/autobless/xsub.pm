package xsub;
$VERSION = 1.0;

my %XSUB;

sub import {
  my $p = shift;

  my ($package, $file, $line) = caller;

  my $source = pop;
  my $name = shift;
  my $prototype = @_ && $_[0] !~ /^:/ ? shift : undef;
  my $attributes = [@_];
  s/^:// for @$attributes;

  my $xs = bless {
    name       => $name,
    source     => $source,
    package    => $package,
    file       => $file,
    line       => $line,
    prototype  => $prototype,
    attributes => $attributes,
  }, $p;

  if ($name) {
    my $pr = defined($prototype) ? "($prototype)" : "";
    eval "package $package; sub $name $pr";
    $@ and die $@;
  }

  local *XSUB  = \@{$XSUB{$file}};
  push @XSUB, $xs;
}

sub _reindent($$) {
  my $v = ' ' x shift;
  my @l = split /\n/, $_[0];

  my $i = 0;
  $i++ while $i < @l && $l[$i] eq '';
  $i < @l && $l[$i] =~ m/^(\s+)/ or return $_[0];
  my $k = $1;

  s/^$k/$v/ for @l;
  join "\n", @l, '';
}

sub _unindent($) {
  _reindent(0, $_[0])
}

sub _compile {
  my ($c, $so) = @_;
  my $cmd =
    "$C{cc} $C{ccflags} -O3 $C{cccdlflags} " .
    "-I$C{archlib}/CORE $C{lddlflags} -o $so $c";
  my $x = system $cmd;
  $x and die;
  -e $so or die;
}

sub bootstrap {
  my $p = shift;
  my ($q, $qpm) = (caller)[0, 1];
  my ($qc, $qso);

  local *XSUB  = \@{$XSUB{$qpm}};
  defined @XSUB or return;

  -e $qpm or die;
  $qpm =~ m/\.pm$/ or die;
  ($qc =  $qpm) =~ s/\.pm$/\.c/ or die;
  ($qso = $qpm) =~ s/\.pm$/\.so/ or die;

  if (!-e $qso || (-M $qpm < -M $qso) || (-M __FILE__ < -M $qso)) {
    local *XS;
    open XS, '>', $qc or die;
    my $pre = select(XS);

    print _unindent qq{
      #include "EXTERN.h"
      #include "perl.h"
      #include "XSUB.h"

      #define __PACKAGE__	"$q"
      #define undef		(&PL_sv_undef)
      #define true		(&PL_sv_yes)
      #define yes		true
      #define false		(&PL_sv_no)
      #define no		false
      #define unless(x)		if (!(x))
      #define wantarray		(GIMME == G_ARRAY)
      #define wantvoid		(GIMME == G_VOID)
      #define wantscalar	(GIMME == G_SCALAR)
    };

    print _unindent q{
      #define _C_RETURN_AV(sv) { \
        AV *av = (AV *)(sv); I32 n = 1 + AvFILL(av); \
        EXTEND(SP, n); Copy(AvARRAY(av), SP + 1, n, SV *); SP += n; \
        av_undef(av); \
        PUTBACK; return; \
      }

      #define _C_RETURN_SV(sv) { \
        PUSHs(sv_2mortal(sv)); \
        PUTBACK; return; \
      }

      #define _C_DECLARE(name) XS(name) { \
        dXSARGS; SP -= items; { \
          SV *(_C_ ## name)(U32, SV **); \
          SV *sv = (_C_ ## name)(items, &ST(0)); \
          if (!sv) { PUTBACK; return; } \
          if (SvTYPE(sv) == SVt_PVAV) \
            _C_RETURN_AV(sv) \
          else \
            _C_RETURN_SV(sv) \
        } \
      } SV *_C_ ## name (UV argc, SV **argv)
    };

    for (@XSUB) {
      unless ($$_{name}) {
        print "#line $$_{line} \"$$_{file}\"\n";
        print _unindent($$_{source}), "\n";
        next;
      }

      (my $name = "XS_$$_{package}_$$_{name}") =~ s/::/__/g;

      print "\n";
      print "_C_DECLARE($name) {\n";
      print "#line $$_{line} \"$$_{file}\"\n";
      print _reindent(2, $$_{source});
      print "}\n";
      # print "#define $$_{name} _C_$name\n";
    }

    (my $boot_q = "boot_$q") =~ s/::/__/g;
    print "\nXS($boot_q) {\n";
    for (@XSUB) {
      $$_{name} or next;
      my $realname = "$$_{package}::$$_{name}";
      (my $name = "XS_$$_{package}_$$_{name}") =~ s/::/__/g;

      my $pr = $$_{prototype};
      defined $pr and $pr =~ s/\\/\\\\/g;

      print "  newXS";
      print "proto" if defined $pr;
      print "(\"$realname\", $name, __FILE__";
      print ", \"$pr\"" if defined $pr;
      print ");\n";
    }
    print "}\n";

    select($pre);
    close XS;

    require Config;
    local *C = \%Config::Config;

    unlink($qso);
    _compile($qc, $qso);
    unlink($qc);
  }

  require DynaLoader;
  $qso =~ m<^/> or $qso = "./$qso";
  my $libref = DynaLoader::dl_load_file($qso, 0) or die;
  (my $boot_q = "boot_$q") =~ s/::/__/g;
  my $symref = DynaLoader::dl_find_symbol($libref, $boot_q) or die;
  DynaLoader::dl_install_xsub($boot_q, $symref, $qso) or die;

  &{$boot_q};

  require attributes;
  for (@XSUB) {
    $$_{name} && @{$$_{attributes}} or next;
    for my $a (@{$$_{attributes}}) {
      import attributes $$_{package}, \&{"$$_{package}::$$_{name}"}, $a;
    }
  }
}

1
