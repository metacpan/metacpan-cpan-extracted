package goddamn::warnings::anywhere;

use strict qw(vars subs);
use warnings::everywhere;

*goddamn::warnings::anywhere:: = \*warnings::everywhere::;

=head1 NAME

goddamn::warnings::anywhere - an insistent alias for warnings::everywhere

=head1 SYNOPSIS

 no goddamn::warnings::anywhere qw(uninitialized);
 
=head1 DESCRIPTION

A mildly profane, and grammatical, name for warnings::everywhere, when you
really, really care about turning off warnings.

=head1 SUBROUTINES

=over

=item categories_disabled

=item categories_enabled

=item disable_warning_category

=item enable_warning_category

As per warnings::anywhere.

=back

=cut

1;
