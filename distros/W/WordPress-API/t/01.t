use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::API;

#use Smart::Comments '###';

ok(1,'starting test.');


my $conf = skiptest();


### $conf


my $w = WordPress::API->new($conf);
### $w
ok($w,'object initiated');



ok( $w->proxy, 'proxy method returns') or die('check your conf');
ok( $w->password, 'password method returns') or die;
ok( $w->username, 'username method returns') or die;


my $blog_id = $w->blog_id;
my $blog_name = $w->blog_name;
my $blog_url = $w->blog_url;

ok($blog_id, "blog id $blog_id");
ok($blog_name, "blog name $blog_name");
ok($blog_url, "blog url $blog_url");








# TRY INTERFACE

my $p = $w->page;

$p->description(_description()) or die;

$p->title('api titl') or die;
$p->save or die($p->errstr);
my $pid = $p->id or die;


my $l = $w->page($pid);
ok( $l->load, 'loaded '.$pid) or die;

my $_loaded = $l->structure_data;
### $_loaded

$l->save_file('./t/out.yml');
-f './t/out.yml' or die;




# try to upload the page from the file

my $g = $w->page;
$g->abs_path('./t/out.yml');
$g->load_file or die;

my $_c = $g->structure_data;
### $_c


$g->save or die($g->errstr);





$w->deletePage($pid);








sub _description {
return q/

Pay Inequity Continues: For every $1.00 earned by a man, the average woman receives only 77 cents, while African American women only get 67 cents and Latinas receive only 57 cents.

Hate Crimes on the Rise: The number of hate crimes increased nearly 8 percent to 7,700 incidents in 2006.

Efforts Continue to Suppress the Vote: A recent study discovered numerous organized efforts to intimidate, mislead and suppress minority voters.

Disparities Continue to Plague Criminal Justice System: African Americans and Hispanics are more than twice as likely as whites to be searched, arrested, or subdued with force when stopped by police. Disparities in drug sentencing laws, like the differential treatment of crack as opposed to powder cocaine, are unfair.
Barack Obama's Plan
Strengthen Civil Rights Enforcement

Obama will reverse the politicization that has occurred in the Bush Administration's Department of Justice. He will put an end to the ideological litmus tests used to fill positions within the Civil Rights Division.
Combat Employment Discrimination

Obama will work to overturn the Supreme Court's recent ruling that curtails racial minorities' and women's ability to challenge pay discrimination. Obama will also pass the Fair Pay Act to ensure that women receive equal pay for equal work.
Expand Hate Crimes Statutes

Obama will strengthen federal hate crimes legislation and reinvigorate enforcement at the Department of Justice's Criminal Section.
End Deceptive Voting Practices

Obama will sign into law his legislation that establishes harsh penalties for those who have engaged in voter fraud and provides voters who have been misinformed with accurate and full information so they can vote.
End Racial Profiling

Obama will ban racial profiling by federal law enforcement agencies and provide federal incentives to state and local police departments to prohibit the practice.
Reduce Crime Recidivism by Providing Ex-Offender Support

Obama will provide job training, substance abuse and mental health counseling to ex-offenders, so that they are successfully re-integrated into society. Obama will also create a prison-to-work incentive program to improve ex-offender employment and job retention rates.
Eliminate Sentencing Disparities

Obama believes the disparity between sentencing crack and powder-based cocaine is wrong and should be completely eliminated.
Expand Use of Drug Courts

Obama will give first-time, non-violent offenders a chance to serve their sentence, where appropriate, in the type of drug rehabilitation programs that have proven to work better than a prison term in changing bad behavior.
Barack Obama's Record

Record of Advocacy: Obama has worked to promote civil rights and fairness in the criminal justice system throughout his career. As a community organizer, Obama helped 150,000 African Americans register to vote. As a civil rights lawyer, Obama litigated employment discrimination, housing discrimination, and voting rights cases. As a State Senator, Obama passed one of the country's first racial profiling laws and helped reform a broken death penalty system. And in the U.S. Senate, Obama has been a leading advocate for protecting the right to vote, helping to reauthorize the Voting Rights Act and leading the opposition against discriminatory barriers to voting.
For More Information about Barack's Plan

(PDF)Read the Plan
Speech at the Howard University Convocation
/;

}
