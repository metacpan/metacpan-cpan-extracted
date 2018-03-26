
package cli::tsv::latextable ;

our $VERSION = 0.111 ;

=encoding utf8
=pod
=head1

   Program Name : '=SCRIPT='    ('=Bin=')

   Usage Example : 
     '=SCRIPT=' -_ -c 12 -3 4..8  # Assuming 12 columns and treat some column in numbers and emphasize spaces.

    Give the tab separated table from STDIN, then it yields a LaTeX table code from "\begin{table})..".
    Labor-saving to create LaTeX tables from the copy/paste from Excel and SQL outputs, etc.

    Main functions : 
     NOT ONLY performing the tedious work in typing LaTeX codes such as 
    (1) transforming tab characters into ampersands (&) characters for table environments,
    (2) adding the "\hline" on the beginning and the ending inside the tabular environments,
     BUT ALSO
    (3) grouping every 3 digits by comma on numbers >= 1000 and aligning toward right in a column,
    (4) properly modifying various signs \~!<>_%#&$ fitting into LaTeX (with -j, Japanese half-width as well),
    (5) emphasizing the space chacters both usual half-size space and full-width space, 
    (6) by with -z, emphasizing the fullsize hyphen to indicate that it differs from prolonged sound sign.

 Options :     
    -=   : To indicate that the first line in STDIN is the header, to yield "\hline" btw. 1st and 2nd lines.
    -c N : To explicitly indicate that the table has N columns. (Else, automatically determined by 1st line)
    -j   : For Japanese half-width character. The LaTeX output utilize \scalebox{0.5}[1]{...}
    -s N : N is the displaying magnifying factor. Often used for large-size table to reduce the physical size.
    -_   : To emphasize the space character. Both for half-width \x{20} and full-width \x{3000}.

    -3 n[..n][,n[..n]][,n[..n]].. ;  Specify number columns. The leftest columns is numbered 1. 
    -9  : Rotate the entire table 90 degree unclockwise, using "\rotatebox{90}".
    -\'  : Rotate each cell of the 1st line unclockwise. Often used that column names are long string. 
    -H :  (Just for the author's usage. 64digit hexagonal codes from SHA2 is shrinked into 15 digits.)


    --help : Print this online help manual of this command "'=SCRIPT='". Similar to "perldoc `which [-t] '=SCRIPT='` ".
    --help opt ..or..  --help options : Only shows the option helps. It is easy to read when you are in very necessary.
    --help ja : Shows Japanese online help manual. ; latextable --help ja で日本語のオンラインマニュアルを表示します。

 Remarks : 
  - \usepackage{graphicx} is needed between \documentclass and \begin{document}, for rotating and magnifying.
  - The output LaTeX snippet does not work well if the column number of each line increase in a table.
  - Please fill in \caption{} and \label{} as neccessary in the output LaTeX code.
  
 Notes for developing : 
   * I want to add -r switching options to specify only right alignment.
   * I have not yet fully investigate good LaTeX books yet. I only developed this program merely mainly by experience.

 # This program has been made since 2018-02-09(Fri) by Toshiyuki Shimono, as a part of TSV hacking toolset for table data.
=begin JapaneseManual
  プログラム名 : '=SCRIPT='    ('=Bin=')

  標準入力からタブ区切りのデータを読取り、それを LaTeX の表で使えるように変換する。
  下記の作業などを省力化することが目的である。
    (1) タブ区切りをアンパサンド区切りに変換すること
    (2) \hline コマンドを書き入れること
    (3) 数値はコンマ3桁区切りで右詰めにすること
    (4) 各種記号や半角カナをLaTeXで出力できるようにすること
    (5) 半角空白と全角空白を目立たせること
    (6) 全角ハイフンも、全角長音と区別させること
オプション : 
    -=   : 標準入力の最初の行は、作りたいテーブルのヘッダであると仮定する。(\hlineの処理に関わる)
    -c N : 表が幅何列かを明示的に指定する。未指定なら先頭行の列数で判定する。
    -j   : 日本語の半角カナに対応する。
    -s N : 出力の拡大率を指定する。未指定なら 1.0。
    -z   : 全角スペース(UTF8)を、LaTeXの出力結果において、正方形の下半分のような形で可視化する。

    -3 n[,n][,n].. :  3桁区切りにして右寄せにしたい列を1始まりで指定する。 ..で範囲指定。
    -9  : LaTeXで表示させる表の全体を90度左回りに回転させる。
    -H : 便宜上のもの。リリース時に消去。16進の長い文字列を短くする。
    -\'   : 1行目を左回りに回転する。

    --help : このコマンド '=SCRIPT=' のオンラインヘルプマニュアルを表示する。
    --help opt ないし --help options : 分かり安くオプションのヘルプのみを表示する。

注意点 : 
  - 途中で列数が変わると、LaTeXの動作がうまくいかなくなるので注意。
  - \caption と \label の中が空白なので、後で書き込む必要がある。
  - LaTeX の \scalebox コマンドなどを使うので \usepackage{graphicx} がプリアンブルに必要となる。
 このプログラムの開発上のメモ : 
   * 3桁区切りにしたい数ではなくて、単に右寄せしたい列の指定をする -r を実装したい。
   * ドルマークとバックスラッシュの処理は内部処理上でトリッキーだった。正規表現の \Gで解決した。   

# このブログラムは 2018年2月9日(金)から表形式データに対する道具作りの一環として、下野寿之が作成したものである。
=end JapaneseManual
=cut

1; # End of CLI::latextable
