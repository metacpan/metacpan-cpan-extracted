#
# For details about the client and server API conventions, refer
# to the PlRPC POD documentation.
#
# $Id: BridgeServer.pm,v 1.21 2008-01-21 09:16:56 kiesling Exp $

use lib qw(blib/arch blib/lib);

our $VERSION = '0.25';

$| = 1;

require Net::Daemon;
require RPC::PlServer;
require IO::Socket;
use UnixODBC ':all';

package BridgeAPI;

sub new {
    my $proto = shift;
    my $self = { @_ };
    bless($self, (ref($proto) || $proto));
    $self;
}

sub dm_log_open ($$$) {
    my $self = shift;
    my $appname = $_[0];
    my $filename = $_[1];
    my $r = UnixODBC::dm_log_open ($appname, $filename);
    return $r;
}

sub dm_log_close ($) {
    my $self = shift;
    my $r = UnixODBC::dm_log_close;
    return $r;
}

sub sql_alloc_connect ($) {
    my $self = shift;
    my $evh = $_[0];
    my $newhandle = 0;
    my $r = &UnixODBC::SQLAllocConnect ($evh, $newhandle);
    return $newhandle if (!$r);
    return undef;
}

sub sql_alloc_handle ($$) {
    my $self = shift;
    my $newhandle = 0;
    my $r = &UnixODBC::SQLAllocHandle(@_, $newhandle);
    return $newhandle if (!$r);
    return undef;
}

sub sql_alloc_env () {
    my $self = shift;
    my $newhandle = 0;
    my $r = &UnixODBC::SQLAllocEnv ($newhandle);
    return $newhandle if (!$r);
    return undef;
}

sub sql_cancel ($$) {
    my $self = shift;
    my $sth = $_[0];
    my $r = &UnixODBC::SQLCancel ($sth);
    return $r;
}

sub sql_col_attribute ($$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $colno = $_[1];
    my $attr = $_[2];
    my $maxlen = $_[3];
    my $char_attr = '';
    my $attr_len = 0;
    my $num_attr = 0;
    my $r = &UnixODBC::SQLColAttribute ($sth, $colno, $attr, $char_attr,
                                        $maxlen, $attr_len, $num_attr);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $char_attr, $attr_len, $num_attr);
    } else {
        return ($r, '', 0, 0);
    }
}

sub sql_column_privileges ($$$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[3];
    my $schema_length = $_[4];
    my $table = $_[5];
    my $table_length = $_[6];
    my $column = $_[7];
    my $column_length = $_[8];
    my $r = &UnixODBC::SQLColumnPrivileges ($sth, 
                                            $catalog, $catalog_length,
                                            $schema, $schema_length,
                                            $table, $table_length,
                                            $column, $column_length);
    return $r;
}

sub sql_columns ($$$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[3];
    my $schema_length = $_[4];
    my $table = $_[5];
    my $table_length = $_[6];
    my $type = $_[7];
    my $type_length = $_[8];
    my $r = &UnixODBC::SQLColumns ($sth, $catalog, $catalog_length, 
                                   $schema, $schema_length, 
                                   $table, $table_length,
                                   $type, $type_length);
    return $r;
}

sub sql_connect ($$$$$$$) {
    my $self = shift;
    my $cnh = $_[0];
    my $dsn = $_[1];
    my $dsn_len = $_[2];
    my $username = $_[3];
    my $username_len = $_[4];
    my $password = $_[5];
    my $password_len = $_[6];
    my $r = &UnixODBC::SQLConnect ($cnh, $dsn, $dsn_len, 
                                   $username, $username_len, 
                                   $password, $password_len);
    return $r;
}

sub sql_data_sources ($$$$$) {
    my $self = shift;
    my $evh = $_[0];
    my $order = $_[1];
    my $maxlength1 = $_[2];
    my $maxlength2 = $_[3];
    my $dsnname = '';
    my $dsnlength = 0;
    my $drivername = '';
    my $driverlength = 0;
    my $r = &UnixODBC::SQLDataSources ($evh, $order, 
                                       $dsnname, $maxlength1, $dsnlength,
                                       $drivername, $maxlength2, 
                                       $driverlength );

    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $dsnname, $dsnlength, $drivername, $driverlength);
    } else {
        return ($r, '', 0, '', 0);
    }
}

sub sql_describe_col ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $colno = $_[1];
    my $maxlen = $_[2];
    my $name = '';
    my $namelength = 0;
    my $type = 0;
    my $size = 0;
    my $decimal_digits = 0;
    my $nullable = 0;
    my $r = &UnixODBC::SQLDescribeCol ($sth, $colno, $name, 
                                       $maxlen, $namelength, $type, $size, 
                                       $decimal_digits, $nullable);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $name, $namelength, $type, $size, $decimal_digits, $nullable);
    } else {
        return ($r, '', '', '', '', '', '');
    }
}

sub sql_disconnect ($$) {
    my $self = shift;
    my $cnh = $_[0];
    my $r = &UnixODBC::SQLDisconnect ($cnh);
    return $r;
}

sub sql_drivers ($$$$$) {
    my $self = shift;
    my $handle = $_[0];
    my $order = $_[1];
    my $desc_max = $_[2];
    my $attr_max = $_[3];
    my $desc = '';
    my $desc_len = 0;
    my $attr = '';
    my $attr_len = 0;
    my $r = &UnixODBC::SQLDrivers ($handle, $order, $desc, $desc_max,
                                    $desc_len, $attr, $attr_max,
                                    $attr_len);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $desc, $desc_len, $attr, $attr_len);
    } else {
        return ($r, '', 0, '', 0);
    }
}

