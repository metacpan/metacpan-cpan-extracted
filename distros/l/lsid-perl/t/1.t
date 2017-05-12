# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

# Test LS and LS::Base

use Test::More qw(no_plan);

BEGIN { 

	use_ok('LS');
}

ok(${LS::VERSION}, 'Verify that the version is set');

ok(!${LS::Base::_ERR}, 'Verify the package error string is not defined');

isa_ok(${LS::Base::_STACK_TRACE}, 'ARRAY', 'Verify the stack trace');

cmp_ok(scalar(@{ ${LS::Base::_STACK_TRACE} }), '==', '0', 'Verify the stack trace array is empty');

LS::Base->recordError('Error message');

cmp_ok(LS::Base->errorString(), 'eq' ,'Error message', 'Test the package error string');



__END__
