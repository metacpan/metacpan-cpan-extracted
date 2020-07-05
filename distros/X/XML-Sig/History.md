
BYRNE - Byrne Reese: (byrnereese/perl-XML-Sig)

XML::Sig was originally written by in 2009 by Byrne Reese and was maintained
by him until 23 Dec 2009 which was the last commit to his github repo commit
id: 27a95a07ce5570f96fb5bbf1346fe074fe3e1a14 which incremented the version 
to 0.23.

Version 0.23 was never released to cpan and version 0.22 remained the latest
version available on cpan until 2020.

CHRISA - Chris Andrews: (chrisa/perl-XML-Sig)

Forked the latest version of byrnereese/perl-XML-Sig and starting in Sept 2010
committed 11 changes to XML::Sig in his repo.

As of commit id d957081d17ce397d6c92b1134129c3a54213aaaa Chris moved XML::Sig
into Net::SAML2 as an embedded module as Development had effectively stopped on
the cpan available version of XML::Sig.

CHRISA - Chris Andrews: (chrisa/perl-Net-SAML2)

Net::SAML2 commit id e8e207509b58ccfe0eeb8e7cb645d84120a39d8a added XML::Sig.

That commit is aproximately d957081d17ce397d6c92b1134129c3a54213aaaa with some
pod changes.

Work continued on Net::SAML2's version of XML::Sig under CHRISA's Net::SAML2
module until Chris ceased maintenance of Net::SAML2.

xmikew/perl-Net-SAML2:

xmikew's github fork of the final CHRISA github version introduced a number of
changes to Net::SAML2::XML::Sig from: 

1. Peter Marschall marschap
1. Jeff Fearn jfearn
1. Mike Wisener

TIMLEGGE - Timothy Legge (timlegge/perl-Net-SAML2)

Small clean-ups of white space and removed XML::Canonical as a dependency.  The
version was incremented to match Net-SAML2 and it was released to cpan as a part
of Net::SAML2.

TIMLEGGE - Timothy Legge

Byrne Reese approved the transfer of the XML::Sig module to TIMLEGGE who has
begun to prepare for a new release of XML::Sig based on the version maintained
as part of Net::SAML2.

TIMLEGGE - Timothy Legge (perl-Net-SAML2/perl-XML-Sig)

Merged the changes from Net::SAML2::XML::Sig into XML::Sig in preparation for a new
release and fixed couple of small bugs in tests and one in the xpath location for the
KeyInfo.

