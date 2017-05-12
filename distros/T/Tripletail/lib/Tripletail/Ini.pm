# -----------------------------------------------------------------------------
# Tripletail::Ini - 設定ファイルを読み書きする
# -----------------------------------------------------------------------------
package Tripletail::Ini;
use strict;
use warnings;
use File::Basename qw(dirname);

# NOTE: Importing Tripletail here leads to a circular dependency so we
# have to break it by letting Tripletail#newIni to fill this
# package-global variable $TL.
our $TL;

1;

sub _new {
	my $pkg = shift;
	my $this = {};
	bless $this, $pkg;

	$this->{filename} = undef;
	$this->{ini} = {};
	$this->{order} = {};

	if (scalar(@_)) {
		$this->read(@_);
	}

	$this;
}

sub const {
	my $this = shift;
	$this->{const} = 1;
	$this;
}

sub read {
	my $this = shift;
	my $filename = shift;

	%{$this->{ini}} = ();
	%{$this->{order}} = ();
	
	my $fh = $TL->_gensym;
	if(!open($fh, "$filename")) {
		die __PACKAGE__."#read: failed to open a file to read. [$filename] ($!) (ファイルを読めません)\n";
	}

	binmode($fh);
	flock($fh, 1);
	seek($fh, 0, 0);
	my $group = '';
	while(<$fh>) {
		next if(m/^#/);
		s/^\s+//;
		s/\s+$//;
		next if(m/^$/);
		if(m/^\[(.+)\]$/) {
			$group = $1;
		} else {
			my ($key, $value) = split(/\s*=\s*/, $_, 2);
			if(defined($group) && defined($key) && defined ($value)) {
				if(!exists($this->{ini}{$group})) {
					push(@{$this->{order}{group}},$group);
				}
				if(!exists($this->{ini}{$group}{$key})) {
					$this->{ini}{$group}{$key} = $value;
					push(@{$this->{order}{key}{$group}},$key);
				}
			} else {
				die __PACKAGE__."#read: syntax error in the ini. line [$.] (INIファイルの形式が不正です)\n";
			}
		}
	}
	close($fh);

	$this->{filename} = $filename;
	$this;
}

sub write {
	my $this = shift;
	my $filename = shift;

	my $fh = $TL->_gensym;
	if(!open($fh, ">$filename")) {
		die __PACKAGE__."#write: failed to open a file to write. [$filename] ($!) (ファイルに書けません)\n";
	}

	binmode($fh);
	flock($fh, 2);
	seek($fh, 0, 0);
	foreach my $group (@{$this->{order}{group}}) {
		print $fh "[$group]\n";
		foreach my $key (@{$this->{order}{key}{$group}}) {
			print $fh "$key = " . $this->{ini}{$group}{$key} . "\n";
		}
		print $fh "\n";
	}
	close($fh);

	$this;
}

sub existsGroup {
	my $this = shift;
	my $group = shift;
	my $raw = shift;

	if(!defined($group)) {
		die __PACKAGE__."#existsGroup: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($group)) {
		die __PACKAGE__."#existsGroup: arg[1] is a reference. [$group] (第1引数がリファレンスです)\n";
	}

	$group = ($this->_getrawgroupname($group))[0] if(!$raw);

	return 0 if(!defined($group));

	if(exists($this->{ini}{$group})) {
		return 1;
	} else {
		return 0;
	}
}

sub existsKey {
	my $this = shift;
	my $group = shift;
	my $key = shift;
	my $raw = shift;

	if(!defined($group)) {
		die __PACKAGE__."#existsKey: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($group)) {
		die __PACKAGE__."#existsKey: arg[1] is a reference. [$group] (第1引数がリファレンスです)\n";
	}
	if(!defined($key)) {
		die __PACKAGE__."#existsKey: arg[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#existsKey: arg[2] is a reference. [$key] (第2引数がリファレンスです)\n";
	}

	my @group;
	if($raw) {
		push(@group,$group);
	} else {
		@group = $this->_getrawgroupname($group);
	}

	foreach my $groupname (@group) {
		if(exists($this->{ini}{$groupname}{$key})) {
			return 1;
		}
	}

	undef;
}

sub getGroups {
	my $this = shift;
	my $raw = shift;
	
	my @groups;
	
	if($raw) {
		foreach my $group (@{$this->{order}{group}}) {
			push(@groups,$group);
		}
	} else {
		foreach my $group (@{$this->{order}{group}}) {
			$group =~ /^([^:]+)/;
			foreach my $groupname ($this->_getrawgroupname($1)) {
				$groupname =~ /^([^:]+)/;
				push(@groups,$1);
			}
		}
	}

	@groups;
}

sub getKeys {
	my $this = shift;
	my $group = shift;
	my $raw = shift;

	if(!defined($group)) {
		die __PACKAGE__."#getKeys: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($group)) {
		die __PACKAGE__."#getKeys: arg[1] is a reference. [$group] (第1引数がリファレンスです)\n";
	}

	my @group;
	if($raw) {
		push(@group,$group);
	} else {
		@group = $this->_getrawgroupname($group);
	}

	my @result;
	my %occurence;
	foreach my $groupname (@group) {
		foreach my $key (@{$this->{order}{key}{$groupname}}) {
			if(!$occurence{$key}) {
				push(@result,$key);
				$occurence{$key} = 1;
			}
		}
	}

	@result;
}

sub get {
	my $this    = shift;
	my $group   = shift;
	my $key     = shift;

	if(!defined($group)) {
		die __PACKAGE__."#get: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($group)) {
		die __PACKAGE__."#get: arg[1] is a reference. [$group] (第1引数がリファレンスです)\n";
	}
	if(!defined($key)) {
		die __PACKAGE__."#get: arg[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#get: arg[2] is a reference. [$key] (第2引数がリファレンスです)\n";
	}

    my $default_ref = do {
        if (@_) {
            \(shift);
        }
        else {
            undef;
        }
    };

    my @group = do {
        if (@_) {
            my $raw = shift;
            if ($raw) {
                $group;
            }
            else {
                $this->_getrawgroupname($group);
            }
        }
        else {
            $this->_getrawgroupname($group);
        }
    };

	my $result;
	foreach my $groupname (@group) {
		if(exists($this->{ini}{$groupname}) && exists($this->{ini}{$groupname}{$key})) {
			$result = $this->{ini}{$groupname}{$key};
			last;
		}
	}

    if (defined $result) {
        return $result;
    }
    elsif (defined $default_ref) {
        return $$default_ref;
    }
    else {
        my $undef_if_absent = $TL->INI->get(Ini => treat_absent_values_as_undef => 'false');
        if ($undef_if_absent eq 'true') {
            return;
        }
        else {
            die __PACKAGE__."#get: Either group [$group] or key [$key] is absent but no default values are provided (file=".(defined($this->{filename})?$this->{filename}:"-").")".
              " (グループ [$group] もしくはキー [$key] が存在しない上に、デフォルト値も与えられていませんでした。)";
        }
    }
}

sub get_reloc
{
  my $this = shift;
  my $value = $this->get(@_);
  if( $value && $this->{filename} )
  {
    $value =~ s{^\.{3}(?=$|/)}{dirname($this->{filename})}e;
  }
  $value;
}

sub set {
	my $this = shift;
	my $group = shift;
	my $key = shift;
	my $value = shift;
	my $raw = shift;

	if(exists($this->{const})) {
		die __PACKAGE__."#set: This instance is a const object. (このIniオブジェクトの内容は変更できません)\n";
	}

	if(!defined($group)) {
		die __PACKAGE__."#set: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($group)) {
		die __PACKAGE__."#set: arg[1] is a reference. [$group] (第1引数がリファレンスです)\n";
	}
	if(!defined($key)) {
		die __PACKAGE__."#set: arg[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#set: arg[2] is a reference. [$key] (第2引数がリファレンスです)\n";
	}
	if(!defined($value)) {
		die __PACKAGE__."#set: arg[3] is not defined. (第3引数が指定されていません)\n";
	} elsif(ref($value)) {
		die __PACKAGE__."#set: arg[2] is a reference. [$value] (第2引数がリファレンスです)\n";
	}
	if($group =~ m/[\x00-\x1f]/) {
		die __PACKAGE__."#set: arg[1]: contains a control code. (第1引数にコントロールコードが含まれています)\n";
	}
	if($key =~ m/[\x00-\x1f]/) {
		die __PACKAGE__."#set: arg[2]: contains a control code. (第2引数にコントロールコードが含まれています)\n";
	}
	if($value =~ m/[\x00-\x1f]/) {
		die __PACKAGE__."#set: arg[3]: contains a control code. (第3引数にコントロールコードが含まれています)\n";
	}
	if($group =~ m/^\s+/ or $group =~ m/\s+$/) {
		die __PACKAGE__."#set: arg[1]: the argument is not allowed to have preceding or trailing spaces. (第1引数の前後にスペースが含まれています)\n";
	}
	if($key =~ m/^\s+/ or $key =~ m/\s+$/) {
		die __PACKAGE__."#set: arg[2]: the argument is not allowed to have preceding or trailing spaces. (第2引数の前後にスペースが含まれています)\n";
	}
	if($value =~ m/^\s+/ or $value =~ m/\s+$/) {
		die __PACKAGE__."#set: arg[3]: the argument is not allowed to have preceding or trailing spaces. (第3引数の前後にスペースが含まれています)\n";
	}

	if(!$raw) {
		my @group = $this->_getrawgroupname($group);
		$group = $group[0] if(defined($group[0]) && $group[0] ne '');
	}

	if(!exists($this->{ini}{$group})) {
		push(@{$this->{order}{group}},$group);
	}
	if(!exists($this->{ini}{$group}{$key})) {
		push(@{$this->{order}{key}{$group}},$key);
	}
	$this->{ini}{$group}{$key} = $value;

	$this;
}

sub delete {
	my $this = shift;
	my $group = shift;
	my $key = shift;
	my $raw = shift;

	if(exists($this->{const})) {
		die __PACKAGE__."#delete, This instance is const object.\n";
	}

	if(!defined($group)) {
		die __PACKAGE__."#delete: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($group)) {
		die __PACKAGE__."#delete: arg[1] is a reference. [$group] (第1引数がリファレンスです)\n";
	}
	if(!defined($key)) {
		die __PACKAGE__."#delete: arg[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#delete: arg[2] is a reference. [$key] (第2引数がリファレンスです)\n";
	}

	my @group;
	if($raw) {
		push(@group,$group);
	} else {
		@group = $this->_getrawgroupname($group);
	}

	foreach my $groupname (@group) {
		delete $this->{ini}{$groupname}{$key};
	}


	$this;
}

sub deleteGroup {
	my $this = shift;
	my $group = shift;
	my $raw = shift;

	if(exists($this->{const})) {
		die __PACKAGE__."#delete, This instance is a const object.\n";
	}

	if(!defined($group)) {
		die __PACKAGE__."#delete: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($group)) {
		die __PACKAGE__."#delete: arg[1] is a reference. [$group] (第1引数がリファレンスです)\n";
	}

	my @group;
	if($raw) {
		push(@group,$group);
	} else {
		@group = $this->_getrawgroupname($group);
	}

	foreach my $groupname (@group) {
		delete $this->{ini}{$groupname};
	}

	$this;
}

sub _filename {
	my $this = shift;
	$this->{filename};
}

#特化指定やIPアドレス指定に適合しているグループを全て返す
sub _getrawgroupname {
	my $this = shift;
	my $group = shift;
	
	my @group;
	foreach my $spec (@Tripletail::specialization, '') {
		my $groupname = (length $spec ? "$group:$spec" : $group);
		foreach my $rawgroup ($this->getGroups(1)) {
			next if(!defined($rawgroup));
			if($rawgroup =~ m/^([^\@]+)/) {
				next if($groupname ne $1);
				my $matchflag = 1;
				if($rawgroup =~ m/\@server:([^\@:]+)/){
					$matchflag = 0;
					my $servermask = $this->get('HOST' => $1,undef,1);
					if(defined($servermask)) {
						my $server = $ENV{SERVER_ADDR};
						if(!defined($server)){
							# ipaddress of host.
							$server = $TL->_readcmd("hostname -i 2>&1");
							$server = $server && $server =~ /^\s*([0-9.]+)\s*$/ ? $1 : undef;
						}
						if(defined($server)) {
							if($TL->newValue->set($server)->isIpAddress($servermask)) {
								$matchflag = 1;
							}
						}
					}
				}
				if($matchflag == 1 && $rawgroup =~ m/\@remote:([^\@:]+)/){
					$matchflag = 0;
					my $remotemask = $this->get('HOST' => $1,undef,1);
					if(defined($remotemask)) {
						if(my $remote = $ENV{REMOTE_ADDR}) {
							if($TL->newValue->set($remote)->isIpAddress($remotemask)) {
								$matchflag = 1;
							}
						}
					}
				}
				if($matchflag == 1) {
					push(@group,$rawgroup);
				}
			}
		}
	}
	@group;
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::Ini - 設定ファイルを読み書きする

=head1 SYNOPSIS

  my $ini = $TL->newIni('foo.ini');

  print $ini->get(Group1 => 'Key1');

  $ini->set(Group2 => 'Key1' => 'value');
  $ini->write('bar.ini');

=head1 DESCRIPTION

以下のような設定ファイルを読み書きする。

  [HOST]
  Debughost = 192.168.10.0/24
  Testuser = 192.168.11.5 192.168.11.50
  [TL@server:Debughost]
  logdir = /home/tl/logs
  errormail = tl@example.org
  [TL:regist@server:Debughost]
  logdir = /home/tl/logs/regist
  [TL]
  logdir = /home/tl/logs
  errormail = tl@example.org
  [TL:regist]
  logdir = /home/tl/logs/regist
  [Debug@remote:Testuser]
  enable_debug=1
  [Group]
  Key=Value
  [DB]
  Type=MySQL
  host=1.2.3.4
  [Cookie]
  expire=30day
  domain=.ymir.jp
  [Smtp]
  host=localhost

=over 4

=item TLのuse及び特化指定も参照する事

=item グループ名には "[" "]" 制御文字(0x00-0x20,0x7f,0x80-0x9f,0xff) 以外の半角英数字が使用可能。

=item 全て大文字のグループ名は予約語の為、任意のグループ名としては使用は出来ない。

=item グループ名の"@" ":"は特化指定用の文字となる為、任意のグループ名には使用は出来ない。

=item 空行は無視する

=item # で始まる行はコメントになる（writeを使用し書き出した場合、コメント行は反映されない）

=item 連続行は対応しない

=item 同じグループ名を複数記述した場合、一つのグループとして扱われる

=item 同一項目は最初に書かれた物が有効になる（特化指定を使っている場合も同様であるため、通常は特化指定は非特化指定グループより先に書く必要性がある）

=item 特化指定は グループ名:名称@server:Servermask@remote:Remotemask の順番で記述する必要性がある

=item 初期にC<use>で指定されるiniファイル以外のiniファイルにもC<use>で指定した特化指定が有効となる

=item HOSTグループには、特化指定は使用できない

=back


=head2 METHODS

=over 4

=item C<< $TL->newIni >>

  $TL->newIni
  $TL->newIni($filename)

Tripletail::Ini オブジェクトを作成。
設定ファイルを指定してあればreadメソッドで読み込む。

=item C<< read >>

  $ini->read($filename)

指定した設定ファイルを読み込む。

=item C<< write >>

  $ini->write($filename)

指定した設定ファイルに書き込む。
自動的に読み込まれる$INIに関しては書き込みは出来ない。
コメント行に関しては書き込まれないので注意が必要である。

=item C<< existsGroup >>

  $bool = $ini->existsGroup($group, $raw)

グループの存在を確認する。存在すれば1、しなければundefを返す。
$rawに1を指定した場合、特化指定を含んだグループ文字列で存在を確認する。

=item C<< existsKey >>

  $bool = $ini->existsKey($group => $key, $raw)

指定グループのキーの存在を確認する。存在すれば1、しなければundefを返す。
$rawに1を指定した場合、特化指定を含んだグループ文字列で存在を確認する。

=item C<< getGroups >>

  @groups = $ini->getGroups($raw)

グループ一覧を配列で返す。
$rawに1を指定した場合、特化指定を含んだグループ文字列で一覧を返す。

=item C<< getKeys >>

  @keys = $ini->getKeys($group, $raw)

グループのキー一覧を配列で返す。グループがなければ空配列を返す。
$rawに1を指定した場合、特化指定を含んだグループ文字列で確認し一覧を返す。

=item C<< get >>

  $val = $ini->get($group => $key, $default, $raw)

指定されたグループ・キーの値を返す。グループorキーがなければ$defaultで指定された値を返す。
$defaultが指定されなかった場合は die で例外を送出する。
$rawに1を指定した場合、特化指定を含んだグループ文字列で確認し値を返す。

$default は undef であっても構わない。

このメソッドはかつて $default が無く且つ値も存在しなければ undef を返していた。
その時の動作に基いて書かれた既存のコードとの互換性を得るためのオプションが存在する。
詳しくは L<"Ini パラメータ"> を参照。

=item C<< get_reloc >>

  $val = $ini->get_reloc($group => $key, $default, $raw)

指定されたグループ・キーの値を返す。
基本的な動作及び引数は L</get> と同様だが、値が C<.../> で始まるとき(若しくはC<...>そのものの時)に、 C<...> 部分を ini ファイルのディレクトリ名で置き換える。
(L</read> 以外で生成された Ini インスタンスの時は、この情報を持たないため処理されない。)

0.46 以降で利用可能。

=item C<< set >>

  $ini->set($group => $key => $value, $raw)

指定されたグループ・キーの値を設定する。グループがなければ作成される。
$rawに1を指定した場合、特化指定を含んだグループ文字列で作成する。
指定しない場合、現在利用可能な最も上位のグループに設定される。

=item C<< const >>

  $ini->const

このメソッドを呼び出すと、以後データの変更は不可能となる。

=item C<< delete >>

  $ini->delete($group => $key, $raw)

指定されたグループ・キーの値を削除する。
$rawに1を指定した場合、特化指定を含んだグループ文字列で確認し削除する。

=item C<< deleteGroup >>

  $ini->deleteGroup($group, $raw)

指定されたグループを削除する。
$rawに1を指定した場合、特化指定を含んだグループ文字列で確認し削除する。

=back


=head2 Ini パラメータ

Tripletail::Ini クラス自体の動作を設定するためのパラメータ。

C<< use Tripletail qw(foo.ini); >> に与えられたシステム設定用 ini
ファイルに書かれたものが参照される。

グループ名は "Ini" とする。例:

  [Ini]
  treat_absent_values_as_undef = true

=over 4

=item C<< treat_absent_values_as_undef >>

  tread_absent_values_as_undef = true

非推奨オプション。true を指定した場合、
L<< get >> メソッドにデフォルト値が与えられていないのに要求したキーに対する値が存在した場合に
die することなく undef を返す。

=back


=head1 SEE ALSO

L<Tripletail>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
