#
#   Copyright (C) 2000 Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/TextQuery/Text-Query-SQL/t/mifluz.pl,v 1.1 2000/04/21 09:46:24 loic Exp $
#

sub builder {
    return 'Text::Query::BuildSQLMifluz';
}

sub dbi_args {
    return ();
}

sub upperlower {
    return $_[0];
}

sub t1_schema {
    return undef;
}

sub t1_drop { return undef; }

sub t1_postamble { return undef; }

1;
