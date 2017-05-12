XBRL::JPFR version 0.03
===================

XBRL::JPFR は株式会社東京証券取引所(TDnet)や金融庁(EDINET)で開示されている
決算短信や財務諸表などのXBRLインスタンスを読み込むためのモジュールです。
JPFR は Japan Financial Reporting(日本の財務報告)の略です。

インストール
    perl Makefile.PL
    make
    make install
    cp taxo/* your/schema/directory/

必要モジュール
    XBRL
    Hash::Merge
    Clone
    URI

用法
    bin/{dumpxbrl,timeseries} を見てください。

コピーライト及びライセンス
    Copyright (C) 2012 by Mark Gannon
    Copyright (C) 2015 山本鉄矢
    このモジュールはフリーソフトです。
    再配布や修正は Perl の条項に従います。
    このモジュールで抜き出した情報が正確であることを一切保証しません。
    このモジュールの使用により生じたいかなる損害についても責任を負いません。

参考
    XBRL                 https://www.xbrl.org/
    XBRL2.1仕様          http://www.xbrl.org/Specification/XBRL-2.1/REC-2003-12-31/XBRL-2.1-REC-2003-12-31+corrected-errata-2013-02-20.html
    東証XBRLデータ仕様   http://www.jpx.co.jp/equities/listing/xbrl/03.html
    金融庁XBRLデータ仕様 https://disclosure.edinet-fsa.go.jp/E01NW/EKW0EZ0015.html とその過去基準リンク
    東証企業開示情報     https://www.release.tdnet.info/index.html
    金融庁企業開示情報   http://disclosure.edinet-fsa.go.jp/
    時系列財務諸表       http://www6.kiwi-us.com/~biz/fr/

バグなどの問題点
    他にもあるだろうけど、気がついたものだけ。
    1. Item.pm: decimals は XBRL2.1 に完全に基づいてはいない。
    2. Taxonomy.pm
       DTS(Discoverable Taxonomy Set)
       XBRL2.1: 3.2
         基準の内、以下だけを採用
         1. referenced directly from an XBRL Instance using the <schemaRef> element.
         2. referenced from a discovered taxonomy schema via an XML Schema import element.
         3. referenced from a discovered Linkbase document via a <loc> element.
         6. referenced from a discovered taxonomy schema via a <linkbaseRef> element.
    3. roleファイル、referenceファイル、glaファイル、未対応。
    4. XBRL2.1: 3.5.3.7.2
       locator の href は relative の可能性がある。
    5. XBRL2.1: 3.5.4
       locator の要素の指し方。abc.xsd#element(/1/14) ...  には未対応。
    6. definition tree のラベルの決定方法が不明。
       2009/S00046BP/jpfr-q3r-E00351-000-2009-09-30-01-2009-11-10.xbrl
       uri=http://info.edinet-fsa.go.jp/jp/fr/gaap/role/StatementsOfIncome
       id_short=jpfr-q3r-E00351-000_SubsidyIncomeEIBounty など。
    7. EDINET 2013-08-31 基準では連結個別の判別が不能？
       http://www.fsa.go.jp/search/20130821/2b_1.pdf: P31
       連結・個別の区別がされない箇所(「大株主の状況」等)がある。
       そのリストもない。
       Context.pm:make_label_ja_edinet
    8. Context の形式、綴りが間違ってる。
       2684/S00057FU/jpfr-q2r-E03369-000-2009-12-31-01-2010-02-12.xbrl
         No relative duration nor instant(edinet,Pruir1QuarterConsolidatedInstant)
       4684/S00039KN/jpfr-q1r-E05025-000-2009-06-30-01-2009-08-07.xbrl
         No relative duration nor instant(edinet,Prior1LastQuarterConsolidatedInstant)
       4686
         No relative duration nor instant(edinet,Prior1LastQuarterConsolidatedInstant)
       7921
         No relative duration nor instant(edinet,Prior1NonYearConsolidatedInstant)
       8697
         No relative duration nor instant(edinet,Prir1QuarterConsolidatedInstant)
    9. prefix の namespace への解決をしていない。
       6779/S000B2EV/ifrs-asr-E01807-000-2012-03-31-01-2012-06-22.xbrl
         No dimension label(ifrs0_ComponentsOfEquityAxis)
         ifrs0 は namespace に変換すると 'http://xbrl.ifrs.org/taxonomy/2011-03-25/ifrs'。
   10. Linuxで動作確認しています。Windowsでは動きません。

日本語ラベルの決定方法
    JPFR->get_label でのラベルの決定方法
    std_labelsフラグが設定されているときは、なるべく標準ラベルを使用する。
    std_labelsフラグが設定されてないときは、
        EDINET 2013-03-01以前(ExtendedLinkRole* に関する解説はみあたらない。)
          1. XBRL-instance(.xbrlファイル)の ExtendedLinkRoleLabel* に対応する rolelink を使用。
          2. preferredLabel が設定されているなら、それを rolelink として使用。
          3. 標準rolelink を使用。
        TDnet 2013以前(05_Kaiji_taxonomy_kaisetsu_CG.pdf: P37)
          1. 特定事業の中間期なら、rolelink は QuarterlyForSpecificBusiness2Q を使用。
          2. 四半期なら、rolelink は Quarterly を使用。
          3. preferredLabel が設定されているなら、それを rolelink として使用。
          4. 標準rolelink を使用。

