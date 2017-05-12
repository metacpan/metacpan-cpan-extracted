package WWW::WolframAlpha::Units;

use 5.008008;
use strict;
use warnings;

require Exporter;

use WWW::WolframAlpha::Unit;

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

    my ($count,$unit,$img);

    if ($xmlo) {
	$count = $xmlo->{'count'} || undef;
	$unit = $xmlo->{'unit'} || undef;
	$img = $xmlo->{'img'} || undef;

	$self->{'count'} = $count if defined $count;

	if (defined $unit) {
	    @{$self->{'unit'}} = ();
	    foreach my $value (@{$unit}) {
		push(@{$self->{'unit'}}, WWW::WolframAlpha::Unit->new($value));
	    }
	}

	if (defined $img) {
	    my $html = '<img';
	    foreach my $attr (keys %{$img}) {
		$html .= ' ' . $attr . '=\'' . $img->{$attr} . '\'';
	    }
	    $html .= '/>';
	    $self->{'img'} = $html;
	}

    }


    return(bless($self, $class));
}

sub count {shift->{'count'};}
sub unit {shift->{'unit'};}
sub img {shift->{'img'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::Units

=head1 VERSION

version 1.10

=head1 SYNOPSIS

    if ($info->units->count) {
      print "      units img: ", $info->units->img, "\n" if $info->units->img;
        foreach my $unit (@{$info->units->unit}) {
          ...
        }
     }

=head1 DESCRIPTION

=head2 ATTRIBUTES

$units->count

=head2 SECTOINS

$units->unit - array of L<WWW::WolframAlpha::Unit> elements

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha::Units - Perl objects returned via $info->units

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