sub sql_end_tran ($$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $handle_type = $_[1];
    my $handle = $_[2];
    my $completion_type = $_[3];
    my $r = &UnixODBC::SQLEndTran ($handle_type, $sth, $completion_type);
    return $r;
}

sub sql_error ($$$$) {
    my $self = shift;
    my $evh = $_[0];
    my $cnh = $_[1];
    my $sth = $_[2];
    my $maxlength = $_[3];
    my ($sqlstate, $native, $text, $textlength);
    my $r = &UnixODBC::SQLError ($evh, $cnh, $sth, 
                                 $sqlstate, $native, $text,
                                 $maxlength, $textlength);
    return ($r, $sqlstate, $native, $text, $textlength) if (!$r);
    return $r;
}

sub sql_exec_direct ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $query = $_[1];
    my $length = $_[2];
    my $r = &UnixODBC::SQLExecDirect ($sth, $query, $length);
    return $r;
}

sub sql_execute ($$) {
    my $self = shift;
    my $sth = $_[0];
    my $r = &UnixODBC::SQLExecute ($sth);
    return $r;
}

sub sql_fetch ($$) {
    my $self = shift;
    my $sth = $_[0];
    my $r = &UnixODBC::SQLFetch ($sth);
    return $r;
}

sub sql_fetch_scroll ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $order = $_[1];
    my $offset = $_[2];
    my $r = &UnixODBC::SQLFetchScroll ($sth, $order, $offset);
    return $r;
}

sub sql_foreign_keys ($$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[3];
    my $schema_length = $_[4];
    my $table = $_[5];
    my $table_length = $_[6];
    my $foreign_catalog = '';
    my $foreign_catalog_length = 0;
    my $foreign_schema = '';
    my $foreign_schema_length = 0;
    my $foreign_table = '';
    my $foreign_table_length = 0;
    my $r = &UnixODBC::SQLForeignKeys ($sth, 
                                       $catalog, $catalog_length,
                                       $schema, $schema_length,
                                       $table, $table_length,
                                       $foreign_catalog, $foreign_catalog_length,
                                       $foreign_schema, $foreign_schema_length,
                                       $foreign_table, $foreign_table_length);
    return $r;
}

sub sql_free_connect ($$) {
    my $self = shift;
    my $handle = $_[0];
    my $r = &UnixODBC::SQLFreeConnect ($handle);
    return $r;
}

sub sql_free_env ($$) {
    my $self = shift;
    my $handle = $_[0];
    my $r = &UnixODBC::SQLFreeEnv ($handle);
    return $r;
}

sub sql_free_stmt ($$) {
    my $self = shift;
    my $sth = $_[0];
    my $option = $_[1];
    my $r = &UnixODBC::SQLFreeStmt ($sth, $option);
    return $r;
}

sub sql_free_handle ($$$) {
    my $self = shift;
    my $handle_type = $_[0];
    my $handle = $_[1];
    my $r = &UnixODBC::SQLFreeHandle ($handle_type, $handle);
    return $r;
}

sub sql_get_connect_attr ($$$$) {
    my $self = shift; 
    my $cnh = $_[0];
    my $attr = $_[1];
    my $maxlength = $_[2];
    my $text = '';
    my $textlength = 0;
    my $r = &UnixODBC::SQLGetConnectAttr ($cnh, $attr, $text, 
                                       $maxlength, $textlength);
    return ($r, $text, $textlength) if $r == $UnixODBC::SQL_SUCCESS;
    return ($r, '', 0);
}

sub sql_get_cursor_name ($$$) {
    my $self = shift;
    my $sth = $_[0];
    my $maxlen = $_[1];
    my $buf = '';
    my $length = 0;
    my $r = &UnixODBC::SQLGetCursorName ($sth, $buf, $maxlen, $length);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $buf, $length);
    } else {
        return ($r, '', 0);
    }
}

sub sql_get_data ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $colno = $_[1];
    my $datatype = $_[2];
    my $maxlen = $_[3];
    my $result_text = '';
    my $result_text_len = 0;
    my $r = &UnixODBC::SQLGetData ($sth, $colno, $datatype, 
                                   $result_text, $maxlen, 
                                   $result_text_len);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $result_text, $result_text_len);
    } else {
        return ($r, '', 0);
    }
}

sub sql_get_diag_field ($$$$$) {
    my $self = shift;
    my $handle_type = $_[0];
    my $handle = $_[1];
    my $fieldno = $_[2];
    my $maxlen = $_[3];
    my $native = 0;
    my $text = '';
    my $textlen = 0;
    my $r = &UnixODBC::SQLGetDiagField ($handle_type, $handle, 
                                        $fieldno, $native, 
                                        $text, $maxlen, $textlen);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $native, $text, $textlen);
    } else {
        return ($r, 0, '', 0);
    }
}

sub sql_get_diag_rec ($$$$$) {
    my $self = shift;
    my ($handle_type, $handle, $recno, $buflen) = @_;
    my $sqlstate = '';
    my $native = 0;
    my $text = '';
    my $textlen = 0;
    my $r = &UnixODBC::SQLGetDiagRec ($handle_type, $handle, $recno,
                                      $sqlstate, $native, $text,
                                      $buflen, $textlen);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $sqlstate, $native, $text, $textlen);
    } else {
        return ($r, '', 0, '', 0);
    }
}

sub sql_get_env_attr ($$$$) {
    my $self = shift;
    my $evh = $_[0];
    my $attr = $_[1];
    my $buflen = $_[2];
    my $text = '';
    my $textlen = 0;
    my $r = &UnixODBC::SQLGetEnvAttr ($evh, $attr, $text, $buflen, $textlen);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $text, $textlen);
    } else {
        return ($r, '', 0);
    }
}

