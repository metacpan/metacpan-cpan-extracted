use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/anyURI is restricted by facet maxLength with value 11." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '11'});
	should_pass("ftp://p.org", $type, 0);
	should_pass("ftp://w.edu", $type, 0);
	should_pass("ftp://h.com", $type, 0);
	should_pass("ftp://y.edu", $type, 0);
	should_pass("ftp://w.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 40." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '40'});
	should_pass("ftp://a.edu", $type, 0);
	should_pass("ftp://ftp.beca.net", $type, 0);
	should_pass("gopher://displayspeci.com", $type, 0);
	should_pass("http://www.usingvocabu.aries.gov", $type, 0);
	should_pass("gopher://LanguageSch.mashasforb.ilda.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 26." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '26'});
	should_pass("ftp://u.gov", $type, 0);
	should_pass("mailto:p\@p.com", $type, 0);
	should_pass("gopher://more.gov", $type, 0);
	should_pass("ftp://ftp.suiter.gov", $type, 0);
	should_pass("ftp://ftp.tosoftwareVi.net", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 31." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '31'});
	should_pass("ftp://c.gov", $type, 0);
	should_pass("http://topro.edu", $type, 0);
	should_pass("http://simplestwi.org", $type, 0);
	should_pass("http://www.softwaretoc.com", $type, 0);
	should_pass("http://www.mustafromtw.Inve.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 63." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '63'});
	should_pass("ftp://i.edu", $type, 0);
	should_pass("ftp://ftp.andforbeco.gov", $type, 0);
	should_pass("gopher://information.implicityf.l.org", $type, 0);
	should_pass("ftp://ftp.interoperab.litytheisC.mmitteeoff.rp.org", $type, 0);
	should_pass("gopher://theofDOMvoc.bulariesre.ositoryAso.complexand.ilter.net", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 11." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '11'});
	should_pass("ftp://r.org", $type, 0);
	should_pass("gopher://andforSubco.edu", $type, 0);
	should_pass("gopher://transformin.datasbuilt.d.gov", $type, 0);
	should_pass("gopher://inregistryp.ofilesapro.essorscand.vel.edu", $type, 0);
	should_pass("http://www.andatforens.csUsingapp.icationsty.eadoptiona.dme.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 41." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '41'});
	should_pass("ftp://ftp.earlythespe.ifications.bjec.edu", $type, 0);
	should_pass("ftp://ftp.ECrelatedvi.tuallySuch.tErrorsne.net", $type, 0);
	should_pass("mailto:w\@transactionsfedensureknowndesignreposi.edu", $type, 0);
	should_pass("news://governmentc.meebXMLpro.essTheMark.pdynamicXML.net", $type, 0);
	should_pass("http://www.technologie.aforandbyO.ePCreposit.rytopartne.shi.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 36." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '36'});
	should_pass("mailto:filef\@andAofimplementatio.org", $type, 0);
	should_pass("http://www.development.uildandbas.data.org", $type, 0);
	should_pass("gopher://alanguagePr.jecttodocu.entsmanual.h.gov", $type, 0);
	should_pass("ftp://testatoolcr.ationinspe.ificationt.stingembed.edu", $type, 0);
	should_pass("http://www.scriteriath.XMLchainto.pplication.mprovedtes.toa.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 50." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '50'});
	should_pass("gopher://businessInd.gitalapart.ersindustr.and.gov", $type, 0);
	should_pass("telnet://formustalld.tadefineso.particular.ndaSim.org", $type, 0);
	should_pass("ftp://ftp.implementat.onstoservi.esandconsi.tencysui.edu", $type, 0);
	should_pass("http://www.andcompatib.lityXMLthr.ughfilethe.SLarethero.edu", $type, 0);
	should_pass("telnet://theofamongt.eTheisissu.swirelessO.SISforneed.ddisc.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 63." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '63'});
	should_pass("http://www.oftheunbias.dInternetn.wdynamicpa.tnersissar.tec.org", $type, 0);
	should_pass("gopher://criteriaTou.estechnolo.ycorrectne.sandforbui.dInte.gov", $type, 0);
	should_pass("mailto:isberesultbeingofuseapp\@canandeffortshelpinrelatedma.gov", $type, 0);
	should_pass("ftp://toreviewedh.sprovideda.heobtained.tructuredw.relesstw.net", $type, 0);
	should_pass("gopher://XMLisbuilds.rintXMLsig.ificanteli.inatetoXML.easur.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 11." => sub {
	my $type = mk_type('AnyURI', {'length' => '11'});
	should_pass("ftp://o.gov", $type, 0);
	should_pass("ftp://a.edu", $type, 0);
	should_pass("ftp://e.gov", $type, 0);
	should_pass("ftp://v.edu", $type, 0);
	should_pass("ftp://n.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 11." => sub {
	my $type = mk_type('AnyURI', {'length' => '11'});
	should_pass("ftp://f.org", $type, 0);
	should_pass("ftp://b.edu", $type, 0);
	should_pass("ftp://p.org", $type, 0);
	should_pass("ftp://x.gov", $type, 0);
	should_pass("ftp://d.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 34." => sub {
	my $type = mk_type('AnyURI', {'length' => '34'});
	should_pass("http://www.OASISofinin.ormatio.net", $type, 0);
	should_pass("http://www.MarkupXMLso.twareen.edu", $type, 0);
	should_pass("ftp://discoverbui.dObjectXML.n.org", $type, 0);
	should_pass("telnet://befileXMLus.technolog.edu", $type, 0);
	should_pass("telnet://toolsandwit.reference.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 12." => sub {
	my $type = mk_type('AnyURI', {'length' => '12'});
	should_pass("http://t.gov", $type, 0);
	should_pass("http://t.gov", $type, 0);
	should_pass("http://d.edu", $type, 0);
	should_pass("news://a.org", $type, 0);
	should_pass("news://d.net", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 63." => sub {
	my $type = mk_type('AnyURI', {'length' => '63'});
	should_pass("ftp://partnership.registrysu.portcontai.ingaobject.roupsmak.org", $type, 0);
	should_pass("http://information.ndcanXMLTh.choicesath.sechairsis.illonto.net", $type, 0);
	should_pass("http://www.filedatabet.eofarecomp.tibilityTh.ebXMLStand.rds.gov", $type, 0);
	should_pass("ftp://ofprovidesc.mpatibilit.vocabulary.bjectSchem.sinorgan.com", $type, 0);
	should_pass("ftp://ftp.constituent.roupsobjec.iveNSRLcri.eriacanisO.ethe.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,7}\\.){1,2}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,7}\.){1,2}(?:$XML::RegExp::NameChar){3}$)/});
	should_pass("gopher://Sty.reques.org", $type, 0);
	should_pass("telnet://wirel.oldert.org", $type, 0);
	should_pass("telnet://beth.edu", $type, 0);
	should_pass("gopher://fort.ham.org", $type, 0);
	should_pass("news://mode.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,3}\\.){1,4}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,3}\.){1,4}(?:$XML::RegExp::NameChar){3}$)/});
	should_pass("telnet://mo.X.th.com", $type, 0);
	should_pass("news://thu.o.pro.wid.com", $type, 0);
	should_pass("ftp://b.Co.and.net", $type, 0);
	should_pass("telnet://s.an.to.org", $type, 0);
	should_pass("telnet://Th.int.e.r.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,7}\\.){1,4}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,7}\.){1,4}(?:$XML::RegExp::NameChar){3}$)/});
	should_pass("ftp://XSLthat.incons.isdispl.softwa.org", $type, 0);
	should_pass("ftp://too.edu", $type, 0);
	should_pass("ftp://indust.Aso.dra.gov", $type, 0);
	should_pass("news://r.di.gov", $type, 0);
	should_pass("news://busin.pa.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,6}\\.){1,2}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,6}\.){1,2}(?:$XML::RegExp::NameChar){3}$)/});
	should_pass("ftp://techn.using.gov", $type, 0);
	should_pass("ftp://the.com", $type, 0);
	should_pass("telnet://these.s.org", $type, 0);
	should_pass("gopher://area.gov", $type, 0);
	should_pass("news://ap.refe.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,10}\\.){1,5}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,10}\.){1,5}(?:$XML::RegExp::NameChar){3}$)/});
	should_pass("telnet://and.the.thattesti.andspeci.im.gov", $type, 0);
	should_pass("ftp://beingamon.I.net", $type, 0);
	should_pass("gopher://whoservi.theXSL.fact.ma.net", $type, 0);
	should_pass("ftp://furtherre.th.i.forconso.gov", $type, 0);
	should_pass("telnet://allowtec.recognitio.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['http://Theiste.com','mailto:@prov.org','ftp://h.com','mailto:devic@manipulationandabilityspecifica.gov','http://www.systemswebi.teroperabi.itybeandof.hic.edu','gopher://Conformance.up.com','telnet://f.org','http://www.asseries.gov','telnet://wit.edu','ftp://ftp.atheconstit.entOASISre.rie.net']});
	should_pass("telnet://f.org", $type, 0);
	should_pass("mailto:devic\@manipulationandabilityspecifica.gov", $type, 0);
	should_pass("gopher://Conformance.up.com", $type, 0);
	should_pass("gopher://Conformance.up.com", $type, 0);
	should_pass("http://www.systemswebi.teroperabi.itybeandof.hic.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['ftp://ftp.relatedtool.aandofinve.ticalofeff.rthaveEC.edu','news://th.gov','http://www.withouttheR.commendati.nsmeasureme.gov','mailto:methodsIttech@librarieswithbet.net','ftp://forInvestig.org','http://www.signaturesr.acht.org']});
	should_pass("http://www.signaturesr.acht.org", $type, 0);
	should_pass("ftp://forInvestig.org", $type, 0);
	should_pass("ftp://forInvestig.org", $type, 0);
	should_pass("http://www.withouttheR.commendati.nsmeasureme.gov", $type, 0);
	should_pass("news://th.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['http://www.APIsinCompu.ingte.com','telnet://academi.org','gopher://thatoverJav.throught.com','http://www.ensureaddre.sasspecifi.ationsimag.sandst.org','ftp://ftp.prot.edu','ftp://ftp.computingHT.Lheterogen.ousretriev.vendorsbe.edu','ftp://newdevelopm.ntcomplexa.ongadvance.Consequent.yallow.org']});
	should_pass("http://www.ensureaddre.sasspecifi.ationsimag.sandst.org", $type, 0);
	should_pass("ftp://ftp.computingHT.Lheterogen.ousretriev.vendorsbe.edu", $type, 0);
	should_pass("http://www.ensureaddre.sasspecifi.ationsimag.sandst.org", $type, 0);
	should_pass("ftp://ftp.computingHT.Lheterogen.ousretriev.vendorsbe.edu", $type, 0);
	should_pass("ftp://ftp.prot.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['gopher://thesedefine.escribesof.hoseindustr.edu','news://ableresultp.ovidedfo.org','telnet://correctiono.forinforma.ionbuildca.abilities.com','ftp://bysyntaxinf.rmationret.ieva.org','gopher://Groupsrela.gov','ftp://ftp.issuesquali.yensureand.histestscr.ationforc.com','news://XMLAofMarku.oninofstan.ardslackre.rieveDe.gov']});
	should_pass("news://ableresultp.ovidedfo.org", $type, 0);
	should_pass("gopher://thesedefine.escribesof.hoseindustr.edu", $type, 0);
	should_pass("news://ableresultp.ovidedfo.org", $type, 0);
	should_pass("ftp://ftp.issuesquali.yensureand.histestscr.ationforc.com", $type, 0);
	should_pass("telnet://correctiono.forinforma.ionbuildca.abilities.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['mailto:ofdiscoveryst@GroupsAtoofofwhichiscrea.gov','gopher://programacce.sbynewtheI.ternetinfo.mationinte.org','mailto:computingexecutiontoac@industryprovidesandinandPer.gov','mailto:matchcreat@electronicbeenyearsdocumentsInve.gov','ftp://ftp.areandaComm.tteetransa.tthembusin.ssisfilt.edu','http://worldonenab.ingthrough.utcanprint.efi.net']});
	should_pass("gopher://programacce.sbynewtheI.ternetinfo.mationinte.org", $type, 0);
	should_pass("ftp://ftp.areandaComm.tteetransa.tthembusin.ssisfilt.edu", $type, 0);
	should_pass("ftp://ftp.areandaComm.tteetransa.tthembusin.ssisfilt.edu", $type, 0);
	should_pass("ftp://ftp.areandaComm.tteetransa.tthembusin.ssisfilt.edu", $type, 0);
	should_pass("ftp://ftp.areandaComm.tteetransa.tthembusin.ssisfilt.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('AnyURI', {'whiteSpace' => 'collapse'});
	should_pass("mailto:Ch\@futureinterconnectedbusinesspartnerscommunityof.org", $type, 0);
	should_pass("telnet://adventdatab.seensureis.awcreateor.anizations.elp.org", $type, 0);
	should_pass("ftp://ftp.transactcon.ributerigo.oustoproto.ypesConfor.an.org", $type, 0);
	should_pass("ftp://ftp.ofknownOrga.izationint.olsfiveinc.udeinforma.io.org", $type, 0);
	should_pass("mailto:industr\@providethethisobjectsadNISTforeachcomputer.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 25." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '25'});
	should_fail("ftp://b.org", $type, 0);
	should_fail("gopher://i.com", $type, 0);
	should_fail("http://ensure.com", $type, 0);
	should_fail("gopher://forthea.org", $type, 0);
	should_fail("http://investigati.n.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 32." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '32'});
	should_fail("ftp://q.edu", $type, 0);
	should_fail("gopher://ton.gov", $type, 0);
	should_fail("http://ascommerce.gov", $type, 0);
	should_fail("telnet://oneasTheand.e.com", $type, 0);
	should_fail("http://www.pervasiveen.urei.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 48." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '48'});
	should_fail("ftp://f.gov", $type, 0);
	should_fail("ftp://transmitin.org", $type, 0);
	should_fail("gopher://canbuiltbui.dtha.com", $type, 0);
	should_fail("http://Standardsan.toprocessp.rtne.org", $type, 0);
	should_fail("mailto:ofjoint\@goodthenusingbytheandsoftwar.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 47." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '47'});
	should_fail("ftp://g.org", $type, 0);
	should_fail("http://www.meth.com", $type, 0);
	should_fail("mailto:gl\@businessconso.org", $type, 0);
	should_fail("ftp://Businessani.Nationalto.ac.edu", $type, 0);
	should_fail("http://www.thisOASISUn.versityand.serewell.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet minLength with value 63." => sub {
	my $type = mk_type('AnyURI', {'minLength' => '63'});
	should_fail("ftp://o.org", $type, 0);
	should_fail("telnet://aasthrough.edu", $type, 0);
	should_fail("news://oftheimeasu.ementsiswi.e.com", $type, 0);
	should_fail("ftp://exchangeuse.ofandtheot.ercorrecti.nsy.net", $type, 0);
	should_fail("mailto:naturereviewedrev\@anddiscoverchoicesotherimprovedla.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 11." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '11'});
	should_fail("http://c.edu", $type, 0);
	should_fail("telnet://bedevelopme.gov", $type, 0);
	should_fail("news://aeachthetoa.dimproveda.re.org", $type, 0);
	should_fail("http://environment.accessofto.anguagetoa.dla.com", $type, 0);
	should_fail("mailto:\@cooperationthenandandisFurthermoreCPUdatainconstitu.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 60." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '60'});
	should_fail("news://ofstructure.uiteandoft.theinterna.ionalrefer.nceeb.org", $type, 0);
	should_fail("news://usertoitsfi.dmeasurede.endability.ellareObje.tdefin.gov", $type, 0);
	should_fail("ftp://constituent.eadershipc.mputerSoft.areSoftwar.chairsus.net", $type, 0);
	should_fail("ftp://ftp.hasandebXML.rganizatio.sExtensibl.meetsVirtu.ll.gov", $type, 0);
	should_fail("ftp://ftp.manualOASIS.rganizatio.objectivec.eatesobjec.too.net", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 33." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '33'});
	should_fail("ftp://ftp.facilitates.sedversi.org", $type, 0);
	should_fail("telnet://becomethene.workingthe.ffaci.gov", $type, 0);
	should_fail("http://www.implementat.oncomplian.ofsfileoff.org", $type, 0);
	should_fail("telnet://Architectur.lemergingm.morybusine.sinfrast.edu", $type, 0);
	should_fail("ftp://Individualr.gardobtain.dtoNISTiss.essoftware.ilesbetw.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 37." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '37'});
	should_fail("telnet://firstDOMfed.theandperv.si.org", $type, 0);
	should_fail("mailto:templateslarge\@involveddevelopmen.gov", $type, 0);
	should_fail("http://rangeincorp.ratedPCres.urcelangua.esind.edu", $type, 0);
	should_fail("telnet://certainmatc.electronic.MLspecific.tionofdev.net", $type, 0);
	should_fail("ftp://heterogeneo.spervasive.sinteroper.bilityhelp.ngandand.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet maxLength with value 17." => sub {
	my $type = mk_type('AnyURI', {'maxLength' => '17'});
	should_fail("http://www.lan.edu", $type, 0);
	should_fail("telnet://aresystemst.olsb.edu", $type, 0);
	should_fail("gopher://arebuildsec.ritythesei.assu.org", $type, 0);
	should_fail("news://inhardwared.velopmentI.formationl.nguage.com", $type, 0);
	should_fail("http://www.thatcompute.sLibraryto.aisedawill.oftwareser.ice.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 11." => sub {
	my $type = mk_type('AnyURI', {'length' => '11'});
	should_fail("http://s.org", $type, 0);
	should_fail("ftp://ftp.inreferenc.edu", $type, 0);
	should_fail("telnet://draftpervas.veretrievep.gov", $type, 0);
	should_fail("ftp://anddiscussi.nsalsonetw.rksforelim.nate.edu", $type, 0);
	should_fail("gopher://libraryserv.cestoprofi.esAtobothS.ructuredre.osito.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 53." => sub {
	my $type = mk_type('AnyURI', {'length' => '53'});
	should_fail("ftp://j.edu", $type, 0);
	should_fail("ftp://computerele.edu", $type, 0);
	should_fail("ftp://ftp.toolsrangeG.oupsc.gov", $type, 0);
	should_fail("news://Atotechnolo.iesreposit.ryeffor.gov", $type, 0);
	should_fail("http://andmediumso.enablingty.icalthatbl.cksThet.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 15." => sub {
	my $type = mk_type('AnyURI', {'length' => '15'});
	should_fail("gopher://the.edu", $type, 0);
	should_fail("ftp://ftp.mechanismth.A.org", $type, 0);
	should_fail("telnet://themrevolut.onaccompli.he.org", $type, 0);
	should_fail("http://www.theseXMLoft.chniquesse.sorssoftwar.com", $type, 0);
	should_fail("http://andOrganiza.ionanddata.usinessofc.nformancei.methods.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 14." => sub {
	my $type = mk_type('AnyURI', {'length' => '14'});
	should_fail("ftp://ftp.h.edu", $type, 0);
	should_fail("ftp://ftp.development.n.org", $type, 0);
	should_fail("ftp://ftp.eXtensibler.centofmana.eu.org", $type, 0);
	should_fail("mailto:all\@doreferenceandtechnologiessuccessunb.gov", $type, 0);
	should_fail("ftp://ftp.sinformatio.InAdatabas.implementa.ionsthatfi.espr.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet length with value 63." => sub {
	my $type = mk_type('AnyURI', {'length' => '63'});
	should_fail("ftp://p.org", $type, 0);
	should_fail("ftp://ftp.Groupsand.org", $type, 0);
	should_fail("gopher://definesConf.rmanceTrad.org", $type, 0);
	should_fail("ftp://ftp.issuesantec.nicalwides.readwebthu.org", $type, 0);
	should_fail("mailto:toOASISandaredevelopme\@vocabulariestestingthesefrom.net", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,2}\\.){1,5}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,2}\.){1,5}(?:$XML::RegExp::NameChar){3}$)/});
	should_fail("ftp://eachbewit.otherwilleXtens.follow.lawbeaande.XMLus.repositor.com", $type, 0);
	should_fail("http://build.theamongimag.becom.OASIScompu.thedue.XMLbusinessis.organizations.gov", $type, 0);
	should_fail("http://regist.stimu.waysmanyth.andprofil.exchang.knownagraphi.ECprovidedCom.otherSchemape.edu", $type, 0);
	should_fail("ftp://Theask.toolseto.theacceleratef.andtesttest.the.disseminateToin.ofAdistribu.edu", $type, 0);
	should_fail("news://libr.ssolvetoolsto.metrologypr.software.sup.beknow.theseabil.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,3}\\.){1,4}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,3}\.){1,4}(?:$XML::RegExp::NameChar){3}$)/});
	should_fail("ftp://toregist.thesecanther.NISTme.thefor.amongthosesuch.andtonetw.org", $type, 0);
	should_fail("gopher://aInternetthela.Virtuallyso.software.communi.widelyTo.usedtheover.andeachS.com", $type, 0);
	should_fail("ftp://andbothreposit.regis.revolutioniz.oncreatedt.resourcesI.usingandmakeNI.org", $type, 0);
	should_fail("telnet://interoperabilit.donatea.portable.ofandE.knownforaut.bothNa.comput.isITLProvid.edu", $type, 0);
	should_fail("gopher://successand.isconformanto.enterprisesm.andErrorswes.devel.andAd.someModelA.com", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,5}\\.){1,4}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,5}\.){1,4}(?:$XML::RegExp::NameChar){3}$)/});
	should_fail("news://olderperfo.totempla.forlanguageth.thesethecreate.towidetotheb.abilitySchema.useofyears.edu", $type, 0);
	should_fail("telnet://filewithinD.thecomputera.byresidesitp.nointhemsi.arecreates.withtodocuments.accomplishsec.gov", $type, 0);
	should_fail("ftp://Businessdepe.thebenefitswo.SOCgovernment.referencech.deployedTh.aroledistrib.andXMLarepub.com", $type, 0);
	should_fail("gopher://vendor.buildfiles.theandparticip.browserssetTof.fororganiz.industry.edu", $type, 0);
	should_fail("telnet://anddisc.fromdesktopi.addition.onlypro.XMLasthet.versionss.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,10}\\.){1,3}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,10}\.){1,3}(?:$XML::RegExp::NameChar){3}$)/});
	should_fail("telnet://aboutdevelopm.referenceofreg.mustthebuildLan.ofamongAtois.andtheandmust.certainOASI.theInternetaan.thethetheseus.com", $type, 0);
	should_fail("gopher://CPUtographics.ebXMLArchitec.furthertheofa.thecomplexadd.fourcorrection.ofrelatedvo.com", $type, 0);
	should_fail("ftp://scomputingth.certaintheof.issueselectroni.thetechnologie.partnersofthis.gov", $type, 0);
	should_fail("gopher://forandandpervas.testingthisde.andStandardscha.DelawareandviaS.repositoryaProv.Organizationsp.theSchemassig.willbothsof.com", $type, 0);
	should_fail("telnet://registryourde.includecanof.testableleade.discoveryobtai.thatreferen.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet pattern with value \\c{3,6}://(\\c{1,7}\\.){1,3}\\c{3}." => sub {
	my $type = mk_type('AnyURI', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){3,6}:\/\/((?:$XML::RegExp::NameChar){1,7}\.){1,3}(?:$XML::RegExp::NameChar){3}$)/});
	should_fail("gopher://mustNISTproc.aselectronican.systemsstan.andwireles.Informationa.definecanfo.completi.wouldofanat.gov", $type, 0);
	should_fail("telnet://aparadigmsta.XMLstake.dataaregr.repositori.signaturesNat.andprocessdocum.gov", $type, 0);
	should_fail("news://understandthe.including.whichamong.partnerships.andsupplytest.contribut.forofhel.net", $type, 0);
	should_fail("ftp://distributed.anofandbusin.typespecific.databaseinclu.thesetestbrow.creationwhereTh.theconsortiu.supplyasv.edu", $type, 0);
	should_fail("ftp://availableobj.theDevelopand.thatmostfori.fromAnsignif.allowswo.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['http://ultimateapp.icati.gov','ftp://themNavalIn.ormati.com','telnet://specificati.nsknowinto.n.org','telnet://prototypeso.automating.rogramwebd.taofdistri.utedn.edu','http://www.mechanismao.participat.ngchaineb.edu','http://www.unbiasedsuc.essavailab.eaccessDOM.hetheXML.org']});
	should_fail("ftp://organizatio.sobjectneu.ralledtech.ol.gov", $type, 0);
	should_fail("http://systemsis.org", $type, 0);
	should_fail("ftp://ftp.theviaXMLme.rolo.edu", $type, 0);
	should_fail("http://www.i.com", $type, 0);
	should_fail("http://www.suchma.edu", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['telnet://OnlyOASISth.groupsInfor.com','news://compliantme.hods.org','ftp://backToolloc.tiondiscov.rprofilesi.fl.gov','gopher://Standardscr.atestheand.takeho.org','ftp://ftp.andpartners.mplementat.onscomp.gov']});
	should_fail("ftp://preciseboth.ndicationa.dOASISthis.othethetoo.s.edu", $type, 0);
	should_fail("gopher://theFacilita.iondomains.pecificati.nsofprovide.gov", $type, 0);
	should_fail("mailto:partnershipsbe\@itsofsoftwarenaturethatorganiza.gov", $type, 0);
	should_fail("news://standardsth.stakeholde.sfr.org", $type, 0);
	should_fail("ftp://ensurewayst.etoisSoftw.readdres.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['ftp://ftp.Theledamong.fforandass.ci.net','mailto:maint@thosemanipulateAwithdai.edu','http://andthebeare.sofsoftwar.rev.edu','telnet://otherthedis.ussionsfor.mplementat.onchoicesa.nfor.org','gopher://andataiTheo.specif.gov','http://pa.gov','ftp://andforcontr.buteOASISD.velopavail.bilitytest.n.edu','ftp://filehightra.sactionsas.ociatedaco.pliantasel.ctronic.gov','telnet://forconforman.net']});
	should_fail("telnet://DOMwiththeh.ssensorspro.gov", $type, 0);
	should_fail("ftp://ftp.specificati.nsthetarge.andn.gov", $type, 0);
	should_fail("telnet://fiveXSLalso.echnologie.TothetheXS.widewil.org", $type, 0);
	should_fail("ftp://DOMcontaini.ginobvious.ngofECst.gov", $type, 0);
	should_fail("http://www.collaborate.p.gov", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['ftp://specificati.nstoindust.ystandardi.ation.net','ftp://ftp.nextperform.ncemustANI.TCPUexerci.ela.com','mailto:areassimu@theminDOMeModelsignaturesspec.gov','http://forissuesmo.elstotocre.tesinengin.er.gov','telnet://setisspecif.cunb.edu','gopher://tochallen.org','http://www.theallowint.r.gov','http://t.edu','ftp://inallows.gov']});
	should_fail("http://www.issuesbysta.dardssigni.icantSXMLS.yles.net", $type, 0);
	should_fail("ftp://havingclean.hehashasFu.thermorewo.kSME.edu", $type, 0);
	should_fail("ftp://repositorie.organizati.nsofDOMthe.OASIS.org", $type, 0);
	should_fail("http://willthebyBu.inessneede.incan.org", $type, 0);
	should_fail("http://www.forNSRLfilt.r.org", $type, 0);
	done_testing;
};

subtest "Type atomic/anyURI is restricted by facet enumeration." => sub {
	my $type = mk_type('AnyURI', {'enumeration' => ['telnet://arereposito.yassociate.andAPIscon.orti.org','telnet://ofandtechno.ogiessens.org','telnet://specificMar.upfilerepo.itoryisfor.rovidecrea.ionT.gov','ftp://ftp.asthea.org','telnet://locationava.lablealack.gov','ftp://suiteutiliz.testab.edu','news://Co.net','gopher://aofOASIScre.tetemplate.comm.edu','http://testseameet.itssimu.edu']});
	should_fail("ftp://ftp.technologyk.ownHTMLtoo.sArchitect.ralch.net", $type, 0);
	should_fail("mailto:prominentEXiSTrais\@implementationsofitwellandexecu.gov", $type, 0);
	should_fail("http://suchItebXML.ecurityand.fw.org", $type, 0);
	should_fail("telnet://largehighth.AXMLvocabul.org", $type, 0);
	should_fail("http://Stylesheetf.rOrganizati.com", $type, 0);
	done_testing;
};

done_testing;

