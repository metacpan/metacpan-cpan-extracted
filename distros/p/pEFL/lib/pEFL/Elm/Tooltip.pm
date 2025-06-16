package pEFL::Elm::Tooltip;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;

our @ISA = qw(Exporter ElmTooltipPtr);

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
XSLoader::load('pEFL::Elm::Tooltip');


package ElmTooltipPtr;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Elm:Tooltip

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $widget = pEFL::Elm::Tooltip->add($parent);
  $widget->collapse_set(1);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Tooltip widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Tooltip.html 

For instructions, how to use pEFL::Elm::Tooltip, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Tooltip gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_tooltip_" at the beginning of the c functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Tooltip.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
