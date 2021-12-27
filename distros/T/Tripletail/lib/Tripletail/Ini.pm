# -----------------------------------------------------------------------------
# Tripletail::Ini - 設定ファイルを読み書きする
# -----------------------------------------------------------------------------
package Tripletail::Ini;
use strict;
use warnings;
use File::Basename qw(dirname);
use Fcntl qw(LOCK_EX LOCK_SH);
use Tripletail::Ini::Group;

# NOTE: Importing Tripletail here leads to a circular dependency so we
# have to break it.
my $TL = $Tripletail::TL;

my $re_annotated_group
  = qr{
          ([^:@]+)             # base name
          (?:
              :
              ([^:@]+?)         # variant tag
          )?
          (?:
              \@server:([^:@]+?) # local-host constraint
          )?
          (?:
              \@remote:([^:@]+?) # remote-host constraint
          )?
  }x;

my $re_group_start
  = qr{
          \[ ($re_annotated_group) \]
  }x;

my $re_key_value_pair
  = qr{
          (.+?)             # key
          \s* = \s*
          (.*?)             # value
  }x;

1;

sub __setEnabledTags {
    my $pkg = shift;

    Tripletail::Ini::Group::Annotation->setEnabledTags(@_);

    return;
}

sub _parseAnnotatedGroup {
    my $pkg = shift;
    my $str = shift;

    if ($str =~ m/^$re_annotated_group$/o) {
        my ($base, $tag, $local, $remote) = ($1, $2, $3, $4);
        my $anno = Tripletail::Ini::Group::Annotation->new($2, $3, $4);

        return ($base, $anno);
    }
    else {
        return;
    }
}

use fields qw(group_for groups is_const file_path);
sub _new {
    my Tripletail::Ini $this = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{group_for} = {};    # {basename => Group}
    $this->{groups   } = [];    # [Group]
    $this->{is_const } = undef;
    $this->{file_path} = undef;

    if (scalar @_) {
        $this->read(@_);
    }

    return $this;
}

sub const {
    my Tripletail::Ini $this = shift;

    $this->{is_const} = 1;

    return $this;
}

sub getFilePath {
    my Tripletail::Ini $this = shift;

    if (defined $this->{file_path}) {
        return $this->{file_path};
    }
    else {
        return;
    }
}

sub read {
    my Tripletail::Ini $this = shift;
    my $fpath                = shift;

    if (!defined $fpath) {
        die __PACKAGE__."#read: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    if ($this->{is_const}) {
        die __PACKAGE__."#read: This object is marked as a constant. ".
          "(このIniオブジェクトの内容は変更できません)\n";
    }

    $this->_clear();

    open my $fh, '<', $fpath
      or
        die __PACKAGE__."#read: failed to open the file to read. [$fpath] ".
          "($!) (ファイルを読めません)\n";

    flock $fh, LOCK_SH
      or
        die __PACKAGE__."#read: failed to acquire a shared lock on file. ".
          "[$fpath] ($!) (ファイルの共有ロックに失敗しました)\n";

    binmode $fh
      or
        die __PACKAGE__."#read: failed to change the mode of file handle. ".
          "[$fpath] ($!) (ファイルのバイナリモード変更に失敗しました)\n";

    my Tripletail::Ini::Group::Variant $variant;
    while (defined(my $line = <$fh>)) {
        next if $line =~ m/^#/;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if !length $line;

        if ($line =~ m/^$re_group_start$/o and
              my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($1)) {

            my $group = $this->_touchGroup($base);
            $variant  = $group->touchVariant($anno);
        }
        elsif ($line =~ m/^$re_key_value_pair$/o and defined $variant) {
            $variant->set($1 => $2);
        }
        else {
            die __PACKAGE__."#read: syntax error at line ${.}. [$line] ".
              "(INIファイルの形式が不正です)\n";
        }
    }

    $this->{file_path} = $fpath;
    return $this;
}

sub write {
    my Tripletail::Ini $this = shift;
    my $fpath                = shift;

    if (!defined $fpath) {
        die __PACKAGE__."#write: arg[1] is not defined. (第1引数が指定されていません)\n";
    }

    open my $fh, '>', $fpath
      or
        die __PACKAGE__."#write: failed to open the file to write. ".
          "[$fpath] ($!) (ファイルに書けません)\n";

    flock $fh, LOCK_EX
      or
        die __PACKAGE__."#write: failed to acquire an exclusive lock on file. ".
          "[$fpath] ($!) (ファイルの排他的ロックに失敗しました)\n";

    binmode $fh
      or
        die __PACKAGE__."#write: failed to change the mode of file handle. ".
          "[$fpath] ($!) (ファイルのバイナリモード変更に失敗しました)\n";

    my $is_first = 1;
    foreach my Tripletail::Ini::Group $group (@{ $this->{groups} }) {
        if ($is_first) {
            $is_first = undef;
        }
        else {
            print {$fh} "\n";
        }

        print {$fh} $group->toStr;
    }

    return $this;
}

