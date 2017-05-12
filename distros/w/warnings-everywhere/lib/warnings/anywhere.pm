package warnings::anywhere;

use strict qw(vars subs);
use warnings::everywhere;

*warnings::anywhere:: = \*warnings::everywhere::;

=head1 NAME

warnings::anywhere - an alias for warnings::everywhere

=head1 SYNOPSIS

 no warnings::anywhere qw(uninitialized);
 
=head1 DESCRIPTION

A more grammatical name for warnings::everywhere, when you're turning off
warnings.

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