sub sql_get_functions ($$$) {
    my $self = shift;
    my $cnh = $_[0];
    my $function = $_[1];
    my $supported = 0;
    my $r = &UnixODBC::SQLGetFunctions ($cnh, $function, $supported);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $supported);
    } else {
        return ($r, 0);
    }
}

sub sql_get_info ($$$$) {
    my $self = shift;
    my $cnh = $_[0];
    my $attr = $_[1];
    my $buflen = $_[2];
    my $text = '';
    my $textlen = 0;
    my $r = &UnixODBC::SQLGetInfo ($cnh, $attr, $text, $buflen, $textlen);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $text, $textlen);
    } else {
        return ($r, '', 0);
    }
}

sub sql_get_stmt_attr ($$$) {
    my $self = shift;
    my $sth = $_[0];
    my $attr =$_[1];
    my $buflen = $_[2];
    my $text = '';
    my $textlength = 0;
    my $r = &UnixODBC::SQLGetStmtAttr ($sth, $attr, $text, 
                                       $buflen, $textlength);
    if ($r == &UnixODBC::SQL_SUCCESS) {
        return ($r, $text, $textlength);
    } else {
        return ($r, '', 0);
    }
}

sub sql_get_type_info ($$$) {
    my $self = shift;
    my $sth = $_[0];
    my $type = $_[1];
    my $r = &UnixODBC::SQLGetTypeInfo ($sth, $type);
    return $r;
}

sub sql_more_results ($$) {
    my $self = shift;
    my $sth = $_[0];
    my $r = &UnixODBC::SQLMoreResults ($sth);
    return $r;
}

sub sql_native_sql ($$$$$) {
    my $self = shift;
    my $cnh = $_[0];
    my $query = $_[1];
    my $querylength = $_[2];
    my $maxlen = $_[3];
    my $buf = '';
    my $buflen = 0;
    my $r = &UnixODBC::SQLNativeSql ($cnh, $query, $querylength, $buf, 
                                     $maxlen, $buflen);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $buf, $buflen);
    } else {
        return ($r, '', 0);
    }
}

sub sql_num_result_columns ($$) {
    my $self = shift;
    my $sth = $_[0];
    my $ncols = 0;
    my $r = &UnixODBC::SQLNumResultCols ($sth, $ncols);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $ncols);
    } else {
        return ($r, 0);
    }
}

sub sql_prepare ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $query = $_[1];
    my $length = $_[2];
    my $r = &UnixODBC::SQLPrepare ($sth, $query, length ($query));
    return $r;
}

sub sql_primary_keys ($$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[3];
    my $schema_length = $_[4];
    my $table = $_[5];
    my $table_length = $_[6];
    my $r = &UnixODBC::SQLPrimaryKeys ($sth, 
                                       $catalog, 
                                       $catalog_length,
                                       $schema,
                                       $schema_length,
                                       $table,
                                       $table_length);
    return $r;
}

sub sql_procedure_columns ($$$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[2];
    my $schema_length = $_[3];
    my $proc = $_[4];
    my $proc_length = $_[5];
    my $column = $_[6];
    my $column_length = $_[7];
    my $r = &UnixODBC::SQLProcedureColumns ($sth, $catalog, $catalog_length,
                                            $schema, $schema_length, 
                                            $proc, $proc_length,
                                            $column, $column_length);
    return $r;
}

sub sql_procedures ($$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[3];
    my $schema_length = $_[4];
    my $proc = $_[5];
    my $proc_length = $_[6];
    my $r = &UnixODBC::SQLProcedures ($sth, $catalog, $catalog_length,
                                      $schema, $schema_length, 
                                      $proc, $proc_length);
    return $r;
}

sub sql_row_count ($$) {
    my $self = shift;
    my $sth = $_[0];
    my $nrows = 0;
    my $r = &UnixODBC::SQLRowCount ($sth, $nrows);
    if ($r == $UnixODBC::SQL_SUCCESS) {
        return ($r, $nrows);
    } else {
        return ($r, 0);
    }
}

sub sql_set_connect_attr ($$$$$) {
    my $self = shift;
    my $cnh = $_[0];
    my $attr = $_[1];
    my $buf = $_[2];
    my $buflen = $_[3];
    my $r = &UnixODBC::SQLSetConnectAttr ($cnh, $attr, $buf, $buflen);
    return $r;
}

sub sql_set_connect_option ($$$) {
    my $self = shift;
    my $cnh = $_[0];
    my $attr = $_[1];
    my $value = $_[2];
    my $r = &UnixODBC::SQLSetConnectOption ($cnh, $attr, $value);
    return $r;
}

sub sql_set_cursor_name ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $cname = $_[1];
    my $length = $_[2];
    my $r = &UnixODBC::SQLSetCursorName ($sth, $cname, $length);
    return $r;
}

sub sql_set_env_attr ($$$$) {
    my $self = shift;
    my $r = &UnixODBC::SQLSetEnvAttr (@_);
    return $r;
}

sub sql_set_pos ($$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $row = $_[1];
    my $order = $_[2];
    my $lock = $_[3];
    my $r = &UnixODBC::SQLSetPos ($sth, $row, $order, $lock);
    return $r;
}

sub sql_set_scroll_options ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $concurrency = $_[1];
    my $keyset = $_[2];
    my $rowset = $_[3];
    my $r = &UnixODBC::SQLSetScrollOptions ($sth, $concurrency, 
                                            $keyset, $rowset);
    return $r;
}

