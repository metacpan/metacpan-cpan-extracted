# Copyright (c) 2000, 2009 Michael G. Schwern.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package URI::Find::Schemeless;

use strict;
use warnings;
use base qw(URI::Find);

# base.pm error in 5.005_03 prevents it from loading URI::Find if I'm
# required first.
use URI::Find ();

use vars qw($VERSION);
$VERSION = 20160806;

my($dnsSet) = '\p{isAlpha}A-Za-z0-9-'; # extended for IDNA domains

my($cruftSet) = __PACKAGE__->cruft_set . '<>?}';

my($tldRe) = __PACKAGE__->top_level_domain_re;

my($uricSet) = __PACKAGE__->uric_set;

=head1 NAME

URI::Find::Schemeless - Find schemeless URIs in arbitrary text.


=head1 SYNOPSIS

  require URI::Find::Schemeless;

  my $finder = URI::Find::Schemeless->new(\&callback);

  The rest is the same as URI::Find.


=head1 DESCRIPTION

URI::Find finds absolute URIs in plain text with some weak heuristics
for finding schemeless URIs.  This subclass is for finding things
which might be URIs in free text.  Things like "www.foo.com" and
"lifes.a.bitch.if.you.aint.got.net".

The heuristics are such that it hopefully finds a minimum of false
positives, but there's no easy way for it know if "COMMAND.COM" refers
to a web site or a file.

=cut

