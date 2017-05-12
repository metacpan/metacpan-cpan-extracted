/* -*- c -*- */
/*    gzip.xs
 *
 *    Copyright (C) 2001, Nicholas Clark
 *
 *    You may distribute this work under the terms of either the GNU General
 *    Public License or the Artistic License, as specified in perl's README
 *    file.
 *
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perliol.h"

/* Constant associated with zip files:  */
#define ZIP_ENDCENTRALDIRSIZE	22L
#define ZIP_ENDCENTRALDIRNEEDED	16
#define ZIP_CENTRALDIRENTRYSIZE	46
#define ZIP_LOCALFILEHEADERSIZE	30
#define ZIP_MAXCOMMENTLEN	65535

#define UNZIP_VERSION		20
#define ZIP_DIRATTR		0x10
#define ZIP_DEFLATED		8
#define ZIP_STORED		0

/* This associated with this implemementation:  */
struct cache {
  off_t		size;
  off_t		progress;
  time_t	mtime;
};

#define CLASSNAME		"ex::lib::zip"
#define LIBZIB_OBJ HV


#define UNZIP_SEARCH_BUFFERSIZE		512 + 3

/* returns the offset of the central directory, or 0 if it's not a valid
   zip file (for any reason).  */
static off_t
openzipfile (PerlIO *zipfile, off_t length)
{
  off_t searchfrom;
  off_t searchlen;
  off_t searchoffset;
  off_t toread;
  off_t tosearch;
  unsigned char buffer[UNZIP_SEARCH_BUFFERSIZE];
  unsigned char *where;
  dTHX;

  if (length < ZIP_ENDCENTRALDIRSIZE) {
#ifdef DEBUG_LIBZIP
    PerlIO_debug("length %ld < ZIP_ENDCENTRALDIRSIZE (%ld) so can't be zip\n",
		 (long)length, (long)ZIP_ENDCENTRALDIRSIZE);
#endif
    return 0;
  }
  if (length < (ZIP_MAXCOMMENTLEN + ZIP_ENDCENTRALDIRSIZE)) {
    searchfrom = 0;
    searchlen = length - ZIP_ENDCENTRALDIRSIZE;
  } else {
    searchlen = ZIP_MAXCOMMENTLEN;
    searchfrom = length - searchlen - ZIP_ENDCENTRALDIRSIZE;
  }

  /* First read just enough to work if there is zero comment.  */
  toread = 4 + ZIP_ENDCENTRALDIRNEEDED;
  tosearch = 1;
  searchoffset = searchfrom + searchlen;

#ifdef DEBUG_LIBZIP
  PerlIO_debug("Search %ld to %ld, starting search from %ld, length %ld\n",
	       (long)searchfrom, (long)(searchfrom + searchlen),
	       (long)searchoffset, (long)toread);
#endif


  while (1) {
    unsigned char *buffer_end = buffer + toread;

    where = buffer + tosearch;

    if (PerlIO_seek (zipfile, searchoffset, SEEK_SET) == -1
	|| (PerlIO_read (zipfile, buffer, toread) != toread)) {
#ifdef DEBUG_LIBZIP
      PerlIO_debug("Read or seek failed\n");
#endif
      return 0;
    }

    while (where-- > buffer) {
#if 0
#ifdef DEBUG_LIBZIP
      if (isprint(where[0]))
	PerlIO_debug(" %c\n", where[0]);
      else
	PerlIO_debug("%02X\n", where[0]);
#endif
#endif
      if (where[0] == 0x50 && where[1] == 0x4b && where[2] == 0x05
	  && where[3] == 0x06) {
	/* Found the signature.  */
	int entries;
	long size;
	long offset;

	/* Record where in the file we found the signature  */
	searchoffset += (where - buffer);

#ifdef DEBUG_LIBZIP
  PerlIO_debug("Hit at %ld\n", (long)searchoffset);
#endif

	/* Do we have enough of the end central directory to be useful?
	 */
	where +=4;

	if ((where + ZIP_ENDCENTRALDIRNEEDED) > (buffer_end)) {
	  int got = buffer_end - where;
	  int need = ZIP_ENDCENTRALDIRNEEDED - got;
#ifdef DEBUG_LIBZIP
	  PerlIO_debug("Got %d, reading %d\n", got, need);
#endif
	  memmove (buffer, where, got);
	  /* File pointer will be at end of block we just buffered.  */
	  if (PerlIO_read (zipfile, buffer + got, need) != need)
	    return 0;

	  where = buffer;
	}

	/* Got it. */
#ifdef DEBUG_LIBZIP
	PerlIO_debug("Hit!\n");
#endif

	if (where[0] || where[1] || where[2] || where[3]) {
#ifdef DEBUG_LIBZIP
	  PerlIO_debug("This is not disc zero, or central dir is not on disc zero.\n");
#endif
	  return 0;
	}

	entries = where[6] | (where[7] << 8);
	size = where[8] | (where[9] << 8) | (where[10] << 16)
	  | (where[11] << 24);
	offset = where[12] | (where[13] << 8) | (where[14] << 16)
	  | (where[15] << 24);

#ifdef DEBUG_LIBZIP
	PerlIO_debug("%ld entries, offset %ld, size %ld, ends at %ld\n",
		     entries, (long)offset, (long)size, (long)(offset + size));
#endif

	if ((offset == 0) || (size + offset != searchoffset)) {
	  /* Central directory is at start of zip (hence no files in it) or
	     calculated position of end of central directory does not match
	     actual location.  */
#ifdef DEBUG_LIBZIP
	  PerlIO_debug("Bah. dir at zero, or not where expected.\n");
#endif
	    return 0;
	}

#ifdef DEBUG_LIBZIP
	  PerlIO_debug("Success\n");
#endif
	return offset;	/* Start with first file of central dir.  */
      }
    }

    /* Run out of buffered data.  */

    toread = UNZIP_SEARCH_BUFFERSIZE-3;
    searchoffset -= toread;

#ifdef DEBUG_LIBZIP
    PerlIO_debug("reading another %ld bytes from offset %ld\n", (long)toread,
		 (long)searchoffset);
#endif
    if (searchoffset < searchfrom) {
      /* No longer a whole buffer left.  */
      toread -= (searchfrom - searchoffset);
      if (toread == 0) {
	/* Reading nothing means we are out of data.  */
	return 0;
      }

      searchoffset = searchfrom;
#ifdef DEBUG_LIBZIP
      PerlIO_debug("------- another %ld bytes from offset %ld\n", (long)toread,
		   (long)searchoffset);
#endif
    }
    tosearch = toread;

    /* Copy over the first 3 bytes.  */
    buffer[UNZIP_SEARCH_BUFFERSIZE-1] = buffer[2];
    buffer[UNZIP_SEARCH_BUFFERSIZE-2] = buffer[1];
    buffer[UNZIP_SEARCH_BUFFERSIZE-3] = buffer[0];
    /* Loop.  */
  }
}

