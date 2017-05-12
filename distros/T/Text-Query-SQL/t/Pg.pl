#
#   Copyright (C) 2000 Benjamin Drieu
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
#

sub builder {
    return 'Text::Query::BuildSQLPg';
}

sub dbi_args {
    return ();
}

sub upperlower {
    return $_[0];
}

sub t1_schema {
    return undef if(!exists($ENV{'DBI_DSN'}) || $ENV{'DBI_DSN'} !~ /Pg/);
    return "
create table t1 (
	field1 varchar(32),
	field2 varchar(128)
)
";
}

sub t1_drop { return "drop table t1"; }

sub t1_postamble { return undef; }

1;


