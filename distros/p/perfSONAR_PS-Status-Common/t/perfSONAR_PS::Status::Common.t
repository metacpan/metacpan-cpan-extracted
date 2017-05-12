use Test::More 'no_plan';

use_ok('perfSONAR_PS::Status::Common');
use perfSONAR_PS::Status::Common;

ok (isValidOperState("up"));
ok (isValidOperState("down"));
ok (isValidOperState("degraded"));
ok (isValidOperState("unknown"));
ok (isValidOperState("DeGrAdEd"));
ok (!isValidOperState("INVALID"));
ok (isValidAdminState("normaloperation"));
ok (isValidAdminState("maintenance"));
ok (isValidAdminState("troubleshooting"));
ok (isValidAdminState("underrepair"));
ok (isValidAdminState("unknown"));
ok (isValidAdminState("UnKnOwN"));
ok (!isValidAdminState("INVALID"));
