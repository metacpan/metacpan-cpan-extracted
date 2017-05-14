BEGIN {warn "In preinit!\n";}		# Of course, the order is different
					# in static and dynamic version
use c_plus_plus;
warn "After initialization.\n";
