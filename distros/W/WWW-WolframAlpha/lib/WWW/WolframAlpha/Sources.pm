package WWW::WolframAlpha::Sources;

use 5.008008;
use strict;
use warnings;

require Exporter;

use WWW::WolframAlpha::Source;

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

    $self->{'count'} = 0;
    @{$self->{'source'}} = ();

    my ($count,$source);

    if ($xmlo) {
	$count = $xmlo->{'count'} || undef;
	$source = $xmlo->{'source'} || undef;

	$self->{'count'} = $count if defined $count;

	if (defined $source) {
	    foreach my $value (@{$source}) {
		push(@{$self->{'source'}}, WWW::WolframAlpha::Source->new($value));
	    }
	}
    }


    return(bless($self, $class));
}

sub count {shift->{'count'};}
sub source {shift->{'source'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::Sources

=head1 VERSION

version 1.10

=head1 SYNOPSIS

    if ($query->sources->count) {
      foreach my $source (@{$query->sources->source}) {
        ...
      }
    }

=head1 DESCRIPTION

=head2 ATTRIBUTES

$sources->count

=head2 SECTOINS

$sources->source - array of L<WWW::WolframAlpha::Source> elements

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha::Sources - Perl object returned via $query->sources

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

