package WebService::KuronekoYamato;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.5');

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;
use Encode;
use WWW::Mechanize;
use Web::Scraper;
use YAML;


# Module implementation here

# コンストラクタ
sub new {
  my $class = shift;
  my $self;
  my $mech = WWW::Mechanize->new();
  $mech->agent_alias( 'Windows IE 6' );
  $mech->get('http://toi.kuronekoyamato.co.jp/cgi-bin/tneko?init');
  $self->{mech} = $mech;
  $self->{user_agent} = __PACKAGE__;
  return bless $self, $class;
}
 
# ヤマト運輸に問い合わせ
sub check {
  my $self    = shift;
  my $numbers = shift; # 荷物問い合わせ番号のリストのリファレンス
  # フォームの問い合わせは10件ごとなので10件ごとのリストのリストにする
  my $list; # 10件ごとに分割されたリストのリストが入る
  my $j = -1; #添え字調整
  foreach ( my $i = 0; $i < $#$numbers + 1; $i++ ) {
    $j++ unless $i % 10;
    push @{$list->[$j]}, $numbers->[$i];
  }
  # _requestを呼んで実際にWebアクセスする
  my $result = [];
  foreach my $item( @$list ) {
    sleep 5 if $#$result != -1; # 2回目のアクセスの前に5秒ウェイト 
    my $res = _request($self, $item);
    push @$result, @$res; # 返答は最大10件なので、$resultにためていく
  }
  return $result; # 集まったリストを返す
}
 
# 実際にリストからアクセスする
sub _request {
  my $self = shift;
  my $list = shift;
  $self->{mech}->form_number(1);
  for ( my $i = 0; $i < $#$list + 1; $i++) {
    my $field = sprintf "number%02d", $i+1;
    $self->{mech}->set_fields( $field => $list->[$i]);
  }
  $self->{mech}->submit;
  
  # Web::Scraper による解析
  my $s = scraper {
    process '//tr/td[2]/input/../../td[3][contains(. , "-")]/..',
    'results[]' => scraper {
      process '//td[3]',
      number => 'TEXT',
      process '//td[4]',
      date => 'TEXT',
      process '//td[5]',
      status => 'TEXT',
    },
  };
  my $res = $s->scrape( 
             $self->{mech}->content() 
            );
  # 得られた結果をリストで返す
  
  my $res2 = [];
  foreach my $item ( @{$res->{results}} ) {
    my $item2 = {};
    foreach my $key ( keys %$item ) {
      $item2->{$key} = encode('utf8', $item->{$key});
    }
    delete $item2->{date} if $item2->{date} eq q();
    $item2->{user_agent} = $self->{user_agent};
    push @$res2, $item2;
  }
  $res->{results} = $res2;
  return $res->{results};
}
 
sub dump {
  my $self = shift;
  print Dump($self);
  return;
}
 
1; # Magic true value required at end of module
__END__


=encoding utf-8

=head1 NAME

WebService::KuronekoYamato - Check Track Shipments (Yamato Transport Co., Ltd. /Japan)


=head1 NAME (ja)

WebService::KuronekoYamato - クロネコヤマトの荷物お問い合わせシステムへ照会するモジュール


=head1 SYNOPSIS

    use WebService::KuronekoYamato;
    
    my $neko = WebService::KuronekoYamato->new();
    
    my $res = $neko->check([
      '000000000001',
      '000000000012',
    ]);
    
    use YAML::Syck;
    print Dump( $res );
    

=head1 DESCRIPTION

「クロネコヤマトの荷物お問い合わせシステム」Webページに、問い合わせ番号を入力し、回答を回収します。


=head1 METHOD
	
=over
	
=item new()

=item check(I<$args>)

=item dump()
	
=back


=head1 DEPENDENCIES

=over

=item L<Encode>

=item L<WWW::Mechanize>

=item L<Web::Scraper>

=item L<YAML>

=back


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-KuronekoYamato@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

OONO Yoshitaka  C<< <aab61120@pop12.odn.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OONO Yoshitaka C<< <aab61120@pop12.odn.ne.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=cut