sub sql_set_stmt_attr ($$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $attrib = $_[1];
    my $value = $_[2];
    my $length = $_[3];
    my $r = &UnixODBC::SQLSetStmtAttr ($sth, $attrib, $value, $length);
    return $r;
}

sub sql_special_columns ($$$$$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $id_type = $_[1];
    my $catalog = $_[2];
    my $catalog_length = $_[3];
    my $schema = $_[4];
    my $schema_length = $_[5];
    my $table = $_[6];
    my $table_length = $_[7];
    my $scope = $_[8];
    my $nullable = $_[9];
    my $r = &UnixODBC::SQLSpecialColumns ($sth, $id_type, 
                                          $catalog, $catalog_length,
                                          $schema, $schema_length,
                                          $table, $table_length,
                                          $scope, $nullable);
    return $r;
}

sub sql_statistics ($$$$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[3];
    my $schema_length = $_[4];
    my $table = $_[5];
    my $table_length = $_[6];
    my $unique = $_[7];
    my $reserved = $_[8];
    my $r = &UnixODBC::SQLStatistics ($sth, 
                                   $catalog, $catalog_length,
                                   $schema, $schema_length, 
                                   $table, $table_length,
                                   $unique, $reserved);
    return $r;
}

sub sql_table_privileges ($$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $catalog = $_[1];
    my $catalog_length = $_[2];
    my $schema = $_[3];
    my $schema_length = $_[4];
    my $table = $_[5];
    my $table_length = $_[6];
    my $r = &UnixODBC::SQLTablePrivileges ($sth, 
                                        $catalog, $catalog_length,
                                        $schema, $schema_length,
                                        $table, $table_length);
    return $r;
}

sub sql_tables ($$$$$$$$$$) {
    my $self = shift;
    my $sth = $_[0];
    my $cat_name = $_[1];
    my $cat_name_len = $_[2];
    my $schema_name = $_[3];
    my $schema_name_len = $_[4];
    my $table_name = $_[5];
    my $table_name_len = $_[6];
    my $table_type = $_[7];
    my $table_type_len = $_[8];
    my $r = &UnixODBC::SQLTables ($sth, $cat_name, $cat_name_len,
                                  $schema_name, $schema_name_len,
                                  $table_name, $table_name_len,
                                  $table_type, $table_type_len);
    return $r;
}

package UnixODBC::BridgeServer;

use vars qw($VERSION @ISA);

$UnixODBC::BridgeServer::VERSION = $UnixODBC::VERSION;

@UnixODBC::BridgeServer::ISA = qw(RPC::PlServer);

sub new { 
    return shift -> SUPER::new(@_); 
}

sub Bind { return shift -> SUPER::Bind(); }

sub main {
    my $server = UnixODBC::BridgeServer 
        -> new({'configfile' => '/usr/local/etc/odbcbridge.conf',
                  'methods' => 
                  { 'UnixODBC::BridgeServer' => {
                      'ClientObject' => 1,
                      'CallMethod' => 1,
                      'NewHandle' => 1,
                      },
                          'BridgeAPI' => {
                           'new' => 1,
                           'sql_alloc_connect' => 1,
                           'sql_alloc_env' => 1,
                           'sql_alloc_handle' => 1,
                           'sql_cancel' => 1,
                           'sql_col_attribute' => 1,
                           'sql_column_privileges' => 1,
                           'sql_columns' => 1,
                           'sql_connect' => 1,
                           'sql_data_sources' => 1,
                           'sql_describe_col' => 1,
                           'sql_disconnect' => 1,
                           'sql_drivers' => 1,
                           'sql_end_tran' => 1,
                           'sql_error' => 1,
                           'sql_execute' => 1,
                           'sql_exec_direct' => 1,
                           'sql_fetch' => 1,
                           'sql_fetch_scroll' => 1,
                           'sql_foreign_keys' => 1,
                           'sql_free_connect' => 1,
                           'sql_free_env' => 1,
                           'sql_free_handle' => 1,
                           'sql_free_stmt' => 1,
                           'sql_get_connect_attr' => 1,
                           'sql_get_cursor_name' => 1,
                           'sql_get_data' => 1,
                           'sql_get_diag_rec' => 1,
                           'sql_get_env_attr' => 1,
                           'sql_get_functions' => 1,
                           'sql_get_info' => 1,
                           'sql_get_stmt_attr' => 1,
                           'sql_get_type_info' => 1,
                           'sql_more_results' => 1,
                           'sql_native_sql' => 1,
                           'sql_num_result_columns' => 1,
                           'sql_prepare' => 1,
                           'sql_primary_keys' => 1,
                           'sql_procedure_columns' => 1,
                           'sql_procedures' => 1,
                           'sql_row_count' => 1,
                           'sql_set_connect_attr' => 1,
                           'sql_set_connect_option' => 1,
                           'sql_set_cursor_name' => 1,
                          'sql_set_env_attr' => 1,
                           'sql_set_pos' => 1,
                           'sql_set_scroll_options' => 1,
			   'sql_set_stmt_attr' => 1,
                           'sql_special_columns', => 1,
                           'sql_statistics' => 1,
                           'sql_table_privileges' => 1,
                           'sql_tables' => 1,
                          'dm_log_open' => 1,
                          'dm_log_close' => 1},
                }, 
            }, \@_);
    $server->Bind();
}

=head1 NAME

   BridgeServer.pm - ODBC API for network clients.

=head1 SYNOPSIS

    use UnixODBC::BridgeServer;
    UnixODBC::BridgeServer::main();

=head1 DESCRIPTION

