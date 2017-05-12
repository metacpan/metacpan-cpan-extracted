use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/QName is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('QName', {'maxLength' => '1'});
	should_pass("d", $type, 0);
	should_pass("xthe:aand-be.qua", $type, 0);
	should_pass("_to:fby-execution_with_where_di", $type, 0);
	should_pass("ftestability.focusing-issues.measure-world_the", $type, 0);
	should_pass("amust.launching_the.and:greference-are_cooperation_contributo", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet maxLength with value 4." => sub {
	my $type = mk_type('QName', {'maxLength' => '4'});
	should_pass("r", $type, 0);
	should_pass("f:fprofile.where", $type, 0);
	should_pass("dof_business.fact.many_specific", $type, 0);
	should_pass("sfed.and_standards.s:fsoftware-systems-related", $type, 0);
	should_pass("isoftware.related_per:_use-success-commerce.other-computing-s", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet maxLength with value 57." => sub {
	my $type = mk_type('QName', {'maxLength' => '57'});
	should_pass("e", $type, 0);
	should_pass("uaddressing.make", $type, 0);
	should_pass("bwide.back_for.via_medium-sized", $type, 0);
	should_pass("eand_and-prod:ocomputers_as.by_that_that.these", $type, 0);
	should_pass("da_with.via.sense_and.development-by_this-and-specifications-", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet maxLength with value 61." => sub {
	my $type = mk_type('QName', {'maxLength' => '61'});
	should_pass("_", $type, 0);
	should_pass("esoftware-files.", $type, 0);
	should_pass("ffor-the-as.the-provide.that.fo", $type, 0);
	should_pass("mfiles.if.and-specifications_as-compliant.supp", $type, 0);
	should_pass("_interoperability_recent.suites-embedded_retrieves_that.perva", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('QName', {'maxLength' => '64'});
	should_pass("_", $type, 0);
	should_pass("sestablish_will.", $type, 0);
	should_pass("rmany-wil:kto.first_with-implem", $type, 0);
	should_pass("_be-are-systems_requires.of.is.software.data-w", $type, 0);
	should_pass("sand_and:gspecifications.be-and.of_wireless_accelerate-and.wh", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet minLength with value 1." => sub {
	my $type = mk_type('QName', {'minLength' => '1'});
	should_pass("r", $type, 0);
	should_pass("ecom:_partners.f", $type, 0);
	should_pass("ebe:mto-blocks.widespread-choic", $type, 0);
	should_pass("_or_techn:mas-of.wireless.is_of_as_and-to.busi", $type, 0);
	should_pass("xin-and.availa:his-provided_better-be.particularly-to-able-an", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet minLength with value 8." => sub {
	my $type = mk_type('QName', {'minLength' => '8'});
	should_pass("t", $type, 0);
	should_pass("rfor.related_on_", $type, 0);
	should_pass("xjoint_f:pand_for.web.repositor", $type, 0);
	should_pass("mquality.for-the_the.significant.versions_and-", $type, 0);
	should_pass("vdiagnost:atools_versions_for_support-for-be.if.first-generat", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet minLength with value 50." => sub {
	my $type = mk_type('QName', {'minLength' => '50'});
	should_pass("j", $type, 0);
	should_pass("ksi:bwith_techno", $type, 0);
	should_pass("eintuit:ptesting.is.mechanism.a", $type, 0);
	should_pass("tsoftw:cprimary.from.contained.the.is_for_serv", $type, 0);
	should_pass("ruser.pervasive_typ:qbuild-tool_these-both_advent-and.to.as.c", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet minLength with value 18." => sub {
	my $type = mk_type('QName', {'minLength' => '18'});
	should_pass("a", $type, 0);
	should_pass("_both.a:ythem_wo", $type, 0);
	should_pass("_has_is.file_u:was_key.file-fil", $type, 0);
	should_pass("his_support.for.retrieve.service_a.for-filter-", $type, 0);
	should_pass("oaspects_the_the_applications.and.and.computer.problems_indus", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('QName', {'minLength' => '64'});
	should_pass("d", $type, 0);
	should_pass("gprovides.cost-e", $type, 0);
	should_pass("urepository-that_file_and.many.", $type, 0);
	should_pass("fand.fed-to_is_fac:gand.will.as-the_enough_and", $type, 0);
	should_pass("yexecution.those.context-rich:_through_and_that-cross-referen", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet length with value 1." => sub {
	my $type = mk_type('QName', {'length' => '1'});
	should_pass("_", $type, 0);
	should_pass("_outfit:_this_st", $type, 0);
	should_pass("dw:fand_the-tools_heterogeneous", $type, 0);
	should_pass("vfor.the.define_portable_disseminate_allow.dat", $type, 0);
	should_pass("brecent-one-adoption-:lmore.include_allow_available_files_man", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet length with value 7." => sub {
	my $type = mk_type('QName', {'length' => '7'});
	should_pass("a", $type, 0);
	should_pass("qasked_fact_tech", $type, 0);
	should_pass("lof_:binteracting.and_of.build.", $type, 0);
	should_pass("x:frich-and-revolution.particularly-support_in", $type, 0);
	should_pass("_of_we-and_adoption_these_used-unbiased_documents.will-versio", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet length with value 33." => sub {
	my $type = mk_type('QName', {'length' => '33'});
	should_pass("e", $type, 0);
	should_pass("mretrieve-simple", $type, 0);
	should_pass("_met:ka.partnerships_reference-", $type, 0);
	should_pass("rits_test.of_tests-standard.different-registry", $type, 0);
	should_pass("sa.e_by.l:etests_criteria-of.networks-recognition-bandwidth_s", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet length with value 34." => sub {
	my $type = mk_type('QName', {'length' => '34'});
	should_pass("t", $type, 0);
	should_pass("win_ava:sdevices", $type, 0);
	should_pass("o:rfurther-and-and-around_the-w", $type, 0);
	should_pass("kincluding_define_implementation_structured_hi", $type, 0);
	should_pass("sin.associated-pico-cellular_:mchallenges_the-been-data-with.", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet length with value 64." => sub {
	my $type = mk_type('QName', {'length' => '64'});
	should_pass("h", $type, 0);
	should_pass("_w:lscreen-into_", $type, 0);
	should_pass("oled-digital-with-related-as-ch", $type, 0);
	should_pass("_project_will.technolo:keliminate_documents.co", $type, 0);
	should_pass("wbase.service.well.soft:_standards_enabling_measurement-a.for", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet pattern with value ([\\i-[:]][\\c-[:]]*:)?[\\i-[:]][\\c-[:]]{40}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('QName', {});
	should_pass("mas_the.and-significant.find-way.environm", $type, 0);
	should_pass("swork_must_and.partners-and:jmanage_and-of_partnerships.industry-prof", $type, 0);
	should_pass("ithe.by.and.tools.software-adoption-in-wi", $type, 0);
	should_pass("vnext-visibl:_with_bottlenecks_software.testability-in", $type, 0);
	should_pass("hare-and-to.which-of_stand:nbuild_one_help-having.to_objects.systems", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet pattern with value ([\\i-[:]][\\c-[:]]*:)?[\\i-[:]][\\c-[:]]{20}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('QName', {});
	should_pass("ithat.and_for_the.in_", $type, 0);
	should_pass("rwith_s.vir:ddevices.ensure.to_to", $type, 0);
	should_pass("uknow_provide.must_in", $type, 0);
	should_pass("qmanipul:vtestable-in.software", $type, 0);
	should_pass("_and-organization.to.its:qprovided-interoperab", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet pattern with value ([\\i-[:]][\\c-[:]]*:)?[\\i-[:]][\\c-[:]]{33}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('QName', {});
	should_pass("_buil:hby_to-of.to-computing_significant", $type, 0);
	should_pass("boffer_draft.obtained-to_systems-g", $type, 0);
	should_pass("_registry-both-understandi:opopular-processors.is-new_establi", $type, 0);
	should_pass("_chair_known-same.necessary.open_a", $type, 0);
	should_pass("ne:oenable-rapidly_pico-cellular.data", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet pattern with value ([\\i-[:]][\\c-[:]]*:)?[\\i-[:]][\\c-[:]]{27}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('QName', {});
	should_pass("_known.embed:fdiscover.to.transactional-w", $type, 0);
	should_pass("qg_o:oboth.to.location-that.of.sy", $type, 0);
	should_pass("luser-and-that.business_inte", $type, 0);
	should_pass("pvertical_on_industry-and-an", $type, 0);
	should_pass("_will_new.embedded-a_con:uand.and.well_efforts_busine", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet pattern with value ([\\i-[:]][\\c-[:]]*:)?[\\i-[:]][\\c-[:]]{58}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('QName', {});
	should_pass("pare.to-debug-discover.hardware-information-is_frameworks_i", $type, 0);
	should_pass("sall_ability.emerging-lacking_a.to-registry.are_retrieval_p", $type, 0);
	should_pass("_original:efirst_intelligent_industries_who.repository-as.the_to.defi", $type, 0);
	should_pass("yare-collaborate-specifications_measurement-the_their.which", $type, 0);
	should_pass("wregistries_and.organizations:pembedded-among_g_can.discovery_eliminated.and-language-dis", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet enumeration." => sub {
	my $type = mk_type('QName', {'enumeration' => ['_:cengine','_for.be_provide_relat','rinfluence-create_information_reviewed_as.re','_those-to_business_and.issues-data.for','wspecifications.emerging.that_and.is_','_also.to_t:pvocabularies_any-promi']});
	should_pass("_for.be_provide_relat", $type, 0);
	should_pass("_those-to_business_and.issues-data.for", $type, 0);
	should_pass("wspecifications.emerging.that_and.is_", $type, 0);
	should_pass("_for.be_provide_relat", $type, 0);
	should_pass("_:cengine", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet enumeration." => sub {
	my $type = mk_type('QName', {'enumeration' => ['_also.to_t:pvocabularies_any-promi','dpervasive:ndevelopment_be','awith.and-as.and-by-world.t:cinformation-information.langua','ncreate','c:xsolutions.filter_reviewed-led-allow_by_industry_pr','_a:vreach-s','kdomains-as.automatic-academia_work-ensure_tes']});
	should_pass("awith.and-as.and-by-world.t:cinformation-information.langua", $type, 0);
	should_pass("dpervasive:ndevelopment_be", $type, 0);
	should_pass("awith.and-as.and-by-world.t:cinformation-information.langua", $type, 0);
	should_pass("_a:vreach-s", $type, 0);
	should_pass("ncreate", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet enumeration." => sub {
	my $type = mk_type('QName', {'enumeration' => ['kdomains-as.automatic-academia_work-ensure_tes','lfine-d:vcomputing.of-as_','_languages-and-transforming.technologies.is_impa','xstandard-file_use-ea','_lan:iand-must.effecti','ton.and_its.t','yinvolved.e-effor','q:tthe.with-']});
	should_pass("ton.and_its.t", $type, 0);
	should_pass("_lan:iand-must.effecti", $type, 0);
	should_pass("xstandard-file_use-ea", $type, 0);
	should_pass("lfine-d:vcomputing.of-as_", $type, 0);
	should_pass("_languages-and-transforming.technologies.is_impa", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet enumeration." => sub {
	my $type = mk_type('QName', {'enumeration' => ['q:tthe.with-','etransforming-specific.emerging_is-developed.act_rela','yof_automatic-partnerships.and.set-series_is.key.e','fand_is_include.voca:jwork.tools-and.widely.electronic_manipul','tmany-retrieval-with_language.both-be.results-is-of-b','ito_d:lcomputing-object_for_a_must-be-from-design-ro','_interoperability.s.led_also-specifications_provide_with.is.thu','_the:lwhich_','uthe.base_the_ability-into-target_the_testability-discove']});
	should_pass("yof_automatic-partnerships.and.set-series_is.key.e", $type, 0);
	should_pass("ito_d:lcomputing-object_for_a_must-be-from-design-ro", $type, 0);
	should_pass("fand_is_include.voca:jwork.tools-and.widely.electronic_manipul", $type, 0);
	should_pass("ito_d:lcomputing-object_for_a_must-be-from-design-ro", $type, 0);
	should_pass("etransforming-specific.emerging_is-developed.act_rela", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet enumeration." => sub {
	my $type = mk_type('QName', {'enumeration' => ['uthe.base_the_ability-into-target_the_testability-discove','_for-files.supply.for.to-must_measur','d:i','ps.pervasive.in-house_on.performance-als','_build.retrieves.cor:_among.to.must_and.industry-from-that_','hmanipulate-us']});
	should_pass("d:i", $type, 0);
	should_pass("_for-files.supply.for.to-must_measur", $type, 0);
	should_pass("d:i", $type, 0);
	should_pass("_for-files.supply.for.to-must_measur", $type, 0);
	should_pass("d:i", $type, 0);
	done_testing;
};

subtest "Type atomic/QName is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('QName', {'whiteSpace' => 'collapse'});
	should_pass("mis.both_to.such-info", $type, 0);
	should_pass("fcertai:sfor.test_ver", $type, 0);
	should_pass("iinformation.testing.", $type, 0);
	should_pass("fto.foru:rin.process-", $type, 0);
	should_pass("_test_library_to.medi", $type, 0);
	done_testing;
};

done_testing;

