# `<!yatt:import>` を「parse 時の `_Item` への Part コピー」で実装してはいけない理由 — 検証レポート

- 日付: 2026-07-20
- 関連: `<!yatt:import>` 宣言の設計議論(`<!yatt:base>` の弱点への対処)
- 検証スクリプト: [`import-naive-item-copy/`](./import-naive-item-copy/) 配下の `00`〜`05`
- 実行方法: `cd /home/hkoba/db/yatt/lib && perl YATT/Lite/agent_docs/reports/import-naive-item-copy/NN_*.pl`
  (各スクリプトは tempdir に使い捨てのテンプレート一式を作って動くので、リポジトリを汚さない)

「素朴実装」とはここでは、`declare_import` が parse 時にソーステンプレートの
Part オブジェクトを取込側の `$tmpl->{_Item}{$name}` へ代入する実装を指す。
各スクリプトはこの代入を Core API 経由で手作業再現し、その結果を
実際の dispatch / refresh / cgen 経路に通して観察する。

## 0. 前提となるコード地図

素朴実装の問題は、以下の既存機構との相互作用で生じる。先に位置を確認しておく。

| 機構 | 場所 | 要点 |
|---|---|---|
| part 探索 | `Lite/Core.pm:481-539` `find_part_handler` | `$tmpl->{_Item}{$itemKey} \|\| find_part_from(...)` で part を探し、**その後** `$pkg = find_product(perl => $tmpl)`(=要求された側のテンプレート)から `$pkg->can($method)` で sub を取る |
| widget 用の別経路 | `Lite/Core.pm:454-479` `find_part_renderer` | こちらは `$part->cget('folder')`(=part の所属テンプレート)から product package を引く。part と package の対応が要求側に依存しない |
| VFS lookup 連鎖 | `Lite/VFS.pm:245-250` `Folder::lookup` | `lookup_1 // lookup_base` |
| ファイル内探索 + refresh | `Lite/VFS.pm:279-293` `File::lookup_1` | **探しに行った先のファイルだけ** `$file->refresh($vfs)` してから `_Item` を引く。refresh は mtime 比較で再 parse(`Lite/Core.pm:682-709`) |
| base 走査 | `Lite/VFS.pm:319-342` `lookup_base` | entns があれば `mro::get_linear_isa` で線形化して各 super の `lookup_1` を呼ぶ |
| @ISA の確立時期 | `Lite/CGen.pm:53` → `Lite/CGen/Perl.pm:43-74` `setup_inheritance_for` | **コード生成時**。parse 直後の entns は base と未連結 |
| 再 parse 時のリセット | `Lite/Core.pm:673-681` `Template::reset` | `_partlist/_Item/_product/subroutes` を全部 undef して作り直す |
| ファイル消失時 | `Lite/Core.pm:690-692` | `return; # XXX: ファイルが消された` — キャッシュ温存 |
| 他テンプレート widget 呼び出しの生成コード | `Lite/CGen/Perl.pm:389-398` | `Other::EntNS->render_foo($CON, ...)` の**パッケージ名による静的束縛** + `add_dependency` 登録。coderef や Part 参照を跨いで持たない |
| base 宣言の登録方法 | `Lite/VFS.pm:697-703` `declare_base` | Part をコピーせず、`$vfs->create(...)` した記述子を `weaken` して置くだけ |

最後の 2 行が示す通り、**既存設計はテンプレート境界を跨ぐ参照を「名前(パッケージ名・記述子)」で持ち、オブジェクトの直接参照では持たない**。素朴実装はこの原則を破る。そこから以下の各問題が派生する。

## 検証 00(前提の訂正): 現行 `<!yatt:base>` の page/action 継承は「順序依存で半分だけ動く」

スクリプト: [`00_base_inheritance_is_order_dependent.pl`](./import-naive-item-copy/00_base_inheritance_is_order_dependent.pl)

import 設計の前提として現状を実測した。`find_part_handler` の base フォールバック
(Core.pm:522)は存在するが、@ISA はコンパイル時にしか張られない(上表)ため、
**プロセス起動後いきなり継承 page を踏むと 500 になり、失敗リクエスト自体は
コンパイルを引き起こさないので、他のリクエストが子を通常描画するまで 500 が続く**:

```
/child?~confirm=1      : [500] No such page in file child.yatt: confirm
/child                 : [200] <h2>child</h2>          ← ここで child がコンパイルされ @ISA 確立
/child?~confirm=1      : [200] confirm from form       ← 以後は動く
```

つまり「継承で page/action が見えない」という問題認識は実用上正しい
(見えるのは偶然コンパイル済みだった場合のみ)。またこの挙動自体が、
**dispatch を Perl の @ISA/`can` に依存させる設計の脆さ**の実例になっている。

## 検証 01: 素朴コピーは `$pkg->can($method)` で止まり、そもそも dispatch できない

スクリプト: [`01_dispatch_can_failure.pl`](./import-naive-item-copy/01_dispatch_can_failure.pl)

`find_part_handler` は part を(コピーされた `_Item` から)見つけた後、
**要求された側**のテンプレートの product package から `can` する(Core.pm:530-536)。
import は ISA を張らないので、コピー元パッケージにある `render_confirm` は見えない:

