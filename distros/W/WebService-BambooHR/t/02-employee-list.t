#!perl

use strict;
use warnings;
use utf8;

use LWP::Online ':skip_all';
use Test::More 0.88 tests => 4;
use WebService::BambooHR;
my $domain  = 'testperl';
my $api_key = 'bfb359256c9d9e26b37309420f478f03ec74599b';
my $bamboo;
my @employees;
my $employee;

SKIP: {

    my $bamboo = WebService::BambooHR->new(
                        company => $domain,
                        api_key => $api_key);
    ok(defined($bamboo), "create BambooHR class");

    eval {
        @employees = $bamboo->employee_list();
    };
    ok(!$@ && @employees > 0, 'get employee list');

    ok(@employees == 122, 'expected number of employees');

    my $employee_string = render_employees(\@employees);
    my $expected_employee_string = read_data();
    is($employee_string, $expected_employee_string, "compare employee fields");

};

sub render_employees
{
    my $employee_ref = shift;
    my $result = "firstName|lastName|status|selfServiceAccess|location|jobTitle\n";

    foreach my $employee (sort by_employee_name @$employee_ref) {
        $result .= $employee->firstName
                   .'|'
                   .$employee->lastName
                   .'|'
                   .$employee->status
                   .'|'
                   .$employee->selfServiceAccess
                   .'|'
                   .($employee->location || '')
                   .'|'
                   .($employee->jobTitle || '')
                   ."\n";
    }

    return $result;
}

sub by_employee_name
{
    if ($a->lastName ne $b->lastName) {
        return $a->lastName cmp $b->lastName;
    } else {
        return $a->firstName cmp $a->firstName;
    }
}

sub read_data
{
    local $/;
    return scalar <DATA>;
}

