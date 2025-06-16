package pEFL::Eina::List;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EinaListPtr);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL::Elm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

require XSLoader;
XSLoader::load('pEFL::Eina::List');

sub add {
    my ($class,$parent) = @_;
    my $list = eina_list_add($parent);
    #$widget->smart_callback_add("del", \&pEFL::PLSide::cleanup, $widget);
    return $list;
}

*new = \&add;

package EinaListPtr;

our @ISA = qw();

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Eina::List

=head1 DESCRIPTION

This module is a perl binding to the Eina List datatype. 

If a method returns an Eina_List, it is better to use the perl function with the
suffix _pv. This translates the Eina_List into an perl array.

You can manually convert an Eina_List to a perl array with Eina::list2array($list, $class).

Note: At the moment it is not planed to support the Eina datatypes in Perl. Also the function in this
module are not tested at the moment. So use it at your own risk!

=head2 EXPORT

None by default.


=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Eina__List__Group.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