sub _clear {
    my Tripletail::Ini $this = shift;

    %{ $this->{group_for} } = ();
    @{ $this->{groups   } } = ();
    $this->{file_path}      = undef;

    return $this;
}

sub _touchGroup {
    my Tripletail::Ini $this = shift;
    my $base                 = shift;

    if (exists $this->{group_for}{$base}) {
        return $this->{group_for}{$base};
    }
    else {
        my $group = Tripletail::Ini::Group->new($base);

        $this->{group_for}{$base} = $group;
        push @{ $this->{groups} }, $group;

        return $group;
    }
}

sub existsGroup {
    my Tripletail::Ini $this = shift;
    my $name                 = shift;
    my $raw                  = shift;

    if (!defined $name) {
        die __PACKAGE__."#existsGroup: arg[1] is not defined. ".
          "(第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#existsGroup: arg[1] is a reference. [$name] ".
          "(第1引数がリファレンスです)\n";
    }

    if ($raw) {
        if (my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($name)) {
            if (exists $this->{group_for}{$base}) {
                if ($this->{group_for}{$base}->hasVariant($anno)) {
                    return 1;
                }
            }
        }
    }
    elsif (exists $this->{group_for}{$name}) {
        my $hosts = $this->{group_for}{HOST};

        if ($this->{group_for}{$name}->filterVariants($hosts)) {
            return 1;
        }
    }

    return;
}

sub existsKey {
    my Tripletail::Ini $this = shift;
    my $name                 = shift;
    my $key                  = shift;
    my $raw                  = shift;

    if (!defined $name) {
        die __PACKAGE__."#existsKey: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#existsKey: arg[1] is a reference. [$name] ".
          "(第1引数がリファレンスです)\n";
    }
    if (!defined $key) {
        die __PACKAGE__."#existsKey: arg[2] is not defined. (第2引数が指定されていません)\n";
    }
    elsif (ref $key) {
        die __PACKAGE__."#existsKey: arg[2] is a reference. [$key] ".
          "(第2引数がリファレンスです)\n";
    }

    if ($raw) {
        if (my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($name)) {
            if (exists $this->{group_for}{$base}) {
                my $variant = $this->{group_for}{$base}->getVariant($anno);

                if (defined $variant and $variant->exists($key)) {
                    return 1;
                }
            }
        }
    }
    elsif (exists $this->{group_for}{$name}) {
        my $hosts    = $this->{group_for}{HOST};
        my @variants = $this->{group_for}{$name}->filterVariants($hosts);

        foreach my $variant (@variants) {
            if ($variant->exists($key)) {
                return 1;
            }
        }
    }

    return;
}

sub getGroups {
    my Tripletail::Ini $this = shift;
    my $raw                  = shift;

    my $hosts = $this->{group_for}{HOST};
    my @names;
    foreach my $group (@{ $this->{groups} }) {
        if ($raw) {
            foreach my $variant ($group->variants) {
                push @names, $group->basename . $variant->annotation;
            }
        }
        elsif ($group->filterVariants($hosts)) {
            push @names, $group->basename;
        }
    }

    return @names;
}

sub getKeys {
    my Tripletail::Ini $this = shift;
    my $name                 = shift;
    my $raw                  = shift;

    if (!defined $name) {
        die __PACKAGE__."#getKeys: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#getKeys: arg[1] is a reference. [$name] ".
          "(第1引数がリファレンスです)\n";
    }

    if ($raw) {
        if (my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($name)) {
            if (exists $this->{group_for}{$base}) {
                my $variant = $this->{group_for}{$base}->getVariant($anno);

                if (defined $variant) {
                    return $variant->keys;
                }
            }
        }
    }
    elsif (exists $this->{group_for}{$name}) {
        my $hosts    = $this->{group_for}{HOST};
        my @variants = $this->{group_for}{$name}->filterVariants($hosts);

        my @keys;
        my %seen;
        foreach my $variant (@variants) {
            foreach my $key ($variant->keys) {
                if (!exists $seen{$key}) {
                    push @keys, $key;
                    $seen{$key} = 1;
                }
            }
        }
        return @keys;
    }

    return;
}

