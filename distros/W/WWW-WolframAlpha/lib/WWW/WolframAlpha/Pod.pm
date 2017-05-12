package WWW::WolframAlpha::Pod;

use 5.008008;
use strict;
use warnings;

require Exporter;

use WWW::WolframAlpha::Subpod;
use WWW::WolframAlpha::States;
use WWW::WolframAlpha::Infos;
use WWW::WolframAlpha::Sounds;
use WWW::WolframAlpha::Error;

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

    @{$self->{'subpods'}} = ();

    my ($title,$scanner,$position,$error,$numsubpods,$subpods,$states,$infos,$markup,$sounds,$async);

    $self->{'error'} = 1;

    if ($xmlo) {
	$title = $xmlo->{'title'} || undef;
	$scanner = $xmlo->{'scanner'} || undef;
	$position = $xmlo->{'position'} || undef;
	$error = $xmlo->{'error'} || undef;
	$numsubpods = $xmlo->{'numsubpods'} || undef;
	$subpods = $xmlo->{'subpod'} || undef;
	$states = $xmlo->{'states'} || undef;
	$sounds = $xmlo->{'sounds'} || undef;
	$infos = $xmlo->{'infos'} || undef;
	$markup = $xmlo->{'markup'} || undef;
	$async = $xmlo->{'async'} || undef;

	$self->{'title'} = $title if defined $title;
	$self->{'scanner'} = $scanner if defined $scanner;
	$self->{'position'} = $position if defined $position;
	$self->{'numsubpods'} = $numsubpods if defined $numsubpods;
	$self->{'markup'} = $markup if defined $markup;
	$self->{'async'} = $async if defined $async;

	if (defined $error && $error eq 'false') {
	    $self->{'error'} = 0;
	} elsif (defined $error && $error ne 'false') {
	    $self->{'error'} = WWW::WolframAlpha::Error->new($error);
	}

	if (defined $subpods) {
	    foreach my $subpod (@{$subpods}) {
		push(@{$self->{'subpods'}}, WWW::WolframAlpha::Subpod->new($subpod));
	    }
	}
    }

    $self->{'states'} = WWW::WolframAlpha::States->new($states);
    $self->{'infos'} = WWW::WolframAlpha::Infos->new($infos);
    $self->{'sounds'} = WWW::WolframAlpha::Sounds->new($sounds);

    return(bless($self, $class));
}

sub title {shift->{'title'};}
sub scanner {shift->{'scanner'};}
sub position {shift->{'position'};}
sub error {shift->{'error'};}
sub numsubpods {shift->{'numsubpods'};}
sub subpods {shift->{'subpods'};}
sub states {shift->{'states'};}
sub infos {shift->{'infos'};}
sub markup {shift->{'markup'};}
sub sounds {shift->{'sounds'};}
sub async {shift->{'async'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::Pod

=head1 VERSION

version 1.10

=head1 SYNOPSIS

  foreach my $subpod (@{$pod->subpods}) {
    ...
 }

if ($pod->sounds->count) {
 ...
}

=head1 DESCRIPTION

=head2 SUCCESS

$pod->error - 0 or L<WWW::WolframAlpha::Error>, tells whether there was an error or not

=head2 ATTRIBUTES

$pod->title

$pod->scanner

$pod->position

$pod->markup

$pod->async

$pod->numsubpods

=head2 SECTOINS

$pod->subpods - array of L<WWW::WolframAlpha::Subpod> elements

$pod->states - L<WWW::WolframAlpha::States> object

$pod->sounds - L<WWW::WolframAlpha::Sounds> object

$pod->infos - L<WWW::WolframAlpha::Infos> object

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha::Pod - Perl objects accessed via $query->pods

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

