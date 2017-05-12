package WWW::SuperMan;
use Slurp;
use JSON;
use LWP::UserAgent;

our $VERSION = 0.01;

sub new {
  my($class, %cnf) = @_;
  my $self = bless {
    user => $cnf{ user },
    pass => $cnf{ pass },
    ua => LWP::UserAgent->new,
  }, $class;

  return $self;
}
sub getUserInfo {
  my ( $self ) = @_;
  my $url = 'http://api2.sz789.net:88/GetUserInfo.ashx';

  my $res = $self->{ ua }->post( $url, {
      username => $self->{user},
      password => $self->{ pass }
    }
  );

  return {} unless $res->is_success;
  return _deJson( $res );
}

sub getCode {
  my ( $self, $img_file ) = @_;
  my $url = 'http://api2.sz789.net:88/RecvByte.ashx';

  my $file = slurp( $img_file );
  my $b = unpack("H*" , $file );

  my $post = {
    username => $self->{ user },
    password => $self->{ pass },
    imgdata => $b,
    softId => '16635',
  };

  my $res = $self->{ua}->post( $url, $post );
  return {} unless $res->is_success;

  return _deJson( $res );
}


sub _deJson {
  my $res = shift;
  my $json = $res->content;
  eval {
    $json = from_json( $json );
  };

  return {} if $@;
  return $json;
}

1;

__END__
=head1 NAME

WWW::SuperMan - Perl interface to www.qqchaoren.com
使用QQ超人的验证码代打服务

=head1 SYNOPSIS

 # Functional style
 use WWW::SuperMan;

 my $sm = WWW::SuperMan->new( user => 'foo', pass => 'bar' );

 my $account_info = $sm->getUserInfo();
 # $account_info it's a hashref
 # $account_info->{ left };  # 剩余点数
 # $account_info->{ today }; # 今日消耗点数
 # $account_info->{ total }; # 总消耗点数

 my $vcode = $sm->getCode( '/path/to/file' );
 # $vcode also a hasref too,
 # $vcode->{ info };   # 识别状态:
 #  0 => 超时无人打码,
 #  1 => 成功,
 #  -1 => 识别失败,超时或者没有传放正确的参数或其它原因
 #  -2 => 余额不足
 #  -3 => 未绑定或者未在绑定机器上运行
 #  -4 => 时间过期
 #  -5 => 时间过期
 #  -6 => 文件格式错误,不是图片格式

 # $vcode->{ result }; # 验证码识别结果
 # $vcode->{ imgId };  # 验证码ID

 if ( $vccode->{ info } == 1 ) {
  print $vcode->{ result }; # 正真验证码
 }

=head1 DESCRIPTION

C<WWW::SuperMan> 使用QQ超人的人工代打码服务, 破解某些网站的验证码.

仅提供学习娱乐使用, 请勿非法用途.

=head1 INCLUDE MODULES

L<JSON>,
L<Slurp>,
L<LWP::UserAgent>,

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

 Copyright 1998-2003 Gisle Aas.
 Copyright 1995-1996 Neil Winton.
 Copyright 1991-1992 RSA Data Security, Inc.

The MD5 algorithm is defined in RFC 1321. This implementation is
derived from the reference C code in RFC 1321 which is covered by
the following copyright statement:

=over 4

=item

Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
rights reserved.

License to copy and use this software is granted provided that it
is identified as the "RSA Data Security, Inc. MD5 Message-Digest
Algorithm" in all material mentioning or referencing this software
or this function.

License is also granted to make and use derivative works provided
that such works are identified as "derived from the RSA Data
Security, Inc. MD5 Message-Digest Algorithm" in all material
mentioning or referencing the derived work.

RSA Data Security, Inc. makes no representations concerning either
the merchantability of this software or the suitability of this
software for any particular purpose. It is provided "as is"
without express or implied warranty of any kind.

These notices must be retained in any copies of any part of this
documentation and/or software.

=back

This copyright does not prohibit distribution of any version of Perl
containing this extension under the terms of the GNU or Artistic
licenses.

=head1 AUTHORS

The C<WWW::SuperMan> module is written by Gisle Aas <mc.cheung@aol.com>.

=cut