sub get {
    my Tripletail::Ini $this = shift;
    my $name                 = shift;
    my $key                  = shift;
    my $default_ref          = @_ ? \shift : undef;
    my $raw                  = shift;

    if (!defined $name) {
        die __PACKAGE__."#get: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#get: arg[1] is a reference. [$name] ".
          "(第1引数がリファレンスです)\n";
    }
    if (!defined $key) {
        die __PACKAGE__."#get: arg[2] is not defined. (第2引数が指定されていません)\n";
    }
    elsif (ref $key) {
        die __PACKAGE__."#get: arg[2] is a reference. [$key] (第2引数がリファレンスです)\n";
    }

    my @variants;
    if ($raw) {
        if (my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($name)) {
            my $variant = $this->{group_for}{$base}->getVariant($anno);

            if (defined $variant) {
                @variants = ($variant);
            }
        }
    }
    elsif (exists $this->{group_for}{$name}) {
        my $hosts = $this->{group_for}{HOST};
        @variants = $this->{group_for}{$name}->filterVariants($hosts);
    }

    foreach my $variant (@variants) {
        if (defined(my $value = $variant->get($key))) {
            return $value;
        }
    }

    if (defined $default_ref) {
        return $$default_ref;
    }
    else {
        my $undef_if_absent
          = $TL->INI->get(Ini => treat_absent_values_as_undef => 'false');

        if ($undef_if_absent eq 'true') {
            return;
        }
        else {
            die sprintf(
                    "%s#get: Either group [%s] or key [%s] is ".
                      "absent but no default value is given (file: %s) ".
                        "(グループ [%s] もしくはキー [%s] が存在しない上に、デフォルト値も与えられていませんでした。)\n",
                    __PACKAGE__, $name, $key,
                    defined $this->{file_path} ? $this->{file_path} : '-',
                    $name, $key
                   );
        }
    }
}

sub get_reloc {
    my Tripletail::Ini $this = shift;
    my $value                = $this->get(@_);

    if (defined $value) {
        if (defined $this->{file_path}) {
            $value =~ s{^\.{3}(?=$|/)}{
                dirname $this->{file_path}
            }e;
        }
        return $value;
    }
    else {
        return;
    }
}

sub set {
    my Tripletail::Ini $this = shift;
    my $name                 = shift;
    my $key                  = shift;
    my $value                = shift;
    my $raw                  = shift;

    if ($this->{is_const}) {
        die __PACKAGE__."#set: This object is marked as a constant. ".
          "(このIniオブジェクトの内容は変更できません)\n";
    }

    if (!defined $name) {
        die __PACKAGE__."#set: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#set: arg[1] is a reference. [$name] ".
          "(第1引数がリファレンスです)\n";
    }
    elsif ($name =~ m/[\x00-\x1f]/) {
        die __PACKAGE__."#set: arg[1]: contains a control code. ".
          "(第1引数にコントロールコードが含まれています)\n";
    }
    elsif ($name =~ m/^\s+/ or $name =~ m/\s+$/) {
        die __PACKAGE__."#set: arg[1]: the argument is not allowed to ".
          "have preceding or trailing spaces. (第1引数の前後にスペースが含まれています)\n";
    }

    if (!defined $key) {
        die __PACKAGE__."#set: arg[2] is not defined. (第2引数が指定されていません)\n";
    }
    elsif (ref $key) {
        die __PACKAGE__."#set: arg[2] is a reference. [$key] (第2引数がリファレンスです)\n";
    }
    elsif ($key =~ m/[\x00-\x1f]/) {
        die __PACKAGE__."#set: arg[2]: contains a control code. ".
          "(第2引数にコントロールコードが含まれています)\n";
    }
    elsif ($key =~ m/^\s+/ or $key =~ m/\s+$/) {
        die __PACKAGE__."#set: arg[2]: the argument is not allowed to have ".
          "preceding or trailing spaces. (第2引数の前後にスペースが含まれています)\n";
    }

    if (!defined $value) {
        die __PACKAGE__."#set: arg[3] is not defined. (第3引数が指定されていません)\n";
    }
    elsif (ref $value) {
        die __PACKAGE__."#set: arg[2] is a reference. [$value] ".
          "(第2引数がリファレンスです)\n";
    }
    elsif ($value =~ m/[\x00-\x1f]/) {
        die __PACKAGE__."#set: arg[3]: contains a control code. ".
          "(第3引数にコントロールコードが含まれています)\n";
    }
    elsif ($value =~ m/^\s+/ or $value =~ m/\s+$/) {
        die __PACKAGE__."#set: arg[3]: the argument is not allowed to have ".
          "preceding or trailing spaces. (第3引数の前後にスペースが含まれています)\n";
    }

    my Tripletail::Ini::Group::Variant $variant = do {
        if ($raw) {
            if (my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($name)) {
                my $group = $this->_touchGroup($base);

                $group->touchVariant($anno);
            }
            else {
                die __PACKAGE__."#set: arg[1]: malformed name. [$name] ".
                  "(第2引数の形式が不正です)\n";
            }
        }
        else {
            my $group = $this->_touchGroup($name);

            $group->touchVariant(
                Tripletail::Ini::Group::Annotation->new());
        }
    };

    $variant->set($key => $value);
    return $this;
}

