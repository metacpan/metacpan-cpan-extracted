package WWW::WolframAlpha::Link;

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

    my ($url,$text,$title);

    if ($xmlo) {
	$title = $xmlo->{'title'} || undef;
	$text = $xmlo->{'text'} || undef;
	$url = $xmlo->{'url'} || undef;

	$self->{'title'} = $title if defined $title;
	$self->{'text'} = $text if defined $text;
	$self->{'url'} = $url if defined $url;
    }

    return(bless($self, $class));
}

sub title {shift->{'title'};}
sub text {shift->{'text'};}
sub url {shift->{'url'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::Link

=head1 VERSION

version 1.10

=head1 SYNOPSIS

    foreach my $link (@{$info->link}) {
      print "      link: ", $link->url, "\n";
      print "        title: ", $link->title, "\n" if $link->title;
      print "        text: ", $link->text, "\n" if $link->text;
    }

=head1 DESCRIPTION

=head2 ATTRIBUTES

$link->title

$link->text

$link->url

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha::Link - Perl objects returned via $info->link

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

