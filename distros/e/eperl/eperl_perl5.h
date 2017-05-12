/*
**        ____           _ 
**    ___|  _ \ ___ _ __| |
**   / _ \ |_) / _ \ '__| |
**  |  __/  __/  __/ |  | |
**   \___|_|   \___|_|  |_|
** 
**  ePerl -- Embedded Perl 5 Language
**
**  ePerl interprets an ASCII file bristled with Perl 5 program statements
**  by evaluating the Perl 5 code while passing through the plain ASCII
**  data. It can operate both as a standard Unix filter for general file
**  generation tasks and as a powerful Webserver scripting language for
**  dynamic HTML page programming. 
**
**  ======================================================================
**
**  Copyright (c) 1996,1997,1998 Ralf S. Engelschall <rse@engelschall.com>
**
**  This program is free software; it may be redistributed and/or modified
**  only under the terms of either the Artistic License or the GNU General
**  Public License, which may be found in the ePerl source distribution.
**  Look at the files ARTISTIC and COPYING or run ``eperl -l'' to receive
**  a built-in copy of both license files.
**
**  This program is distributed in the hope that it will be useful, but
**  WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
**  Artistic License or the GNU General Public License for more details.
**
**  ======================================================================
**
**  eperl_perl5.h -- Perl 5 header file mangling
*/
#ifndef EPERL_PERL5_H
#define EPERL_PERL5_H 1


/*  first include the standard Perl 
    includes designed for embedding   */
#include <EXTERN.h>
#include <perl.h>                 


/*  try to adjust for PerlIO handling  */
#ifdef USE_PERLIO
#undef  fwrite
#define fwrite(buf,size,count,f) PerlIO_write(f,buf,size*count)
#endif


/*  define the I/O type string for verbosity */
#ifdef USE_PERLIO
#ifdef USE_SFIO
#define PERL_IO_LAYER_ID "PerlIO/SfIO"
#else
#define PERL_IO_LAYER_ID "PerlIO/StdIO"
#endif
#else
#define PERL_IO_LAYER_ID "Raw/StdIO"
#endif


#endif /* EPERL_PERL5_H */
/*EOF*/