sub delete {
    my Tripletail::Ini $this = shift;
    my $name                 = shift;
    my $key                  = shift;
    my $raw                  = shift;

    if ($this->{is_const}) {
        die __PACKAGE__."#delete: This object is marked as a constant. ".
          "(このIniオブジェクトの内容は変更できません)\n";
    }

    if (!defined $name) {
        die __PACKAGE__."#delete: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#delete: arg[1] is a reference. [$name] ".
          "(第1引数がリファレンスです)\n";
    }
    if (!defined $key) {
        die __PACKAGE__."#delete: arg[2] is not defined. (第2引数が指定されていません)\n";
    }
    elsif (ref $key) {
        die __PACKAGE__."#delete: arg[2] is a reference. [$key] ".
          "(第2引数がリファレンスです)\n";
    }

    my @variants;
    if ($raw) {
        if (my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($name)) {
            if (exists $this->{group_for}{$base}) {
                my $variant = $this->{group_for}{$base}->getVariant($anno);

                if (defined $variant) {
                    @variants = ($variant);
                }
            }
        }
    }
    elsif (exists $this->{group_for}{$name}) {
        my $hosts = $this->{group_for}{HOST};
        @variants = $this->{group_for}{$name}->filterVariants($hosts);
    }

    foreach my $variant (@variants) {
        $variant->delete($key);
    }

    return $this;
}

sub deleteGroup {
    my Tripletail::Ini $this = shift;
    my $name                 = shift;
    my $raw                  = shift;

    if ($this->{is_const}) {
        die __PACKAGE__."#deleteGroup: This object is marked as a constant. ".
          "(このIniオブジェクトの内容は変更できません)\n";
    }

    if (!defined $name) {
        die __PACKAGE__."#deleteGroup: arg[1] is not defined. ".
          "(第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#deleteGroup: arg[1] is a reference. [$name] ".
          "(第1引数がリファレンスです)\n";
    }

    my %variants; # {basename => annotation}
    if ($raw) {
        if (my ($base, $anno) = __PACKAGE__->_parseAnnotatedGroup($name)) {
            if (exists $this->{group_for}{$base}) {
                my $variant = $this->{group_for}{$base}->getVariant($anno);

                if (defined $variant) {
                    $variants{$base} = [$variant->annotation];
                }
            }
        }
    }
    elsif (exists $this->{group_for}{$name}) {
        my $hosts = $this->{group_for}{HOST};

        $variants{$name} = [
            map {
                $_->annotation;
              }
              $this->{group_for}{$name}->filterVariants($hosts)
           ];
    }

    while (my ($base, $annotations_ref) = each %variants) {
        $this->{group_for}{$base}->deleteVariants(@$annotations_ref);

        if (!scalar $this->{group_for}{$base}->variants) {
            delete $this->{group_for}{$base};

            @{ $this->{groups} }
              = grep {
                    $_->basename ne $base
                  }
                  @{ $this->{groups} };
        }
    }

    return $this;
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
  [TL:register@server:Debughost]
  logdir = /home/tl/logs/register
  [TL:register]
  logdir = /home/tl/logs/register
  [TL]
  logdir = /home/tl/logs
  errormail = tl@example.org
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
  $TL->newIni($file_path)

Tripletail::Ini オブジェクトを作成。
設定ファイルを指定してあればreadメソッドで読み込む。

=item C<< read >>

  $ini->read($file_path)

指定した設定ファイルを読み込む。

=item C<< getFilePath >>

  $fpath = $ini->getFilePath;

ファイルから設定を読み込んでいた場合、そのファイルパスを返す。
そうでなければ C<undef> を返す。

=item C<< write >>

  $ini->write($file_path)

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
