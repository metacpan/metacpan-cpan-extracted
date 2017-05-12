package WWW::WolframAlpha::Warnings;

use 5.008008;
use strict;
use warnings;

require Exporter;

use WWW::WolframAlpha::Spellcheck;

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
    @{$self->{'spellcheck'}} = ();

    my ($count,$delimiters,$spellchecks);

    if ($xmlo) {
	$count = $xmlo->{'count'} || undef;
	$delimiters = $xmlo->{'delimiters'} || undef;
	$spellchecks = $xmlo->{'spellcheck'} || undef;

	$self->{'count'} = $count if defined $count;

	if (defined $delimiters && $delimiters->{'text'}) {
	    $self->{'delimiters'} = $delimiters->{'text'};
	}

	if (defined $spellchecks) {
	    foreach my $spellcheck (@{$spellchecks}) {
		push(@{$self->{'spellcheck'}}, WWW::WolframAlpha::Spellcheck->new($spellcheck));
	    }
	}
    }


    return(bless($self, $class));
}

sub count {shift->{'count'};}
sub delimiters {shift->{'delimiters'};}
sub spellcheck {shift->{'spellcheck'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::Warnings

=head1 VERSION

version 1.10

=head1 SYNOPSIS

    if ($query->warnings->count) {
        print "\nWarnings\n";
        print "  delimiters: ", $query->warnings->delimiters, "\n" if $query->warnings->delimiters;

        foreach my $spellcheck (@{$query->warnings->spellcheck}) {
          ...
        }
    }

=head1 DESCRIPTION

=head2 ATTRIBUTES

$warnings->count

$warnings->delimiters

=head2 SECTOINS

$warnings->spellcheck - array of L<WWW::WolframAlpha::Spellcheck> elements

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha::Warnings - Perl object returned via $wa->(?:validate|)query->warnings

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

