package vm;
$VERSION = '1.0.1';

bootstrap xsub;

use xsub q{
  #include <sys/mman.h>
  #include <unistd.h>
};

use xsub peek => q($$), q{
  U8 *pv = (U8 *)SvUV(argv[0]);
  STRLEN pvl = SvUV(argv[1]);
  return newSVpv(pvl ? pv : (U8*)"", pvl);
};
  
use xsub poke => q($$), q{
  U8 *p = (U8 *)SvUV(argv[0]);
  SV *sv = argv[1];
  STRLEN pvl;
  char *pv = SvPV(sv, pvl);
  if (pvl)
    Copy(pv, (U8 *)p, pvl, U8);
  return newSVuv(pvl);
};
  
use xsub malloc => q($), q{
  UV n = SvUV(argv[0]);
  void *p;
  New(0, p, n, U8);
  return newSVuv((UV)p);
};

use xsub calloc => q($), q{
  UV n = SvUV(argv[0]);
  void *p;
  Newz(0, p, n, U8);
  return newSVuv((UV)p);
};
  
use xsub realloc => q($$), q{
  void *p = (void *)SvUV(argv[0]);
  UV n = SvUV(argv[1]);
  if (!n) {
    Safefree(p);
    return newSVuv(0);
  }
  Renew(p, n, U8);
  return newSVuv((UV)p);
};
  
use xsub free => q($), q{
  void *p = (void *)SvUV(argv[0]);
  Safefree(p);
  return &PL_sv_yes;
};
  
use xsub memcpy => q($$$), q{
  void *p = (void *)SvUV(argv[0]);
  void *q = (void *)SvUV(argv[1]);
  UV n = SvUV(argv[2]);
  if (n)
    Copy(p, q, n, U8);
  return newSVuv(n);
};

use xsub memmove => q($$$), q{
  void *p = (void *)SvUV(argv[0]);
  void *q = (void *)SvUV(argv[1]);
  UV n = SvUV(argv[2]);
  if (n)
    Move(p, q, n, U8);
  return newSVuv(n);
};

use xsub memset => q($$$), q{
  void *p = (void *)SvUV(argv[0]);
  UV c = SvUV(argv[1]);
  UV n = SvUV(argv[2]);
  if (n)
    memset(p, c, n);
  return newSVuv(n);
};

use xsub memzero => q($$), q{
  void *p = (void *)SvUV(argv[0]);
  UV n = SvUV(argv[1]);
  if (n)
    Zero(p, n, U8);
  return newSVuv(n);
};

use xsub memchr => q($$$), q{
  UV p = SvUV(argv[0]);
  UV c = SvUV(argv[1]);
  UV n = SvUV(argv[2]);
  UV i = n ? (UV)memchr((void *)p, c, n) : 0;
  return i ? newSVuv(i) : &PL_sv_undef;
};

use xsub memmem => q($$$$), q{
  char *p = (char *)SvUV(argv[0]);
  UV pn = SvUV(argv[1]);
  char *q = (char *)SvUV(argv[0]);
  UV qn = SvUV(argv[1]);
  UV i = (UV)memmem((void *)p, pn, q, qn);
  return i ? newSVuv(i) : &PL_sv_undef;
};

use xsub memcmp => q($$$), q{
  UV p = SvUV(argv[0]);
  UV q = SvUV(argv[1]);
  UV n = SvUV(argv[2]);
  UV i = n ? memcmp((void *)p, (void *)q, n) : 0;
  return newSVuv(i);
};

use xsub mlock => q($$), q{
  UV p   = SvUV(argv[0]);
  UV len = SvUV(argv[1]);
  return mlock((void *)p, len) ? &PL_sv_undef : &PL_sv_yes;
};

use xsub munlock => q($$), q{
  UV p   = SvUV(argv[0]);
  UV len = SvUV(argv[1]);
  return munlock((void *)p, len) ? &PL_sv_undef : &PL_sv_yes;
};

use xsub MCL_CURRENT => q(), q{ return newSVuv(MCL_CURRENT);  };
use xsub MCL_FUTURE  => q(), q{ return newSVuv(MCL_FUTURE);   };

use xsub mlockall => q($), q{
  UV flags = SvUV(argv[0]) & (MCL_CURRENT | MCL_FUTURE);
  return mlockall(flags) ? &PL_sv_undef : &PL_sv_yes;
};

use xsub munlockall => q(), q{
  return munlockall() ? &PL_sv_undef : &PL_sv_yes;
};

use xsub PROT_READ   => q(), q{ return newSVuv(PROT_READ);   };
use xsub PROT_WRITE  => q(), q{ return newSVuv(PROT_WRITE);  };
use xsub PROT_EXEC   => q(), q{ return newSVuv(PROT_EXEC);   };
use xsub PROT_NONE   => q(), q{ return newSVuv(PROT_NONE);   };

use xsub MAP_SHARED  => q(), q{ return newSVuv(MAP_SHARED);  };
use xsub MAP_PRIVATE => q(), q{ return newSVuv(MAP_PRIVATE); };

use xsub MS_ASYNC      => q(), q{ return newSVuv(MS_ASYNC);      };
use xsub MS_INVALIDATE => q(), q{ return newSVuv(MS_INVALIDATE); };
use xsub MS_SYNC       => q(), q{ return newSVuv(MS_SYNC);       };