/* 0 is success. non-0 is failure.  This subrouting checks the zip file
   central directory (either our cache, or resume the linear search, for
   the file named in the SV.  */
static int
findfileinzipdir (HV *self, struct cache *aswas, PerlIO *fp, SV *file)
{
  dTHX;
  SV **entry;
  STRLEN wantednamelen;
  const char *wantedname = SvPV(file, wantednamelen);

  /* Hash lookup filename, before resuming linear search.  */
  entry = hv_fetch (self, wantedname, wantednamelen, 0);
  if (entry) {
    off_t offset = SvIV (*entry);
#ifdef DEBUG_LIBZIP
    PerlIO_debug("Hash success for %.*s at offset %ld\n", (int)wantednamelen,
		 wantedname, (long)offset);
#endif

    /* Return 0 if PerlIO_seek succeeds.  */
    return PerlIO_seek (fp, offset, SEEK_SET) == -1;
  }
#ifdef DEBUG_LIBZIP
  PerlIO_debug("Hash fail for %.*s\n", (int)wantednamelen, wantedname);
#endif

  /* File lookup.  */
  if (aswas->progress == 0 || PerlIO_seek (fp, aswas->progress, SEEK_SET) == -1)
    return -1;

  while (1) {
    unsigned char buffer[ZIP_CENTRALDIRENTRYSIZE];
    off_t offset;
    int filenamelen;
    int skiplen;


    if (PerlIO_read (fp, buffer, sizeof (buffer)) != sizeof (buffer)
	|| buffer[0] != 0x50 || buffer[1] != 0x4b || buffer[2] != 0x01
	|| buffer[3] != 0x02 || buffer[34] || buffer[35]) {
      /* Failed to read buffer, or incorrect signature (either end of central
	 directory signature or garbage), or disk number start is not zero.
	 Mark central directory as all read.  */
#ifdef DEBUG_LIBZIP
      if (buffer[0] == 0x50 && buffer[1] == 0x4b && buffer[2] == 0x05
	  && buffer[3] == 0x06)
	PerlIO_debug("End of the central directory\n");
      else
	PerlIO_debug("Failed to read buffer, or buffer bad\n");
#endif
      aswas->progress;
      return -1;
    }

    /* signature (PK\01\02)		4 bytes	 0- 3 */
    /* version made by			2 bytes	 4, 5 */
    /* version needed to extract	2 bytes	 6, 7 */
    /* general purpose bit flag		2 bytes	 8, 9 */
    /* compression method		2 bytes	10,11 */
    /* last mod file time		2 bytes	12,13 */
    /* last mod file date		2 bytes	14,15 */
    /* crc-32				4 bytes	16-19 */
    /* compressed size			4 bytes	20-23 */
    /* uncompressed size		4 bytes	24-27 */
    /* filename length			2 bytes	28,29 */
    /* extra field length		2 bytes	30,31 */
    /* file comment length		2 bytes	32,33 */
    /* disk number start		2 bytes	34,35 */
    /* internal file attributes		2 bytes	36,37 */
    /* external file attributes		4 bytes	38-41 */
    /* relative offset of local header	4 bytes	42-45 */
    /* filename			(variable size) */
    /* extra field		(variable size) */
    /* file comment		(variable size) */

    filenamelen = buffer[28] | (buffer[29] << 8);
    skiplen = (buffer[30] | (buffer[31] << 8))
      + (buffer[32] | (buffer[33] << 8));	/* Extra field plus comment.  */

    /* Is it a directory?  */
    if (buffer[38] & ZIP_DIRATTR) {
#ifdef DEBUG_LIBZIP
      PerlIO_debug("Skipping directory\n");
#endif
      if (PerlIO_seek (fp, filenamelen + skiplen, SEEK_CUR) == -1) {
#ifdef DEBUG_LIBZIP
	PerlIO_debug("Skipping directory failed\n");
#endif
	aswas->progress = 0;
	return -1;
      }
    } else {
      /* It's (probably) a file.  */
      char *filename;

      New (103,filename,filenamelen,char);

      if (!filename || PerlIO_read (fp, filename, filenamelen) != filenamelen) {
	Safefree (filename);
#ifdef DEBUG_LIBZIP
	PerlIO_debug("All going pear shaped :-(\n");
#endif
	/* Everything is going to go pear shaped at this point.  */
	aswas->progress = 0;
	return -1;
      }

#ifdef DEBUG_LIBZIP
      if (skiplen > sizeof (buffer))
	PerlIO_debug("Skipping %ld byte(s) from %ld to ", skiplen,
		     (long) PerlIO_tell (fp));
#endif

      if (skiplen && ((skiplen > sizeof (buffer))
	/* Seek if we can't fread() the extra field into our (small) buffer.  */
		      ? (PerlIO_seek (fp, skiplen, SEEK_CUR) == -1)
	/* assume that for 42 bytes buffered fread() is faster than fseek()  */
		      : (PerlIO_read (fp, buffer, skiplen) != skiplen)))
	{
#ifdef DEBUG_LIBZIP
	  PerlIO_debug("Skip failed :-(\n");
#endif
	  Safefree (filename);
	  aswas->progress = 0;
	  return -1;
	}

#ifdef DEBUG_LIBZIP
      if (skiplen)
	PerlIO_debug("%ld\n", PerlIO_tell (fp));
#endif

      offset = buffer[42] | (buffer[43] << 8) | (buffer[44] << 16)
	| (buffer[45] << 24);

#ifdef DEBUG_LIBZIP
      PerlIO_debug("file %.*s at offset %ld\n", (int)filenamelen,
		   filename, (long)offset);
#endif

      /* Hash it */
      entry = hv_fetch (self, filename, filenamelen, 1);
      if (entry)
	sv_setiv (*entry, offset);
#ifdef DEBUG_LIBZIP
      else
	PerlIO_debug("problem making hash entry\n");
#endif

      if ((filenamelen == wantednamelen)
	  && memEQ (filename, wantedname, wantednamelen)) {
	/* Found the file.  */
	Safefree (filename);
	aswas->progress = PerlIO_tell(fp);
	if (aswas->progress == -1)
	  aswas->progress = 0;
#ifdef DEBUG_LIBZIP
	PerlIO_debug("Got it, returning seek() return, progress now %ld\n",
		     aswas->progress);
#endif
	if (PerlIO_seek (fp, offset, SEEK_SET) != -1)
	  return 0;	/* Return success - fp now points to local entry.  */
	
	return -1;
      }
      Safefree (filename);
    }
  } /* loop forever */
}

