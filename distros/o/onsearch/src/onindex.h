/* $Id: onindex.h,v 1.4 2005/07/28 08:01:53 kiesling Exp $ */

#ifndef _ONINDEX_H
#define _ONINDEX_H

#define FALSE 0
#define TRUE (!FALSE)
#define MAXPATH 255
#define MAXREC 4096

#define LOGNAME "onsearch.log"
#define LOCALPIDFILEDIR "/usr/local/var/run/onsearch"
#define PIDFILENAME "onindex.pid"

#define TEXTTYPE "text/plain"
#define HTMLSIG "<html"
#define HTMLSIG_U "<HTML"
#define HTMLDOCTYPE "<!doctype html"
#define HTMLDOCTYPE_U "<!DOCTYPE HTML"
#define HTMLTYPE "text/html"
#define XMLSIG "<?xml"
#define XMLSIG_U "<?XML"
#define XMLTYPE "text/xml"
#define PSSIG "%!PS-Adobe"
#define PSTYPE "application/postscript"
#define PDFSIG "%PDF-"
#define PDFTYPE "application/pdf"
#define PKZIPSIG "PK"
#define PKZIPTYPE "application/zip"
#define GZIPSIG "\213"
#define GZIPTYPE "application/x-gzip"
#define GIFSIG "GIF8"
#define GIFTYPE "image/gif"
#define JPEGSIG "JFIF"
#define JPEGTYPE "image/jpeg"
#define COMPRESSSIG "\037\235"
#define COMPRESSTYPE "application/compress"
#define SUNPKGBINSIG "outname=install.sfx.$$"
#define SUNPKGBINTYPE "application/vnd.sun.pkg"
#define PNGSIG "\211PNG"
#define PNGTYPE "image/png"
#define ELFSIG "\177ELF"
#define ELFTYPE "application/elf"
#define JAVACLASSSIG "0xca0xfe0xba0xbe"
#define JAVACLASSTYPE "application/java-class"

#endif /* _ONINDEX_H */