UnixODBC::BridgeServer provides an object oriented API for
communicating with ODBC driver managers on network systems.  A
UnixODBC::BridgeServer client is a subclass of RPC::PlClient, and
communicates with a UnixODBC::BridgeServer daemon (see "man
odbcbridge") on the DBMS server system using Remote Procedure Calls.
UnixODBC::BridgeServer provides a network interface to the API in
UnixODBC.pm.  The UnixODBC manual page describes those functions.

Here is a client that uses the UnixODBC::BridgeServer API.

  #! /usr/bin/perl

  use RPC::PlClient;
  use UnixODBC qw (:all);
  use UnixODBC::BridgeServer;

  #
  # Edit for the Host Address, DSN, TableName, UserName and PassWord of 
  # the remote data source.
  #
  my $HostAddress = '127.0.0.1';
  my $DSN = 'Data_Source_Name';
  my $TableName = 'Table_Name';
  my $UserName = 'User_Name';
  my $PassWord = 'Password';

  # Port address used by client and odbcbridge daemon.

  my $Port = 9999;

  # Maximum field length.  The RPC::PlServer POD documentation describes
  # how to change this.

  my $MaxFieldLength = 65535;

  # ODBC Handles

  my $evh = 0;  # Environment Handle
  my $cnh = 0;  # Connection Handle
  my $sth = 0;  # Statement Handle

  # Return values for sql_get_diag_rec 

  my ($r, $sqlstate, $native, $text, $textlen);

  # SQL Query Text

  my $query = "select \* from $TableName\;";

  # Rows and columns in the result set

  my ($nrows, $ncols);

  # Create a RPC network client object.  This manages the 
  # network connection.

  my $client = 
      eval { RPC::PlClient->new('peeraddr' => $HostAddress,
                          'peerport' => $Port,
                          'application' => 'UnixODBC::BridgeServer',
                          'version' => $UnixODBC::VERSION,
                          'user' => $UserName,
                          'password' => $PassWord) }
     or do {
        print "Failed to make first connection: $@\n";
        exit 1;
     };

  # Create the BridgeClient object.

  my $c = $client -> ClientObject ('BridgeAPI', 'new');

  # Uncomment if you want the Driver Manager to log the ODBC 
  # function calls.  Also uncomment the call to dm_log_close,
  # below.

  # my $ODBCLogFile = '/tmp/sampleclient.log';
  # $c -> dm_log_open ('UnixODBC Bridge Sample Client', $ODBCLogFile);

  # Allocate an environment handle.

  $evh =  $c -> sql_alloc_env ();
  if (defined $evh) { 
      $r = $c -> 
          sql_set_env_attr ($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);
  } else {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_ENV, $evh, 1, 255);
      print "\nsql_alloc_handle: $r, $text, $textlen\n";
      exit 1;
  }

  # Allocate a connection handle.

  $cnh = $c -> sql_alloc_handle ($SQL_HANDLE_DBC, $evh);

  # Connect to the data source.

  $r = $c -> sql_connect ($cnh, $DSN, length($DSN),
                          $UserName, length($UserName), 
                          $PassWord, length($PassWord), 0);
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_DBC, $cnh, 1, 255);
      print "\nconnect: $r, $text, $textlen\n";
  }

  # Allocate a statement handle.

  $sth = $c -> sql_alloc_handle ($SQL_HANDLE_STMT, $cnh);
  if (! defined $sth) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_DBC, $cnh, 1, 255);
      print "\nsql_alloc_handle sth: $r, $text, $textlen\n";
  }

  # Query the remote DBMS.

  $r = $c -> sql_exec_direct ($sth, $query, length ($query));
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_STMT, $sth, 1, 255);
      print "\nsql_exec_direct: $r, $text, $textlen\n";
  }

  # Get the number of columns in the result set.

  ($r, $ncols) = $c -> sql_num_result_columns ($sth);
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_STMT, $sth, 1, 255);
      print "\nsql_num_result_columns: $r, $text, $textlen\n";
  }

  # Get the number of rows in the result set.

  ($r, $nrows) = $c -> sql_row_count ($sth);
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_STMT, $sth, 1, 255);
      print "\nsql_num_result_columns: $r, $text, $textlen\n";
  }

  # Print the number of rows and columns in the result set.

  print "\n$nrows rows, $ncols columns\n";

  # Fetch each row and each column's contents.

  while (1) {
    $r = $c -> sql_fetch ($sth);
    last if $r == $SQL_NO_DATA;
    foreach my $colno (1..$ncols) {
        ($r, $text, $textlen) = 
            $c -> sql_get_data ($sth, $colno, $SQL_C_CHAR, $MaxFieldLength);
        print "$text\t";
    }
    print "\n";
  }

  # De-allocate the ODBC handles.

  $r = $c -> sql_free_handle ($SQL_HANDLE_STMT, $sth);
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_DBC, $cnh, 1, 255);
      print "\nfree_handle sth: $r, $text, $textlen\n";
  }

  $r = $c -> sql_disconnect ($cnh);
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_DBC, $cnh, 1, 255);
      print "\nconnect: $r, $text, $textlen\n";
  }

  $r = $c -> sql_free_connect ($cnh);
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_ENV, $evh, 1, 255);
      print "\nfree_connect: $r, $text, $textlen\n";
  }

  $r = $c -> sql_free_handle ($SQL_HANDLE_ENV, $evh);
  if ($r != 0) {
      ($r, $sqlstate, $native, $text, $textlen) = 
          $c -> sql_get_diag_rec ($SQL_HANDLE_ENV, $evh, 1, 255);
      print "\nfree_connect: $r, $text, $textlen\n";
  }

  # $c -> dm_log_close;