/* Return true only if successful location of file in zip and successful
   installation of layer discipline to deal with it (inflating or counting).  */
static int
findfile (HV *self, struct cache *aswas, PerlIO *fp, SV *file)
{
  dTHX;
  /* Make four byte values word aligned. Hopefully optimisers on little
     endian compilers that can't read unaligned can spot this.  */
  unsigned char buffer[ZIP_LOCALFILEHEADERSIZE + 2];
  int filenamelen;
  int skiplen;
  char *filename;
  STRLEN wantednamelen; 
  const char *wantedfilename = SvPV(file, wantednamelen);
  int status;

  if (findfileinzipdir (self, aswas, fp, file)) {
#ifdef DEBUG_LIBZIP
    PerlIO_debug("findfileinzipdir failed, returning.\n");
#endif
    return -1;
  }
#ifdef DEBUG_LIBZIP
  PerlIO_debug("You are at %ld\n", (long) PerlIO_tell (fp));
#endif

  if ((PerlIO_read (fp, buffer + 2, sizeof (buffer) - 2)
       != sizeof (buffer) - 2)
      || buffer[2] != 0x50 || buffer[3] != 0x4b || buffer[4] != 0x03
      || buffer[5] != 0x04 || buffer[6] > UNZIP_VERSION || buffer[11]
      || !(buffer[10] == ZIP_DEFLATED
	   || (buffer[10] == ZIP_STORED && ((buffer[8] & 8) == 0)))) {
#ifdef DEBUG_LIBZIP
  PerlIO_debug("Local header failed: %x%x%x%x %d\n", buffer[2], buffer[3],
	       buffer[4], buffer[5], buffer[6]);
#endif
    /* Failed to read buffer, or incorrect signature, or too recent for us,
       or not (compression method is deflation or (compression method is
       stored and sizes follow it)).  */
    return -1;
  }

  /* as it's loaded 2 off it's:		      */
  /* signature (PK\03\04)	4 bytes	 2- 5 */
  /* version needed to extract	2 bytes	 6, 7 */
  /* general purpose bit flag	2 bytes	 8, 9 */
  /* compression method		2 bytes	10,11 */
  /* last mod file time		2 bytes	12,13 */
  /* last mod file date		2 bytes	14,15 */
  /* crc-32			4 bytes	16-19 */
  /* compressed size		4 bytes	20-23 */
  /* uncompressed size		4 bytes	24-27 */
  /* filename length		2 bytes	28,29 */
  /* extra field length		2 bytes	30,31 */
  /* filename			(variable size) */
  /* extra field		(variable size) */

  filenamelen = buffer[28] | (buffer[29] << 8);
  skiplen = (buffer[30] | (buffer[31] << 8));	/* Extra field.  */

  if ((filenamelen != wantednamelen)
      || !(New(103, filename, filenamelen + skiplen, char)))
    return -1;

  status = (PerlIO_read (fp, filename, filenamelen + skiplen)
	    == (filenamelen + skiplen))
    || memNE (filename, wantedfilename, filenamelen);
  Safefree (filename);
  if (!status)
    return -1;

#ifdef DEBUG_LIBZIP
  PerlIO_debug("Compression method %d\n", buffer[10]);
#endif

#ifdef DEBUG_LIBZIP
  PerlIO_debug("You are at %ld\n", (long) PerlIO_tell (fp));
#endif

  {
    const char *layer_name;
    STRLEN layer_len;
    PerlIO_funcs *layer;
    SV *arg;
    int result;

    /* ZIP_STORED is zero, ZIP_DEFLATED is 8.  */
    if (buffer[10]) {
      layer_name = "gzip";
      layer_len = 4;
      arg = newSVpvn("none",4);
    } else {
      /* The number of bytes we need to copy.  */
      UV offset = (buffer[24] | (buffer[25] << 8)
                     | (buffer[26] << 16) | (buffer[27] << 24));
      layer_name = "subfile";
      layer_len = 7;
      arg = newSVuv(offset);
    }
    layer = PerlIO_find_layer(aTHX_ layer_name, layer_len, 0);

    if (!layer)
      Perl_croak(aTHX_ CLASSNAME " failed to find layer \"%s\"", layer_name);

    result = PerlIO_push(aTHX_ fp, layer, NULL, arg) ? 0 : -1;
      
#ifdef DEBUG_LIBZIP
    PerlIO_debug("Apply layer of %s gave %d\n", layer_name, result);
#endif

    return result;
  }
}

