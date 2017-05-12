NewsLib - a News Library for Perl
=================================

NewsLib is a library of perl modules for managing Network News services.
It's meant to be used for code-reuse and sharing when writing news-based
applications.  It currently includes:

News::Article::Response		Create responses to News::Article articles
News::Article::Ref		Reference functions for news articles	
News::Article::Clean		Subroutines to clean News::Article headers
News::Article::Cancel		Generate accurate cancel messages
News::NNTPAuth			Deprecated for Net::NNTP::Auth
Net::NNTP::Auth			A standard NNTP authentication method
Net::NNTP::Proxy		A news server in perl
Net::NNTP::Client		Simulate an entire NNTP client
Net::NNTP::Functions		Code to implement NNTP-standard functions

Installation Instructions
=========================

If you've got perl installed, it's easy:

  perl Makefile.PL
  make
  make test
  sudo make install

(If you don't have sudo installed, run the final command as root.)

If you don't have perl installed, then go install it and start over.
It'll do you good.

Existing Applications 
=====================

NewsProxy - a proxying news server
  http://www.killfile.org/~tskirvin/software/newsproxy/

PGPMoose - a cancelbot for policing moderated newsgroups
  http://www.killfile.org/~tskirvin/software/pgpmoose/
