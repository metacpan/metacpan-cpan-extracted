package VMS::CMS;

use strict;
use warnings;
use Carp;

use Exporter qw(import);
use AutoLoader;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use VMS::CMS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'routines' => [ qw(
	show_version
	get_messages
	transaction_mask
    ) ],
    'constants' => [ qw(
	CMS_K_ACCEPT
	CMS_K_ACL_CLASS
	CMS_K_ACL_COMMAND
	CMS_K_ACL_ELEMENT
	CMS_K_ACL_GROUP
	CMS_K_ACL_LIBRARY
	CMS_K_AFTER
	CMS_K_BEFORE
	CMS_K_CANCEL
	CMS_K_MARK
	CMS_K_REJECT
	CMS_K_REVIEW
	CMS_K_SUPERSEDE
	CMS_M_ELEMENT_DIF
	CMS_M_GENERATIONAL_DIF
	CMS_M_IGNORE_CASE
	CMS_M_IGNORE_FIRST_VARIANT
	CMS_M_IGNORE_FORM
	CMS_M_IGNORE_HISTORY
	CMS_M_IGNORE_LEAD
	CMS_M_IGNORE_NOTES
	CMS_M_IGNORE_SPACE
	CMS_M_IGNORE_TRAIL
	CMS_M_VARIANT_DIF
	CMS__ABSTIM
	CMS__ACCEPTANCES
	CMS__ACCEPTED
	CMS__ACCVIORD
	CMS__ACCVIOWT
	CMS__ALL
	CMS__ALPHACHAR
	CMS__ALRDYEXISTS
	CMS__ALRDYINCLS
	CMS__ALRDYINGRP
	CMS__ALRDYMARKED
	CMS__ANNOTATED
	CMS__ANNOTATIONS
	CMS__ANNSIGNAL
	CMS__ARGCONFLICT
	CMS__ARGCOUNTERR
	CMS__AUTOREC
	CMS__AUTORECSUC
	CMS__BADBUG
	CMS__BADCALL
	CMS__BADCRC
	CMS__BADCRETIME
	CMS__BADFORMAT
	CMS__BADLENSTR
	CMS__BADLIB
	CMS__BADLST
	CMS__BADLSTSTR
	CMS__BADORDSTR
	CMS__BADPTR
	CMS__BADREF
	CMS__BADREFHDR
	CMS__BADSTRING
	CMS__BADTYPSTR
	CMS__BADVERSION
	CMS__BADVERSTR
	CMS__BCKPTRSTR
	CMS__BUG
	CMS__CANCELATIONS
	CMS__CANCELED
	CMS__CLASSGENEXP
	CMS__CMPSIGNAL
	CMS__CNTSTR
	CMS__COMPARED
	CMS__CONCLS
	CMS__CONCURRENT
	CMS__CONELE
	CMS__CONFIRM
	CMS__CONFLICTS
	CMS__CONGRP
	CMS__CONHIS
	CMS__CONRES
	CMS__CONTROLC
	CMS__CONVERTED
	CMS__CONVERTLIB
	CMS__CONVNOTNEC
	CMS__COPIED
	CMS__COPIES
	CMS__CREATED
	CMS__CREATES
	CMS__DEFAULTDIR
	CMS__DELETED
	CMS__DELETIONS
	CMS__DIFFCLASS
	CMS__DIFFERENT
	CMS__DUPEDF
	CMS__DUPREF
	CMS__EDFINWRONGDIR
	CMS__EDFMISS
	CMS__ELEEXISTS
	CMS__ELEEXP
	CMS__ELEMULTRES
	CMS__ELEXPIGN
	CMS__ENDOFLIST
	CMS__ENDPTRSTR
	CMS__EOF
	CMS__ERRACCEPTANCES
	CMS__ERRANNOTATIONS
	CMS__ERRCANCELATIONS
	CMS__ERRCLOSE
	CMS__ERRCOPIES
	CMS__ERRCREATES
	CMS__ERRDELETIONS
	CMS__ERRELEHIS
	CMS__ERREMOVALS
	CMS__ERREPLACEMENTS
	CMS__ERRESERVATIONS
	CMS__ERRETRIEVALS
	CMS__ERRFETCHES
	CMS__ERRGENDELETIONS
	CMS__ERRHISLINE
	CMS__ERRINSERTIONS
	CMS__ERRMARKS
	CMS__ERRMODACLS
	CMS__ERRMODIFIES
	CMS__ERRPAREXP
	CMS__ERRREJECTIONS
	CMS__ERRREVIEWS
	CMS__ERRUNRESERVES
	CMS__ERRVER2
	CMS__ERRVERARC
	CMS__ERRVERCLS
	CMS__ERRVERCMD
	CMS__ERRVERCON
	CMS__ERRVEREDFS
	CMS__ERRVERELE
	CMS__ERRVERFRE
	CMS__ERRVERGEN
	CMS__ERRVERGRP
	CMS__ERRVERREFS
	CMS__ERRVERRES
	CMS__ERRVERSTR
	CMS__EXCLUDE
	CMS__EXIT
	CMS__EXTENDEDLIB
	CMS__EXTFOUND
	CMS__FACILITY
	CMS__FETCHED
	CMS__FETCHES
	CMS__FILEXISTS
	CMS__FILINUSE
	CMS__FIXCRC
	CMS__FIXHDR
	CMS__FREBLKCON
	CMS__GENCREATED
	CMS__GENDELETED
	CMS__GENDELETIONS
	CMS__GENEXISTS
	CMS__GENINSERTED
	CMS__GENMULTRES
	CMS__GENNOINSERT
	CMS__GENNOREMOVE
	CMS__GENNOTANC
	CMS__GENNOTFOUND
	CMS__GENNOTRES
	CMS__GENRECSIZE
	CMS__GENREMOVED
	CMS__GENRESREV
	CMS__GENTOODEEP
	CMS__GROUPEXP
	CMS__HASFILES
	CMS__HASMEMBERS
	CMS__HISNOTSTM
	CMS__HISTDEL
	CMS__IDENTCLASS
	CMS__IDENTICAL
	CMS__IDENTNOTRES
	CMS__ILLACT
	CMS__ILLARCREC
	CMS__ILLCHAR
	CMS__ILLCLSNAM
	CMS__ILLCONREC
	CMS__ILLDATREC
	CMS__ILLEGALDEV
	CMS__ILLELENAM
	CMS__ILLELEXP
	CMS__ILLFORMAT
	CMS__ILLGEN
	CMS__ILLGRPNAM
	CMS__ILLHIST
	CMS__ILLNAME
	CMS__ILLNOTE
	CMS__ILLOBJTYP
	CMS__ILLPAR
	CMS__ILLPOSVAL
	CMS__ILLREFDIR
	CMS__ILLRMK
	CMS__ILLSEQ
	CMS__ILLSUBTYP
	CMS__ILLVAR
	CMS__INCLIBVER
	CMS__INCRANGSPEC
	CMS__INSERTED
	CMS__INSERTIONS
	CMS__INUSE
	CMS__INVFETDB
	CMS__INVFIXMRS
	CMS__INVGENLRL
	CMS__INVLENGTH
	CMS__INVLIBDB
	CMS__INVOKERBK
	CMS__INVSTRDES
	CMS__ISMEMBER
	CMS__ISRESERVED
	CMS__LIBALRINLIS
	CMS__LIBINSLIS
	CMS__LIBIS
	CMS__LIBLISMOD
	CMS__LIBLISNOTMOD
	CMS__LIBNOTINLIS
	CMS__LIBREMLIS
	CMS__LIBSET
	CMS__LONGVARFOUND
	CMS__MANCONLIB
	CMS__MARKED
	CMS__MARKS
	CMS__MAXARG
	CMS__MERGECONFLICT
	CMS__MERGECOUNT
	CMS__MERGED
	CMS__MINARG
	CMS__MISBLKSTR
	CMS__MISMATCON
	CMS__MODACL
	CMS__MODACLS
	CMS__MODIFICATIONS
	CMS__MODIFIED
	CMS__MSGBUILD
	CMS__MSGCANCEL
	CMS__MSGCONTINUE
	CMS__MSGPOST
	CMS__MSGUPDATE
	CMS__MSSBLKSTR
	CMS__MULTCALL
	CMS__MULTPAR
	CMS__MUSTBEDIR
	CMS__MUSTBEFIL
	CMS__MUSTBEPOS
	CMS__MUTEXC
	CMS__NEEDNUMBER
	CMS__NEEDPERIOD
	CMS__NETNOTALL
	CMS__NOACCEPT
	CMS__NOACCESS
	CMS__NOACE
	CMS__NOALTDELETE
	CMS__NOANNOTATE
	CMS__NOBACKUP
	CMS__NOBCKPTR
	CMS__NOCANCEL
	CMS__NOCHANGES
	CMS__NOCLOSE
	CMS__NOCLS
	CMS__NOCMD
	CMS__NOCOMMALIST
	CMS__NOCOMPARE
	CMS__NOCONCUR
	CMS__NOCONFIRM
	CMS__NOCONRES
	CMS__NOCONVERT
	CMS__NOCOPY
	CMS__NOCREATE
	CMS__NODEFACL
	CMS__NODELACCESS
	CMS__NODELETE
	CMS__NODELETIONS
	CMS__NODELFUTURE
	CMS__NODELGEN1
	CMS__NOEDFIWDREPAIR
	CMS__NOELE
	CMS__NOELEENT
	CMS__NOERRLOG
	CMS__NOEXTENDED
	CMS__NOEXTENDEDREF
	CMS__NOFETCH
	CMS__NOFILE
	CMS__NOGENBEFORE
	CMS__NOGENDELETED
	CMS__NOGENS
	CMS__NOGRP
	CMS__NOHIS
	CMS__NOHISNOTES
	CMS__NOHISPAR
	CMS__NOINPUT
	CMS__NOINSERT
	CMS__NOMARK
	CMS__NOMATCH
	CMS__NOMODACL
	CMS__NOMODARG
	CMS__NOMODIFY
	CMS__NOMOREPARAM
	CMS__NOOBJ
	CMS__NOOBJTYP
	CMS__NORECOVER
	CMS__NOREF
	CMS__NOREFDIR
	CMS__NOREFELE
	CMS__NOREJECT
	CMS__NOREMARK
	CMS__NOREMOVAL
	CMS__NOREPAIR
	CMS__NOREPBCKPTR
	CMS__NOREPCMD
	CMS__NOREPEDF
	CMS__NOREPGENLRL
	CMS__NOREPGENMRS
	CMS__NOREPLACE
	CMS__NOREPREF
	CMS__NOREPRO
	CMS__NOREPSEQDATA
	CMS__NORES
	CMS__NORESERVATION
	CMS__NORESNOCON
	CMS__NORESRO
	CMS__NORETRIEVE
	CMS__NOREV
	CMS__NOREVIEW
	CMS__NOREVPEND
	CMS__NOREVSPEND
	CMS__NORMAL
	CMS__NOSINCE
	CMS__NOSRCHLST
	CMS__NOSUPERSEDE
	CMS__NOTBYCMS
	CMS__NOTCMSLIB
	CMS__NOTCOMPLETED
	CMS__NOTCRELIB
	CMS__NOTDIRDES
	CMS__NOTESVALREQ
	CMS__NOTFOUND
	CMS__NOTLOGGED
	CMS__NOTNOREF
	CMS__NOTRESBYOU
	CMS__NOTSET
	CMS__NOTTHERE
	CMS__NOTWILD
	CMS__NOUNRESERVE
	CMS__NOVERIFY
	CMS__NOWLDCARD
	CMS__NULLARG
	CMS__NULLSTR
	CMS__NUMGENEXP
	CMS__OLDSYNTAX
	CMS__ONEPERIOD
	CMS__OPENARC
	CMS__OPENIN
	CMS__OPENIN1
	CMS__OPENIN2
	CMS__OPENOUT
	CMS__OVERDRAFT
	CMS__POSVALREQ
	CMS__PROCEEDING
	CMS__QUALCONFLICT
	CMS__READERR
	CMS__READIN
	CMS__READONLY
	CMS__RECGRP
	CMS__RECNOTNEC
	CMS__RECOVERED
	CMS__REFMISMAT
	CMS__REFMISS
	CMS__REFREPAIR
	CMS__REJECTED
	CMS__REJECTIONS
	CMS__REMARK
	CMS__REMOVALS
	CMS__REMOVED
	CMS__REPAIRED
	CMS__REPBADLST
	CMS__REPBADTYP
	CMS__REPBCKPTR
	CMS__REPCMD
	CMS__REPCNTSTR
	CMS__REPDEL
	CMS__REPEDF
	CMS__REPENDPTR
	CMS__REPGENLRL
	CMS__REPGENMRS
	CMS__REPILLDATREC
	CMS__REPLACEMENTS
	CMS__REPMISBLK
	CMS__REPREF
	CMS__RESERVATIONS
	CMS__RESERVED
	CMS__RESERVEDBYYOU
	CMS__RETRIEVALS
	CMS__RETRIEVED
	CMS__REVIEWED
	CMS__REVIEWS
	CMS__REVPENDING
	CMS__SAMELINE
	CMS__SEQFAIL
	CMS__SEQMISMAT
	CMS__SEQUENCED
	CMS__SIZEMISMAT
	CMS__STARTHIS
	CMS__STOPPED
	CMS__SUPERSEDE
	CMS__SYSTIMDIF
	CMS__SYSTIMERR
	CMS__TIMEORDER
	CMS__TOODEEP
	CMS__TOOLONG
	CMS__TOOMANYLIBS
	CMS__TRUNCLST
	CMS__TRYAGNLAT
	CMS__UNDEFLIB
	CMS__UNFOUT
	CMS__UNRECTYPE
	CMS__UNRESERVED
	CMS__UNRESERVES
	CMS__UNSUPFRMT
	CMS__USERECOVER
	CMS__USEREPAIR
	CMS__USERERR
	CMS__USESETLIB
	CMS__VARINRANGE
	CMS__VARLETTER
	CMS__VER2
	CMS__VERARC
	CMS__VERCLS
	CMS__VERCMD
	CMS__VERCON
	CMS__VEREDF
	CMS__VEREDFERR
	CMS__VEREDFS
	CMS__VERELE
	CMS__VERFRE
	CMS__VERGRP
	CMS__VERIFIED
	CMS__VERILLDATREC
	CMS__VERLMTERR
	CMS__VERREF
	CMS__VERREFERR
	CMS__VERREFERRW
	CMS__VERREFS
	CMS__VERRES
	CMS__VERSTR
	CMS__WAITING
	CMS__WILDCONFLICT
	CMS__WILDMATCH
	CMS__WILDNEEDED
	CMS__WILDNOMATCH
	CMS__WILDVER
	CMS__WRITEERR
	CMS__ZEROADD
	CMS__ZLENBLK
) ] );
$EXPORT_TAGS{all} = [ @{@EXPORT_TAGS{qw(routines constants)}} ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ();
our $VERSION = '0.3';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&VMS::CMS::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('VMS::CMS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VMS::CMS - Perl extension for access to the CMS Code Management System

=head1 SYNOPSIS

  use VMS::CMS;

=head1 DESCRIPTION

This module provides access to the Code Management System (CMS) software
using its callable interface.

Most routines will return a true value if successful or C<undef>
instead of the return value documented below if the underlying CMS
routine returns a failure status.  In this case, the CMS status can be
found in $^E.

=head2 EXPORT

None by default.

=head3 Exportable constants

    CMS_K_ACCEPT CMS_K_ACL_CLASS CMS_K_ACL_COMMAND
    CMS_K_ACL_ELEMENT CMS_K_ACL_GROUP CMS_K_ACL_LIBRARY
    CMS_K_AFTER CMS_K_BEFORE CMS_K_CANCEL CMS_K_MARK CMS_K_REJECT
    CMS_K_REVIEW CMS_K_SUPERSEDE CMS_M_ELEMENT_DIF
    CMS_M_GENERATIONAL_DIF CMS_M_IGNORE_CASE
    CMS_M_IGNORE_FIRST_VARIANT CMS_M_IGNORE_FORM
    CMS_M_IGNORE_HISTORY CMS_M_IGNORE_LEAD CMS_M_IGNORE_NOTES
    CMS_M_IGNORE_SPACE CMS_M_IGNORE_TRAIL CMS_M_VARIANT_DIF
    CMS__ABSTIM CMS__ACCEPTANCES CMS__ACCEPTED CMS__ACCVIORD
    CMS__ACCVIOWT CMS__ALL CMS__ALPHACHAR CMS__ALRDYEXISTS
    CMS__ALRDYINCLS CMS__ALRDYINGRP CMS__ALRDYMARKED
    CMS__ANNOTATED CMS__ANNOTATIONS CMS__ANNSIGNAL
    CMS__ARGCONFLICT CMS__ARGCOUNTERR CMS__AUTOREC
    CMS__AUTORECSUC CMS__BADBUG CMS__BADCALL CMS__BADCRC
    CMS__BADCRETIME CMS__BADFORMAT CMS__BADLENSTR CMS__BADLIB
    CMS__BADLST CMS__BADLSTSTR CMS__BADORDSTR CMS__BADPTR
    CMS__BADREF CMS__BADREFHDR CMS__BADSTRING CMS__BADTYPSTR
    CMS__BADVERSION CMS__BADVERSTR CMS__BCKPTRSTR CMS__BUG
    CMS__CANCELATIONS CMS__CANCELED CMS__CLASSGENEXP
    CMS__CMPSIGNAL CMS__CNTSTR CMS__COMPARED CMS__CONCLS
    CMS__CONCURRENT CMS__CONELE CMS__CONFIRM CMS__CONFLICTS
    CMS__CONGRP CMS__CONHIS CMS__CONRES CMS__CONTROLC
    CMS__CONVERTED CMS__CONVERTLIB CMS__CONVNOTNEC CMS__COPIED
    CMS__COPIES CMS__CREATED CMS__CREATES CMS__DEFAULTDIR
    CMS__DELETED CMS__DELETIONS CMS__DIFFCLASS CMS__DIFFERENT
    CMS__DUPEDF CMS__DUPREF CMS__EDFINWRONGDIR CMS__EDFMISS
    CMS__ELEEXISTS CMS__ELEEXP CMS__ELEMULTRES CMS__ELEXPIGN
    CMS__ENDOFLIST CMS__ENDPTRSTR CMS__EOF CMS__ERRACCEPTANCES
    CMS__ERRANNOTATIONS CMS__ERRCANCELATIONS CMS__ERRCLOSE
    CMS__ERRCOPIES CMS__ERRCREATES CMS__ERRDELETIONS
    CMS__ERRELEHIS CMS__ERREMOVALS CMS__ERREPLACEMENTS
    CMS__ERRESERVATIONS CMS__ERRETRIEVALS CMS__ERRFETCHES
    CMS__ERRGENDELETIONS CMS__ERRHISLINE CMS__ERRINSERTIONS
    CMS__ERRMARKS CMS__ERRMODACLS CMS__ERRMODIFIES CMS__ERRPAREXP
    CMS__ERRREJECTIONS CMS__ERRREVIEWS CMS__ERRUNRESERVES
    CMS__ERRVER2 CMS__ERRVERARC CMS__ERRVERCLS CMS__ERRVERCMD
    CMS__ERRVERCON CMS__ERRVEREDFS CMS__ERRVERELE CMS__ERRVERFRE
    CMS__ERRVERGEN CMS__ERRVERGRP CMS__ERRVERREFS CMS__ERRVERRES
    CMS__ERRVERSTR CMS__EXCLUDE CMS__EXIT CMS__EXTENDEDLIB
    CMS__EXTFOUND CMS__FACILITY CMS__FETCHED CMS__FETCHES
    CMS__FILEXISTS CMS__FILINUSE CMS__FIXCRC CMS__FIXHDR
    CMS__FREBLKCON CMS__GENCREATED CMS__GENDELETED
    CMS__GENDELETIONS CMS__GENEXISTS CMS__GENINSERTED
    CMS__GENMULTRES CMS__GENNOINSERT CMS__GENNOREMOVE
    CMS__GENNOTANC CMS__GENNOTFOUND CMS__GENNOTRES
    CMS__GENRECSIZE CMS__GENREMOVED CMS__GENRESREV
    CMS__GENTOODEEP CMS__GROUPEXP CMS__HASFILES CMS__HASMEMBERS
    CMS__HISNOTSTM CMS__HISTDEL CMS__IDENTCLASS CMS__IDENTICAL
    CMS__IDENTNOTRES CMS__ILLACT CMS__ILLARCREC CMS__ILLCHAR
    CMS__ILLCLSNAM CMS__ILLCONREC CMS__ILLDATREC CMS__ILLEGALDEV
    CMS__ILLELENAM CMS__ILLELEXP CMS__ILLFORMAT CMS__ILLGEN
    CMS__ILLGRPNAM CMS__ILLHIST CMS__ILLNAME CMS__ILLNOTE
    CMS__ILLOBJTYP CMS__ILLPAR CMS__ILLPOSVAL CMS__ILLREFDIR
    CMS__ILLRMK CMS__ILLSEQ CMS__ILLSUBTYP CMS__ILLVAR
    CMS__INCLIBVER CMS__INCRANGSPEC CMS__INSERTED CMS__INSERTIONS
    CMS__INUSE CMS__INVFETDB CMS__INVFIXMRS CMS__INVGENLRL
    CMS__INVLENGTH CMS__INVLIBDB CMS__INVOKERBK CMS__INVSTRDES
    CMS__ISMEMBER CMS__ISRESERVED CMS__LIBALRINLIS CMS__LIBINSLIS
    CMS__LIBIS CMS__LIBLISMOD CMS__LIBLISNOTMOD CMS__LIBNOTINLIS
    CMS__LIBREMLIS CMS__LIBSET CMS__LONGVARFOUND CMS__MANCONLIB
    CMS__MARKED CMS__MARKS CMS__MAXARG CMS__MERGECONFLICT
    CMS__MERGECOUNT CMS__MERGED CMS__MINARG CMS__MISBLKSTR
    CMS__MISMATCON CMS__MODACL CMS__MODACLS CMS__MODIFICATIONS
    CMS__MODIFIED CMS__MSGBUILD CMS__MSGCANCEL CMS__MSGCONTINUE
    CMS__MSGPOST CMS__MSGUPDATE CMS__MSSBLKSTR CMS__MULTCALL
    CMS__MULTPAR CMS__MUSTBEDIR CMS__MUSTBEFIL CMS__MUSTBEPOS
    CMS__MUTEXC CMS__NEEDNUMBER CMS__NEEDPERIOD CMS__NETNOTALL
    CMS__NOACCEPT CMS__NOACCESS CMS__NOACE CMS__NOALTDELETE
    CMS__NOANNOTATE CMS__NOBACKUP CMS__NOBCKPTR CMS__NOCANCEL
    CMS__NOCHANGES CMS__NOCLOSE CMS__NOCLS CMS__NOCMD
    CMS__NOCOMMALIST CMS__NOCOMPARE CMS__NOCONCUR CMS__NOCONFIRM
    CMS__NOCONRES CMS__NOCONVERT CMS__NOCOPY CMS__NOCREATE
    CMS__NODEFACL CMS__NODELACCESS CMS__NODELETE CMS__NODELETIONS
    CMS__NODELFUTURE CMS__NODELGEN1 CMS__NOEDFIWDREPAIR
    CMS__NOELE CMS__NOELEENT CMS__NOERRLOG CMS__NOEXTENDED
    CMS__NOEXTENDEDREF CMS__NOFETCH CMS__NOFILE CMS__NOGENBEFORE
    CMS__NOGENDELETED CMS__NOGENS CMS__NOGRP CMS__NOHIS
    CMS__NOHISNOTES CMS__NOHISPAR CMS__NOINPUT CMS__NOINSERT
    CMS__NOMARK CMS__NOMATCH CMS__NOMODACL CMS__NOMODARG
    CMS__NOMODIFY CMS__NOMOREPARAM CMS__NOOBJ CMS__NOOBJTYP
    CMS__NORECOVER CMS__NOREF CMS__NOREFDIR CMS__NOREFELE
    CMS__NOREJECT CMS__NOREMARK CMS__NOREMOVAL CMS__NOREPAIR
    CMS__NOREPBCKPTR CMS__NOREPCMD CMS__NOREPEDF CMS__NOREPGENLRL
    CMS__NOREPGENMRS CMS__NOREPLACE CMS__NOREPREF CMS__NOREPRO
    CMS__NOREPSEQDATA CMS__NORES CMS__NORESERVATION
    CMS__NORESNOCON CMS__NORESRO CMS__NORETRIEVE CMS__NOREV
    CMS__NOREVIEW CMS__NOREVPEND CMS__NOREVSPEND CMS__NORMAL
    CMS__NOSINCE CMS__NOSRCHLST CMS__NOSUPERSEDE CMS__NOTBYCMS
    CMS__NOTCMSLIB CMS__NOTCOMPLETED CMS__NOTCRELIB
    CMS__NOTDIRDES CMS__NOTESVALREQ CMS__NOTFOUND CMS__NOTLOGGED
    CMS__NOTNOREF CMS__NOTRESBYOU CMS__NOTSET CMS__NOTTHERE
    CMS__NOTWILD CMS__NOUNRESERVE CMS__NOVERIFY CMS__NOWLDCARD
    CMS__NULLARG CMS__NULLSTR CMS__NUMGENEXP CMS__OLDSYNTAX
    CMS__ONEPERIOD CMS__OPENARC CMS__OPENIN CMS__OPENIN1
    CMS__OPENIN2 CMS__OPENOUT CMS__OVERDRAFT CMS__POSVALREQ
    CMS__PROCEEDING CMS__QUALCONFLICT CMS__READERR CMS__READIN
    CMS__READONLY CMS__RECGRP CMS__RECNOTNEC CMS__RECOVERED
    CMS__REFMISMAT CMS__REFMISS CMS__REFREPAIR CMS__REJECTED
    CMS__REJECTIONS CMS__REMARK CMS__REMOVALS CMS__REMOVED
    CMS__REPAIRED CMS__REPBADLST CMS__REPBADTYP CMS__REPBCKPTR
    CMS__REPCMD CMS__REPCNTSTR CMS__REPDEL CMS__REPEDF
    CMS__REPENDPTR CMS__REPGENLRL CMS__REPGENMRS
    CMS__REPILLDATREC CMS__REPLACEMENTS CMS__REPMISBLK
    CMS__REPREF CMS__RESERVATIONS CMS__RESERVED
    CMS__RESERVEDBYYOU CMS__RETRIEVALS CMS__RETRIEVED
    CMS__REVIEWED CMS__REVIEWS CMS__REVPENDING CMS__SAMELINE
    CMS__SEQFAIL CMS__SEQMISMAT CMS__SEQUENCED CMS__SIZEMISMAT
    CMS__STARTHIS CMS__STOPPED CMS__SUPERSEDE CMS__SYSTIMDIF
    CMS__SYSTIMERR CMS__TIMEORDER CMS__TOODEEP CMS__TOOLONG
    CMS__TOOMANYLIBS CMS__TRUNCLST CMS__TRYAGNLAT CMS__UNDEFLIB
    CMS__UNFOUT CMS__UNRECTYPE CMS__UNRESERVED CMS__UNRESERVES
    CMS__UNSUPFRMT CMS__USERECOVER CMS__USEREPAIR CMS__USERERR
    CMS__USESETLIB CMS__VARINRANGE CMS__VARLETTER CMS__VER2
    CMS__VERARC CMS__VERCLS CMS__VERCMD CMS__VERCON CMS__VEREDF
    CMS__VEREDFERR CMS__VEREDFS CMS__VERELE CMS__VERFRE
    CMS__VERGRP CMS__VERIFIED CMS__VERILLDATREC CMS__VERLMTERR
    CMS__VERREF CMS__VERREFERR CMS__VERREFERRW CMS__VERREFS
    CMS__VERRES CMS__VERSTR CMS__WAITING CMS__WILDCONFLICT
    CMS__WILDMATCH CMS__WILDNEEDED CMS__WILDNOMATCH CMS__WILDVER
    CMS__WRITEERR CMS__ZEROADD CMS__ZLENBLK

=head2 Functions

=head3 show_version

Returns a reference to a hash containing information about the installed
version of CMS.

    my $hashref = VMS::CMS::show_version;
    print "CMS version $hashref->{BRIEF} is installed\n";

The hash will contain the following attributes.

=over 4

=item BRIEF

A short string containing the version of CMS, e.g., 'V4.2'.

=item FULL

A longer string containing the product name and version, e.g. 'CMS
Version V4.2'.

=item ABSOLUTE

The monotonic version number for the installed CMS release, e.g., 100205.

=back

=head3 get_messages

The callable CMS routines send various status messages to the calling code
using VMS signalling.  Many of these routines allow the caller to provide a
callback routine to intercept and handle these messages.

The C<get_messages> routine returns the messages generated by the last call
to a CMS routine that provides this capability.  The messages are returned
in a reference to an array of strings.

    my $arrayref = VMS::CMS::get_messages;

=head3 get_message_details

Similar to C<get_messages> but returns a list of unformatted messages
with the arguments to those messages.  This is useul for finding out
details of exactly what CMS did, such as file names acted upon,
generations created, etc.

    $l->replace($element,{REMARK=>$text});
    $m = VMS::CMS::get_message_details;
    $newgen = $m->[0]{Args}[0];

Each hashref in the list will contain the following elements:

=over 4

=item MessageId

The status code.

=item Message

The raw message text.

=item Args

An reference to an array containing the arguments to the FAO
directives in the message text.

=back

=head3 transaction_mask

Returns an integer that can be used to specify a set of transactions to
select for C<delete_history> or C<show_history>.

    my $int = VMS::CMS::transaction_mask(qw(CREATE INSERT DELETE));

Recognized transactions include COPY, CREATE, DELETE, FETCH, INSERT, MODIFY,
REMARK, REMOVE, REPLACE, RESERVE, UNRESERVE, VERIFY, SET ACL, ACCEPT,
CANCEL, MARK, REJECT and REVIEW.

=head3 new

Returns a blessed reference to a library descriptor block.  This
object can be used to invoke other routines.

    my $ldb = VMS::CMS::new;

=head2 Library Access Routines

These routines can be used to create, access, or modify CMS
libraries.

=head3 create_library

Creates a new CMS library in the directory specified.  Returns a CMS
status code if the operation is successful.

    my $sts = $ldb->create_library($path,{option=>value,...});
    die "CMS create library failed with status $^E\n"
        unless ($sts);

C<$path> specifies an empty directory CMS should use to build the
new library.  C<$remark> is a string to be logged in the history.
The following options are recognized.

=over 4

=item REFERENCE_COPY

Specifies a directory to contain reference copies of elements in
the library.

=item CREATE

Boolean value that tells CMS to create missing directories.  By
default, the directories must already exist.

=item KEEP

By default, CMS deletes files after storing them in the library.
To change the default for all files stored in this library, set
C<KEEP> to true.

=item REVISION_TIME

Boolean value telling CMS to use the file's last revision time
(0) or its storage time (1).

=item CONCURRENT

Boolean value that indicates whether concurrent reservations
should be allowed.  The default is true.

=item EXTENDED_NAMES

On systems running versions of VMS that support extended
filenames, set this option to allow CMS to use this support.

=item POSITION

Used with the PATH option to specify where in the current search
list of CMS libraries the new library should be placed.  Valid
values are C<SUPERSEDE> (default), C<BEFORE> or C<AFTER>.  If
C<BEFORE> or C<AFTER> is specified but the C<PATH> option is not,
the library will be inserted at the beginning or end,
respectively, of the current search list.

=item PATH

Specifies an CMS library path already in the CMS library search
list.

=item REMARK

A string to save as the creation remark for the new library.

=back

=head3 set_library

    $ldb->set_library($path,{option=>value});

=over 4

=item POSITION

Used with the PATH option to specify where in the current search
list of CMS libraries the new library should be placed.  Valid
values are C<SUPERSEDE> (default), C<BEFORE> or C<AFTER>.  If
C<BEFORE> or C<AFTER> is specified but the C<PATH> option is not,
the library will be inserted at the beginning or end,
respectively, of the current search list.

=item PATH

Specifies an CMS library path already in the CMS library search
list.

=item VERIFY

A boolean requesting that CMS verify the library before proceding.

=back

=head3 set_nolibrary

Removes a library from or clears the library search list.

    $sts = $ldb->set_nolibrary([$path]);

=head3 modify_library

Changes attributes of a library.

    $sts = $ldb->modify_library({option=>value});

Available options:

=over 4

=item REMARK

Specifies a remark to store in the history with this command.

=item REFERENCE_COPY

Specifies a directory to contain reference copies of elements in
the library.

=item KEEP

By default, CMS deletes files after storing them in the library.
To change the default for all files stored in this library, set
C<KEEP> to true.

=item REVISION_TIME

Boolean value telling CMS to use the file's last revision time
(0) or its storage time (1).

=item CONCURRENT

Boolean value that indicates whether concurrent reservations
should be allowed.  The default is true.

=item EXTENDED_NAMES

On systems running versions of VMS that support extended
filenames, set this option to allow CMS to use this support.

=back

=head3 remark

Adds a remark to the library history.

    sts = $ldb->remark($remark,{option=>value});

Options:

=over 4

=item UNUSUAL

Boolean indicating that this is an unusual remark.

=back

=head3 show_history

Returns history information.

    my $arrayref = $ldb->show_history({option=>value});
    
Options:

=over 4

=item OBJECT_NAME

=item USER

=item BEFORE

=item SINCE

=item TRANSACTION_MASK

=back

Returns a reference to an array of hashes.  Each hash contains the following
information:

=over 4

=item COMMAND

=item OBJECT

=item USER

=item REMARK

=item TRANSACTION_TIME

=item UNUSUAL

=back

=head3 show_library

Returns a reference to a hash that contains information about a CMS
library.

    my $hashref = $ldb->show_library({option=>value});

Options:

=over 4

=item VERIFY

A boolean requesting that CMS verify the library before proceding.

=back

Information returned:

=over 4

=item REFERENCE_COPY

Indicates the directory used for reference copies if enabled.

=item ELEMENTS

Contains the number of elements stored in the library.

=item GROUPS

Contains the number of groups defined in the library.

=item CLASSES

Contains the number of classes defined in the library.

=item RESERVATIONS

Contains the number of elements currently reserved from the library.

=item CONCURRENT

Indicates whether concurrent reservations are allowed from the library.

=item REVIEWS_PENDING

Indicates the number of generations requiring review.

=back

=head3 show_reservations

Returns a reference to a list of elements currently reserved from the
library.

    my $res = $ldb->show_reservations({option=>value});

Options:

=over 4

=item ELEMENT

Limits the list to elements matching the provided element expression.

=item GENERATION

Limits the list to generations matching the specified generation
expression.

=item USER

Limits the list to elements reserved by the specified user.

=item IDENTIFICATION

Limits the list to reservations having the specified identification.

=back

The returned list will contain references to hashes containing the
following attributes.

=over 4

=item ELEMENT

The element name.

=item GENERATION

The generation of the element that is reserved.

=item TIME

The time that the element was reserved.

=item USER

The user that reserved the element.

=item REMARK

The remark entered when the element was reserved.

=item CONCURRENT

Indicates concurrent reservation status.  C<-1> indicates a concurrent
replacement, C<0> indicates a current reservation, C<1> indicates a
concurrent reservation.

=item MERGE_GENERATION

Indicates a generation that was merged with the reserved generation.

=item NONOTES

True if notes were supressed.

=item NOHISTORY

True if history was supressed.

=item ACCESS

Indicates whether concurrent accesses are allowed. C<0> indicates that
concurrent reservations are allowed. C<1> indicates that they are not
allowed.  C<2> indicates that the current reservation does not allow
concurrent reservations.

=back

=head2 Element Access Routines

These routines provide access to files stored in a CMS library.

=head3 create_element

    $sts = $ldb->create_element($element, {option=>value});

Options:

=over 4

=item HISTORY

=item NOTES

=item INPUT_FILE

=item POSITION

=item KEEP

=item RESERVE

=item CONCURRENT

=item REFERENCE_COPY

=item REVIEW

=item REMARK

=back

=head3 delete_element

=head3 differences

    $sts = $ldb->differences({option=>value});

Options:

=over 4

=item FILENAME1

=item GENERATION1

=item FILENAME2

=item GENERATION2

=item OUTPUT_FILE

=item OUTPUT_ROUTINE

A reference to a subroutine to call for each line of output.  The
subroutine is passed one or two arguments.  The first is a hash
containing the output record and some flags.  The second argument is
the value of option USER_ARG, if specified.

The hash passed to the subroutine contains the following values.

=over 4

=item OUTPUT_RECORD

=item FIRST_CALL

=item EOF

=back

=item USER_ARG

An argument to pass to the subroutine pass to OUTPUT_ROUTINE.

=item NOOUTPUT

=item PARALLEL

=item FULL

=item WIDTH

=item PAGE_BREAK

=item APPEND

=item FORMAT

=item IGNORE

=item SKIP_LINES

=item BEGIN_SENTINAL

=item END_SENTINAL

=item REMARK

=back

=head3 fetch

Retrieves and optionally reserves an element from the library.

    $sts = $ldb->fetch($element,{option=>value})

Options:

=over 4

=item REMARK

=item GENERATION

=item MERGE_GENERATION

=item OUTPUT_FILE

=item HISTORY

=item NOTES

=item RESERVE

=item NOHISTORY

=item CONCURRENT

=item NOOUTPUT

=item POSITION

=back

=head3 modify_element

=head3 remove_element

=head3 replace

    $sts = $ldb->replace($element, {option=>value});

Options:

=over 4

=item VARIANT

=item INPUT_FILE

=item GENERATION

=item RESERVE

=item KEEP

=item IF_CHANGED

=item IDENTIFICATION

=item REMARK

=back

=head3 show_element

Returns a reference to an array of hash references.  Each hash contains
information about one matching element.

    $array_ref = $ldb->show_element({option=>value})

Options:

=over 4

=item ELEMENT

=item MEMBERS

=back

The following information is returned for each element.

=over 4

=item ELEMENT

=item REMARK

=item HISTORY

=item NOTES

=item POSITION

=item CONCURRENT

=item REFERENCE_COPY

=item GROUP_LIST

=item REVIEW

=back

=head3 unreserve

=head2 Group Access Routines

These routines provide access to element groups defined in a CMS
library.

=head3 create_group

    $sts = $ldb->create_group($group, {option=>value});

=head3 delete_group

    $sts = $ldb->delete_group($group, {option=>value});

=head3 insert_element

    $sts = $ldb->insert_element($element, $group, {option=>value});

Options:

=over 4

=item REMARK

=item IF_ABSENT

=item REMARK

=back

=head3 insert_group

    $sts = $ldb->insert_group($subgroup, $group, {option=>value});

Options:

=over 4

=item REMARK

=item IF_ABSENT

=back

=head3 modify_group

=head3 remove_element

=head3 remove_group

=head3 show_group

    $arrayref = $ldb->show_group({option=>value});

Options:

=over 4

=item GROUP

=item CONTENTS

=back

Returns a reference to an array of hashes containing:

=over 4

=item GROUP

=item REMARK

=item READ_ONLY

=item LEVEL

=item CONTENTS

=back

=head2 Generation Access Routines

These routines provide access to generations of elements defined
in a CMS library.

=head3 delete_generation

=head3 modify_generation

=head3 review_generation

=head3 show_generation

    $arrayref = $ldb->show_generation({option=>value});

Options:

=over 4

=item ELEMENT

=item GENERATION

=item FROM_GENERATION

=item ANCESTORS

=item DESCENDANTS

=item MEMBERS

=item BEFORE

=item SINCE

=back

Returns a reference to an array of hashes containing:

=over 4

=item ELEMENT

=item GENERATION

=item USER

=item REMARK

=item CLASS_LIST

=item FORMAT

=item ATTRIBUTES

=item TRANSACTION_TIME

=item CREATION_TIME

=item REVISION_TIME

=item REVISION

=item RESERVATIONS

=item RECORD_SIZE

=item REVIEW_STATUS

=back

=head3 show_reviews_pending

=head2 Class Access Routines

These routines provide access to classes defined in a CMS
library.

=head3 create_class

    $sts = $ldb->create_class($class, {option=>value});

=head3 delete_class

    $sts = $ldb->delete_class($class, {option=>value});

=head3 insert_generation

    $sts = $ldb->insert_generation($element, $class, {option=>value});

Options:

=over 4

=item REMARK

=item GENERATION

=item ALWAYS

=item SUPERSEDE

=item IF_ABSENT

=back


=head3 modify_class

=head3 remove_generation

=head3 show_class

    my $arrayref = $ldb->show_class({option=>value});

Options:

=over 4

=item CLASS

=back

Returns a reference to an array of hashes containing:

=over 4

=item CLASS

=item REMARK

=item READ_ONLY

=back

=head2 SEE ALSO

See the VMS/CMS documentation including the Callable Routines
Reference Manual.

=head2 AUTHOR

Thomas Pfau, E<lt>tfpfau@gmail.com<gt>

=head2 COPYRIGHT AND LICENSE

Copyright (C) 2008,2010,2011,2012 by Thomas Pfau.

This module is free software.  You can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This module is distributed in the hope that it will be useful but it
is provided "as is"and without any express or implied warranties.

=cut