MODULE = ex::lib::zip		PACKAGE = ex::lib::zip		

PROTOTYPES: ENABLE

SV *
new (class, file)
	char *	class
	SV *	file
      CODE:
	{
	  dTHR;
	  STRLEN len;
          HV *stash = gv_stashpv(class, 1);
	  HV *self;
	  SV *self_ref;
          SV **entry;
	  /* A cache struct all zero.  Read only.  */
	  static const struct cache zeros;

	  if (!stash)
	    XSRETURN_UNDEF;

	  self = newHV();
	  if (!self)
	    XSRETURN_UNDEF;

	  /* It really doesn't matter what the second pointer is, as it's
	     length zero.  We're setting $self->{''}  */
	  entry = hv_fetch (self, (char *)self, 0, 1);
	  if (!entry) {
	    SvREFCNT_dec(self);
	    XSRETURN_UNDEF;
	  }
	  sv_setpvn(*entry, (const char *)&zeros, sizeof(zeros));
	  sv_catsv(*entry, file);

	  self_ref = newRV_noinc((SV *)self);
	  RETVAL = sv_bless(self_ref, stash);
	}
      OUTPUT:
	RETVAL

SV *
name (self)
	LIBZIB_OBJ *	self
      CODE:
	{
          SV **entry = hv_fetch (self, (char *)self, 0, 0);
	  const char *name;
	  STRLEN namelen;
	  
	  if (!entry)
	    XSRETURN_UNDEF;

	  name = SvPV(*entry, namelen);
	  if (namelen < sizeof(struct cache))
	    XSRETURN_UNDEF;

	  RETVAL = newSVpvn(name + sizeof(struct cache),
			    namelen - sizeof(struct cache));
	}
      OUTPUT:
	RETVAL

