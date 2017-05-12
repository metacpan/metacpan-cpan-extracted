use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/base64Binary is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('Base64Binary', {'maxLength' => '1'});
	should_pass("YQ==", $type, 0);
	should_pass("aA==", $type, 0);
	should_pass("Yw==", $type, 0);
	should_pass("aQ==", $type, 0);
	should_pass("ZA==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet maxLength with value 45." => sub {
	my $type = mk_type('Base64Binary', {'maxLength' => '45'});
	should_pass("ZQ==", $type, 0);
	should_pass("bGNlbmdnamh4eXBy", $type, 0);
	should_pass("bnJyY2J0b3Zhb2pqaXdsd2tiam5kc3I=", $type, 0);
	should_pass("YWR2eHdicnVzdmx3YW1tdnV2c3drZHVlbHBjb29vbHR3ZA==", $type, 0);
	should_pass("ZmNhYWNvY3l5a3d0bGF5bmRidHVvY2lmcmt5ZGdxcmtxcXNnZHlsZG94bmJ2", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet maxLength with value 54." => sub {
	my $type = mk_type('Base64Binary', {'maxLength' => '54'});
	should_pass("Yg==", $type, 0);
	should_pass("Y3V2bmFka3dxZHdiY2U=", $type, 0);
	should_pass("eXNidmxsbnF3Z3JiYWRodWF5aW9paHViZ2Vm", $type, 0);
	should_pass("ZHZtamxud2doaGNpZ3F0bGVxdXNlZGhucHh2anZtYmxia2Zwcm5sZg==", $type, 0);
	should_pass("cmp4c2NlYnRsc3d2d25ld2tld215eXNzdWVkdWp3ZGpwaWdsbWlhYnVxZ2l3Y2ZqZ2Nkb2o=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet maxLength with value 61." => sub {
	my $type = mk_type('Base64Binary', {'maxLength' => '61'});
	should_pass("Yw==", $type, 0);
	should_pass("b3l1a3F5dWJpa3dkcmdoeQ==", $type, 0);
	should_pass("dGRweWRkY3ZoYnFuaGZ4ampsdHBibXFldGx1ZHd1cA==", $type, 0);
	should_pass("Ymp4cmVva2R4dmJ4am9wbWdyc255Zm1mcWZpZ3VxZXJ3eHZ4ZmdrdnVmZmJmYQ==", $type, 0);
	should_pass("cW93dWRoa2pub2FtaWNkdmNldWF3ZXNnYm9taXR2eG93eG5uYmJxanJudXZ3ZHFldmhiZ3NoYXRndWtxaw==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet maxLength with value 74." => sub {
	my $type = mk_type('Base64Binary', {'maxLength' => '74'});
	should_pass("aQ==", $type, 0);
	should_pass("ZGFldHZrZGlsYm94Ymx4YXVwaQ==", $type, 0);
	should_pass("c3ViaGl3ZWFsZmdqaGJneXh3and4bnR3am9neGtkbGhrbnllaA==", $type, 0);
	should_pass("YmNnc3lqYmZvYnBscmhqamZraHZ5dndxZG90cnB1dXJuZWp0bnlzamx0ZWh5ZGxkcG1hY25hdg==", $type, 0);
	should_pass("aWN0YXJlam94am9yaWhybWhkaGFuY2Fza2FsaXFyZWhsa21qY2hnZWl0aWh0eGJvZGlyaWtmdXJicG14cmh5Z2x5eHF3Y2Focw==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet minLength with value 1." => sub {
	my $type = mk_type('Base64Binary', {'minLength' => '1'});
	should_pass("aA==", $type, 0);
	should_pass("dHVzd2VtY3lidXZ0ZmhydXFzZg==", $type, 0);
	should_pass("YXN5b3JwbXJubGxraWFzYmZucGd2Y3NpbWxkbnhpaXBtd3ZveA==", $type, 0);
	should_pass("bWpjbGNxY2ZvamFicmxhamZic2NnbXF4c2JsZXdzdnRlZHh5d210anVobnl2Zm9wZWdka2hrYg==", $type, 0);
	should_pass("eWlmYWh3c29zZGJ1YWtldGh2cXBpcG1iZXZya2d5b2VtcGdmc3BjbGNvcG1tbHZqZHdtYmZ5Ymt1Z3N0eW9rdmllYXFxYnBuYw==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet minLength with value 27." => sub {
	my $type = mk_type('Base64Binary', {'minLength' => '27'});
	should_pass("aGZkb2Jub2x1Y2p1YXhlbWRxb2Rwa3F5dmpw", $type, 0);
	should_pass("bXVqY3NwdG53aXh0eWp2ZGZzc3VxcGpramt2Y2JqeHBpbnNicHg=", $type, 0);
	should_pass("Y2JmdnR3ZHh1amFjZnV2Z2RpcmJvcWxhYXBlcGpsY2dia2JianVmaGdqcGlncWllaw==", $type, 0);
	should_pass("a3NtZ2pmdmVreHl4ZXJhaHR5eGpzaGJzcXBucWpob2VycnlybHZ3bWlmb295c2NibHNncGhjcmVkaGtx", $type, 0);
	should_pass("ZHlta3ljbW9pY25tdnNtYXZna2hmdXJzaWZwZ3RwbG1iZ3R3a3d4Y3Nwbmh4cnZzbGZneG5rZ2ZucHFlZGhmZ21sZWF0ZXk=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet minLength with value 14." => sub {
	my $type = mk_type('Base64Binary', {'minLength' => '14'});
	should_pass("a2tjYnBrcXNod3Roc3A=", $type, 0);
	should_pass("amVxdGtzbW9jdHNpaWFkbXBwd2pycXBpamhndGQ=", $type, 0);
	should_pass("cHR1anZoZHBxaWZxcmJya3Rhb21zcWptZ25kZWh2amdkd2p2ZHJ1cWx0c2U=", $type, 0);
	should_pass("ZGNzamRveHZ5cXRsbXNva3NtamNid2hsc3dvbW9udm13Z3ljZHdhYXdxZGtlYWRmc2FqeXdlbmZjbmk=", $type, 0);
	should_pass("c3V5bnRocm5oc2pqZWhxdm5mZnNsd2pkaG1tbHhrbHdmd2N5c3Vuc2dsZ2NpYXJndGh4a2Fwc3JsaGhsc3NrZWxhYmp0ZWxleGo=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet minLength with value 11." => sub {
	my $type = mk_type('Base64Binary', {'minLength' => '11'});
	should_pass("a3JubmtudXVvbmk=", $type, 0);
	should_pass("dm14dWN1YXFwZWljd3dtYnNudWJrZmFoaWw=", $type, 0);
	should_pass("cWVwc2djeHlranR3cmJ1b29ucWhwdHhpaGF0dnNnZ3ZtaW9veGZ5dmg=", $type, 0);
	should_pass("ZmtycHFnanh5cnh5d2hnb2Rtc3JleG1pcnZ1ZWVhZ3FtdHdnZWtwZW11dWF4aHhhZHVrd3l3Y3E=", $type, 0);
	should_pass("Y3hxdWljeGFwcXhoZ3JhaXNwdWlmdGtnZHlmbGlxanhibmFpeXZ1Y294dHJoZXdmbWZ3b2JudHVtd3V3aWFrYWN3ZnB4dmw=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet minLength with value 74." => sub {
	my $type = mk_type('Base64Binary', {'minLength' => '74'});
	should_pass("dnBwcmh3dGFocGN5b25jeHJjYW9zaXJpbGdpc2xmY2dzZWRna25peXBqaW1iaHV0ZHhhZ2hmZ2NnY3lnYWVvbWdiYXZzZGZya3U=", $type, 0);
	should_pass("YWVnc2NnYnhkYnF0aHF2cHh1ZG5qdnBzcWhuZnlja210cHVoY21jdXRzZ2pxa2lybG9yY3Jhd2Nvb2NpbGV2bnV3ZmJud2xwYmg=", $type, 0);
	should_pass("dmJnd3Rwbmx1aGt2ZmhteWtrYmhrcWJxZXRwdnd4dmxibXNsZWJvZ3NscmhqeWZuY3Vic3N1b3Zqd21vcXh5eHVudm5keHF4aHA=", $type, 0);
	should_pass("YWJrbmlubGRyZ3d3ZHVrdnNmd2h0aGJ4cWNqeXBjbnBpZ3d5Z2tkcXRpZm9oZmR1aHlubXN3d2dmZXZlcHhrZm5meXFzd3B4aGg=", $type, 0);
	should_pass("aXBpb2RuaGF3aGtld3hrdHVyYmFmcHl3eGtqZ2VvcXdyaHhiaWtzd3lvd3hydmdjbHdrd3FncmZlZWtjZGVxYXdncGRjd3JheGk=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet length with value 1." => sub {
	my $type = mk_type('Base64Binary', {'length' => '1'});
	should_pass("Yw==", $type, 0);
	should_pass("eQ==", $type, 0);
	should_pass("cw==", $type, 0);
	should_pass("aQ==", $type, 0);
	should_pass("dQ==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet length with value 1." => sub {
	my $type = mk_type('Base64Binary', {'length' => '1'});
	should_pass("cw==", $type, 0);
	should_pass("aw==", $type, 0);
	should_pass("cA==", $type, 0);
	should_pass("dQ==", $type, 0);
	should_pass("aw==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet length with value 31." => sub {
	my $type = mk_type('Base64Binary', {'length' => '31'});
	should_pass("c3dqYWFmdml0dGZyeG9lanJsYWR3eHF4b3JuYm53ag==", $type, 0);
	should_pass("YnRvYmlzZnFmcmhrcHB3eGJ1eXhmZ3l0aWtoZmVubg==", $type, 0);
	should_pass("YWlnb3RqcmFoeWZ2eGJhZG5sdHBkYWV3aGxpaGRyYw==", $type, 0);
	should_pass("YW13cHJpcmhwbmJuZW93cmpqaWdwbWxlaG53d2t5aw==", $type, 0);
	should_pass("YXVoaGVnZXBic2Nzb3NveXVvbmd4eXNsZmh2aXdvbA==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet length with value 47." => sub {
	my $type = mk_type('Base64Binary', {'length' => '47'});
	should_pass("c3dtdG9ka2lrbmhsZ2ZjYmV3b3BxdG1od2p4aWpnaWZsZm92d3d1cmF1cHBueGU=", $type, 0);
	should_pass("bGFnaHhkd3F2dHRzcnFiY3Z4cWVubmxhZ3h5ZmV2aXhjZmFmdWVzZ2x0eWdqZmM=", $type, 0);
	should_pass("ZGVmcGhiYWF2eWZkcHBxa3dncWhnZHNqd3N2am1nZGhnYXN4d2JwY21qc2h0c2Q=", $type, 0);
	should_pass("cnFraW5sbG1ieXBrdXh4bXVndndkYWV4cWNhY3lkdGxwdXFlaHF3ZHl1dWhzZWQ=", $type, 0);
	should_pass("aWFjYmdtY3Jia2tyZXByZHNxeGxnYWxwc2t5Y21qdWpmYnlldnNsbW10YmVpb24=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet length with value 74." => sub {
	my $type = mk_type('Base64Binary', {'length' => '74'});
	should_pass("d3d4YW1iam5qeGNhbHBmaXhyaHZqcHRsbXRzbWJ1ZGxpd3R2Y2xuYm9yc2lxYnFuYWtnZHFjc2l4ZHZ1eWd2d3JqYmZtYnhtYnE=", $type, 0);
	should_pass("dWhhZmNiZHl2b211aHJpa2FoeG5oZGdqYm1wZGNtd3Zxcmt2ZWV3bHNxb2RkY2hod29hYXJxcWZqbWVodmhvbXZocXdkdHhidXc=", $type, 0);
	should_pass("YmV4YXZwZHZoc2h4bXdocHBxdmFndnN1dmlydnl5am1waWVzeGhnanl5bmdibmhhdmxkbnF1aGFpcXZ2amphb29rbnljYmpocmk=", $type, 0);
	should_pass("cHhqY3Fqdmx4bGxpZGZveGpudGNhYWF5bmZxc3Nya3BvdHJuc25wYWNoYWZ2c29hYWRheGZnb3JleHJyc3FhZmRydXV5dmhnaWI=", $type, 0);
	should_pass("ZWhzeGlja21qdHFzZmphaXRtZGNzdGlxYnFvZndpeHdpcGlqbmZhdHhtdmFpdm54b3draGphdndnZGV2dWhzYnhkdGN2bmdjaXE=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet pattern with value [a-zA-Z0-9+/]{20}." => sub {
	my $type = mk_type('Base64Binary', {'pattern' => qr/(?ms:^[a-zA-Z0-9+\/]{20}$)/});
	should_pass("dGRoYWx5anVnZnRydGRl", $type, 0);
	should_pass("dnBtZWFvZHNkcWNjbHBx", $type, 0);
	should_pass("bWhqcWdjd2ZwdGtjbXJs", $type, 0);
	should_pass("ZHFrcWt4eWRjZ2d4YnR0", $type, 0);
	should_pass("Y25hc3dxZGd2eGlqZGx0", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet pattern with value [a-zA-Z0-9+/]{68}." => sub {
	my $type = mk_type('Base64Binary', {'pattern' => qr/(?ms:^[a-zA-Z0-9+\/]{68}$)/});
	should_pass("ZWxxdXJyanJuanFodGZ3Z25sc3VrZGJ0cGp5dHFoaGJxYmVyZ2RpbXl0c3NueWJpdXVq", $type, 0);
	should_pass("eGpycXh2dXFsa3lsbWtwcWt4d2hkcHVicXFlcWp2b2FtcGRucmNmbmFwcHFpcG9tdm9j", $type, 0);
	should_pass("Y2V5c2dic3R0Z3V0eHdwb3JlY2hmbGlkZW9yb25xZGl1aXZsaG9mcGVrdnd4bXlid3Fv", $type, 0);
	should_pass("Z2htb25kbmRycWpjc2pmYXVpamFtZGtsdm1sa3Fjc3RrdWRybWRlaGdmeGNxZHhzeW1v", $type, 0);
	should_pass("b2tsb3lpd3Rjcm5ybWt2c3dqdWRzcGFtbWlmbmFlZHJ0a3d3bGR1b3V4b2xhbmZ4eWx5", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet pattern with value [a-zA-Z0-9+/]{64}." => sub {
	my $type = mk_type('Base64Binary', {'pattern' => qr/(?ms:^[a-zA-Z0-9+\/]{64}$)/});
	should_pass("b21pbWV3Ym9ibm1pbnBmdGdyYnl1Ymxybm9kcGhqbXNydmthamFocGtwaW55b2t1", $type, 0);
	should_pass("dGx4aHlyaWxkY29hc25md3hqZnBnc214Ymlwb2t1dGdvZnNjaWljY3N1Z2NuZnB4", $type, 0);
	should_pass("aXRhcmxvbW9lZW1zaGR3ZnF1ZW5jdHdjdG9hZmxvdnV4dWtseHd3YmJybWl1aGJo", $type, 0);
	should_pass("Ym5rbmJxZ2V2ZmxoZHdhZnBtbXlnbGZ5cnBta3lhZGtpb2dwbW1ha29iY2pxYm9i", $type, 0);
	should_pass("Z2pvYmZwaHhxeGZxdW1od2ZpYWlld2pwbHZlY3J5bmV4bmNjZG1qbWVrYmx3dmd3", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet pattern with value [a-zA-Z0-9+/]{24}." => sub {
	my $type = mk_type('Base64Binary', {'pattern' => qr/(?ms:^[a-zA-Z0-9+\/]{24}$)/});
	should_pass("bmxscXJ5bWRpeWJraWxybW1l", $type, 0);
	should_pass("cmRnd3drb291cWhnaGFpdGZz", $type, 0);
	should_pass("ZGJ4cHFzdnVxZXd5a2RvZnJz", $type, 0);
	should_pass("dmp1amFhandsY21yeWJ0dHNp", $type, 0);
	should_pass("aXZkcGl3eWdyd2ZleG9pbmly", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet pattern with value [a-zA-Z0-9+/]{60}." => sub {
	my $type = mk_type('Base64Binary', {'pattern' => qr/(?ms:^[a-zA-Z0-9+\/]{60}$)/});
	should_pass("a2dicW9mY29ybWdjb2tycGRscWNxamp0ZWxxbWlzaXFrZm9oZ2twdWR5eHh5", $type, 0);
	should_pass("c3V1d2ZqdHJ1eG1nZm1kdHN4bWtoYXdrdWNzbGhrdmhxc2R5Y2tpb25lbXZx", $type, 0);
	should_pass("a2VzdXZub2hscG53aHZsdml4aGZxdGZ3aXl3cmRocXdkcmNuaWpxZGVpYmlx", $type, 0);
	should_pass("b3FocGJvcmtrdG5nZnFkcWtsb3NnZ3FnbWtnZ2JzbmZ3d3BvanZkZmVveWNv", $type, 0);
	should_pass("aW9wdmhldHRkc2t3cXllZXZjbm9haXNhcWhvZXFpdXNpdXh3dmpqY25oZWJs", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet enumeration." => sub {
	my $type = mk_type('Base64Binary', {'enumeration' => ['ZmFyaml5Zm1i','dHJhZWJmc3Zhcg==','Y29zaXB5amtvZnhwb2lpanhvZnRrcHVxa3BybnByZGhjeHR3c2dqcGRrdmFqbm9seXhyeHZzYnFjZm10','b250Z21mb2x5bGluYmduandpbnBwb3V1YWhqd2NidA==','c3Rjb2xycnd2bWpza29wdmdjbnk=']});
	should_pass("b250Z21mb2x5bGluYmduandpbnBwb3V1YWhqd2NidA==", $type, 0);
	should_pass("dHJhZWJmc3Zhcg==", $type, 0);
	should_pass("b250Z21mb2x5bGluYmduandpbnBwb3V1YWhqd2NidA==", $type, 0);
	should_pass("dHJhZWJmc3Zhcg==", $type, 0);
	should_pass("dHJhZWJmc3Zhcg==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet enumeration." => sub {
	my $type = mk_type('Base64Binary', {'enumeration' => ['dmxpbXRpbnJ3aWlwamp3ZXhiZXJ0cXBx','d2xnbmNkZWN4ZWZleHNqYXZkc2xlcXRidnZ1aXV0aGhzdmZ0ZWxwbndiZmln','ZGdqbG5hc2tzeWN2bW5qcHdhcnhucnFndXZicXF5cmRj','ZHFzbWxnbWVw','dGVmd3BsbWRmY3htcG1kd2JoaWZtcnhobXZlYWVnYXRlYWxwbm1meW14dXU=','cWFoYnd1dGZleWV3d3Rra3NpbnFiZGNqamdrcWF4YXZ5Y3Ri','c2dmc2ZhZXBuZGZnY214Z2Rsd2N4am1hbXl3ZGRuY3hpcHZscHlzeWpkZHNwcGdwbGlpZXJzaHRqaw==','dXZiZ3RkcGxwZ3hkc3FqeGZtcmVsbHNqaW5qeHlma2Z5bXZiYmVrZmZ2Z2xxdHB4bW5ycHZ0anZ2amtvd2N1aWh2dWdiZGltdw==','d3N5cHJoZ250aWtmYml2ZGN2bGZ4cnZk']});
	should_pass("c2dmc2ZhZXBuZGZnY214Z2Rsd2N4am1hbXl3ZGRuY3hpcHZscHlzeWpkZHNwcGdwbGlpZXJzaHRqaw==", $type, 0);
	should_pass("ZHFzbWxnbWVw", $type, 0);
	should_pass("dGVmd3BsbWRmY3htcG1kd2JoaWZtcnhobXZlYWVnYXRlYWxwbm1meW14dXU=", $type, 0);
	should_pass("dmxpbXRpbnJ3aWlwamp3ZXhiZXJ0cXBx", $type, 0);
	should_pass("d2xnbmNkZWN4ZWZleHNqYXZkc2xlcXRidnZ1aXV0aGhzdmZ0ZWxwbndiZmln", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet enumeration." => sub {
	my $type = mk_type('Base64Binary', {'enumeration' => ['eGJjeXJjbHVjcXJlbHZhbmRzamthcmprbXZydGV4Z3hoZXZtcXZ0bmx0dnh4dGRvd2ZxcmtqY2s=','cXNraWVxYWN1ZXh5b3F0dmRnZ2ZnbGl2eGRsdGk=','cnVmZGRucWV5c3ZsZ2ZzdGVyZHlyb2VtaGFtb211cG50eHN3','cnVia21pZ3d3cWF5dHlvZGtrY2tvZXF4dmRkZmthZmNwamp1ZGRvcGRrdndnZnJmdGttdnVoZ3I=','YnVuanVxZnh0aXhzYmpjeHFmcXNxd3lrYmtjdnRrd2lqbXh3aG9xdmphdnVnampkeWdndGx1dXBzYmlnanY=','YnZ0cGVzYXlwZ2lvc3NoYWZodWNxb3B1cGt5Y2NudGpueXlhd29wdXFhY25qZXl1dm5ydGFn']});
	should_pass("cXNraWVxYWN1ZXh5b3F0dmRnZ2ZnbGl2eGRsdGk=", $type, 0);
	should_pass("YnVuanVxZnh0aXhzYmpjeHFmcXNxd3lrYmtjdnRrd2lqbXh3aG9xdmphdnVnampkeWdndGx1dXBzYmlnanY=", $type, 0);
	should_pass("cnVia21pZ3d3cWF5dHlvZGtrY2tvZXF4dmRkZmthZmNwamp1ZGRvcGRrdndnZnJmdGttdnVoZ3I=", $type, 0);
	should_pass("cnVmZGRucWV5c3ZsZ2ZzdGVyZHlyb2VtaGFtb211cG50eHN3", $type, 0);
	should_pass("YnVuanVxZnh0aXhzYmpjeHFmcXNxd3lrYmtjdnRrd2lqbXh3aG9xdmphdnVnampkeWdndGx1dXBzYmlnanY=", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet enumeration." => sub {
	my $type = mk_type('Base64Binary', {'enumeration' => ['aGo=','YWZkcWd2a2ZzcHN5cnNjbWF3eGR2Z3Nwa2xkdWd4YXBlcHludGFvcmd3eWJsbHlz','dW15anlkeWxuZHhkaXF1ZWl0bHNma2pleXRhd3ViYmlxeG9reXNlZXV5c2NiY3l5aWtlc21xdHNpaWdvbA==','c3RmdHZoeGFmdHF3aWJmYW9wdmliY3JiZA==','ZXJueG91cG9zYmtwcXZleGhmeHljc3RsdWdqcXA=','dHJna3FscXJ1aHVwZ2h5dGx5bXV1d2xpdGxxYnBqaWJwcHdmZGxhZ25tdnN2ZHFtdGJhaXlicnZqdGViaWthYWV3','YmZ1c21md3R2bmd3bnZ4cnRubG15cHJhamFsb2Rscg==']});
	should_pass("YmZ1c21md3R2bmd3bnZ4cnRubG15cHJhamFsb2Rscg==", $type, 0);
	should_pass("dW15anlkeWxuZHhkaXF1ZWl0bHNma2pleXRhd3ViYmlxeG9reXNlZXV5c2NiY3l5aWtlc21xdHNpaWdvbA==", $type, 0);
	should_pass("YWZkcWd2a2ZzcHN5cnNjbWF3eGR2Z3Nwa2xkdWd4YXBlcHludGFvcmd3eWJsbHlz", $type, 0);
	should_pass("ZXJueG91cG9zYmtwcXZleGhmeHljc3RsdWdqcXA=", $type, 0);
	should_pass("YmZ1c21md3R2bmd3bnZ4cnRubG15cHJhamFsb2Rscg==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet enumeration." => sub {
	my $type = mk_type('Base64Binary', {'enumeration' => ['ZWNkbmVkcnJhZG9mYmpwb3Jwc25ic3c=','ZmJkZ3FtY2h0dXd5eGRnb2VzZmFoc25sYWZteHZ4cWNncWRzaWxwZWNkYmptbXRiZnc=','dWtyamFvdGtjbW93bXBpZWhxcGFxbHB1a2ZrZW95eHN1b2pvaXVyamVreG9zY2p2bmdybW10aHV5a2lscW1tY2thbw==','dGdmY2dlbmZudm14bHF5ZnlieXBreG9kZXV4cmxhanVjdGdvbXFqeGlidXNreW1ucGJiaGtkbnB5YWpscw==','eHRhdnFkaXNxZQ==','anV0YnBvY2JueXB0YXBtcHFycnFybWxvanFkeXdtY3llb3N0bmdtbmRxYQ==','cGJ1bGhkeGZwc2hoa3B3aWtmYWpqaW5nbGxkaGlwanh0aHliaW9qaWNpdmJpdm54cQ==']});
	should_pass("ZWNkbmVkcnJhZG9mYmpwb3Jwc25ic3c=", $type, 0);
	should_pass("ZmJkZ3FtY2h0dXd5eGRnb2VzZmFoc25sYWZteHZ4cWNncWRzaWxwZWNkYmptbXRiZnc=", $type, 0);
	should_pass("ZmJkZ3FtY2h0dXd5eGRnb2VzZmFoc25sYWZteHZ4cWNncWRzaWxwZWNkYmptbXRiZnc=", $type, 0);
	should_pass("ZmJkZ3FtY2h0dXd5eGRnb2VzZmFoc25sYWZteHZ4cWNncWRzaWxwZWNkYmptbXRiZnc=", $type, 0);
	should_pass("eHRhdnFkaXNxZQ==", $type, 0);
	done_testing;
};

subtest "Type atomic/base64Binary is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Base64Binary', {'whiteSpace' => 'collapse'});
	should_pass("cGdjb2VtcGF1d29ramhld2d2bm53bnR3d3B5b3dkeGpnc29sY2Y=", $type, 0);
	should_pass("Y3JvaGxveW9maXhlandleGhhZnFza3RicG5wbmRndW94aXlsYXY=", $type, 0);
	should_pass("ZWJteW90cXVvcWp0dHhiYWhhcWpzdHh4dmFuamp3dW5hcm11dHA=", $type, 0);
	should_pass("eWJtYm1jaWFhZnBjcWxxa3FwaWVsdW1pd2xzcmd0aW90cnZqY2s=", $type, 0);
	should_pass("dW1pbGlmb2R1dWNjbHd5ZGJyZXNhcmVlb3JwamJqZmpxb2pubGs=", $type, 0);
	done_testing;
};

done_testing;

