package Tk::EntryCheck;
use warnings; # removed to be backward compatible with perl5.005_03
use strict;
use 5.005;
use Carp;

use vars qw( $VERSION );

$VERSION = '0.04';

use base qw( Tk::Derived Tk::Entry );
Construct Tk::Widget 'EntryCheck';
# ------------------------------------------------------------
sub ClassInit {
    my( $class, $parent ) = @_;

    # class bindings here

    $class->SUPER::ClassInit( $parent );
} # ClassInit
# ------------------------------------------------------------
sub Populate {
    my( $self, $args ) = @_;

    $self->SUPER::Populate( $args );

    $self->ConfigSpecs
        (
         -maxlength => [ 'PASSIVE', 'maxlength', undef, $args->{-maxlength} ],
         -pattern   => [ 'PASSIVE', 'pattern'  , undef, qr/./ ],
#         -totalpattern => [ 'PASSIVE', 'totalPattern', undef, qr/./ ],
     );

    my $maxLength = $args->{-maxlength};
    if( defined $maxLength ) {
        if( $maxLength =~ /\D/ ) {
            Carp::carp( "-maxlength not numeric: '$maxLength'" );
        } # if
        elsif( $maxLength =~ /^\d+/ and $maxLength < 1 ) {
            Carp::carp( "-maxlength must be int > 0: '$maxLength'" );
        } # elsif
    } # if

    $self->configure
        (
         -validate => 'all',
         -validatecommand => [ \&_EntryCheckValidate, $self ],
     );

    return $self;
} # Populate
# ------------------------------------------------------------
sub _EntryCheckValidate {
    my ($self, $text, $textNew, $textOld, $pos, $mode) = @_;

    my $maxlength = $self->{Configure}->{-maxlength};
    my $pattern   = $self->{Configure}->{-pattern};

    # check if -maxlength is reached
    if (defined $maxlength and length($text) > $maxlength) {
	if ($mode == -1) { # change done by -textvariable
	    &Carp::carp("EntryCheck: content of textvariabe too long");
	} # if
	return 0;
    } # if

    # allow all deletions
    return 1 if $mode == 0;

    # check if -pattern is matching
    if (defined $pattern) {
	if (defined($textNew)) {
	    if ($textNew !~ /^$pattern*$/) {
		if ($mode == -1) { # change done by -textvariable
		    &Carp::carp("EntryCheck: invalid chars by textvariable");
		} # if
		return 0;
	    } # if
	} # if

	elsif (defined $text) {
	    if ($text !~ /^$pattern*$/) {
		if ($mode == -1) { # change done by -textvariable
		    &Carp::carp("EntryCheck: invalid chars by textvariable");
		} # if
		return 0 ;
	    } # if
	} # elsif
    } # if

    return 1;
} # _EntryCheckValidate
# ------------------------------------------------------------


#------------------------------------------------------------
1; # modules have to return a true value
__END__

=head1 NAME

Tk::EntryCheck - Interface to Tk::Entry for controlling its maximum length
and content in an easy way.

=head1 SYNOPSIS

  use Tk;
  use Tk::EntryCheck;

  my $mw = MainWindow->new();

  my $entry = $mw->EntryCheck(

    # some standard Entry-Options which are forwarded to Tk::Entry
    -width => 20,

    # and now the new options
    -maxlength => 10,     # accepts 10 chars at maximum for content
    -pattern   => qr/\d/, # accepts only \d, nothing else
  )
  ->pack();

  MainLoop();

=head1 DESCRIPTION

This module acts as a little wrapper around Tk::Entry and adds an easy to
use interface to B<-validate> and B<-validatecommand> for controlling length
and content of an entry widget.

It's provides the following additional features:

x) Set a maximum length to this entry with the parameter -maxlenght. Gives a 
warning by B<carp> if this is defined but not a positive integer. If the 
content is added by changing a variable attached as B<-textvariable>, it also
gives a warning with B<carp> and denies the change.

x) Allow only certain characters inside this entry. You can submit
it as a regular expression in the parameter -pattern, e.g.

  -pattern => qr/[A-Za-z0-9]/, # alphanumeric

  -pattern = qr/\d/,           # numbers only

  -pattern = qr/[A-Z ]/,       # capital characters and spaces

If the content is added by a variable attached to the widget as 
B<-textvariable>, it also gives a warning with B<carp> and denies the change.

B<ATTENTION:> this character class check is done for each character and 
enhanced internally by *, so don't try to use something like 
I<-pattern => qr(\d+)>, because that would result in \d+* and give an error.

B<ATTENTION:> don't forget to specify an empty space if you need it...

If you want to overwrite the methods used for validation, you can do so by
just setting the original entry options B<-validate> and/or 
B<-validatecommand>...

=head1 Dependencies

x) Perl-Version >= 5.005 

x) Tk and L<Tk::Entry> must be installed and running

=head1 EXPORT

Nothing. As there is no need for exports and as I hate namespace pollution, 
I removed the Exporter...

=head1 SEE ALSO

See L<Tk::Entry> for the other options, especially the options B<-validate> 
and B<-validatecommand>

See L<Tk::FilterEntry> which is similar.

=head4 Differences between Tk::EntryCheck and Tk::FilterEntry

x) FilterEntry doesn't deny adding invalid chars or strings which are too long

x) EntryCheck just checks each char if it in a characterclass, whereas 
FilterEntry checks the whole content with a regular expression, so it is
more helpful when checking for special formats

x) FilterEntry (v0.02) gives a warning if the field is empty

x) FilterEntry gives nice textcolors if the content of the textfield is 
invalid; but that just works when the widget leaves the focus (V0.02)

See L<http://www.fabiani.net/>: My Homepage (in German)

See L<http://www.perl-community.de/>: German Perl Forum


=head1 AUTHOR

Martin Fabiani (aka Strat), E<lt>martin@fabiani.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Martin Fabiani

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
