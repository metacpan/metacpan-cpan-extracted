package WWW::WolframAlpha::Unit;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::WolframAlpha ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '1.0';


sub new {
    my $class = shift;
    my $xmlo = shift;

    my $self = {};

    my ($short,$long);

    if ($xmlo) {
	$short = $xmlo->{'short'} || undef;
	$long = $xmlo->{'long'} || undef;

	$self->{'short'} = $short if defined $short;
	$self->{'long'} = $long if defined $long;
    }

    return(bless($self, $class));
}

sub short {shift->{'short'};}
sub long {shift->{'long'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::Unit

=head1 VERSION

version 1.10

=head1 SYNOPSIS

    foreach my $unit (@{$info->units->unit}) {
      print "      unit: ", $unit->short, "\n";
      print "        long: ", $unit->long, "\n";
    }

=head1 DESCRIPTION

=head2 ATTRIBUTES

$unit->short

$unit->long

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha::Unit - Perl objects returned via $info->units->unit

=head1 SEE ALSO

L<WWW::WolframAlpha>

=head1 AUTHOR

Gabriel Weinberg, E<lt>yegg@alum.mit.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gabriel Weinberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Gabriel Weinberg <yegg@alum.mit.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Gabriel Weinberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
# Below is stub documentation for your module. You'd better edit it!

