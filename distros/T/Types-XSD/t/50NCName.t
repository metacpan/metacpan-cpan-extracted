use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/NCName is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('NCName', {'maxLength' => '1'});
	should_pass("g", $type, 0);
	should_pass("k", $type, 0);
	should_pass("v", $type, 0);
	should_pass("h", $type, 0);
	should_pass("l", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 48." => sub {
	my $type = mk_type('NCName', {'maxLength' => '48'});
	should_pass("i", $type, 0);
	should_pass("vby_to-this_", $type, 0);
	should_pass("iof-a_of_methods-profil", $type, 0);
	should_pass("kand_today.that.related-interconne", $type, 0);
	should_pass("sand-tools-to.as.developers-as-software.it_wi", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 12." => sub {
	my $type = mk_type('NCName', {'maxLength' => '12'});
	should_pass("w", $type, 0);
	should_pass("hon", $type, 0);
	should_pass("qdisc", $type, 0);
	should_pass("ain-hou", $type, 0);
	should_pass("ofoster.o", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 37." => sub {
	my $type = mk_type('NCName', {'maxLength' => '37'});
	should_pass("c", $type, 0);
	should_pass("las_partic", $type, 0);
	should_pass("eof_simplicity.mani", $type, 0);
	should_pass("qand-and.efforts-industry-in", $type, 0);
	should_pass("nbe_specifications-vocabulary_that_sy", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('NCName', {'maxLength' => '64'});
	should_pass("_", $type, 0);
	should_pass("iis.information-", $type, 0);
	should_pass("mwith_is_component_reference-th", $type, 0);
	should_pass("wfrom.related.that-which-dynamic-of.registry_b", $type, 0);
	should_pass("_revisions_in.products-and-of.is-ultimate-become-to_must.and_", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 1." => sub {
	my $type = mk_type('NCName', {'minLength' => '1'});
	should_pass("_", $type, 0);
	should_pass("bfile-by.particu", $type, 0);
	should_pass("eallow_uses_g-and-for.set.porta", $type, 0);
	should_pass("_and.exchange_known-use-to_data_means.implemen", $type, 0);
	should_pass("ctest-come-must-criteria_partnerships.well-entire_and.chosen_", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 47." => sub {
	my $type = mk_type('NCName', {'minLength' => '47'});
	should_pass("dweb.of-in_both.chains_computing_and.using-a.su", $type, 0);
	should_pass("gregard-hardware-first-generation.ambiguities.a-opp", $type, 0);
	should_pass("sand.of.of_discussions-data_has.chain.industry-computed", $type, 0);
	should_pass("_shift.the.of-information-and.for-reference.by_and_around_a", $type, 0);
	should_pass("_them-to_for-creation-specifications.versions_these-data.intero", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 32." => sub {
	my $type = mk_type('NCName', {'minLength' => '32'});
	should_pass("mthe-to.provided_cost.and.cross-", $type, 0);
	should_pass("aimplementation.file.embedded-of-and.add", $type, 0);
	should_pass("gtechnologies_is_and_business.versions.use-of_av", $type, 0);
	should_pass("vspecifications.electronic.allow_a-four-developing_embed", $type, 0);
	should_pass("mservices-for_has.wireless.sense-the-and.of-indication.as.and.fo", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 60." => sub {
	my $type = mk_type('NCName', {'minLength' => '60'});
	should_pass("oavailable.the-create-systems-annual.basis-exchange-issues_a", $type, 0);
	should_pass("yenvironment.with_and_range-operating-generation_a.would.refe", $type, 0);
	should_pass("pdynamic.a_partnerships-the-with-the-from-libraries-systems-in", $type, 0);
	should_pass("ftools_based-systems-to-widely_using_industry.development-and-f", $type, 0);
	should_pass("_for-for.offer-languages_would-diagnostic.maintained.for.effort-", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('NCName', {'minLength' => '64'});
	should_pass("eincluding-models-object-and_information-life_of_a-and-reach.ove", $type, 0);
	should_pass("oof.and.are_a-business-accelerate-generation-known.unbiased_voca", $type, 0);
	should_pass("rgeneration_many_in.semantics.around-well_electronic_are.a_to.bu", $type, 0);
	should_pass("hvendors-of_that-be.choices_any_and.meets_tests_file_pervasive.a", $type, 0);
	should_pass("nissues-developing_with.object_and-languages.emerging-will-voice", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 1." => sub {
	my $type = mk_type('NCName', {'length' => '1'});
	should_pass("a", $type, 0);
	should_pass("b", $type, 0);
	should_pass("p", $type, 0);
	should_pass("r", $type, 0);
	should_pass("k", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 61." => sub {
	my $type = mk_type('NCName', {'length' => '61'});
	should_pass("ie.signatures_advent-quality-being_templates.process_can.stan", $type, 0);
	should_pass("ufirst.set_and_20_methods_well_from_and-and_and.adoption_such", $type, 0);
	should_pass("_industries_and_of_and-the_aid.designed-of_and.a.and-among.to", $type, 0);
	should_pass("mlack_documents.by_repository.is.standards.that.be-and-discus", $type, 0);
	should_pass("jmanual.disseminate-for.consortium.performance-foster_provide", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 53." => sub {
	my $type = mk_type('NCName', {'length' => '53'});
	should_pass("kfuture-and-the.eliminate-use_discovery_more-its_that", $type, 0);
	should_pass("_available-these-as-improved_enabling.and.chairs_meet", $type, 0);
	should_pass("yindustry-used-choices.for_key_for_partnerships.proce", $type, 0);
	should_pass("_heterogeneous_good_industry-standardization-concepts", $type, 0);
	should_pass("jcalled-by-is.automate_in-file-profiles_file-a-succes", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 61." => sub {
	my $type = mk_type('NCName', {'length' => '61'});
	should_pass("kand.the.000-will_known.networks.manufacturers-to_resource.g_", $type, 0);
	should_pass("rlanguages-and_localized.and.and_of.enforcement.ensure-comput", $type, 0);
	should_pass("bpico-cellular.of.chosen_of.good_by-around.maintained-by-poss", $type, 0);
	should_pass("ireference_for_and-areas_must_industry.a.and.interconnected-c", $type, 0);
	should_pass("_allows.all-the-conferences-enable-under_registry_embedded_fr", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 64." => sub {
	my $type = mk_type('NCName', {'length' => '64'});
	should_pass("xworld-participate.define.in.to.to.on-act_computing-discovery-pr", $type, 0);
	should_pass("_as_be.for.must_of-the-for-its.time_asked_organizations_implemen", $type, 0);
	should_pass("hfiles_adoption.and.has.the_our_implementation_our.testing_annua", $type, 0);
	should_pass("lthe.the_these_and-a_target.service_high-provides.prototypes-lif", $type, 0);
	should_pass("mindustry_correction.the-of-hoc_and-address_a.implementations.si", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{16}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('NCName', {});
	should_pass("ta-reviewed-and-d", $type, 0);
	should_pass("lwhich.high_parti", $type, 0);
	should_pass("ias.software-a-th", $type, 0);
	should_pass("_standards_partic", $type, 0);
	should_pass("fin_entire.and-ha", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{40}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('NCName', {});
	should_pass("onetworking-and_projector-of-tremendous_a", $type, 0);
	should_pass("rinclude_the-a.the_developers-effort-well", $type, 0);
	should_pass("wand.forensics.processes.etc_due_that-def", $type, 0);
	should_pass("ocreating_file_and-in_and_the.information", $type, 0);
	should_pass("_through_industry-of.and_and.information.", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{27}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('NCName', {});
	should_pass("_a.tools.entire_revolution.o", $type, 0);
	should_pass("lwill-will-industry_conforma", $type, 0);
	should_pass("_the.the.industry.which.prob", $type, 0);
	should_pass("_precise-of.them-this.which_", $type, 0);
	should_pass("_unbiased.implementation.as.", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{12}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('NCName', {});
	should_pass("oof-and-elect", $type, 0);
	should_pass("_tests-domain", $type, 0);
	should_pass("qthe.the-numb", $type, 0);
	should_pass("_a_and_with.t", $type, 0);
	should_pass("vcomponent_an", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet pattern with value [\\i-[:]][\\c-[:]]{63}." => sub {
	local $TODO = "XML Schema regexp not easily translated to Perl";
	my $type = mk_type('NCName', {});
	should_pass("_to.measurements_registries.would.will-success-testing.known.amb", $type, 0);
	should_pass("bfor_will_creating.emerging.result-database-language-for_can-inc", $type, 0);
	should_pass("gand.program_for-that-effective-process-a.and_standards.help-use", $type, 0);
	should_pass("_choices.would.commerce_computing.for-of-in_libraries-technology", $type, 0);
	should_pass("sthis_those_industry_and_automate.file.such-due-discussions-of.p", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet enumeration." => sub {
	my $type = mk_type('NCName', {'enumeration' => ['_is-testing.registry_for_come_popular-networking-is-betwe','ris.both-including-industries_software.which-stak','cof-a-retrieve-contained_into_for.indu','vwith.computers_discussions.applic','ew','_is-known.must_manipulate-to_refer','ga.the_the','ha_ad_prototype_led.process_other-of.specifications_appropriat']});
	should_pass("ga.the_the", $type, 0);
	should_pass("vwith.computers_discussions.applic", $type, 0);
	should_pass("vwith.computers_discussions.applic", $type, 0);
	should_pass("_is-known.must_manipulate-to_refer", $type, 0);
	should_pass("cof-a-retrieve-contained_into_for.indu", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet enumeration." => sub {
	my $type = mk_type('NCName', {'enumeration' => ['osoftware-widespread_must_re','vto.significant_government_disseminate.industry.a_over','_industry-the-in_specifications.the_d','hsystems-i','bresource.and-c','fboth-th','_investigation.of-help_its-be_support.vendors_and_many-commerce','ewho-vocabularies-it-adoption_m']});
	should_pass("fboth-th", $type, 0);
	should_pass("fboth-th", $type, 0);
	should_pass("_industry-the-in_specifications.the_d", $type, 0);
	should_pass("_industry-the-in_specifications.the_d", $type, 0);
	should_pass("_investigation.of-help_its-be_support.vendors_and_many-commerce", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet enumeration." => sub {
	my $type = mk_type('NCName', {'enumeration' => ['uprofiles.pa','cused.de','yboth-in-each-the_discuss_electronic_can_i','cof.issues.includes.used-20_the.e-we.to.manual-to-','gtools_the-the-are.key_mechanism_the_i','_repository_having-based-enterprises_contribute_filte']});
	should_pass("cof.issues.includes.used-20_the.e-we.to.manual-to-", $type, 0);
	should_pass("cof.issues.includes.used-20_the.e-we.to.manual-to-", $type, 0);
	should_pass("cof.issues.includes.used-20_the.e-we.to.manual-to-", $type, 0);
	should_pass("yboth-in-each-the_discuss_electronic_can_i", $type, 0);
	should_pass("uprofiles.pa", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet enumeration." => sub {
	my $type = mk_type('NCName', {'enumeration' => ['xstandards-and-all-different-such.the_particularly.transmit_to','kindication.all-a_of_resources_with.cost-via-','welectronic-worki','iof_for-in.in-repository_other.and-of-i','_within.can.standard-and_fo','nto-use','oexecution_industry_data_indus','wupon-and_available.and-is.to.among_and_application-']});
	should_pass("nto-use", $type, 0);
	should_pass("wupon-and_available.and-is.to.among_and_application-", $type, 0);
	should_pass("nto-use", $type, 0);
	should_pass("_within.can.standard-and_fo", $type, 0);
	should_pass("xstandards-and-all-different-such.the_particularly.transmit_to", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet enumeration." => sub {
	my $type = mk_type('NCName', {'enumeration' => ['kobject-transact-constituent_of_file.is_without_about_are_a.be','ocontribu','dof_set.wireless-buildin','uand-manipulation.good.information.ambiguities-','tthrough-of_av','_divisions.years_for_partnership-fed-','aneutral_heterogeneous.reproduced-will_','_and.to-we_frameworks-pervasive_the-regi','uin-and-ensure.']});
	should_pass("_divisions.years_for_partnership-fed-", $type, 0);
	should_pass("tthrough-of_av", $type, 0);
	should_pass("ocontribu", $type, 0);
	should_pass("kobject-transact-constituent_of_file.is_without_about_are_a.be", $type, 0);
	should_pass("ocontribu", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('NCName', {'whiteSpace' => 'collapse'});
	should_pass("rto.", $type, 0);
	should_pass("hdev", $type, 0);
	should_pass("idoc", $type, 0);
	should_pass("ginf", $type, 0);
	should_pass("aint", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 23." => sub {
	my $type = mk_type('NCName', {'minLength' => '23'});
	should_fail("e", $type, 0);
	should_fail("_testi", $type, 0);
	should_fail("hto.of_for_", $type, 0);
	should_fail("_pervasive-will_", $type, 0);
	should_fail("ta-to_for-and-applica", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 35." => sub {
	my $type = mk_type('NCName', {'minLength' => '35'});
	should_fail("_", $type, 0);
	should_fail("gvisibly.", $type, 0);
	should_fail("kfrom.rigorous_re", $type, 0);
	should_fail("yfilter_is_files.second-g", $type, 0);
	should_fail("eambiguities_dynamic-tools-by_the", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 58." => sub {
	my $type = mk_type('NCName', {'minLength' => '58'});
	should_fail("p", $type, 0);
	should_fail("yneutral_develo", $type, 0);
	should_fail("_and_of_which.interconnected-", $type, 0);
	should_fail("oprint_in_assuring_in.implementations.speci", $type, 0);
	should_fail("vand-to_further-partners.areas.of.made-industries-informa", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 53." => sub {
	my $type = mk_type('NCName', {'minLength' => '53'});
	should_fail("l", $type, 0);
	should_fail("lwireless.imp", $type, 0);
	should_fail("rthese-data-and-defining_", $type, 0);
	should_fail("osimplest_performance-mechanism_to.th", $type, 0);
	should_fail("wmaintains_reference.obtained.that.as.tools.and-e", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('NCName', {'minLength' => '64'});
	should_fail("_", $type, 0);
	should_fail("fdiscovery-softw", $type, 0);
	should_fail("qasked.to-as_memory-and.such-in", $type, 0);
	should_fail("wbuild-its_known.standardization-efforts-signi", $type, 0);
	should_fail("xcomputing_of-a.computer-an.as.as_include_used.role_profiles-", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('NCName', {'maxLength' => '1'});
	should_fail("lt", $type, 0);
	should_fail("qissues-quality-o", $type, 0);
	should_fail("xand_to.templates.and_to_filter_", $type, 0);
	should_fail("afrom-of_application_creating-partnerships.defi", $type, 0);
	should_fail("iis.forum.organizations.to-of.and.files.to_to_use.data-partner", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 24." => sub {
	my $type = mk_type('NCName', {'maxLength' => '24'});
	should_fail("celiminate-to_with-techno", $type, 0);
	should_fail("ibe-product.the_law-and.eliminated", $type, 0);
	should_fail("_reputation_the.and-is_define_in_to-will_of", $type, 0);
	should_fail("abasis-be_about_are_management-define.language_of_e.", $type, 0);
	should_fail("_working-standards_in-manipulate.result.files_and.built_and-a", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 56." => sub {
	my $type = mk_type('NCName', {'maxLength' => '56'});
	should_fail("ksuite.revolution_signatures-asked_make_in.complex_we-dev", $type, 0);
	should_fail("gentire.e_systems-on-a-chip.reference_describes-understand", $type, 0);
	should_fail("jconsistency.ability_a_for_and-then.print.vocabularies-obje", $type, 0);
	should_fail("nreference.discussions.product.networks_by.this-must-of_the-", $type, 0);
	should_fail("nsuites.to_asking_raised_file_networking-conformance-provided", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 20." => sub {
	my $type = mk_type('NCName', {'maxLength' => '20'});
	should_fail("_the-and_pico-cellula", $type, 0);
	should_fail("wimplementations.particularly-p", $type, 0);
	should_fail("vindustry-debug_to_has.and_who.of.of-avai", $type, 0);
	should_fail("_some_these_are_of_is-in.regard.cost.them_would-as.", $type, 0);
	should_fail("padditionally.technologies.support-computer-great_computer.vo", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('NCName', {'maxLength' => '64'});
	should_fail("cdigital-the_that-of.known.tools_and_law.is-variety-vendors_files", $type, 0);
	should_fail("efor_creation_has_will_these-competence_and.known_law.cross-over_discovery_used.", $type, 0);
	should_fail("ugraphics-providing.this-of-international.process_implementations-of-and-repository-adoption-su", $type, 0);
	should_fail("nin-emerging-and_e.documents_for_areas_the-a.technical-them_and_tools.be_systems-the.concepts.for_s-of-languag", $type, 0);
	should_fail("hrobust.define_small-_of_to.automating_versions.industry-that.specifications_a-containing_that.data-computing.data-file.them_", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 1." => sub {
	my $type = mk_type('NCName', {'length' => '1'});
	should_fail("fs", $type, 0);
	should_fail("_capabilities-the", $type, 0);
	should_fail("wobvious.a_environments_will-eli", $type, 0);
	should_fail("uspecifications.eliminate_define-is.to-and.and.", $type, 0);
	should_fail("_both.to.requires.sensors-to_known.market_not_years_of_technic", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 48." => sub {
	my $type = mk_type('NCName', {'length' => '48'});
	should_fail("s", $type, 0);
	should_fail("xcapabilitie", $type, 0);
	should_fail("hdeployed-documents-pro", $type, 0);
	should_fail("bwithin.industries.repository.rapi", $type, 0);
	should_fail("xdata_technologies-and-that_and_measure-we.co", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 11." => sub {
	my $type = mk_type('NCName', {'length' => '11'});
	should_fail("bwireless_an", $type, 0);
	should_fail("smust.guidelines-creation", $type, 0);
	should_fail("ha-particular-ensure.lies.to-from_is-e", $type, 0);
	should_fail("_first-generation-registry_quality-product.systems-", $type, 0);
	should_fail("gsoftware_compatibility_already-ability.g_logic-addressing_throu", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 52." => sub {
	my $type = mk_type('NCName', {'length' => '52'});
	should_fail("_", $type, 0);
	should_fail("kestablish-ca", $type, 0);
	should_fail("genforcement.infrastructu", $type, 0);
	should_fail("iand.filter-software_fact.conformance", $type, 0);
	should_fail("_for_indication.ensure_signatures.their_designed.", $type, 0);
	done_testing;
};

subtest "Type atomic/NCName is restricted by facet length with value 64." => sub {
	my $type = mk_type('NCName', {'length' => '64'});
	should_fail("w", $type, 0);
	should_fail("oa-related-devel", $type, 0);
	should_fail("xwith-recommendation_reference-", $type, 0);
	should_fail("lamong-will_on-and-information_organizations.c", $type, 0);
	should_fail("_than_create.can-language-directions-result_the.and_the.this.", $type, 0);
	done_testing;
};

done_testing;

