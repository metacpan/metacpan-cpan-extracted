package WWW::WolframAlpha::Info;

use 5.008008;
use strict;
use warnings;

require Exporter;

use WWW::WolframAlpha::Link;
use WWW::WolframAlpha::Units;

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

    my ($content,$links,$units);

    @{$self->{'link'}} = ();
    @{$self->{'units'}} = ();

    if ($xmlo) {
	$content = $xmlo->{'content'} || undef;
	$links = $xmlo->{'link'} || undef;
	$units = $xmlo->{'units'} || undef;

	$self->{'text'} = $content if defined $content;

	if (defined $links) {
	    foreach my $link (@{$links}) {
		push(@{$self->{'link'}}, WWW::WolframAlpha::Link->new($link));
	    }
	}
    }

    $self->{'units'} = WWW::WolframAlpha::Units->new($units);

    return(bless($self, $class));
}

sub text {shift->{'text'};}
sub link {shift->{'link'};}
sub units {shift->{'units'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::Info

=head1 VERSION

version 1.10

=head1 SYNOPSIS

         foreach my $info (@{$pod->infos->info}) {
             print "      text: ", $info->text, "\n" if $info->text;
             foreach my $link (@{$info->link}) {
               ...
             }

             if ($info->units->count) {
                 foreach my $unit (@{$info->units->unit}) {
                   ...
                 }
             }
         }

=head1 DESCRIPTION

=head2 ATTRIBUTES

$infos->text

=head2 SECTOINS

$infos->link - array of L<WWW::WolframAlpha::Link> elements

$infos->units - L<WWW::WolframAlpha::Units> object

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha::Info - Perl object returned via $wa->infos->info

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