```
== (1) find_part_handler([child, page => confirm]) ==
DIED: Can't extract render_confirm from file: child

== (2) 内訳 ==
part found in child->{_Item}: name=confirm folder=/tmp/.../form.yatt
find_product(child) = TestImport01::INST1::EntNS::child
  ...::child->can('render_confirm') = undef (FAIL)
find_product(form)  = TestImport01::INST1::EntNS::form
  ...::form->can('render_confirm') = CODE(0x...)
```

part は見つかるのに sub が取れない。つまり素朴コピーは**単体では機能せず**、
必ず次のどちらかの追加変更を伴う:

- (a) dispatch 側を `$part->cget('folder')` 基準に直す(`find_part_renderer` 方式)
  → 検証 02, 03 の問題が残る
- (b) 取込側 `_partlist` にも入れて取込側パッケージでコンパイルさせる
  → 検証 05 の問題が出る

## 検証 02: ソース編集後、古い Part メタ + 新しいコードの食い違いで CGI 引数がクロス配線される

スクリプト: [`02_stale_meta_after_source_edit.pl`](./import-naive-item-copy/02_stale_meta_after_source_edit.pl)

(a) の改良を入れた素朴実装を模倣し、コピー後に form.yatt の
`<!yatt:page confirm x y>` を `<!yatt:page confirm y x>` に書き換えた
(引数宣言順の入れ替え。実務では「引数を先頭に追加」で同じことが起きる):

```
== (1) v1 の時点: child 経由の呼び出しは正常 ==
x=[XX] y=[YY]

== (2) 編集後、form を直接呼ぶと正しく更新される(refresh + 再コンパイル) ==
x=[XX] y=[YY]

== (3) 同じ引数で child のコピー経由: 引数がクロス配線される ==
x=[YY] y=[XX]                                  ← ★x と y の値が入れ替わった

== (4) 内訳: Part の同一性と _arg_order ==
child が握る Part : refaddr=93881840041232 arg_order=(x,y,body)
form の現在の Part: refaddr=93881840041472 arg_order=(y,x,body)
```

メカニズム:

1. `File::lookup_1`(VFS.pm:287)は**探しに行った先のファイルしか refresh しない**。
   child の `_Item` でヒットする限り、form の refresh は child 経由では永久に走らない。
2. 誰かが form を直接触った時点で form は再 parse + 再コンパイルされ、
   `render_confirm` の**コード**(パッケージの glob)は新しい仮引数順になる。
3. しかし child が握る Part オブジェクトは旧世代のまま
   (form の再 parse は `Template::reset` で `_Item` を**作り直す**ので、
   child のコピーは旧オブジェクトへの強参照として取り残される)。
4. 実引数の並べ替え(`reorder_hash_params` / 実 dispatch では
   `reorder_cgi_params`)は Part の `_arg_order` を使うため、
   **古い順序で並べた実引数を新しい仮引数順の sub が受け取り、値が黙って入れ替わる**。

エラーにならず内容だけが化けるため、引数がフォーム項目やアクセス制御パラメータ
だった場合の実害が大きい。これが素朴コピーを不採用とする最大の理由。

なお form を誰も直接触らない場合は逆に「編集がいつまでも child に反映されない」
(古いコードが動き続ける)。どちらに転んでも誤りである点に注意。

対照として、lookup 時に毎回解決する `<!yatt:base>` 経由(= lookup_1 が
form を refresh する経路)では同じ編集が正しく反映される:

```
== (5) 対照: <!yatt:base> の lookup 経由なら編集が正しく反映される ==
x=[XX] y=[YY]
```

## 検証 03: ソースファイル削除後もコピーされた part はプロセスが生きる限り呼び出せる(ゴースト part)

スクリプト: [`03_ghost_part_after_delete.pl`](./import-naive-item-copy/03_ghost_part_after_delete.pl)

```
== (1) 削除前 ==
child のコピー経由: confirm (from form.yatt)
GET /form          : [200]

== (2) form.yatt 削除後 ==
GET /form          : [404] (URL 面では消えている)
GET /form?~confirm : [404]
child のコピー経由: confirm (from form.yatt)      ← ★まだ生きている
```

URL レベルでは SiteApp の lookup が実ファイルを見るので /form は 404 に
なるのに対し、コピーされた part は取込側の `_Item` からの**強参照**で
生き続ける(base 記述子が `weaken` される(VFS.pm:703)のと対照的)。
「消したはずの action が呼べ続ける」形になり得るためセキュリティ面の含意がある。

補足: ファイル消失時の VFS 側の扱い自体に `XXX` コメント付きの未解決課題がある
(Core.pm:690-692 はキャッシュ温存で return)。lookup 時解決であれば、将来
この一箇所を直せば import にも base にも効く。コピー方式では旧 Part への
強参照が各コピー先に散らばっており、どんな修正も届かない。

## 検証 04: 循環参照 — eager コピーは構造的に終わらない

スクリプト: [`04_circular_reference.pl`](./import-naive-item-copy/04_circular_reference.pl)