PerlIO *
INC (self, file)
	LIBZIB_OBJ *	self
	SV *		file
      CODE:
      {
	SV **zipfile = hv_fetch (self, (char *)self, 0, 0);
	const char *name;
	struct cache *aswas;
	STRLEN namelen;
	Stat_t isnow;
	PerlIO *fp;

	if (!zipfile)
	  XSRETURN_UNDEF;

	aswas = (struct cache *) SvPV(*zipfile, namelen);
	if (namelen < sizeof(struct cache))
	  XSRETURN_UNDEF;
	
	/* Right, now we know what the file is called, and how long/how old it
	   was last time we looked, let's stat it.  */
	name = ((const char *)aswas) + sizeof(struct cache);
	if (PerlLIO_stat(name, &isnow) < 0 || !S_ISREG(isnow.st_mode))
	  XSRETURN_UNDEF;
	fp = PerlIO_open (name, "rb");
	if (!fp)
	  XSRETURN_UNDEF;

	if (!(isnow.st_size == aswas->size && isnow.st_mtime == aswas->mtime)) {
	  /* It's changed size or timestamp.  (Or we've never looked at it
	     before.  */

	  if (aswas->size) {
	    /* It had non-zero size before.  Therefore need to scrub the hash,
	       but retain the '' entry.  I *think* increasing its refcount is
	       the way to do it.  */
	    SV *me = SvREFCNT_inc(*zipfile);
	    hv_clear (self);
	    zipfile = hv_fetch (self, (char *)self, 0, 1);
	    if (!zipfile) {
	      SvREFCNT_dec(me);
	      PerlIO_close(fp);
	      croak (CLASSNAME "::INC failed to rebuild cache");
	      XSRETURN_UNDEF;
	    }
	    /* making the SV mortal decreases its refcount at end of scope.
	       Moreover, it should make the copy to *zipfile more efficient.  */
	    sv_setsv(*zipfile, sv_2mortal(me));
	    aswas = (struct cache *) SvPV_nolen(*zipfile);
	    name = ((const char *)aswas) + sizeof(struct cache);
	  }
	  aswas->size = isnow.st_size;
	  aswas->mtime = isnow.st_mtime;
	  
	  /* Failure to find a zip header returns zero.  Linear search finished
	     is also zero.  So failure only happens once, and the (now emptied)
	     cache is accurate.  */
	  aswas->progress = openzipfile (fp, isnow.st_size);
	  /* Right.  Cache now scrubbed, search position reset.  */
	}

	if (findfile (self, aswas, fp, file) == 0)
	  RETVAL = fp;
	else {
	  PerlIO_close(fp);
	  XSRETURN_UNDEF;
	}
      }

      OUTPUT:
	RETVAL
