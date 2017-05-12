#
#   Copyright (C) 1998, 1999 Loic Dachary
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
# $Header: /cvsroot/TextQuery/Text-Query-SQL/t/fulcrum.pl,v 1.2 1999/06/16 11:13:41 loic Exp $
#

sub builder {
    return 'Text::Query::BuildSQLFulcrum';
}

sub dbi_args {
    return {
	PrintError => 0,
	AutoCommit => 0,
    };
}

sub upperlower {
    return uc($_[0]);
}

sub t1_schema {
    return undef if(!exists($ENV{'DBI_DSN'}) || $ENV{'DBI_DSN'} !~ /SearchServer/);

    return "
CREATE SCHEMA t1    -- 
CREATE TABLE t1 (  -- begin column definitions
	field1 char(32)  225,
	field2 char(128) 226
)
";
}

sub t1_drop { return "drop table t1"; }

sub t1_postamble {
    return "validate index t1";
}

1;
