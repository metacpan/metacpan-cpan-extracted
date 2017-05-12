# $Id: makefile,v 1.2 2003/10/23 15:06:45 loosifer Exp $

parser: Parser.pm

Parser.pm: grammar.yp
	yapp -s -m Net::LDAP::Shell::Parser -o Parser.pm grammar.yp