sub schemeless_uri_re {
    @_ == 1 || __PACKAGE__->badinvo;
    return qr{
              # Originally I constrained what couldn't be before the match
              # like this:  don't match email addresses, and don't start
              # anywhere but at the beginning of a host name
              #    (?<![\@.$dnsSet])
              # but I switched to saying what can be there after seeing a
              # false match of "Lite.pm" via "MIME/Lite.pm".
              (?: ^ | (?<=[\s<>()\{\}\[\]]) )
              # hostname
              (?: [$dnsSet]+(?:\.[$dnsSet]+)*\.$tldRe
                  | (?:\d{1,3}\.){3}\d{1,3} ) # not inet_aton() complete
              (?:
                  (?=[\s\Q$cruftSet\E]) # followed by unrelated thing
                  (?!\.\w)              #   but don't stop mid foo.xx.bar
                      (?<!\.p[ml])      #   but exclude Foo.pm and Foo.pl
                  |$                    # or end of line
                      (?<!\.p[ml])      #   but exclude Foo.pm and Foo.pl
                  |/[$uricSet#]*        # or slash and URI chars
              )
           }x;
}

=head3 top_level_domain_re

  my $tld_re = $self->top_level_domain_re;

Returns the regex for matching top level DNS domains.  The regex shouldn't
be anchored, it shouldn't do any capturing matches, and it should make
itself ignore case.

=cut

sub top_level_domain_re {
    @_ == 1 || __PACKAGE__->badinvo;
    my($self) = shift;

    use utf8;
    # Updated from http://www.iana.org/domains/root/db/ with new TLDs
    my $plain = join '|', qw(
        AERO
        ARPA
        ASIA
        BIZ
        CAT
        COM
        COOP
        EDU
        GOV
        INFO
        INT
        JOBS
        MIL
        MOBI
        MUSEUM
        NAME
        NET
        ORG
        PRO
        TEL
        TRAVEL
        ac
        academy
        accountants
        active
        actor
        ad
        ae
        aero
        af
        ag
        agency
        ai
        airforce
        al
        am
        an
        ao
        aq
        ar
        archi
        army
        arpa
        as
        asia
        associates
        at
        attorney
        au
        audio
        autos
        aw
        ax
        axa
        az
        ba
        bar
        bargains
        bayern
        bb
        bd
        be
        beer
        berlin
        best
        bf
        bg
        bh
        bi
        bid
        bike
        bio
        biz
        bj
        bl
        black
        blackfriday
        blue
        bm
        bmw
        bn
        bo
        boutique
        bq
        br
        brussels
        bs
        bt
        build
        builders
        buzz
        bv
        bw
        by
        bz
        bzh
        ca
        cab
        camera
        camp
        capetown
        capital
        cards
        care
        career
        careers
        cash
        cat
        catering
        cc
        cd
        center
        ceo
        cf
        cg
        ch
        cheap
        christmas
        church
        ci
        citic
        ck
        cl
        claims
        cleaning
        clinic
        clothing
        club
        cm
        cn
        co
        codes
        coffee
        college
        cologne
        com
        community
        company
        computer
        condos
        construction
        consulting
        contractors
        cooking
        cool
        coop
        country
        cr
        credit
        creditcard
        cruises
        cu
        cv
        cw
        cx
        cy
        cz
        dance
        dating
        de
        degree
        democrat
        dental
        dentist
        desi
        diamonds
        digital
        directory
        discount
        dj
        dk
        dm
        dnp
        do
        domains
        durban
        dz
        ec
        edu
        education
        ee
        eg
        eh
        email
        engineer
        engineering
        enterprises
        equipment
        er
        es
        estate
        et
        eu
        eus
        events
        exchange
        expert
        exposed
        fail
        farm
        feedback
        fi
        finance
        financial
        fish
        fishing
        fitness
        fj
        fk
        flights
        florist
        fm
        fo
        foo
        foundation
        fr
        frogans
        fund
        furniture
        futbol
        ga
        gal
        gallery
        gb
        gd
        ge
        gf
        gg
        gh
        gi
        gift
        gives
        gl
        glass
        global
        globo
        gm
        gmo
        gn
        gop
        gov
        gp
        gq
        gr
        graphics
        gratis
        green
        gripe
        gs
        gt
        gu
        guide
        guitars
        guru
        gw
        gy
        hamburg
        haus
        hiphop
        hiv
        hk
        hm
        hn
        holdings
        holiday
        homes
        horse
        host
        house
        hr
        ht
        hu
        id
        ie
        il
        im
        immobilien
        in
        industries
        info
        ink
        institute
        insure
        int
        international
        investments
        io
        iq
        ir
        is
        it
        je
        jetzt
        jm
        jo
        jobs
        joburg
        jp
        juegos
        kaufen
        ke
        kg
        kh
        ki
        kim
        kitchen
        kiwi
        km
        kn
        koeln
        kp
        kr
        kred
        kw
        ky
        kz
        la
        land
        lawyer
        lb
        lc
        lease
        li
        life
        lighting
        limited
        limo
        link
        lk
        loans
        london
        lotto
        lr
        ls
        lt
        lu
        luxe
        luxury
        lv
        ly
        ma
        maison
        management
        mango
        market
        marketing
        mc
        md
        me
        media
        meet
        menu
        mf
        mg
        mh
        miami
        mil
        mini
        mk
        ml
        mm
        mn
        mo
        mobi
        moda
        moe
        monash
        mortgage
        moscow
        motorcycles
        mp
        mq
        mr
        ms
        mt
        mu
        museum
        mv
        mw
        mx
        my
        mz
        na
        nagoya
        name
        navy
        nc
        ne
        net
        neustar
        nf
        ng
        nhk
        ni
        ninja
        nl
        no
        np
        nr
        nu
        nyc
        nz
        okinawa
        om
        onl
        org
        organic
        ovh
        pa
        paris
        partners
        parts
        pe
        pf
        pg
        ph
        photo
        photography
        photos
        physio
        pics
        pictures
        pink
        pk
        pl
        plumbing
        pm
        pn
        post
        pr
        press
        pro
        productions
        properties
        ps
        pt
        pub
        pw
        py
        qa
        qpon
        quebec
        re
        recipes
        red
        rehab
        reise
        reisen
        ren
        rentals
        repair
        report
        republican
        rest
        reviews
        rich
        rio
        ro
        rocks
        rodeo
        rs
        ru
        ruhr
        rw
        ryukyu
        sa
        saarland
        sb
        sc
        schule
        scot
        sd
        se
        services
        sexy
        sg
        sh
        shiksha
        shoes
        si
        singles
        sj
        sk
        sl
        sm
        sn
        so
        social
        software
        sohu
        solar
        solutions
        soy
        space
        sr
        ss
        st
        su
        supplies
        supply
        support
        surf
        surgery
        sv
        sx
        sy
        systems
        sz
        tattoo
        tax
        tc
        td
        technology
        tel
        tf
        tg
        th
        tienda
        tips
        tirol
        tj
        tk
        tl
        tm
        tn
        to
        today
        tokyo
        tools
        town
        toys
        tp
        tr
        trade
        training
        travel
        tt
        tv
        tw
        tz
        ua
        ug
        uk
        um
        university
        uno
        us
        uy
        uz
        va
        vacations
        vc
        ve
        vegas
        ventures
        versicherung
        vet
        vg
        vi
        viajes
        villas
        vision
        vlaanderen
        vn
        vodka
        vote
        voting
        voto
        voyage
        vu
        wang
        watch
        webcam
        website
        wed
        wf
        wien
        wiki
        works
        ws
        wtc
        wtf
        测试
           परीक्षा
        集团
        在线
        한국
         ভারত
        موقع
         বাংলা
        公益
        公司
        移动
        我爱你
        москва
        испытание
        қаз
        онлайн
        сайт
        срб
        테스트
        орг
        삼성
          சிங்கப்பூர்
        商标
        商城
        дети
        мкд
        טעסט
        中文网
        中信
        中国
        中國
                     భారత్
               ලංකා
        測試
                ભારત
           भारत
        آزمایشی
           பரிட்சை
           संगठन
        网络
        укр
        香港
        δοκιμή
        إختبار
        台湾
        台灣
        мон
        الجزائر
        عمان
        ایران
        امارات
        بازار
        پاکستان
        الاردن
        بھارت
        المغرب
        السعودية
        سودان
        مليسيا
        شبكة
        გე
        机构
        组织机构
                     ไทย
        سورية
        рф
        تونس
        みんな
        世界
                     ਭਾਰਤ
        网址
        游戏
        مصر
        قطر
          இலங்கை
          இந்தியா
        新加坡
        فلسطين
        テスト
        政务
        xxx
        xyz
        yachts
        ye
        yokohama
        yt
        za
        zm
        zone
        zw
    );
    
    return qr/(?:$plain)/i;
}

=head1 AUTHOR

Original code by Roderick Schertler <roderick@argon.org>, adapted by
Michael G Schwern <schwern@pobox.com>.

Currently maintained by Roderick Schertler <roderick@argon.org>.

=head1 SEE ALSO

  L<URI::Find>

=cut

1;