=head1 Application Programming Interface


=head2 ODBC Return Values


The ODBC API defines these return values for the status of function
calls.

  Perl Variable                   Numeric Value
  -------------                   -------------
  $SQL_NULL_DATA                  -1
  $SQL_DATA_AT_EXEC               -2
  $SQL_SUCCESS                    0
  $SQL_SUCCESS_WITH_INFO          1
  $SQL_NO_DATA                    100
  $SQL_NO_DATA_FOUND              100
  $SQL_ERROR                      -1
  $SQL_INVALID_HANDLE             -2
  $SQL_STILL_EXECUTING            2
  $SQL_NEED_DATA                  99

=head2 Methods in the UnixODBC::BridgeServer API


$c is an instance of a UnixODBC client that has established a network
connection to a UnixODBC server.  The example scripts show how to
construct the client object.

=head2 dm_log_open (I<application_name>, I<log_file_name>)


  Opens a log file on the remote server.  You must have 
  write privileges in that directory.

  Returns 0;

  $c -> dm_log_open ('ODBC Bridge', '/tmp/odbcbridge.log');

=head2 dm_log_close 


  Closes the log file on the remote server.

  $c -> dm_log_close;

=head2 sql_alloc_connect (I<environment_handle>)


  Returns a new connection handle, or undef on error.

  $cnh = $c -> sql_alloc_connect ($evh);

=head2 sql_alloc_env ()


  Returns a new environment handle, or undef on error.

  $evh = $c -> sql_alloc_env ();

=head2 sql_alloc_handle (I<handle_type>, I<parent_handle>)


  Returns the new handle, or undef on error.

  # Allocate an environment handle

  $evh = $c -> sql_alloc_handle ($SQL_HANDLE_ENV, $SQL_NULL_HANDLE);

  # Allocate a connection handle

  $cnh = $c -> sql_alloc_handle ($SQL_HANDLE_DBC, $evh);

  # Allocate a statement handle

  $sth = $c -> sql_alloc_handle ($SQL_HANDLE_STMT, $cnh);

=head2 sql_cancel (I<statement_handle>)


  Returns the ODBC API return value.

  $r = $c -> sql_cancel ($sth);

=head2 sql_col_attribute (I<statement_handle>, I<column_number>, I<attribute>, I<maxlength>)


  Returns a list of
  - SQL return value
  - Text attribute if any
  - Length of text attribute
  - Numeric attribute

  ($r, $text, $textlen, $num) = 
      $c -> sql_col_attribute ($sth, 1, $SQL_COLUMN_NAME, 255);

=head2 sql_columns (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<table_name>, I<table_name_length>, I<column_name>, I<column_name_length>)


  Returns the ODBC API return value.

  # Retrieve and print all column names for table named $table
  $r = $c -> sql_columns ($sth, '', 0, '', 0, 
                          "$table", length($table), '' 0);
  while (1) {
    $r = $c -> sql_fetch ($sth);
    last if $r == $SQL_NO_DATA;
    if ($r != $SQL_SUCCESS) {
      ($r, $sqlstate, $native, $text, $textlen) = 
        $c -> sql_get_diag_rec ($SQL_HANDLE_STMT, $sth, 1, 255);
      print "[sql_fetch]$text\n";
      return 1;
    } 

    # Column names are the fourth column of the result set.
    ($r, $text, $textlen) = 
      $c -> sql_get_data ($sth, 4, $SQL_C_CHAR, 255);
    last if $r == $SQL_NO_DATA;
    print "$text\n";
    if ($r != $SQL_SUCCESS) {
       ($r, $sqlstate, $native, $text, $textlen) = 
        $c -> sql_get_diag_rec ($SQL_HANDLE_STMT, $sth, 1, 255);
      print "[sql_get_data]$text\n";
      return 1;
    } 
  }

=head2 sql_connect (I<connection_handle>, I<data_source_name>, I<user_name>, I<user_name_length>, I<password>, I<password_length>)


  Returns the ODBC API return value.

  $r = $c -> sql_connect ($cnh, 'Customers', 
                          'joe', length('joe'),
                          'password', length('password'));

=head2 sql_data_sources (I<environment_handle>, I<orientation>, I<maximum_dsn_name_length>, I<maximimu_driver_name_length>);


  Returns a list of
  - ODBC API return value.
  - DSN name.
  - Length of DSN name text.
  - Name of DBMS Driver for DSN.
  - Length of driver text.

  ($r, $dsnname, $dsnlength, $drivername, $drivernamelength) = 
  $c -> sql_data_sources ( $evh, $SQL_FETCH_FIRST, 
                           $messagelength1, 
                           $messagelength2 );

=head2 sql_describe_col (I<statement_handle>, I<column_number>, I<maxlength>)


  Returns a list of 
  - SQL API return value
  - Column name
  - Name length
  - Data type
  - Size
  - Decimal digits
  - Nullable

  ($r, $name, $namelength, $type, $size, $decimal_digits, $nullable) 
    = $c -> sql_describe_col ($sth, 1, 255);

=head2 sql_disconnect (I<connection_handle>)


  Returns the ODBC API return value.

  $r = sql_disconnect ($cnh);

=head2 sql_drivers (I<environment_handle>, I<orientation>, I<description_maximum_length>, I<attribute_maximum_length>)


  Returns a list of: 
  - SQL API return value
  - Driver description string
  - Driver description string length
  - Attribute description string
  - Attribute description string length

  ($r, $desc, $desc_len, $attr, $attr_len) =
    sql_drivers ($evh, $order, $desc_max_len, $attr_max_len);