(A) まず現行の相互 `<!yatt:base>`(a.yatt ⇔ b.yatt)の実測。
declare_base は記述子を置くだけなので parse は循環せず、
コンパイル段階の EntNS 衝突検出で(意図されたものかはともかく)止まる:

```
/a   : [500] EntNS confliction for TestImport04::INST1::EntNS::a! ...
/b   : [500] EntNS confliction for TestImport04::INST1::EntNS::b! ...
```

(B) 一方、parse 時に import 元の Part を確定させようとする eager コピーは、
「parse(A) の完了 ← parse(B) の完了 ← parse(A) の完了 ← …」という
依存を作り、コピーすべき確定した Part 集合が存在しない:

```
  parse(a.yatt) 開始
   -> import 元 b.yatt の Part が必要 → parse(b.yatt)
    parse(b.yatt) 開始
     -> import 元 a.yatt の Part が必要 → parse(a.yatt)
      ... (無限再帰、スクリプトでは depth=6 で打ち切り)
```

「parse 中フラグ」で検出してエラーにする追加機構を自作すれば止められるが、
lookup 時解決なら parse は「名前 → ソース」の表を置くだけで完了するため、
この相互依存自体が発生しない(相互 import も、部品参照が実際に循環しない限り
正当なユースケースとして許容できる)。

## 検証 05: `_partlist` にも入れて取込側で再コンパイルする変種は、part の意味を変えてしまう

スクリプト: [`05_partlist_recompile_context_shift.pl`](./import-naive-item-copy/05_partlist_recompile_context_shift.pl)

検証 01 の対処 (b)(取込側パッケージでのコンパイル)を模倣。
form.yatt の `confirm` は内部で `<yatt:header/>` を呼び、
form と child はそれぞれ別内容の `header` widget を持つ:

```
== (1) child のパッケージでコンパイルできてしまうか ==
TestImport05::INST1::EntNS::child->can('render_confirm') = CODE(0x...)

== (2) child 版 confirm の出力(文脈シフト) ==
confirm says: [A-header (child.yatt)]     ← ★child の header にすり替わる

== (3) 対照: form 側の confirm 本来の出力 ==
confirm says: [B-header (form.yatt)]
```

問題点:

1. **文脈シフト**: part 本文中の widget/entity 解決が取込側基準に変わる。
   これは `<!yatt:base>` の継承(テンプレートメソッド)としては正しい挙動だが、
   import に採用すると「定義側に静的束縛」(yatt-js と同じ、移植可能)という
   import 導入の動機そのものと矛盾する。
2. **二重コンパイル**: 同一 Part が form 側・child 側の 2 パッケージで
   別コードにコンパイルされる(N ファイルが import すれば N+1 重)。
3. **不変条件の破壊**: cgen は `$part->{folder}` が「今コンパイル中の
   テンプレート」であることを暗黙に仮定している(エラー報告のファイル帰属、
   `source_region` 系のソース参照)。今回はたまたま動いたが、エラー時の
   行番号・ファイル名は取込側に帰属し、デバッグ情報が嘘をつく。

## 結論: 各問題と「lookup 時間接参照」での消え方

代替案 = import 表(ローカル名 → ソース記述子 + 元名 + kind)を Template に置き、
`Folder::lookup` の連鎖を `lookup_1 // lookup_import // lookup_base` に拡張して
解決時に `$srcFile->lookup_1(...)` する方式(dispatch は part の所属 folder から
product package を引く `find_part_renderer` 方式に寄せる)。

| # | 素朴コピーの問題 | lookup 時解決での帰結 |
|---|---|---|
| 01 | `$pkg->can` が要求側 pkg 基準で失敗 | dispatch を part->folder 基準にするため ISA 不要。@ISA/mro 非依存になり移植(TS/Go)も同型で書ける |
| 02 | 古い Part メタ × 新コードで引数クロス配線 | 毎 lookup で `lookup_1` がソースを refresh するため、Part とコードが常に同世代 |
| 03 | 削除済みソースのゴースト part(強参照) | 記述子は base 同様 weaken 可能。消失時の方針は lookup_1/refresh の一箇所で将来一括修正できる |
| 04 | eager parse の無限再帰 | parse は表を置くだけで完了。相互 import も構造的に安全 |
| 05 | 文脈シフト・二重コンパイル・folder 不変条件の破壊 | ソース側 1 回のコンパイルを名前(パッケージ名)で参照。`CGen/Perl.pm:389-398` の既存の他テンプレート呼び出しと同じ形 |

要するに、**既存コードが他テンプレート widget 呼び出しで既に実践している
「名前で参照し、解決は使用時に行う」原則(静的束縛 + add_dependency)を、
page/action の dispatch にも一貫適用するのが lookup 時解決**であり、
素朴コピーはその原則からの逸脱として上記 5 種の不具合を必然的に伴う。

また検証 00 の通り、現行 base の page/action 継承ですら @ISA 依存ゆえに
順序依存バグを抱えている。import の実装で dispatch を part->folder 基準へ
寄せることは、この種の問題を構造的に避ける意味でも筋が良い。
