use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/Name is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('Name', {'maxLength' => '1'});
	should_pass("h", $type, 0);
	should_pass("j", $type, 0);
	should_pass("y", $type, 0);
	should_pass("_", $type, 0);
	should_pass("w", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 2." => sub {
	my $type = mk_type('Name', {'maxLength' => '2'});
	should_pass("e", $type, 0);
	should_pass("w", $type, 0);
	should_pass("o", $type, 0);
	should_pass("p", $type, 0);
	should_pass("w", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 11." => sub {
	my $type = mk_type('Name', {'maxLength' => '11'});
	should_pass(":", $type, 0);
	should_pass("fin", $type, 0);
	should_pass("cmeth", $type, 0);
	should_pass("ythe:fi", $type, 0);
	should_pass("_the_an-i", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 24." => sub {
	my $type = mk_type('Name', {'maxLength' => '24'});
	should_pass("l", $type, 0);
	should_pass("_langu", $type, 0);
	should_pass("sof.emergin", $type, 0);
	should_pass(":among.systems-s", $type, 0);
	should_pass("vfor_portable.in_oper", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('Name', {'maxLength' => '64'});
	should_pass("i", $type, 0);
	should_pass("_information-div", $type, 0);
	should_pass(":the:for:wireless.reference:as:", $type, 0);
	should_pass("_led_technology-allow:competence:next_a:well.n", $type, 0);
	should_pass("gand.sense_of:academia_the-the.the:to_and_ensure-for.eliminat", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 1." => sub {
	my $type = mk_type('Name', {'minLength' => '1'});
	should_pass("_", $type, 0);
	should_pass("kthe.appropriate", $type, 0);
	should_pass(":the_international.of_as-as-cos", $type, 0);
	should_pass("xregistry:shift.business:known-eliminated.of.s", $type, 0);
	should_pass("maddress-chosen:correction_technologies-including-the.testing", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 63." => sub {
	my $type = mk_type('Name', {'minLength' => '63'});
	should_pass("_ensure-thus.localized:second-generation:templates.of.annual:by", $type, 0);
	should_pass("hif.testability_partnership-manipulation.transforming_allow-as:", $type, 0);
	should_pass("fwill-created.into:processes-filter_them-be.the_chairing-can:di", $type, 0);
	should_pass("dand.entire_recommending-organizations.development_on.in.of_voc", $type, 0);
	should_pass("fand:work:used:community_paradigm.filter:defining.the_repositor", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 28." => sub {
	my $type = mk_type('Name', {'minLength' => '28'});
	should_pass("isoftware_made.tremendous:wi", $type, 0);
	should_pass("dif-the-security:files-5_with-with-it", $type, 0);
	should_pass("eto-to-with.concepts.implementation-respect_be", $type, 0);
	should_pass(":the_industry:discussions-as:hardware.for_these.and:res", $type, 0);
	should_pass("pthe_retrieve_fact-the:be_with-language:back_modeling:the.manipu", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 54." => sub {
	my $type = mk_type('Name', {'minLength' => '54'});
	should_pass("mengineering.devices_these.used:distributed_projector.", $type, 0);
	should_pass("xobjects:and:systems-conformance.the_which:the_own_to-to", $type, 0);
	should_pass("cdeveloping:be.information-creation-both-will.repository:i", $type, 0);
	should_pass("jto:interconnected.and-system.a-manual-the.for:specific:prov", $type, 0);
	should_pass(":use_chain-lack.most:measure-help:the-creating:into.discovery:", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('Name', {'minLength' => '64'});
	should_pass("pconsortiums_known:the:the_market_include_the-revisions-role_mat", $type, 0);
	should_pass("wall_cooperation-to_industries:commerce_hardware.and:high.and-vo", $type, 0);
	should_pass("ghelp.of-into:used-alike-performance-contains.the_the_back_coope", $type, 0);
	should_pass("uusing-organizations.with-who-need-in_automating:as:can:the_be.s", $type, 0);
	should_pass("wis.for-within_from-of.e.for_development_the:personal:of-reputat", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 1." => sub {
	my $type = mk_type('Name', {'length' => '1'});
	should_pass("x", $type, 0);
	should_pass("_", $type, 0);
	should_pass("e", $type, 0);
	should_pass("q", $type, 0);
	should_pass(":", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 8." => sub {
	my $type = mk_type('Name', {'length' => '8'});
	should_pass("ssyntax:", $type, 0);
	should_pass("jto_of.f", $type, 0);
	should_pass("hcompone", $type, 0);
	should_pass("jenforce", $type, 0);
	should_pass("_tools-s", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 60." => sub {
	my $type = mk_type('Name', {'length' => '60'});
	should_pass("yallow.results_of.for_the_is:involved:of:be.daily.led-an.ref", $type, 0);
	should_pass("iwill-computing.other.software.ambiguities-heterogeneous-bus", $type, 0);
	should_pass("_its:resource-fact-new-tools.communication:availability.a:da", $type, 0);
	should_pass("gincluding_other:manipulate_be_users.signature:no.enforcemen", $type, 0);
	should_pass("kportable_and.related-appropriate_user-including.pervasive:f", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 6." => sub {
	my $type = mk_type('Name', {'length' => '6'});
	should_pass("iis_us", $type, 0);
	should_pass("ilink:", $type, 0);
	should_pass("iof-ro", $type, 0);
	should_pass(":measu", $type, 0);
	should_pass("fsubje", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 64." => sub {
	my $type = mk_type('Name', {'length' => '64'});
	should_pass("sinformation-to_is_industry_engineering_object-models-voiced-and", $type, 0);
	should_pass("kis.the-with_a.competence:used-collaborate_technologies-informat", $type, 0);
	should_pass("dmanipulation.on-data_made-supply.will-a:to:implementations-tool", $type, 0);
	should_pass(":define_performance.the:conformance-management_developing_from_g", $type, 0);
	should_pass("oway:a-into-system:we-support:interoperability.led.with_the:the_", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet pattern with value \\i\\c{45}." => sub {
	my $type = mk_type('Name', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar)(?:$XML::RegExp::NameChar){45}$)/});
	should_pass("finteroperability-these_files-print:a_into_or:", $type, 0);
	should_pass("icomputing_will:includes:capabilities:need:to:", $type, 0);
	should_pass("yrecognition.will:security_automating_library_", $type, 0);
	should_pass("wfor-and_obvious_rich_technologies:ensure:indu", $type, 0);
	should_pass("athe.appropriate.landscape-browsers-and.donate", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet pattern with value \\i\\c{52}." => sub {
	my $type = mk_type('Name', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar)(?:$XML::RegExp::NameChar){52}$)/});
	should_pass("ldesktop_object.needs_some:in:collaborating.of-be:app", $type, 0);
	should_pass("rsignatures:the_are:degree_over_is:tests_technologies", $type, 0);
	should_pass("uthe:profile-documents-of-we:and_recent_the_own-using", $type, 0);
	should_pass(":provide.systems.for.specifications.partnerships-of:t", $type, 0);
	should_pass("himpact:filter.computer.for_than.the.must_success.cor", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet pattern with value \\i\\c{32}." => sub {
	my $type = mk_type('Name', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar)(?:$XML::RegExp::NameChar){32}$)/});
	should_pass(":a-a.and_s-for-used_means-high_we", $type, 0);
	should_pass("_the.the-a:raised-to-review-to-hi", $type, 0);
	should_pass("gleadership_interacting_test.avai", $type, 0);
	should_pass("ywith_and.emerging.computer_to_be", $type, 0);
	should_pass("isoftware_graphical-the_areas.tim", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet pattern with value \\i\\c{14}." => sub {
	my $type = mk_type('Name', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar)(?:$XML::RegExp::NameChar){14}$)/});
	should_pass("fof-for-pervasi", $type, 0);
	should_pass(":necessary_auto", $type, 0);
	should_pass("tdata_also_seri", $type, 0);
	should_pass("irelated-ensure", $type, 0);
	should_pass("_to.help.approp", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet pattern with value \\i\\c{31}." => sub {
	my $type = mk_type('Name', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar)(?:$XML::RegExp::NameChar){31}$)/});
	should_pass("lscreen-contribute:2001.reposito", $type, 0);
	should_pass("mmore-s:software:and:each_a:to-f", $type, 0);
	should_pass("dcan_graphical-for.the.daily.all", $type, 0);
	should_pass("_computer_these:through-build_da", $type, 0);
	should_pass("fof.effectively_areas-the:templa", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet enumeration." => sub {
	my $type = mk_type('Name', {'enumeration' => ['_particular:as_participants:standardization.dat','lsoftware-quality_and:interoperability:in-commerce-test:will:.g','rthe:enabling-set_from:d','tprimary-need:the:documents_maintai',':processes_and.both.fi','ais_profiles:academia:for-be',':and-a:including_as.the-coupled.in.complex:this-at:and.a_i','oand.leadership_the.as-manufacturers_th']});
	should_pass("lsoftware-quality_and:interoperability:in-commerce-test:will:.g", $type, 0);
	should_pass("tprimary-need:the:documents_maintai", $type, 0);
	should_pass("ais_profiles:academia:for-be", $type, 0);
	should_pass(":processes_and.both.fi", $type, 0);
	should_pass(":processes_and.both.fi", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet enumeration." => sub {
	my $type = mk_type('Name', {'enumeration' => ['uof.retrieve:the_provided_specific_in_systems-on-a-chi','pis_known:over.allow.','_discovery:designed_graphics_perv','jregistry.interoperability_hampered-o','_great-desk','ra-the-partners-that-pervasive.by_challenges:discover','pnext:creat','yr']});
	should_pass("ra-the-partners-that-pervasive.by_challenges:discover", $type, 0);
	should_pass("yr", $type, 0);
	should_pass("ra-the-partners-that-pervasive.by_challenges:discover", $type, 0);
	should_pass("_discovery:designed_graphics_perv", $type, 0);
	should_pass("uof.retrieve:the_provided_specific_in_systems-on-a-chi", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet enumeration." => sub {
	my $type = mk_type('Name', {'enumeration' => ['uprocessors:for.publishing:methods.for:an-with:included:impleme','_and-dat','ibusiness_processes-language-chain',':specificatio',':medium-sized-testing-to:users:and-registries_su','_to_the:has_to:launchi','gprovide-back.the-are:and_shift.and-creation:is-']});
	should_pass("_and-dat", $type, 0);
	should_pass(":specificatio", $type, 0);
	should_pass("ibusiness_processes-language-chain", $type, 0);
	should_pass(":specificatio", $type, 0);
	should_pass("_to_the:has_to:launchi", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet enumeration." => sub {
	my $type = mk_type('Name', {'enumeration' => ['sprovided:i','prigorous.must.than.s','jgeneration-deployed-consistency_vo','rservices:and:electronic_th','jfor.enabling-around-eliminated-to.for-business-oriented_i','ocan:has_of:to.unambi','mis:and.to:high-use:conference']});
	should_pass("prigorous.must.than.s", $type, 0);
	should_pass("rservices:and:electronic_th", $type, 0);
	should_pass("ocan:has_of:to.unambi", $type, 0);
	should_pass("jfor.enabling-around-eliminated-to.for-business-oriented_i", $type, 0);
	should_pass("prigorous.must.than.s", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet enumeration." => sub {
	my $type = mk_type('Name', {'enumeration' => [':to.environments-define.it.issues.t',':fi','rand_to.and-the.c','_these-known.quality.application_available.the.','papplication_the-object.object_computing_can','dand_applica']});
	should_pass("papplication_the-object.object_computing_can", $type, 0);
	should_pass(":to.environments-define.it.issues.t", $type, 0);
	should_pass("_these-known.quality.application_available.the.", $type, 0);
	should_pass("rand_to.and-the.c", $type, 0);
	should_pass("dand_applica", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Name', {'whiteSpace' => 'collapse'});
	should_pass("tstandardization.a.retrie", $type, 0);
	should_pass("gfact:foster:own.and.inte", $type, 0);
	should_pass("pfact_testing.the_from:or", $type, 0);
	should_pass("_files-to:by_to_providing", $type, 0);
	should_pass(":body_signatures-testing_", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 8." => sub {
	my $type = mk_type('Name', {'minLength' => '8'});
	should_fail("n", $type, 0);
	should_fail("db", $type, 0);
	should_fail("dfo", $type, 0);
	should_fail("yind", $type, 0);
	should_fail("glead", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 13." => sub {
	my $type = mk_type('Name', {'minLength' => '13'});
	should_fail("f", $type, 0);
	should_fail("vto", $type, 0);
	should_fail(":do-t", $type, 0);
	should_fail("mas:eme", $type, 0);
	should_fail("rand:is-r", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 58." => sub {
	my $type = mk_type('Name', {'minLength' => '58'});
	should_fail("i", $type, 0);
	should_fail("xcomputing.the-", $type, 0);
	should_fail(":that:will:a:between_precise:", $type, 0);
	should_fail("vfurther_work-adoption.is.web_significant:a", $type, 0);
	should_fail("dtest.choices_the:unbiased:software-are-standards:from-in", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 4." => sub {
	my $type = mk_type('Name', {'minLength' => '4'});
	should_fail("y", $type, 0);
	should_fail("r", $type, 0);
	should_fail("r", $type, 0);
	should_fail("p", $type, 0);
	should_fail("r", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('Name', {'minLength' => '64'});
	should_fail("j", $type, 0);
	should_fail("cchoices_of.adop", $type, 0);
	should_fail("letc-include_target-base.meet-r", $type, 0);
	should_fail("ifor_displaying:environments:developers:e-test", $type, 0);
	should_fail("qto.interoperability_the:the_with.analysis.ad-are.capabilitie", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('Name', {'maxLength' => '1'});
	should_fail("ri", $type, 0);
	should_fail("hof_project-a_pro", $type, 0);
	should_fail("_as:cost_web:chairs.asked_is_is_", $type, 0);
	should_fail(":computing-hardware-older-is-computing_intercon", $type, 0);
	should_fail("lpopular-define-organizations.a.neutral.the.registry:these-bac", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 31." => sub {
	my $type = mk_type('Name', {'maxLength' => '31'});
	should_fail("ebusiness-file-life:allow:to_voc", $type, 0);
	should_fail("yand_tools.program-measure_discover_incl", $type, 0);
	should_fail("edocuments_networking.the.revisions_back-revolut", $type, 0);
	should_fail("jan-for-testing:for.robust_for:e:wide_technologies.about", $type, 0);
	should_fail("qa-registries.for.provides_to:lack.and-and.interoperability:retr", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 39." => sub {
	my $type = mk_type('Name', {'maxLength' => '39'});
	should_fail("_and.used:of:to.will-effort.provide_is:m", $type, 0);
	should_fail(":this:applications-targeted_files_any-all_from", $type, 0);
	should_fail("_development:s:and_for:must_specifications-and:and.p", $type, 0);
	should_fail("jcomputing-a-files.supply:such.build_work-resources_to-sta", $type, 0);
	should_fail("_as.that:community-can_their.from:clean.small-.retrieve-reproduc", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 53." => sub {
	my $type = mk_type('Name', {'maxLength' => '53'});
	should_fail("ffilter_file.provided-the.in.technologies_for:security", $type, 0);
	should_fail("_000_a:further-more:information-chair:be_standardization", $type, 0);
	should_fail("aunder-use-information.for.the:to.high_to.of.means.to_will", $type, 0);
	should_fail("_test:will_organizations-these.for:database-software-used_ch", $type, 0);
	should_fail("dapplications:being_is-to_techniques:neutral_to.language.diagn", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('Name', {'maxLength' => '64'});
	should_fail("xpervasive_of-related.and:reference_clean:to_environments.informa", $type, 0);
	should_fail("jusing.individual.utilities.logic_by:government:a:to-the-that.digital:software_i", $type, 0);
	should_fail("teach.those_investigation_technologies.directions_other:in:to:the:industry-filter.voice-enabled", $type, 0);
	should_fail("fcomputing:neutral:a-a-tools:reference.a_between-for:supply.users_for.performance_for.by:can-the_and:and-infor", $type, 0);
	should_fail("kdiscussions.intuitive_specification:to:commerce_standardization_and.object_of:will-impact:and_ensure-use:any-these_suites-de", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 1." => sub {
	my $type = mk_type('Name', {'length' => '1'});
	should_fail("ip", $type, 0);
	should_fail("nraised_partnersh", $type, 0);
	should_fail("_measurements.s_build:these-and.", $type, 0);
	should_fail("msense:variety_testing.the.and:access_areas-to-", $type, 0);
	should_fail("ptheir-tools.for-the:business_of:that-being:partners:manipulat", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 38." => sub {
	my $type = mk_type('Name', {'length' => '38'});
	should_fail("_", $type, 0);
	should_fail("fto-and.is", $type, 0);
	should_fail("hand.the-will:creat", $type, 0);
	should_fail("qto.next_business-as:and-sys", $type, 0);
	should_fail("yover-and.reference-throughout.for_th", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 29." => sub {
	my $type = mk_type('Name', {'length' => '29'});
	should_fail("tcost-location_rigorous:the_ra", $type, 0);
	should_fail("lchallenges:browsers.documents-impleme", $type, 0);
	should_fail("isuch.development-methods-must_be-correctness.", $type, 0);
	should_fail("puse:repositories_file:and:recommending.an:that-files.", $type, 0);
	should_fail("rmanage_objects-users:specification:consortium-the_define-all.", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 31." => sub {
	my $type = mk_type('Name', {'length' => '31'});
	should_fail("gnew-achieved:images.systems-com", $type, 0);
	should_fail("lregistry.this.for_joint.developed.organ", $type, 0);
	should_fail("eincluded.in.many-localized_as-repository:discus", $type, 0);
	should_fail("tall_repository:file_must-development.to:some:between:5.", $type, 0);
	should_fail("yfiles_by:for.also_and-developed-widely-modeling-and-acting.thos", $type, 0);
	done_testing;
};

subtest "Type atomic/Name is restricted by facet length with value 64." => sub {
	my $type = mk_type('Name', {'length' => '64'});
	should_fail(":", $type, 0);
	should_fail("_networks-to_wil", $type, 0);
	should_fail("cbeing-specific:be.business_the", $type, 0);
	should_fail("oas:accessible:the-made.has.will-mediums:the-t", $type, 0);
	should_fail("na_of-led_in.the_be:by_original_from.tasks::these:annual:upon", $type, 0);
	done_testing;
};

done_testing;

