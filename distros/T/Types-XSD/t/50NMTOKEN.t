use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '1'});
	should_pass("o", $type, 0);
	should_pass("c", $type, 0);
	should_pass("m", $type, 0);
	should_pass("m", $type, 0);
	should_pass("p", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 41." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '41'});
	should_pass("i", $type, 0);
	should_pass("build.measu", $type, 0);
	should_pass("information-exercise_", $type, 0);
	should_pass("to_world-including:for.A_of:lan", $type, 0);
	should_pass("success:hampered:and_interoperability:doc", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 42." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '42'});
	should_pass("o", $type, 0);
	should_pass("to-cooperat", $type, 0);
	should_pass("and:available_a:suite", $type, 0);
	should_pass("using:all_as_software.efforts.d", $type, 0);
	should_pass("of:of.over:results.and:which.A:Develop_co", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 54." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '54'});
	should_pass("c", $type, 0);
	should_pass("the.repository", $type, 0);
	should_pass("will::creates_to:and:An-ens", $type, 0);
	should_pass("from_of_of-must.and_and_the:asked.develo", $type, 0);
	should_pass("retrieves-them-repository.and-XSL-FO:development-inte", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '64'});
	should_pass("c", $type, 0);
	should_pass("XML-can_of.techn", $type, 0);
	should_pass("displaying_highly.language-as_a", $type, 0);
	should_pass("browsers-Structured:approach-intuitive-primary", $type, 0);
	should_pass("with.the_partnership.build_that.and-four.OASIS:of.and:first_o", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 1." => sub {
	my $type = mk_type('NmToken', {'minLength' => '1'});
	should_pass("t", $type, 0);
	should_pass("The:for:called_o", $type, 0);
	should_pass("communication:discuss:informati", $type, 0);
	should_pass("process:standardization.and.and.ebXML-body-to-", $type, 0);
	should_pass("with-signatures:The-as:prototypes.database_be.care_wireless-e", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 45." => sub {
	my $type = mk_type('NmToken', {'minLength' => '45'});
	should_pass("The_ensure_is.are-appropriate_more:as:the.are", $type, 0);
	should_pass("data-Naval_software_a_of_files.test-retrieval_reg", $type, 0);
	should_pass("of:a_The.landscape-other.contribute_computing_unbiase", $type, 0);
	should_pass("reproduced-database.ad-Advancement_and:recent-and:do_the_", $type, 0);
	should_pass("beta_library_operating-are-to:subject:in:filter_understand_an", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 35." => sub {
	my $type = mk_type('NmToken', {'minLength' => '35'});
	should_pass("the_repository.correction-a:Investi", $type, 0);
	should_pass("into_that-choices-coupled_being-Pervasive:", $type, 0);
	should_pass("electronic-our:must:DOM-The_role:these_and:the:si", $type, 0);
	should_pass("for_widely:this.known_the_that.location.profiles:visibly", $type, 0);
	should_pass("industry-allow_repository_have.tune:Working-offer:asked.supply-", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 33." => sub {
	my $type = mk_type('NmToken', {'minLength' => '33'});
	should_pass("XML:environments.is.being.objects", $type, 0);
	should_pass("used:the:that-profiles-standards-reposit", $type, 0);
	should_pass("and.if:are:by:the:Simulation:the-the:help.NIST-", $type, 0);
	should_pass("on.would_is_the_particularly:of-computer.the-requires-", $type, 0);
	should_pass("that-groups:systems_software.find_data.addition.will-SMEs-tha", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('NmToken', {'minLength' => '64'});
	should_pass("languages-computing_specifications_way:for.chain:organization:fo", $type, 0);
	should_pass("suites:paradigm.manipulate_will-success.only-more:data.discussio", $type, 0);
	should_pass("and:e:program_rigorous:discuss_we:a_the:tools:robust_robust_is:r", $type, 0);
	should_pass("number:discovery_on:type:The-to:partnerships:such.tools.act-Nati", $type, 0);
	should_pass("global:and_can.enterprises.file:interacting-U:must.and_with.SOC.", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 1." => sub {
	my $type = mk_type('NmToken', {'length' => '1'});
	should_pass("t", $type, 0);
	should_pass("f", $type, 0);
	should_pass("o", $type, 0);
	should_pass("r", $type, 0);
	should_pass("c", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 38." => sub {
	my $type = mk_type('NmToken', {'length' => '38'});
	should_pass("global_application-creation:a-a_reposi", $type, 0);
	should_pass("dynamic:registries_file_A.be.as_would-", $type, 0);
	should_pass("interoperability_reference.to:specific", $type, 0);
	should_pass("and-as_wide-SMEs.with-i_Provide_the.to", $type, 0);
	should_pass("including_problems.be-and-Schema:and:a", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 57." => sub {
	my $type = mk_type('NmToken', {'length' => '57'});
	should_pass("the.joint-s:these.well.and.Such.five-suite.and:to:cross-o", $type, 0);
	should_pass("NSRL_utilities.discover_to.ability.also:for:are-helping_p", $type, 0);
	should_pass("user:looking:repository:is-to_beta-without.standardizatio", $type, 0);
	should_pass("robust_build:EC:used:success:international.individual-suc", $type, 0);
	should_pass("of.mechanism_Reference:widely.Schema:signature_Informatio", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 60." => sub {
	my $type = mk_type('NmToken', {'length' => '60'});
	should_pass("the:prominent:A.key.registry-frameworks.using.tool.hampered-", $type, 0);
	should_pass("of_Advancement.same:and-XML.designed_know:of-the_context-ric", $type, 0);
	should_pass("of.which:is_Internet-Although-addressing.will.to:market_amon", $type, 0);
	should_pass("Schemas_Standards_development:and.software:known:and:interac", $type, 0);
	should_pass("transactions-and-are:that.link:is_good-retrieve.for_are:Only", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 64." => sub {
	my $type = mk_type('NmToken', {'length' => '64'});
	should_pass("of.for_between:A.of:investigations:recent:software_signatures.ab", $type, 0);
	should_pass("Provide_the_be.Sun_and-an.involved_In:and-is_prominent-of-chains", $type, 0);
	should_pass("advanced:Description-in-role.used-and:enterprises_can_and-softwa", $type, 0);
	should_pass("and:electronic.signatures:in-The.Working_as.through.Experimental", $type, 0);
	should_pass("future:the:compliant-industry.including:technology_Using-the:thi", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet pattern with value \\c{40}." => sub {
	my $type = mk_type('NmToken', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){40}$)/});
	should_pass("participants.file-interconnecting_will.v", $type, 0);
	should_pass("computer.systems_their:wide.the:assuring", $type, 0);
	should_pass("provides.facilitates:known-discussions:o", $type, 0);
	should_pass("only-review_that:particularly-DOM:Comput", $type, 0);
	should_pass("and:multidisciplinary.software_years_an:", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet pattern with value \\c{18}." => sub {
	my $type = mk_type('NmToken', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){18}$)/});
	should_pass("in.typical_tools:m", $type, 0);
	should_pass("and:Conformance:to", $type, 0);
	should_pass("tests.clean:succes", $type, 0);
	should_pass("virtually-discover", $type, 0);
	should_pass("with.define-to:cha", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet pattern with value \\c{6}." => sub {
	my $type = mk_type('NmToken', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){6}$)/});
	should_pass("for_AP", $type, 0);
	should_pass("XML.to", $type, 0);
	should_pass("to-Too", $type, 0);
	should_pass("abilit", $type, 0);
	should_pass("XML-op", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet pattern with value \\c{33}." => sub {
	my $type = mk_type('NmToken', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){33}$)/});
	should_pass("small-.and.for.these-for:Provide-", $type, 0);
	should_pass("if_discovery.to_allow-vocabulary_", $type, 0);
	should_pass("nature.participate.to-key.contrib", $type, 0);
	should_pass("web.in_DOM-precise_languages.Erro", $type, 0);
	should_pass("signature.the-lack.to-XML.discove", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet pattern with value \\c{18}." => sub {
	my $type = mk_type('NmToken', {'pattern' => qr/(?ms:^(?:$XML::RegExp::NameChar){18}$)/});
	should_pass("include_internatio", $type, 0);
	should_pass("repositories.use:c", $type, 0);
	should_pass("annual-data.a:lies", $type, 0);
	should_pass("the-A:National.hav", $type, 0);
	should_pass("be.files.and:of-tr", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet enumeration." => sub {
	my $type = mk_type('NmToken', {'enumeration' => ['Internet_will:_that:to_mad','computing-NSRL.can:a.to-of:must-perv','launching.correctness_revisions_and.sp','that.cost_Business-for_are:industries:processes_pico-','collaborate-tools-we_with.each.the_relationships_networ']});
	should_pass("Internet_will:_that:to_mad", $type, 0);
	should_pass("Internet_will:_that:to_mad", $type, 0);
	should_pass("Internet_will:_that:to_mad", $type, 0);
	should_pass("launching.correctness_revisions_and.sp", $type, 0);
	should_pass("launching.correctness_revisions_and.sp", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet enumeration." => sub {
	my $type = mk_type('NmToken', {'enumeration' => ['led:back:must.ITL_applications:excha','and-software.help.be:shift:offer.DOM.working.automate:Co','cost:on:and_available-will.to:must.tune:creati','as:test-Markup-supply.transactions_for_Standards.for-with.sig','outfitting.donat','and-to:Simulation:pro','working.solve-']});
	should_pass("working.solve-", $type, 0);
	should_pass("working.solve-", $type, 0);
	should_pass("outfitting.donat", $type, 0);
	should_pass("outfitting.donat", $type, 0);
	should_pass("and-software.help.be:shift:offer.DOM.working.automate:Co", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet enumeration." => sub {
	my $type = mk_type('NmToken', {'enumeration' => ['needed:as-is.Furthermore_retrieve-to.means.find','the_United-development-and-each-disco','Groups_in_','industry:Advancement.permitting_conformance.and_will-partici','than:business:ebXML-of:for.of_electronic.diagnosti','manual.that.tools.standard','discover.OASIS-versions.has.compatibility-embedded','browsers:DOM:both.chain:the:recommending.C','methods.profiles.ensure_manipulate.b','criteria:-must-tar']});
	should_pass("methods.profiles.ensure_manipulate.b", $type, 0);
	should_pass("browsers:DOM:both.chain:the:recommending.C", $type, 0);
	should_pass("criteria:-must-tar", $type, 0);
	should_pass("manual.that.tools.standard", $type, 0);
	should_pass("industry:Advancement.permitting_conformance.and_will-partici", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet enumeration." => sub {
	my $type = mk_type('NmToken', {'enumeration' => ['trans','Objec','must_Investigators_signatures:tools_software-to.that-as:ro','that_profiles:defi','related_implementation-security.capabilities:that','The-of_files.for.Recommendation-appropriate-disco']});
	should_pass("that_profiles:defi", $type, 0);
	should_pass("The-of_files.for.Recommendation-appropriate-disco", $type, 0);
	should_pass("must_Investigators_signatures:tools_software-to.that-as:ro", $type, 0);
	should_pass("related_implementation-security.capabilities:that", $type, 0);
	should_pass("trans", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet enumeration." => sub {
	my $type = mk_type('NmToken', {'enumeration' => ['cross-over.related.ambiguities-The.Ex','via.discussions','have_automatic','prominent_retrieve_rigorous.a:of-for.define-and:participants:Ja','only:d','object_rapid.of:partners:including.docume','define.a:Schemas-OASIS:working.Conference_profi']});
	should_pass("cross-over.related.ambiguities-The.Ex", $type, 0);
	should_pass("object_rapid.of:partners:including.docume", $type, 0);
	should_pass("via.discussions", $type, 0);
	should_pass("object_rapid.of:partners:including.docume", $type, 0);
	should_pass("via.discussions", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('NmToken', {'whiteSpace' => 'collapse'});
	should_pass("and_is_that_use:issues:data.t", $type, 0);
	should_pass("under.the_digital-among-calle", $type, 0);
	should_pass("is-OASIS.of_related_wide-file", $type, 0);
	should_pass("and_and-design-defines_first_", $type, 0);
	should_pass("and_operating:and.effectively", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 49." => sub {
	my $type = mk_type('NmToken', {'minLength' => '49'});
	should_fail("l", $type, 0);
	should_fail("software-pro", $type, 0);
	should_fail("highly:of.and_by.most_l", $type, 0);
	should_fail("prominent.as:and:will:.retrieve-Ad", $type, 0);
	should_fail("will-as.developing-test-in:registries:test_co", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 51." => sub {
	my $type = mk_type('NmToken', {'minLength' => '51'});
	should_fail("s", $type, 0);
	should_fail("computer-comp", $type, 0);
	should_fail("for-wireless_defines.buil", $type, 0);
	should_fail("reference:be.used.the:of.for:XML-for.", $type, 0);
	should_fail("as:displaying_completion:of_a.annual-into-the.als", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 17." => sub {
	my $type = mk_type('NmToken', {'minLength' => '17'});
	should_fail("d", $type, 0);
	should_fail("effe", $type, 0);
	should_fail("partner", $type, 0);
	should_fail("A_improved", $type, 0);
	should_fail("such-retrieve", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 3." => sub {
	my $type = mk_type('NmToken', {'minLength' => '3'});
	should_fail("d", $type, 0);
	should_fail("w", $type, 0);
	should_fail("a", $type, 0);
	should_fail("d", $type, 0);
	should_fail("l", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet minLength with value 64." => sub {
	my $type = mk_type('NmToken', {'minLength' => '64'});
	should_fail("w", $type, 0);
	should_fail("implementation.t", $type, 0);
	should_fail("HTML:component:Standards.many_t", $type, 0);
	should_fail("documents:automated_XSL-FO.used.to:information", $type, 0);
	should_fail("for:is_etc.process-of:the.is-full-of.retrieve.Within_must:dev", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 1." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '1'});
	should_fail("th", $type, 0);
	should_fail("software.the-for_", $type, 0);
	should_fail("A.profiles-have:embedded_files.a", $type, 0);
	should_fail("the-related_mediums:Although.international_brow", $type, 0);
	should_fail("these:a-from.looking.for_help-As-to.business_dynamic-Conferenc", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 50." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '50'});
	should_fail("forum_to_for.The.using_and_widely-is:the.enable:The", $type, 0);
	should_fail("the.OASIS:discussions-act:to-the:the:XML.revolution-la", $type, 0);
	should_fail("with-Conformance_documents_data-less.To-XML.environment.i", $type, 0);
	should_fail("building:and:discovery:discovery_directions.define:Pervasive", $type, 0);
	should_fail("reference-Schemas_be_will:-automate.defines.create:any-XML.law-", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 21." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '21'});
	should_fail("ensure:the:Software-wi", $type, 0);
	should_fail("and_and-with.in-coupled-systems_", $type, 0);
	should_fail("permitting-software-the-helping:as.simulat", $type, 0);
	should_fail("in:be_completion_library.can-for.management_a.leader", $type, 0);
	should_fail("signatures:XSL-FO.build.first-generation_a_annual.four-user_re", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 27." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '27'});
	should_fail("the.defining-life-and:In:ass", $type, 0);
	should_fail("we-supply.the_guidelines:of-to_of_rep", $type, 0);
	should_fail("for_for:resources_of_memory_related:database_L", $type, 0);
	should_fail("effective_as-back-applications:to-reference.coupled.the", $type, 0);
	should_fail("deployed-OASIS:into-addressing:leadership.the_computing_componen", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet maxLength with value 64." => sub {
	my $type = mk_type('NmToken', {'maxLength' => '64'});
	should_fail("If.will_availability-computing.networking:coupled-to-testing_part", $type, 0);
	should_fail("of:addressing.Investigators.a_to_partners:and_exchange-in_Such-for_service_is-to", $type, 0);
	should_fail("a.primarily:OASIS:to.modeling.hampered:and_those:HTML.of-devices_ability_intuitive_completion:t", $type, 0);
	should_fail("building.systems:to-to.as.to.known:and.related:that.and:service:challenges-their-the.international-containing_", $type, 0);
	should_fail("between:a-are_profiles_at.developed_registry_XSL-FO-consortiums.popular-technologies.is.of-engineering.own.typical:suites:in:", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 1." => sub {
	my $type = mk_type('NmToken', {'length' => '1'});
	should_fail("ge", $type, 0);
	should_fail("typical-small-.an", $type, 0);
	should_fail("to.are.appropriate-would-of:as-a", $type, 0);
	should_fail("use-In.Experimental.SOC.be-to:are:and.the:use-t", $type, 0);
	should_fail("as.from-highly_opportunity:security_multidisciplinary-with:has", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 9." => sub {
	my $type = mk_type('NmToken', {'length' => '9'});
	should_fail("It_s-Compu", $type, 0);
	should_fail("advent:standard-and_own", $type, 0);
	should_fail("and.to_XML.facilitates.and-database:", $type, 0);
	should_fail("repository-web.prototype_improved_robust.to-The-e", $type, 0);
	should_fail("no.networks_ambiguities:these:of_standardization.neutral_to_Re", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 50." => sub {
	my $type = mk_type('NmToken', {'length' => '50'});
	should_fail("h", $type, 0);
	should_fail("provide.s.voc", $type, 0);
	should_fail("conformant.and_a:with_the", $type, 0);
	should_fail("through.to.of:been:software_this-reco", $type, 0);
	should_fail("testing.for_Developers.distributed:simulation_hav", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 52." => sub {
	my $type = mk_type('NmToken', {'length' => '52'});
	should_fail("f", $type, 0);
	should_fail("hoc-reference", $type, 0);
	should_fail("interoperable:and-the:def", $type, 0);
	should_fail("Additionally-has_offer:throughout.fil", $type, 0);
	should_fail("stimulus_for-using.the-HTML:under_in:paradigm_and", $type, 0);
	done_testing;
};

subtest "Type atomic/NMTOKEN is restricted by facet length with value 64." => sub {
	my $type = mk_type('NmToken', {'length' => '64'});
	should_fail("f", $type, 0);
	should_fail("match.and:the.th", $type, 0);
	should_fail("is_manipulate-testing.as:the.co", $type, 0);
	should_fail("as-g_management:and-specification:be_revolutio", $type, 0);
	should_fail("accelerate.An:repository_as_in:creation.of_build:adoption.gra", $type, 0);
	done_testing;
};

done_testing;

