# After this module is loaded, perl object can be pickled
# The perl objects can even contain python objects that contain
# perl objects that contain python objects that...
#
# You are not supposed to use any functions from this module.
# Just use Pickle as usual.
#
# Copyright 2000-2001 ActiveState

import perl
perl.require("Storable")
perl.callm("VERSION", "Storable", 0.7);

storable_thaw = perl.get_ref("Storable::thaw")
storable_nfreeze = perl.get_ref("Storable::nfreeze")

def perl_restore(frozen):
    return storable_thaw(frozen)

def perl_reduce(o):
    return (perl_restore,
            (storable_nfreeze(o),)
           )

import copy_reg
copy_reg.pickle(type(perl.get_ref("$")), perl_reduce, perl_restore)
del(copy_reg)

from cPickle import dumps, loads

# Make the dumps and loads functions available for perl
f = perl.get_ref("$Python::Object::pickle_dumps", 1)
f.__value__ = dumps;
f = perl.get_ref("$Python::Object::pickle_loads", 1)
f.__value__ = loads;
del(f)

perl.eval("""

package Python::Object;

sub STORABLE_freeze {
   my($self, $cloning) = @_;
   return Python::funcall($pickle_dumps, $self, 1);
}

sub STORABLE_thaw {
   my($self, $cloning, $serialized) = @_;
   my $other = Python::funcall($pickle_loads, $serialized);
   Python::PyO_transplant($self, $other);
   return;
}

""")