=head2 sql_end_tran (I<handle_type>, I<handle>, I<completion_type>)


  Returns the ODBC API return value.

  $r = sql_end_tran ($SQL_HANDLE_STMT, $sth, 0);

=head2 sql_error (I<environment_handle>, I<connection_handle>, I<statement_handle>, I<maxlength>)


  Returns an ODBC error message.

  ($r, $sqlstate, $native, $text, $textlen) = 
    $c -> sql_error ($evh, $cnh, $sth, $maxlength);

=head2 sql_exec_direct (I<statement_handle>, I<query>, I<query_length>)


  Returns the ODBC SQL return value

  $r = $c -> sql_exec_direct ($sth, $query, length ($query));

=head2 sql_execute (I<statement_handle>)


  Returns the ODBC API return value

  $r = $c -> sql_execute ($sth);

=head2 sql_fetch (I<statement_handle>)


  Returns the ODBC API return value.

  $r = sql_fetch ($sth);


=head2 sql_fetch_scroll (I<statement_handle>, I<orientation>, I<offset>);


  Returns the ODBC API return value.

  $r = $c -> sql_fetch_scroll ($sth, $SQL_FETCH_NEXT, $row++);

=head2 sql_foreign_keys (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<table_name>, I<table_name_length>, I<foreign_catalog_name>, I<foreign_catalog_name_length>, I<foreign_schema_name>, I<foreign_schema_name_length>, I<foreign_table_name>, Iforeign_table_name_length>)


  Returns the ODBC API return value.

  $r = $c -> sql_foreign_keys ($sth, '', 0, '', 0, $table, length ($table),
                               '', 0, '', 0, $foreign_table, 
                               length ($foreign_table));

=head2 sql_free_connect (I<connection_handle>)


  Returns the ODBC API return value.

  $r = $c -> sql_free_connect ($cnh);

=head2 sql_free_env (I<handle>)


Convenience function to de-allocate an environment handle.

  $r = $c -> sql_free_env ($evh);

=head2 sql_free_handle (I<handle_type>, I<handle>)


  Returns the ODBC API return value.

  # Free environment handle

  $r = $c -> sql_free_handle ($SQL_HANDLE_ENV, $evh);

  # Free connection handle

  $r = $c -> sql_free_handle ($SQL_HANDLE_DBC, $cnh);

  # Free statement handle

  $r = $c -> sql_free_handle ($SQL_HANDLE_STMT, $sth);


=head2 sql_free_stmt (I<statement_handle>, I<option>) 


  $r = $c -> sql_free_stmt ($sth, $SQL_CLOSE);

=head2 sql_get_connect_attr (I<connection_handle>, I<attribute>, I<maxlength>)


=head2 sql_get_cursor_name (I<statement_handle>, I<maxlength>)


  Returns a list of 
  - API return value
  - Cursor name
  - Length of cursor name

  ($r, $cursorname, $length) = 
     $c -> sql_get_cursor_name ($sth, 255);

=head2 sql_get_data (I<statement_handle>, I<column_number>, I<data_type>, I<maxlength>)


  Returns a list of
  - API return value
  - Result text
  - Result text length

  ($r, $text, $len) = sql_get_data ($sth, 1, $SQL_C_CHAR, 255);

=head2 sql_get_diag_field (I<handle_type>, I<handle>, I<field_number>, I<maxlength>)


  Returns a list of
  - API return value
  - Server native error
  - ODBC error
  - ODBC error length

  ($r, $native, $text, $textlen) = 
     $c -> sql_get_diag_field ($SQL_HANDLE_STMT, $sth, 1, 255);

=head2 sql_get_diag_rec (I<handle_type>, I<handle>, I<record_number>, I<maxlength>)


  Returns a list of: 
  - API return value
  - SQL state
  - DBMS error number
  - Error text
  - Error text length

  If the return value is $SQL_NO_DATA, the remaining list elements
  are empty.

  ($r, $sqlstate, $native, $text, $textlen) = 
    $c -> sql_get_diag_rec ($SQL_HANDLE_ENV, $evh, 1, 255);

=head2 sql_get_env_attr (I<environment_handle>, I<attribute>, I<maxlength>)


  Returns a list of: 
  - API return value
  - Attribute value
  - Attribute value length.

  If the return value is not $SQL_SUCCESS, the remaining list 
  elements are empty.

  ($result, $version, $versionlength) = 
    $c -> sql_get_env_attr ($evh, $SQL_ATTR_ODBC_VERSION, $maxlength)

=head2 sql_get_functions (I<connection_handle>, I<function>);


  Returns a list of 
  - API return value
  - Non-zero if function is supported, zero if not supported.

  my ($r, $s) = $c -> sql_get_functions ($cnh, $SQL_API_SQLALLOCHANDLESTD);

=head2 sql_get_info (I<connection_handle>, I<attribute>, I<maxlength>);


  Returns a list of 
  - API return value
  - Attribute value
  - Attribute value length

  ($r, $dbmsname, $length) = 
     $c -> sql_get_info ($cnh, $SQL_SERVER_NAME, $maxlength)

=head2 sql_get_stmt_attr (I<statement_handle>, I<attribute>, I<maxlength>)


  Returns a list of 
  - API return value
  - Attribute value
  - Attribute length

  my ($r, $text, $textlength) = 
    $c -> sql_get_stmt_attr ($sth, $SQL_ATTR_CURSOR_SCROLLABLE, 255);


=head2 sql_get_type_info (I<statement_handle>, I<type>)


