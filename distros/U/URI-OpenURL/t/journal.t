use Test;

use strict;
BEGIN { plan tests => 1 }
use URI::OpenURL;

# Construct an OpenURL
my $uri = URI::OpenURL->new("http://openurl.ac.uk/"
	)->referrer(id => 'info:sid/dlib.org:dlib',
	)->requester(id => 'mailto:tdb01r@ecs.soton.ac.uk',
	)->resolver(id => 'http://citebase.eprints.org/',
	)->serviceType()->scholarlyService(
		fulltext => 'yes',
	)->referringEntity(id => 'info:doi/10.1045/march2001-vandesompel')->journal(
		genre => 'article',
		aulast => 'Van de Sompel',
		aufirst => 'Herbert',
		issn => '1082-9873',
		volume => '7',
		issue => '3',
		date => '2001',
		atitle => 'Open Linking in the Scholarly Information Environment using the OpenURL Framework',
	)->referent(id => 'info:doi/10.1045/july99-caplan')->journal(
		genre => 'article',
		aulast => 'Caplan',
		aufirst => 'Priscilla',
		issn => '1082-9873',
		volume => '5',
		issue => '7/8',
		date => '1999',
		atitle => 'Reference Linking for Journal Articles',
	);

ok($uri,'http://openurl.ac.uk/?url_ver=Z39.88-2004&rfr_id=info%3Asid%2Fdlib.org%3Adlib&req_id=mailto%3Atdb01r%40ecs.soton.ac.uk&res_id=http%3A%2F%2Fcitebase.eprints.org%2F&svc_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Asch_svc&svc.fulltext=yes&rfe_id=info%3Adoi%2F10.1045%2Fmarch2001-vandesompel&rfe_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&rfe.genre=article&rfe.aulast=Van+de+Sompel&rfe.aufirst=Herbert&rfe.issn=1082-9873&rfe.volume=7&rfe.issue=3&rfe.date=2001&rfe.atitle=Open+Linking+in+the+Scholarly+Information+Environment+using+the+OpenURL+Framework&rft_id=info%3Adoi%2F10.1045%2Fjuly99-caplan&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&rft.genre=article&rft.aulast=Caplan&rft.aufirst=Priscilla&rft.issn=1082-9873&rft.volume=5&rft.issue=7%2F8&rft.date=1999&rft.atitle=Reference+Linking+for+Journal+Articles');