use xsub _mmap => q($$$$$$), q{
  void *q  = (void *)SvUV(argv[0]);
  UV len   = SvUV(argv[1]);
  UV prot  = SvUV(argv[2]) & (PROT_READ  | PROT_WRITE | PROT_EXEC);
  UV flags = SvUV(argv[3]) & (MAP_SHARED | MAP_PRIVATE);
  UV fd    = SvUV(argv[4]);
  UV off   = SvUV(argv[5]);

  void *p = (void *)mmap(q, len, prot, flags, fd, off);
  return (!p || p == MAP_FAILED) ? &PL_sv_undef : newSVuv((UV)p);
};

use xsub _mremap => q($$$$), q{
  void *q  = (void *)SvUV(argv[0]);
  UV len0  = SvUV(argv[1]);
  UV len1  = SvUV(argv[2]);
  UV flags = SvUV(argv[3]) & (MREMAP_MAYMOVE);

  void *p = (void *)mremap(q, len0, len1, flags);
  return p ? newSVuv((UV)p) : &PL_sv_undef;
};

use xsub _munmap => q($$), q{
  void *p = (void *)SvUV(argv[0]);
  UV len  = SvUV(argv[1]);

  return newSViv(munmap(p, len));
};

use xsub _mprotect => q($$$), q{
  void *p = (void *)SvUV(argv[0]);
  UV len  = SvUV(argv[1]);
  UV prot = SvUV(argv[3]) & (PROT_READ  | PROT_WRITE  | PROT_EXEC);
  return mprotect(p, len, prot) ? &PL_sv_undef : &PL_sv_yes;
};

use xsub _msync => q($$$), q{
  UV p     = SvUV(argv[0]);
  UV len   = SvUV(argv[1]);
  UV flags = SvUV(argv[2]) & (MS_ASYNC | MS_INVALIDATE | MS_SYNC);

  if (msync((void *)p, len, flags))
    return &PL_sv_undef;
  return &PL_sv_yes;
};

use xsub _getpagesize => q(), q{
  return newSVuv(getpagesize());
};

{
  package vm::mmap;

  sub TIESCALAR {
    my ($p, $ptr, $len, $rptr, $rlen, $prot, $flags, $fp) = @_;
    bless  [$ptr, $len, $rptr, $rlen, $prot, $flags, $fp], $p
  }

  sub FETCH {
    my ($x) = @_;
    my ($ptr, $len, undef, undef, $prot) = @$x;
    $prot & &vm::PROT_READ or return undef;

    vm::peek($ptr, $len)
  }

  sub STORE {
    my ($x, $v) = @_;
    my ($ptr, $len, $rptr, $rlen, $prot, $flags, $fp) = @$x;
    $prot & &vm::PROT_WRITE or return undef;
  
    my $vlen = length($v);
    $vlen < $len and $v .= "\0" x ($len - $vlen);
    $vlen > $len and substr($v, $len) = '';

    vm::poke($ptr, $v);

    for (select $fp) {
      $| and vm::_msync($rptr, $rlen, &vm::MS_SYNC);
      select $_;
    }
  }

  sub DESTROY {
    my ($x, $v) = @_;
    my (undef, undef, $rptr, $rlen) = @$x;

    vm::_munmap($rptr, $rlen);
    @$x = ( );
  }
}

sub mmap($;$$$$) {
  my ($fp, $off, $len, $prot, $flags) = @_;
 
  defined $prot or $prot = &PROT_READ | &PROT_WRITE;
  $prot &= (&PROT_READ | &PROT_WRITE | &PROT_EXEC);

  defined $flags or $flags =
    ($prot & &PROT_WRITE) ? &MAP_SHARED : &MAP_PRIVATE;
  $flags &= (&MAP_SHARED | &MAP_PRIVATE);

  my $fd = do {
    if (ref($fp) || ref(\$fp) eq 'GLOB') {
      fileno($fp)
    } elsif ($fp eq '0' or $fp > 0) {
      $fp
    } else {
      my $fn = $fp;
      undef $fp;
      my $mode = ($prot & &PROT_WRITE) ? '+<' : '<';
      open $fp, $mode, $fn or warn("$0: $fn: $!\n"), return undef;
      fileno($fp)
    }
  }; defined $fd or return undef;

  defined $off or $off = 0;
  defined $len or $len = (stat $fp)[7] - $off;
 
  my $pagesize = _getpagesize();
  my $pagemask = $pagesize - 1;
  my $roff = $off & ~$pagemask;
  my $rlen = ($len + $off - $roff);
  $rlen & $pagemask and $rlen = 1 + ($rlen | $pagemask);
  $rlen or $rlen += $pagesize;

  my $rptr = _mmap(0, $rlen, $prot, $flags, $fd, $roff);
  defined $rptr or return undef;
  my $ptr += $rptr + $off - $roff;

  tie my $x, 'vm::mmap', $ptr, $len, $rptr, $rlen, $prot, $flags, $fp;
  \$x
}

sub mmapr  ($$$) { &mmap(@_, &PROT_READ                       ) }
sub mmaprw ($$$) { &mmap(@_, &PROT_READ|&PROT_WRITE           ) }
sub mmaprx ($$$) { &mmap(@_, &PROT_READ|&PROT_EXEC            ) }
sub mmaprwx($$$) { &mmap(@_, &PROT_READ|&PROT_WRITE|&PROT_EXEC) }

sub mprotect($$) {
  my ($x, $prot) = @_;

  ref($x) and ref($x)->isa('SCALAR') or return undef;
  my $mmap = tied($$x) or return undef;
  $mmap->isa('vm::mmap') or return undef;

  my (undef, undef, $rptr, $rlen) = @$mmap;
  _mprotect($rptr, $rlen, $prot)
}

1
