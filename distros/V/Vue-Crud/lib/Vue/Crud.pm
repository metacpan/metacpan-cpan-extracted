package Vue::Crud;

use strict;
use warnings;
 
use Exporter;
use parent 'Exporter';

#------------------------------------------------------------------------------
#   Mojo DBI 版本信息
#------------------------------------------------------------------------------
our $VERSION = '0.0.1';
our @EXPORT  = qw "vue_crud_get";

#------------------------------------------------------------------------------
# 导出函数到外部，用来适配 VUE CRUD 数据结构
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
  my $name = $params->{"name"} || $params->{"id"};
  my $time = $params->{"createTime"};

  # 处理排序规则
  $sort = join( " ", split( /,/, $sort ) ) if ( $sort =~ /,/ );

  # 计算数据偏移量
  my $offset = $page * $size;

  # 初始化 SQL 语句变量
  my $sql_str   = "SELECT * FROM $table";
  my $order_str = " ORDER BY $sort LIMIT $offset, $size";
  my $time_str  = " create_time BETWEEN  \'$time->[0]\' AND \'$time->[1]\'" if $time || undef;
  my $name_str  = " WHERE name LIKE \'%$name%\'" if $name || undef;

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

=head1 NAME

Vue::Crud - The great new Vue::Crud!

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Vue::Crud;

    my $foo = Vue::Crud->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

WENWU YAN, C<< <careline at 126.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vue-crud at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Vue-Crud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Vue::Crud


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Vue-Crud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Vue-Crud>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Vue-Crud>

=item * Search CPAN

L<https://metacpan.org/release/Vue-Crud>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by WENWU YAN.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut
