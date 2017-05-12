$|=1;
use XML::Rules;
use Data::Dumper;

$xml = <<'*END*';
<?xml version="1.0"?>
<HRXMLRequest>
<Sender>
<Company>Peopleclick</Company>
<Id>lidia.pagano</Id>
<Credentials>welcome</Credentials>
</Sender>
<RedirectURL />
<Action>delete</Action>
<TimeStamp />
<Manifest>
<Item id="external" type="JobPosting" />
</Manifest>
<Payload id="external"><![CDATA[<JobPositionPosting status="new">
<JobPositionPostingId idOwner="Peopleclick">PCK232-167454</JobPositionPostingId>
<HiringOrg>
<HiringOrgName></HiringOrgName>
<WebSite></WebSite>
<Contact>
<PostalAddress>
<PostalCode></PostalCode>
<Region></Region>
<Municipality></Municipality>
<DeliveryAddress>
<AddressLine></AddressLine>
<AddressLine></AddressLine>
</DeliveryAddress>
</PostalAddress>
<VoiceNumber>
<TelNumber></TelNumber>
</VoiceNumber>
<E-mail />
<WebSite></WebSite>
</Contact>
</HiringOrg>
<PostDetail>
<StartDate />
<PostedBy>
<Contact>
<PersonName>
<GivenName />
<FamilyName>Huguette Couture</FamilyName>
</PersonName>
<E-mail>Huguette.Couture@rbc.com</E-mail>
<VoiceNumber>
<TelNumber>514-874-2111</TelNumber>
<FaxNumber>514-874-5453</FaxNumber>
</VoiceNumber>
</Contact>
</PostedBy>
</PostDetail>
<JobPositionInformation>
<JobPositionTitle>Représentant(e) des services financiers (stagiaire)CVM-Nov</JobPositionTitle>
<JobPositionDescription>
<JobPositionPurpose>
						Requisition Number:  62263


						Position Title:  Représentant(e) des services financiers (stagiaire)CVM-Nov


						Position Type:  Full-Time


						Position Category:  Sales


						Relocation:  No


						Business Unit:

Who we are
The Canadian Personal and Business (CPB) segment consists of our banking and investment businesses in Canada and our global insurance businesses. Our 30,000 employees provide financial products and services to over 11 million personal and business clients through a variety of distribution channels; including branches, business banking centres, automated banking machines, full-service brokerage operations, career sales forces, the telephone, Internet channels and independent third-party distributors. CPB is comprised of the following business lines:

Personal Lending focuses on meeting the needs of our individual clients at every stage of their lives through a wide range of products including home equity financing, personal financing and credit cards.

Personal Payments and Client Accounts provides core deposit accounts, transactional payment services, foreign exchange and other related services to individual clients.

Investment Management provides full-service and discount brokerage, asset management, trust services and other investment products.

Business Markets offers a wide range of lending, deposit and transaction products and services to small and medium-sized business and commercial, farming and agriculture clients.

Global Insurance offers a wide range of creditor, life, health, travel, home and auto insurance products and services to individual and business clients in Canada and the U.S., as well as reinsurance for clients around the world.


						Job Description:

Financial Services Representatives (FSR’s) are sales-oriented, self-motivated individuals who learn by observation and example. They enjoy interacting with people and turn situations into ‘win-win’ opportunities. Their curiosity prompts them to ask questions and their attention to detail and follow- through ensure delivery on their commitments. FSR’s thrive in an environment that supports change. They leverage the knowledge and experience of their work teams in order to generate sales and build customer loyalty.

Responsibilities: Contributes to meeting team sales plan and related activities by actively and effectively assessing customer financial needs and providing effective product solutions.

Maintains and grows the customer portfolio by identifying and promoting personal banking solutions for customer needs with a continuous focus on relationship building.

FSR Training Program: The Training Program is approximately 4 months in duration depending on previous experience. Training will take place in a branch where a mentor(s) will be assigned to work collaboratively the trainee throughout the program. Training prepares the trainee to deliver excellent responsive and proactive service to branch clients in the areas of investments, credit and lending. Programs start throughout the year depending on RBC needs. Training occurs on-the-job combined with self-study material, interactive satellite courses and classroom training.
Training locations are in various branches throughout the Montreal Centre Region. All candidates must be fully mobile within this Region and after successful completion of the FSR Training Program the candidate will be posted to a FSR role anywhere in that Region. Relocation to this FSR posting will be provided if required at that time. (No relocation provided for the training role


						Requirements:

•Post-secondary degree or diploma in business or arts with related work experience an asset
• Successful completion of Mutual Funds in Canada or Canadian Securities Course
• Sales-oriented and self-motivated with strong interpersonal and communication skills
• Team player who is entrepreneurial, committed to continuous learning, organized, and who can keep up-to-date on changes in client needs, procedures and products
• Ability to build and maintain strong client and colleague relationships
• Commitment to continuous self-development
• Successful completion of FSR training program or direct industry experience in a personal banking role.
. Only selected candidates will be contacted.


						Experience:  Minimum 1 year


						Education:  BA/BS


						Accreditations:  mutual funds license


						Skills:


						Minimum Salary:  Not Available
						Maximum Salary:  Not Available


						We value diversity in the workplace, are committed to employment equity/equal opportunity employment and will provide reasonable workplace accommodation to applicants with disabilities.


						We thank all interested candidates however only those selected for an interview will be contacted.

						</JobPositionPurpose>
<JobPositionLocation>
<LocationSummary>
<Municipality></Municipality>
<Region></Region>
<CountryCode></CountryCode>
<PostalCode></PostalCode>
</LocationSummary>
</JobPositionLocation>
<CompensationDescription>
<Pay>
<SummaryText />
<MinimumPay>0</MinimumPay>
<MaximumPay>0</MaximumPay>
</Pay>
</CompensationDescription>
<SummaryText />
</JobPositionDescription>
<JobPositionRequirements>
<QualificationsRequired>
<Qualification>BA/BS</Qualification>
</QualificationsRequired>
</JobPositionRequirements>
</JobPositionInformation>
<HowToApply>
<ApplicationMethods>
<ByWeb>
<URL>https://careers.peopleclick.com/Client40_RBC/EXT_EN/OLA/ResumeSubmission.xml?functionName=applyFromLink&amp;source=&amp;jobPostID=167454&amp;locale=en-us&amp;sourceType=PREMIUM_POST_SITE&amp;QID=</URL>
<URL name="External">http://careers.peopleclick.com/careerscp/client_rbc/external/gateway.do?functionName=applyFromLink&amp;source=&amp;jobPostID=167454&amp;locale=en-us&amp;sourceType=PREMIUM_POST_SITE</URL>
</ByWeb>
</ApplicationMethods>
</HowToApply>
</JobPositionPosting>]]></Payload>
</HRXMLRequest>


*END*

%rules = (
	_default => 'as is',
	'^bogus' => undef, # means "ignore"
);

my $parser = new XML::Rules (
	rules => \%rules,
	encode => 'cp1252',
	# other options
);

use Encode;
use Encode qw(decode_utf8);

use Data::Dumper;
#print Dumper($parser);

print "About to parse\n";
my $result = $parser->parsestring($xml);

print Dumper($result);

#print encode("cp1252", $result->{HRXMLRequest}{Payload}{_content});