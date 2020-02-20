package Vue::Crud;

use strict;
use warnings;

use Exporter;
use parent 'Exporter';

#------------------------------------------------------------------------------
#   Mojo DBI 版本信息
#------------------------------------------------------------------------------
our $VERSION = '0.0.3';
our @EXPORT  = qw "vue_crud_get";

#------------------------------------------------------------------------------
# 导出函数到外部，用来适配 VUE CRUD 数据结构 -- 语句适配 postgresql
#------------------------------------------------------------------------------
sub vue_crud_get {
  # 接收外部入参 - 前端查询变量 和 查询对象
  my $params = shift;
  my $table  = shift;

  # 截取前端哈希长度
  my $count = scalar( keys %{$params} );

  # 获取前端入参
  my $page = $params->{"page"} || 0;
  my $size = $params->{"size"} || 10;
  my $sort = $params->{"sort"} || "id desc";

  # 提取 query 字段变量
  my $time      = $params->{"createTime"};
  my $query     = grep { !/page|size|sort|createTime/ } ( keys %{$params} );
  my $query_str = $params->{$query} if defined $query;

  # 处理排序规则
  $sort = join( " ", split( /,/, $sort ) ) if ( $sort =~ /,/ );

  # 计算数据偏移量
  my $offset = $page * $size;

  # 初始化 SQL 语句变量
  my $sql_str   = "SELECT * FROM $table";
  my $order_str = " ORDER BY $sort OFFSET $offset LIMIT $size";
  my $name_str  = " WHERE $query LIKE \'%$query_str%\'" if defined $query_str;
  my $time_str  = " create_time BETWEEN  \'$time->[0]\' AND \'$time->[1]\'" if $time;

  # 对数据进行判断
  if ( $count == 3 ) {
    return $sql_str . $order_str;
  }
  elsif ( $count == 4 ) {
    if ($name_str) {
      return $sql_str . $name_str . $order_str;
    }
    elsif ($time_str) {
      return $sql_str . " WHERE" . $time_str . $order_str;
    }
  }
  elsif ( $count == 5 ) {
    return $sql_str . $name_str . " AND" . $time_str . $order_str;
  }
}

1;