__DATA__
firstName|lastName|status|selfServiceAccess|location|jobTitle
Charlotte|Abbott|Active|No|Corporate Office|HR Specialist
Diane|Adams|Inactive|No||
Melissa|Allen|Active|No|Chicago|Marketing Facilitator
Kristina|Allen|Inactive|No||HR Specialist
JD|Allphin|Active|No|Chicago|Marketing Facilitator
Richard|Anderson|Active|No|St. Louis|Development Supervisor
Carmello|Anthony|Inactive|No|St. Louis|
Tyler|Arnold|Active|No||
David|Bagley|Active|No|St. Louis|Marketing Facilitator
Spencer|Baird|Inactive|No||VP
Jonathan|Baker|Active|No|St. Louis|Client Service Representative
Amber|Baldwin|Inactive|No||
Greg|Banks|Active|No|St. Louis|Site Supervisor
Tammy|Barker|Inactive|No||
Trina|Barnes|Inactive|No||
Jill|Barnes|Inactive|No||VP
Julie|Barnes|Inactive|No||
Jonathan|Barringer|Active|No|St. Louis|Client Service Representative
Laura|Barry|Active|No||
Marc|Bean|Active|No|Chicago|Site Supervisor
Sherry|Brewer|Active|No||
Kobe|Bryant|Inactive|No||
George|Butler|Inactive|No||
Edwin|Caldwell|Active|No||
Mark|Cannon|Active|No|Chicago|Marketing Facilitator
Lynsey|Card|Inactive|No||Marketing Facilitator
Marcus|Cardwell|Active|No|Chicago|VP
Gary|Cerny|Inactive|No|Chicago|Site Supervisor
Ralph|Charles|Inactive|No||
Amy|Clark|Active|No||
Matt|Clarke|Active|No|St. Louis|VP
Marissa|Clemmons|Active|No||
George|Clooney|Active|No||
Jonathan|Cole|Inactive|No|Chicago|Site Supervisor
David|Collings|Active|No|Chicago|Client Service Representative
Clint|Connelly|Inactive|No||Marketing Facilitator
Andrew|Davidson|Inactive|No||
Samantha|Davis|Active|No||
Michael|Dobson|Inactive|No||
Stephanie|Dornes|Inactive|No||Site Supervisor
Laurie|Durfey|Active|No|Chicago|Site Supervisor
Kurt|Durkee|Active|No|Chicago|Developer
Edward|Dylan|Inactive|No|Chicago|Site Supervisor
Gavan|Errold|Active|No|St. Louis|Marketing Facilitator
Coy|Escobedo|Active|No|Chicago|Developer
Emily|Ethridge|Active|No|Chicago|Office Administration
Bradly|Eyre|Active|No|St. Louis|Client Service Representative
Jasmine|Farrer|Active|No|Chicago|Marketing Facilitator
Robert|Fordham|Active|No|Corporate Office|Office Administration
Fredré|Francisco|Inactive|No||
Jaclyn|Francom|Active|No|Chicago|Account Representative
Jonathan|Goodrich|Inactive|No|Chicago|VP
Jessica|Hansen|Active|No|Chicago|Account Representative
Veronica|Hanson|Inactive|No||
Devin|Hartwell|Active|No|Chicago|Account Representative
Michael|Harvey|Active|No|St. Louis|Account Representative
Luke|Haslem|Inactive|No|Chicago|Account Representative
Jeff|Hawkes|Active|No|St. Louis|Account Representative
Jimi|Hendrix|Inactive|No||
Avalon|Higginbotham|Inactive|No||Account Representative
Katherine|Hill|Active|No||
Sophie|Hollister|Inactive|No|St. Louis|Account Representative
Chris|Hunter|Active|No|Chicago|Client Service Representative
Maryanne|Jacobson|Active|No||
Perry|Jasper|Inactive|No||
James|John|Active|No||
Nicholas|Johns|Inactive|No||
Bob|Johnson|Inactive|No||
David|Johnson|Active|No||
Simon|Johnson|Active|No||
Corinne|Kent|Inactive|No||
Shelly|Konold|Active|No|Chicago|Client Service Representative
Archie|Krammer|Active|No||
Betty|Larsen|Active|No||
John|LeSueur|Active|Yes||
Lydia|Learner|Inactive|No||
Mason|Marsh|Active|No||
Kelly|Mayberry|Active|No||
Jacob|Miller|Inactive|No|Chicago|Site Supervisor
Jennifer|Miller|Inactive|No|Chicago|Site Supervisor
Larry|Millner|Active|No||
Erin|Monroe|Inactive|No|Corporate Office|VP
Allison|Muaina|Inactive|No|St. Louis|Payroll Administrator
Joshua|Ninow|Active|No|Chicago|Account Representative
Samuel|Nunez|Inactive|No|St. Louis|Account Representative
William|Nye|Active|No|St. Louis|Account Representative
Gabe|Ogden|Active|No|Chicago|Account Representative
Terrie|Orullian|Active|No|Chicago|Account Representative
Chris|Parker|Inactive|No||
Brooke|Petersen|Active|No||
Lacey|Peterson|Active|No||
Nathan|Pyper|Active|No|Chicago|Account Representative
David|Quallman|Inactive|No||Development Supervisor
Brian|Quick|Active|No|Chicago|Client Service Representative
Rachel|Ray|Active|No||
Jordan|Reeves|Active|No|St. Louis|Account Representative
Matt|Reid|Inactive|No||
Melvin|Reynolds|Active|No||
Kodie|Romrell|Active|No|St. Louis|Client Service Representative
Melanie|Sanderson|Active|No|St. Louis|Marketing Facilitator
Betsy|Schow|Active|No|Chicago|Office Administration
Andy|Shaw|Active|No|Chicago|Office Administration
Peter|Showalter|Inactive|No||
Andreas|Silva|Active|No|St. Louis|Office Administration
William|Smith|Inactive|No||
Kevin|Smith|Inactive|No||
Kevin|Smith|Inactive|No|Chicago|Site Supervisor
Steven|Smith|Inactive|No||Office Administration
Kristi|Smith|Active|No||
Sarah|Smith|Active|No||
Kay|Stoddard|Active|No||
Hayley|Thayn|Active|No|St. Louis|Office Administration
George|Thomp|Inactive|No|St. Louis|
Jayne|Thompson|Inactive|No||Marketing Facilitator
Jeff|Thompson|Inactive|No||
Silvia|Turner|Inactive|No||
Kirk|Wensink|Inactive|No||
Kirk|Wensink|Inactive|No|Chicago|Site Supervisor
Dylan|Wright|Active|No|St. Louis|Development Supervisor
Brian|Yack|Inactive|No||Client Service Representative
Tammy|Zabcdef|Inactive|No||
Eric|Zincke|Active|No|Chicago|Payroll Administrator
