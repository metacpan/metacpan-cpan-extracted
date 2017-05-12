package WWW::WolframAlpha::ValidateQuery;

use 5.008008;
use strict;
use warnings;

require Exporter;

use WWW::WolframAlpha::Assumptions;
use WWW::WolframAlpha::Warnings;
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

    my %options = @_;

    my $self = {};
    while(my($key, $val) = each %options) {
	my $lkey = lc($key);
	$self->{$lkey} = $val;
    }

    my ($timing,$parsetiming,$assumptions,$warnings,$error,$success);

    @{$self->{'warnings'}} = ();

    $self->{'success'} = 0;
    $self->{'error'} = 1;

    if ($self->{'xmlo'}) {
	$timing = $self->{'xmlo'}->{'timing'} || undef;
	$parsetiming = $self->{'xmlo'}->{'parsetiming'} || undef;
	$assumptions = $self->{'xmlo'}->{'assumptions'} || undef;
	$success = $self->{'xmlo'}->{'success'} || undef;
	$error = $self->{'xmlo'}->{'error'} || undef;
	$warnings = $self->{'xmlo'}->{'warnings'} || undef;

	$self->{'timing'} = $timing if defined $timing;
	$self->{'parsetiming'} = $parsetiming if defined $parsetiming;

	if (defined $success && $success eq 'true') {
	    $self->{'success'} = 1;
	}

	if (defined $error && $error eq 'false') {
	    $self->{'error'} = 0;
	} elsif (defined $error && $error ne 'false') {
	    $self->{'error'} = WWW::WolframAlpha::Error->new($error);
	}
    }

    $self->{'assumptions'} = WWW::WolframAlpha::Assumptions->new($assumptions);
    $self->{'warnings'} = WWW::WolframAlpha::Warnings->new($warnings);

    return(bless($self, $class));
}

sub success {shift->{'success'};}
sub error {shift->{'error'};}
sub xml {shift->{'xml'};}
sub xmlo {shift->{'xmlo'};}
sub timing {shift->{'timing'};}
sub parsetiming {shift->{'parsetiming'};}
sub assumptions {shift->{'assumptions'};}
sub warnings {shift->{'warnings'};}


# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha::ValidateQuery

=head1 VERSION

version 1.10

=head1 SYNOPSIS

my $validatequery = $wa->validatequery(
    input => $input,
    assumption => '*C.pi-_*Movie-',
    );	

if ($validatequery->success) {
          ...
 }

=head1 DESCRIPTION

=head2 SUCCESS

$validatequery->success - 0/1, tells whether it was successful or not

$validatequery->error - 0 or L<WWW::WolframAlpha::Error>, tells whether there was an error or not

=head2 ATTRIBUTES

$validatequery->timing 

$validatequery->parsetiming

=head2 SECTOINS

$query->assumptions - L<WWW::WolframAlpha::Assumptions> object

$query->warnings - L<WWW::WolframAlpha::Warnings> object

=head2 DEBUGGING

$validatequery->xml - raw XML

$validatequery->xmlo - raw XML::Simple object

=head1 NAME

WWW::WolframAlpha::ValidateQuery - Perl object returned via $wa->validatequery

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

