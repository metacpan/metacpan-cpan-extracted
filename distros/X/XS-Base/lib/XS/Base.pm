package XS::Base;
use strict;
use warnings;
our @EXPORT_OK = qw(has del def clr dump_json load_json strict_mode);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '1.04';

use Exporter 'import';
require XSLoader;
XSLoader::load('XS::Base', $VERSION);

# strict_mode([$on_off]) -> current_value or set+return
sub strict_mode {
    if (@_) {
        my $v = shift;
        $v = $v ? 1 : 0;
        XS::Base::set_strict_mode($v);
    }
    return XS::Base::get_strict_mode();
}

# dump_json: 从 XS 取到 root 的引用，序列化后释放该引用
sub dump_json {
    require JSON::XS;
    my $root = XS::Base::get_root_ref();    # 返回一个 inc'ed hashref scalar
    eval {
        my $json = JSON::XS->new->utf8->canonical->encode($root);
        XS::Base::_dec_sv($root);           # 释放 XS 返回的引用
        return $json;
    } or do {
        my $err = $@ || "unknown error";
        XS::Base::_dec_sv($root);
        die $err;
    };
}

# load_json: decode 后要求 top-level 是 hashref，并调用 replace_root
sub load_json {
    my ($json) = @_;
    require JSON::XS;
    my $perl_struct = JSON::XS->new->utf8->decode($json);
    unless (ref $perl_struct eq 'HASH') {
        die "load_json requires top-level JSON object (hash)";
    }
    # replace_root 会在 XS 内部加写锁并 shallow-copy 到内部 root
    XS::Base::replace_root($perl_struct);
    return 1;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

XS::Base - C/XS 实现的高效 JSON-like 缓存（支持可配置 strict_mode、并发读写锁）

=head1 SYNOPSIS

  use XS::Base qw(has del def clr);
  my ($key,$value);
  $key = "a";
  $value = 5;
  has $key=>$value;
  def $key=>10;
  
  $key = "a->b";
  $value = {"c"=>6};
  has $key=>$value;
  $value = has("a");
  $value = has("a->b");
  $value = has("a->b->c");
  
  clr();

=head1 DESCRIPTION

B<XS::Base>是进程内（包括线程之间）高效快速的数据共享，支持scalar，array和hash，
也支持主程序和use package之间的全局数据共享。
可以避免大量的全局变量使用，也解决主程序和package之间的数据传递的问题。

=head1 函数说明

=head2 has函数

该函数用于设置缓存/获取缓存参数。

=over

=item 参数key

参数key是存储数据的路径，路径支持多级hash

  my $key = "key1->key2->key3";    # 表示多级hash，$hash->{key1}->{key2}->{key3}

=item 参数value

参数value是存储的数据，可以是scalar，array或者hash

=back

=head2 del函数

  use XS::Base qw(:all);
  my ($key,$def_value);
  del $key=>$def_value;

该函数用于设置设置缓存数据的默认值，如果数据已经存在，则不覆盖（不设置）。

=head2 del函数

  use XS::Base qw(:all);
  del($key);

该函数用于删除节点

=head2 clr函数

该函数用于清空所有数据

=head2 静态变量strict_mode  默认:1

=over

=item 严格模式

当 strict_mode == 1（严格）且在遍历中发现中间节点存在且不是 hashref，则 croak（不覆盖）。

=item 宽松模式

当 strict_mode == 0（宽松）且发现中间节点存在但不是 hashref，则覆盖该中间节点

=back

=cut
