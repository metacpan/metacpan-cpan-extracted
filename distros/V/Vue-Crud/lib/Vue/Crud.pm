package Vue::Crud;

use 5.012;
use strict;
use warnings;

use Exporter;
use parent 'Exporter';

#------------------------------------------------------------------------------
#   Mojo DBI 版本信息
#------------------------------------------------------------------------------
our $VERSION = '0.0.6';
our @EXPORT  = qw "vue_crud_get vue_crud_query";

#------------------------------------------------------------------------------
# 导出函数到外部，用来适配 VUE CRUD 数据结构 -- 模糊查询 postgresql
#------------------------------------------------------------------------------
sub vue_crud_query {
  # 接收外部入参 - 前端查询变量 和 查询对象
  my $params = shift;
  my $table  = shift;

  # 截取前端哈希长度
  my $length = scalar( keys %{$params} );

  # 获取前端入参
  my $page = $params->{"page"} || 0;
  my $size = $params->{"size"} || 10;
  my $sort = $params->{"sort"} || "id desc";

  # 提取 query 字段变量
  my $time      = $params->{"create_time"};
  my @query     = grep { !/page|size|sort|create_time/ } ( keys %{$params} );
  my $query_str = $params->{ $query[0] } if @query;

  # 处理排序规则
  $sort = join( " ", split( /,/, $sort ) ) if ( $sort =~ /,/ );

  # 计算数据偏移量
  my $offset = $page * $size;

  # 初始化 SQL 语句变量
  my $query_attr = $query[0] . "\\:\\:varchar";
  my $sql_str    = "SELECT * FROM $table";
  my $count_str  = "SELECT count(*) AS count FROM $table";
  my $order_str  = " ORDER BY $sort OFFSET $offset LIMIT $size";
  my $name_str   = " WHERE $query_attr LIKE \'%$query_str%\'" if defined $query_str;
  my $time_str   = " create_time BETWEEN \'$time->[0]\' AND \'$time->[1]\'" if $time;

  # 对数据进行判断
  my ( $rev, $ret, $cnt );
  if ( $length == 3 ) {
    $rev = $sql_str . $order_str;
    $cnt = $count_str;
  }
  elsif ( $length == 4 ) {
    if ($name_str) {
      $rev = $sql_str . $name_str . $order_str;
      $cnt = $count_str . $name_str;
    }
    elsif ($time_str) {
      $rev = $sql_str . " WHERE" . $time_str . $order_str;
      $cnt = $count_str . " WHERE" . $time_str;
    }
  }
  elsif ( $length == 5 ) {
    $rev = $sql_str . $name_str . " AND" . $time_str . $order_str;
    $cnt = $count_str . $name_str . " AND" . $time_str;
  }

  # 返回计算结果
  push @{$ret}, $rev;
  push @{$ret}, $cnt;

  return $ret;
}

#------------------------------------------------------------------------------
# 导出函数到外部，用来适配 VUE CRUD 数据结构 -- 精确匹配 postgresql
#------------------------------------------------------------------------------
sub vue_crud_get {
  # 接收外部入参 - 前端查询变量 和 查询对象
  my $params = shift;
  my $table  = shift;

  # 截取前端哈希长度
  my $length = scalar( keys %{$params} );

  # 获取前端入参
  my $page = $params->{"page"} || 0;
  my $size = $params->{"size"} || 10;
  my $sort = $params->{"sort"} || "id desc";

  # 提取 query 字段变量
  my $time      = $params->{"create_time"};
  my @query     = grep { !/page|size|sort|create_time/ } ( keys %{$params} );
  my $query_str = $params->{ $query[0] } if @query;

  # 处理排序规则
  $sort = join( " ", split( /,/, $sort ) ) if ( $sort =~ /,/ );

  # 计算数据偏移量
  my $offset = $page * $size;

  # 初始化 SQL 语句变量
  my $sql_str   = "SELECT * FROM $table";
  my $count_str = "SELECT count(*) AS count FROM $table";
  my $order_str = " ORDER BY $sort OFFSET $offset LIMIT $size";
  my $name_str  = " WHERE $query[0] = $query_str" if defined $query_str;
  my $time_str  = " create_time BETWEEN  \'$time->[0]\' AND \'$time->[1]\'" if $time;

  # 对数据进行判断
  my ( $rev, $ret, $cnt );
  if ( $length == 3 ) {
    $rev = $sql_str . $order_str;
    $cnt = $count_str;
  }
  elsif ( $length == 4 ) {
    if ($name_str) {
      $rev = $sql_str . $name_str . $order_str;
      $cnt = $count_str . $name_str;
    }
    elsif ($time_str) {
      $rev = $sql_str . " WHERE" . $time_str . $order_str;
      $cnt = $count_str . " WHERE" . $time_str;
    }
  }
  elsif ( $length == 5 ) {
    $rev = $sql_str . $name_str . " AND" . $time_str . $order_str;
    $cnt = $count_str . $name_str . " AND" . $time_str;
  }

  # 返回计算结果
  push @{$ret}, $rev;
  push @{$ret}, $cnt;

  return $ret;
  return $ret;
}

1;
