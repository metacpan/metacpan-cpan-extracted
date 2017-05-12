use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/ID is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('Id', {'maxLength' => '1'});
	should_pass("_", $type, 0);
	should_pass("a", $type, 0);
	should_pass("f", $type, 0);
	should_pass("r", $type, 0);
	should_pass("_", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 62." => sub {
	my $type = mk_type('Id', {'maxLength' => '62'});
	should_pass("f", $type, 0);
	should_pass("ofollowing.worki", $type, 0);
	should_pass("tthe.the.revolutionize.of_retri", $type, 0);
	should_pass("vlibraries_building_developing.computing_for_d", $type, 0);
	should_pass("qassociated_robust-the.the_and-working-eliminate-participants", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 58." => sub {
	my $type = mk_type('Id', {'maxLength' => '58'});
	should_pass("w", $type, 0);
	should_pass("abeing_g.and-fi", $type, 0);
	should_pass("dthat_known-a.been-enable_wor", $type, 0);
	should_pass("ttransact-information-under-as_documents_th", $type, 0);
	should_pass("_is.development-success.which_technologies_than.registry.", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 22." => sub {
	my $type = mk_type('Id', {'maxLength' => '22'});
	should_pass("n", $type, 0);
	should_pass("cdisco", $type, 0);
	should_pass("dwithin-and", $type, 0);
	should_pass("cfurther_devices", $type, 0);
	should_pass("ttools.implementation", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('Id', {'maxLength' => '64'});
	should_pass("h", $type, 0);
	should_pass("drepository.prot", $type, 0);
	should_pass("tfor.software_portable.will_doc", $type, 0);
	should_pass("_key.not.devices_software.of_is_including_for.", $type, 0);
	should_pass("bfiles.business_both.a.to_more_and.type.information.to_reposi", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 1." => sub {
	my $type = mk_type('Id', {'minLength' => '1'});
	should_pass("t", $type, 0);
	should_pass("_consistency_mat", $type, 0);
	should_pass("pintelligent.these_enable.build", $type, 0);
	should_pass("_are.can_cross-reference-for_test.well_files.m", $type, 0);
	should_pass("fand-and-development-build-widely.only_systems-these_for_stan", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 45." => sub {
	my $type = mk_type('Id', {'minLength' => '45'});
	should_pass("_mechanism-tools.to.for_documents_application", $type, 0);
	should_pass("_2001-both_law_them-that_to-allows_asking.the-sma", $type, 0);
	should_pass("yand.of_years_a-to.among-methods.electronic.these_inf", $type, 0);
	should_pass("cforensics_their_implementations.and.be_and-means_create-", $type, 0);
	should_pass("iand-large.and-to-the-supply.cooperation-languages-each.filte", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 58." => sub {
	my $type = mk_type('Id', {'minLength' => '58'});
	should_pass("_well.lack-retrieval.improved-and-between.file.annual.that", $type, 0);
	should_pass("_business-oriented.generation-related-industry-browsers_dev", $type, 0);
	should_pass("jcan_role_own_libraries-for-involved_this.will_business-and.", $type, 0);
	should_pass("dthe_using.specifications.would.organizations_the.computing_b", $type, 0);
	should_pass("ffor_specifications.divisions_without.from.this.rapid_with_res", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 6." => sub {
	my $type = mk_type('Id', {'minLength' => '6'});
	should_pass("tis-be", $type, 0);
	should_pass("cfiles-of_a_suites_f", $type, 0);
	should_pass("lfacilitates.new-computing-build-o", $type, 0);
	should_pass("afor-to_for-and-work_widespread.through_effort-c", $type, 0);
	should_pass("vtoday.result-security_files_information-as.of-as.in_chosen_as", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('Id', {'minLength' => '64'});
	should_pass("xbe-to_bandwidth.the-are_information_and.software_annual.quality", $type, 0);
	should_pass("_degree_resides-environments-the-software_infrastructure.use-app", $type, 0);
	should_pass("uregistries-transforming_interoperability.as.targeted.from-imple", $type, 0);
	should_pass("wbandwidth.new.are-management_specifications_vocabularies.device", $type, 0);
	should_pass("hbe-under_all_related_provides.community.problems-ways.and_langu", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 1." => sub {
	my $type = mk_type('Id', {'length' => '1'});
	should_pass("c", $type, 0);
	should_pass("_", $type, 0);
	should_pass("l", $type, 0);
	should_pass("_", $type, 0);
	should_pass("_", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 57." => sub {
	my $type = mk_type('Id', {'length' => '57'});
	should_pass("athat-system_the.development_the.that_entire_launching_re", $type, 0);
	should_pass("gspecifications-web.in.g_automatically_four-resides.perso", $type, 0);
	should_pass("msolutions-and.sense_mechanism_a-of-this.need-gain_used.w", $type, 0);
	should_pass("_and.a.that-would_are-the-create.requires.repository.led-", $type, 0);
	should_pass("bindustries_in-of_structure_means-revolutionize_to-networ", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 24." => sub {
	my $type = mk_type('Id', {'length' => '24'});
	should_pass("pdraft.and_manipulation-", $type, 0);
	should_pass("jof.of.complete-meets_no", $type, 0);
	should_pass("_as_information-build_wa", $type, 0);
	should_pass("nbe.file-these-rapidly-d", $type, 0);
	should_pass("swhich_improved_years.sp", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 8." => sub {
	my $type = mk_type('Id', {'length' => '8'});
	should_pass("ythe-bus", $type, 0);
	should_pass("uthrough", $type, 0);
	should_pass("qto-whic", $type, 0);
	should_pass("_profile", $type, 0);
	should_pass("wto.in-h", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 64." => sub {
	my $type = mk_type('Id', {'length' => '64'});
	should_pass("vcomputing.standardization_creation_enable-and-one_of-robust-ref", $type, 0);
	should_pass("_profile-and_a-object.for_revolution-will-used_repository_displa", $type, 0);
	should_pass("pused-pervasive-appropriate-used_tremendous-must.to.e_devices-de", $type, 0);
	should_pass("fsoftware-software-ability.supply_and_will-software_software-mad", $type, 0);
	should_pass("bwill.all_for_formed.database.be_efforts.with.and-is-as-foster_c", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{11}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('Id', {});
	should_pass("_execution_b", $type, 0);
	should_pass("ufor-needed.", $type, 0);
	should_pass("yindustry-in", $type, 0);
	should_pass("ucomputer.th", $type, 0);
	should_pass("sinformation", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{55}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('Id', {});
	should_pass("ncross-reference-the_be-collaborate_systems-e-to.the_par", $type, 0);
	should_pass("yincluding_the_with_use.tools.20_the_retrieves_help-the.", $type, 0);
	should_pass("uand_are_provide-including.as-discovery-system_is.offer_", $type, 0);
	should_pass("_organization_influence_systems-a-which_pervasive-pervas", $type, 0);
	should_pass("iversions.visibly_and.languages-use.the-versions-tools.c", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{18}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('Id', {});
	should_pass("hand-some.the.parti", $type, 0);
	should_pass("_to_contribute_stim", $type, 0);
	should_pass("ktune-degree.from_c", $type, 0);
	should_pass("xbe-the-sensors.als", $type, 0);
	should_pass("hindustry_and-the-a", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{15}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('Id', {});
	should_pass("kvertical-for.al", $type, 0);
	should_pass("wto_development-", $type, 0);
	should_pass("tand.must.provid", $type, 0);
	should_pass("ycollaborating_t", $type, 0);
	should_pass("_competence_comm", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{36}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('Id', {});
	should_pass("jsystems_resources_further_without.ba", $type, 0);
	should_pass("xwill-manipulation.of.describes_and_a", $type, 0);
	should_pass("_build_process_transactional.around_w", $type, 0);
	should_pass("sadoption-set_and.computing.original.", $type, 0);
	should_pass("wusing.asking-library-one-be.commerce", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet enumeration." => sub {
	my $type = mk_type('Id', {'enumeration' => ['itemplates.resource_','horganiz','_work-of-is-documents_relationships-of_at.object','maccomplish.versions.care.define-and.pr','dallow-success-of_devices_enough_the.retrieve','_manufacturers_information.world_th','hdocuments-impact']});
	should_pass("_manufacturers_information.world_th", $type, 0);
	should_pass("_work-of-is-documents_relationships-of_at.object", $type, 0);
	should_pass("dallow-success-of_devices_enough_the.retrieve", $type, 0);
	should_pass("maccomplish.versions.care.define-and.pr", $type, 0);
	should_pass("hdocuments-impact", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet enumeration." => sub {
	my $type = mk_type('Id', {'enumeration' => ['jrequesting-methods-in','pdata_technologies-will-that_their-at_me','tresult-a-of-methods-as.of-networks_and.specifica','mindustry.designed_match.and.influence_to_those.will','jmethods-wide.utilize-known-data-organizatio','_of_of_a-conferences_prominent-organizations-as_recent_te','svisibly.registry_is_support_for-will.industry-in_provide.and','lrigorous-be-pr']});
	should_pass("svisibly.registry_is_support_for-will.industry-in_provide.and", $type, 0);
	should_pass("svisibly.registry_is_support_for-will.industry-in_provide.and", $type, 0);
	should_pass("tresult-a-of-methods-as.of-networks_and.specifica", $type, 0);
	should_pass("_of_of_a-conferences_prominent-organizations-as_recent_te", $type, 0);
	should_pass("_of_of_a-conferences_prominent-organizations-as_recent_te", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet enumeration." => sub {
	my $type = mk_type('Id', {'enumeration' => ['hin.and-software-hardware-a','wto-to.the_and.appr','hinteroperability.used.revolution.methods.systems.cost_ena','_with.measurements.lacking.degree-using_in-co','qprim','uservices_all_of_','mthe_issues_of_creation-bro','tand-performance-can_']});
	should_pass("wto-to.the_and.appr", $type, 0);
	should_pass("uservices_all_of_", $type, 0);
	should_pass("hin.and-software-hardware-a", $type, 0);
	should_pass("hin.and-software-hardware-a", $type, 0);
	should_pass("qprim", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet enumeration." => sub {
	my $type = mk_type('Id', {'enumeration' => ['_for.newcomers_for-resources.forum_and-than.maintained-series-','iimpact-the.devices_templates_sy','nsoftware.the.from_commerce_using-','hi','lprovides.discover.over.clean.rel','qban','wregistries_result_made_key.the.of_without_the.can.organizatio','stesting-addressing_th']});
	should_pass("iimpact-the.devices_templates_sy", $type, 0);
	should_pass("lprovides.discover.over.clean.rel", $type, 0);
	should_pass("stesting-addressing_th", $type, 0);
	should_pass("lprovides.discover.over.clean.rel", $type, 0);
	should_pass("hi", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet enumeration." => sub {
	my $type = mk_type('Id', {'enumeration' => ['ba','ca','efor','hregistry.as.on-work.u','_its-includ']});
	should_pass("hregistry.as.on-work.u", $type, 0);
	should_pass("ca", $type, 0);
	should_pass("hregistry.as.on-work.u", $type, 0);
	should_pass("hregistry.as.on-work.u", $type, 0);
	should_pass("hregistry.as.on-work.u", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Id', {'whiteSpace' => 'collapse'});
	should_pass("yto-by_process-primarily-type_revolution.and-the_te", $type, 0);
	should_pass("rorganization.cooperation-to.of-under.in-the.in-app", $type, 0);
	should_pass("_information.define.screen_interconnected-that_adve", $type, 0);
	should_pass("unetworking.technology_of-provide-developed_ways_th", $type, 0);
	should_pass("ithe_g.other-improved_asking-metrology-number_e.and", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 53." => sub {
	my $type = mk_type('Id', {'minLength' => '53'});
	should_fail("w", $type, 0);
	should_fail("hheterogeneou", $type, 0);
	should_fail("rwill.product-the-that-ou", $type, 0);
	should_fail("achain_will_and_must_from.those-print", $type, 0);
	should_fail("dcommerce.understand_in-the.pervasive.second-gene", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 39." => sub {
	my $type = mk_type('Id', {'minLength' => '39'});
	should_fail("g", $type, 0);
	should_fail("_must.web.", $type, 0);
	should_fail("vweb.in-global-with", $type, 0);
	should_fail("gtwo.performance.templates-t", $type, 0);
	should_fail("_registry-from_software-industry_with", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 33." => sub {
	my $type = mk_type('Id', {'minLength' => '33'});
	should_fail("l", $type, 0);
	should_fail("_annual.", $type, 0);
	should_fail("wincluding-fed.", $type, 0);
	should_fail("ga_a-business.the-help", $type, 0);
	should_fail("gdata_respect_the_commerce_th", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 3." => sub {
	my $type = mk_type('Id', {'minLength' => '3'});
	should_fail("s", $type, 0);
	should_fail("o", $type, 0);
	should_fail("_", $type, 0);
	should_fail("o", $type, 0);
	should_fail("v", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('Id', {'minLength' => '64'});
	should_fail("a", $type, 0);
	should_fail("rraised_approach", $type, 0);
	should_fail("_for.for_and-filter-and_its.par", $type, 0);
	should_fail("ospecifications.used_industries_mediums.each-t", $type, 0);
	should_fail("_can-used.lack-the.exchange.automatic.contributor-is_each_dis", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('Id', {'maxLength' => '1'});
	should_fail("_v", $type, 0);
	should_fail("hthat-describes.t", $type, 0);
	should_fail("lmust-specifications_both.work_t", $type, 0);
	should_fail("aclean.used.and-included.these_debug_for.relate", $type, 0);
	should_fail("jbe.security-standards_the_service.methods.original_as.as_tool", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 7." => sub {
	my $type = mk_type('Id', {'maxLength' => '7'});
	should_fail("sopen.te", $type, 0);
	should_fail("kthat-personal_testing", $type, 0);
	should_fail("uour_respect.has-and-participate_dis", $type, 0);
	should_fail("pas_discovery.as_well-systems-the.target_and_intui", $type, 0);
	should_fail("band.technologies.as.by_become_specifications.transforming_well-", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 62." => sub {
	my $type = mk_type('Id', {'maxLength' => '62'});
	should_fail("acost_can.documents_of_know-tools.s_tools.than-and_enabling_cro", $type, 0);
	should_fail("_for.to.set-software_is.this.the_language-better.and_the_to-app", $type, 0);
	should_fail("hhaving-regard_includes-of.to_and.market_be_computing_and_neede", $type, 0);
	should_fail("ipartnerships.and_diagnostic.commerce_projector_files_dynamic-p", $type, 0);
	should_fail("fuse-the_and-to.reputation_web.on-is-industry.transforming_perv", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 25." => sub {
	my $type = mk_type('Id', {'maxLength' => '25'});
	should_fail("ris-technologies.at-techni", $type, 0);
	should_fail("p20.daily_applications.on.led_testi", $type, 0);
	should_fail("fcomputing_and-manipulate.tools-already.data", $type, 0);
	should_fail("mconformance_discussions_information.consortium_print", $type, 0);
	should_fail("wof-documents.better_the_advanced_led.challenges_any.automatic", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('Id', {'maxLength' => '64'});
	should_fail("svirtually_repository.target-user.the_widespread_who-further_a.en", $type, 0);
	should_fail("gthe.international-of-processors-as.are-mediums_and.ambiguities_pervasive_and-of", $type, 0);
	should_fail("icomputing.back-adoption.exchange.testing_influence.results_following.industry-defining_a_busin", $type, 0);
	should_fail("padvanced.contributor.used.of.of-of-fed-standards-language-of.must.key.and-implementations_robust-graphical_al", $type, 0);
	should_fail("sbrowsers_lack-for-g_specifications.fed-provides.number-defining.hampered_testing_for-series-for_memory.in-using.the.built-th", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 1." => sub {
	my $type = mk_type('Id', {'length' => '1'});
	should_fail("fi", $type, 0);
	should_fail("mleadership-are.o", $type, 0);
	should_fail("eand-is-by.neutral.signatures_to", $type, 0);
	should_fail("_to-the.and-registries.impact_requesting_filter", $type, 0);
	should_fail("nprocess.data-the_defines-heterogeneous.by-networking_the_soft", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 33." => sub {
	my $type = mk_type('Id', {'length' => '33'});
	should_fail("e", $type, 0);
	should_fail("qand_lar", $type, 0);
	should_fail("dexercise_law.e", $type, 0);
	should_fail("ga_information.a.of_a-", $type, 0);
	should_fail("yaccessible_are_transmit-and-", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 3." => sub {
	my $type = mk_type('Id', {'length' => '3'});
	should_fail("aham", $type, 0);
	should_fail("yan_such_lacking_wi", $type, 0);
	should_fail("vindustry_sensors-more_advanced-ha", $type, 0);
	should_fail("linvestigation_no.significant.prominent-s.is_its.", $type, 0);
	should_fail("dthe-in-technologies-files-with.organizations_technologies.proje", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 51." => sub {
	my $type = mk_type('Id', {'length' => '51'});
	should_fail("f", $type, 0);
	should_fail("iheterogeneou", $type, 0);
	should_fail("scomputing_multidisciplin", $type, 0);
	should_fail("vsuite-retrieve-to_issues.documents.v", $type, 0);
	should_fail("schairing.reference.the-next_object-and.community", $type, 0);
	done_testing;
};

subtest "Type atomic/ID is restricted by facet length with value 64." => sub {
	my $type = mk_type('Id', {'length' => '64'});
	should_fail("q", $type, 0);
	should_fail("yas.technical_ar", $type, 0);
	should_fail("nsoftware-of-tune.competence-it", $type, 0);
	should_fail("iwidely.the_distributed.of_organization.promin", $type, 0);
	should_fail("lconformance_and-the-the_testing-of.and-to.with.is_be-and_dat", $type, 0);
	done_testing;
};

done_testing;