Returns the ODBC API return value.  The result of the query is a
result set of the requested types.

  $r = $c -> sql_get_type_info ($sth, $SQL_ALL_TYPES);

=head2 sql_more_results (I<statement_handle>)


  Returns the ODBC API return value.

  $r = $c -> sql_more_results ($sth);


=head2 sql_native_sql (I<connection_handle>, I<query>, I<query_length>, I<maxlength>)


  Returns a list of 
  - API return value
  - Translated SQL query
  - Length of translated query

  ($r, $nativequery, $length) = 
    $c -> sql_native_sql ($cnh, $query, length ($query), 255);

=head2 sql_num_result_columns (I<statment_handle>)


  Returns a list of 
  - API return value
  - Number of columns in result set

  ($r, $ncols) = sql_num_result_columns ($sth);

=head2 sql_prepare (I<statment_handle>, I<query>, I<query_length>)


  Returns the ODBC API value.

  $r = $c -> sql_prepare ($sth, $query, length ($query) );

=head2 sql_primary_keys (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<table_name>, I<table_name_length>)


  Return a result set of primary keys.  The table name is required.

=head2 sql_procedure_columns (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<procedure_name>, I<procedure_name_length>, I<column_name>, I<column_name_length>);


  Returns the ODBC API return value.

  $r = $c -> sql_procedure_columns ($sth, '', 0, '', 0, '', 0, '', 0);

=head2 sql_procedures (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<procedure_name>, I<procedure_name_length>);


  Returns the ODBC API return value.

  $r = &UnixODBC::SQLProcedures ($sth, '', 0, '', 0, '', 0);

=head2 sql_row_count (I<statement_handle>)


  Returns a list of
  - API return value
  - Number of rows in result set

  ($r, $nrows) = sql_row_count ($sth);

=head2 sql_set_connect_attr (I<connection_handle>, I<attribute>, I<buffer>, I<bufferlength>)


  Deprecated in the ODBC standard.

=head2 sql_set_connect_option (I<connection_handle>, I<option>, I<value>)


  # Write function call info to /tmp/sql.log.  

  $r = $c -> sql_set_connect_option ($cnh, $SQL_OPT_TRACE, 
                                     $SQL_OPT_TRACE_ON);

=head2 sql_set_cursor_name (I<statement_handle>, I<cursorname>, I<cursor_name_length>)


  Returns the ODBC API return value.

  $r = $c -> sql_set_cursor_name ($sth, 'cursor', length('cursor'));


=head2 sql_set_env_attr (I<environment_handle>, I<attribute>, I<value>, I<length_of_value_string>)


  Returns the ODBC function return value.

  $r = sql_set_env_attr ($evh, $SQL_ATTR_ODBC_VERSION, $SQL_OV_ODBC2, 0);

=head2 sql_set_pos (I<statement_handle>, I<row>, I<orientation>, I<lock>)


  Returns the ODBC API return value.

  $r = $c -> sql_set_pos ($sth, 1, $SQL_POSITION, $SQL_LOCK_NO_CHANGE);

=head2 sql_set_scroll_options (I<statement_handle>, I<concurrency>, I<keyset>, I<rowset>)


Deprecated in ODBC 3.0.

=head2 sql_set_stmt_attr (I<statement_handle>, I<attribute>, I<value>, I<length>)

=head2 sql_special_columns (I<statement_handle>, I<id_type>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<table_name>, I<table_name_length>, I<scope>, I<nullable>)


  Returns the ODBC API return value.

  $r = sql_special_columns ($sth, $SQL_ROWVER, '', 0, '', 0, 'titles', 6,
                            $SQL_SCOPE_CURROW, 0);

=head2 sql_statistics (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<table_name>, I<table_name_length>, I<unique>, I<reserved>)


  Returns the ODBC API return value.

  $r = $c -> sql_statistics ($sth, '', 0, '', 0, '', 0, 1, 1);

=head2 sql_table_privileges (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<table_name>, I<table_name_length>)


  Returns the ODBC API return value.

  $r = $c -> sql_table_privileges ($sth, '', 0, '', 0, '', 0);
    
=head2 sql_tables (I<statement_handle>, I<catalog_name>, I<catalog_name_length>, I<schema_name>, I<schema_name_length>, I<table_name>, I<table_name_length>, I<table_type_name>, I<table_type_name_length>)


  Returns SQL API return value.  ODBC Level 3 drivers can specify
  wildcards.  Calls to sql_fetch and sql_get_data return a result
  set of:

  - Catalog name
  - Schema name
  - Table name
  - Table type
  - Remarks

  # Print the names of all tables of a DSN
  $r = sql_tables ($sth, '', 0, '', 0, '', 0, '' 0);
  while (1) {
     r = $c -> sql_fetch ($sth);
     last if $r == $SQL_NO_DATA;
     ($r, $text, $textlen) = 
       $c -> sql_get_data ($sth, 3, $SQL_C_CHAR, 255);
     if ($r != $SQL_SUCCESS) {
       ($r, $sqlstate, $native, $text, $textlen) = 
         $c -> sql_get_diag_rec ($SQL_HANDLE_STMT, $sth, 1, 255);
       print "Error: [sql_get_data]$text\n";
     } 
     print "$text\n";
  }

=head1 VERSION INFORMATION AND CREDITS

UnixODBC::BridgeServer.pm is part of the UnixODBC package.

Version: 0.25

Written by: Robert Allan Kiesling, rkies@cpan.org.

=head1 SEE ALSO

perl(1), UnixODBC(3), tkdm(1), odbcbridge(1), remotedsn(1), remotetables(1),
RPC::PlServer(3), RPC::PlClient(3). 

=cut

1;
