package TryUser;

use Try::Tiny::Except;

sub test_try { try { } }
sub test_catch { try { } catch { } }
sub test_finally { try { } finally { } }

1;
