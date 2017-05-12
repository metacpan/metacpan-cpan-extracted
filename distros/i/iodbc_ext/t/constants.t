#**********************************************************************
#             constants.t   The perl iODBC extension 0.1              *
#**********************************************************************
#              Copyright (C) 1996 J. Michael Mahan and                *
#                  Rose-Hulman Institute of Technology                *
#**********************************************************************
#    This package is free software; you can redistribute it and/or    *
# modify it under the terms of the GNU General Public License or      *
# Larry Wall's "Artistic License".                                    *
#**********************************************************************
#    This package is distributed in the hope that it will be useful,  *
#  but WITHOUT ANY WARRANTY; without even the implied warranty of     *
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU  *
#  General Public License for more details.                           *
#**********************************************************************
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN {
    $| = 1;
    print "1..68\n";}
END {
    print "not ok 1\n" unless $loaded;
}
use iodbc;
$loaded = 1;
print "ok 1\n";
eval {print defined(SQL_SUCCESS()) ? "":"not ","ok 2\n";};
eval {print defined(SQL_SUCCESS_WITH_INFO()) ? "":"not ","ok 3\n";};
eval {print defined(SQL_NO_DATA_FOUND()) ? "":"not ","ok 4\n";};
eval {print defined(SQL_ERROR()) ? "":"not ","ok 5\n";};
eval {print defined(SQL_INVALID_HANDLE()) ? "":"not ","ok 6\n";};
eval {print defined(SQL_STILL_EXECUTING()) ? "":"not ","ok 7\n";};
eval {print defined(SQL_NEED_DATA()) ? "":"not ","ok 8\n";};
eval {print defined(SQL_NULL_HENV()) ? "":"not ","ok 9\n";};
eval {print defined(SQL_NULL_HDBC()) ? "":"not ","ok 10\n";};
eval {print defined(SQL_NULL_HSTMT()) ? "":"not ","ok 11\n";};
eval {print defined(SQL_NULL_DATA()) ? "":"not ","ok 12\n";};
eval {print defined(SQL_NO_TOTAL()) ? "":"not ","ok 13\n";};
eval {print defined(SQL_NO_NULLS()) ? "":"not ","ok 14\n";};
eval {print defined(SQL_NULLABLE()) ? "":"not ","ok 15\n";};
eval {print defined(SQL_NULLABLE_UNKNOWN()) ? "":"not ","ok 16\n";};
eval {print defined(SQL_NTS()) ? "":"not ","ok 17\n";};
eval {print defined(SQL_DROP()) ? "":"not ","ok 18\n";};
eval {print defined(SQL_CLOSE()) ? "":"not ","ok 19\n";};
eval {print defined(SQL_UNBIND()) ? "":"not ","ok 20\n";};
eval {print defined(SQL_RESET_PARAMS()) ? "":"not ","ok 21\n";};
eval {print defined(SQL_COLUMN_AUTO_INCREMENT()) ? "":"not ","ok 22\n";};
eval {print defined(SQL_COLUMN_CASE_SENSITIVE()) ? "":"not ","ok 23\n";};
eval {print defined(SQL_COLUMN_COUNT()) ? "":"not ","ok 24\n";};
eval {print defined(SQL_COLUMN_DISPLAY_SIZE()) ? "":"not ","ok 25\n";};
eval {print defined(SQL_COLUMN_LABEL()) ? "":"not ","ok 26\n";};
eval {print defined(SQL_COLUMN_LENGTH()) ? "":"not ","ok 27\n";};
eval {print defined(SQL_COLUMN_MONEY()) ? "":"not ","ok 28\n";};
eval {print defined(SQL_COLUMN_NAME()) ? "":"not ","ok 29\n";};
eval {print defined(SQL_COLUMN_NULLABLE()) ? "":"not ","ok 30\n";};
eval {print defined(SQL_COLUMN_OWNER_NAME()) ? "":"not ","ok 31\n";};
eval {print defined(SQL_COLUMN_PRECISION()) ? "":"not ","ok 32\n";};
eval {print defined(SQL_COLUMN_QUALIFIER_NAME()) ? "":"not ","ok 33\n";};
eval {print defined(SQL_COLUMN_SCALE()) ? "":"not ","ok 34\n";};
eval {print defined(SQL_COLUMN_SEARCHABLE()) ? "":"not ","ok 35\n";};
eval {print defined(SQL_COLUMN_TABLE_NAME()) ? "":"not ","ok 36\n";};
eval {print defined(SQL_COLUMN_TYPE()) ? "":"not ","ok 37\n";};
eval {print defined(SQL_COLUMN_TYPE_NAME()) ? "":"not ","ok 38\n";};
eval {print defined(SQL_COLUMN_UNSIGNED()) ? "":"not ","ok 39\n";};
eval {print defined(SQL_COLUMN_UPDATABLE()) ? "":"not ","ok 40\n";};
eval {print defined(SQL_C_BINARY()) ? "":"not ","ok 41\n";};
eval {print defined(SQL_C_BIT()) ? "":"not ","ok 42\n";};
eval {print defined(SQL_C_BOOKMARK()) ? "":"not ","ok 43\n";};
eval {print defined(SQL_C_CHAR()) ? "":"not ","ok 44\n";};
eval {print defined(SQL_C_DATE()) ? "":"not ","ok 45\n";};
eval {print defined(SQL_C_DEFAULT()) ? "":"not ","ok 46\n";};
eval {print defined(SQL_C_DOUBLE()) ? "":"not ","ok 47\n";};
eval {print defined(SQL_C_FLOAT()) ? "":"not ","ok 48\n";};
eval {print defined(SQL_C_SLONG()) ? "":"not ","ok 49\n";};
eval {print defined(SQL_C_SSHORT()) ? "":"not ","ok 50\n";};
eval {print defined(SQL_C_STINYINT()) ? "":"not ","ok 51\n";};
eval {print defined(SQL_C_TIME()) ? "":"not ","ok 52\n";};
eval {print defined(SQL_C_TIMESTAMP()) ? "":"not ","ok 53\n";};
eval {print defined(SQL_C_ULONG()) ? "":"not ","ok 54\n";};
eval {print defined(SQL_C_USHORT()) ? "":"not ","ok 55\n";};
eval {print defined(SQL_C_UTINYINT()) ? "":"not ","ok 56\n";};
eval {print defined(SQL_C_LONG()) ? "":"not ","ok 57\n";};
eval {print defined(SQL_C_SHORT()) ? "":"not ","ok 58\n";};
eval {print defined(SQL_C_TINYINT()) ? "":"not ","ok 59\n";};
eval {print defined(TRUE()) ? "":"not ","ok 60\n";};
eval {print defined(FALSE()) ? "":"not ","ok 61\n";};
eval {print defined(SQL_UNSEARCHABLE()) ? "":"not ","ok 62\n";};
eval {print defined(SQL_LIKE_ONLY()) ? "":"not ","ok 63\n";};
eval {print defined(SQL_ALL_EXCEPT_LIKE()) ? "":"not ","ok 64\n";};
eval {print defined(SQL_SEARCHABLE()) ? "":"not ","ok 65\n";};
eval {print defined(SQL_ATTR_READONLY()) ? "":"not ","ok 66\n";};
eval {print defined(SQL_ATTR_WRITE()) ? "":"not ","ok 67\n";};
eval {print defined(SQL_ATTR_READWRITE_UNKNOWN()) ? "":"not ","ok 68\n";};
