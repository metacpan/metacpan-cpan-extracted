package WWW::Mechanize::SpamCop;

# $Abso: abso/divers/mat/perl/WWW-Mechanize-SpamCop/SpamCop.pm,v 1.4 2003/08/05 14:28:00 mat Exp $

#---[ pod head ]---{{{

=head1 NAME

WWW::Mechanize::SpamCop - SpamCop reporting automation.

=head1 SYNOPSIS

    use WWW::Mechanize::SpamCop;

    $s = WWW::Mechanize::SpamCop->new(
	login    => 'login@spamcop.net',
	passwd => 'passwd'
    );

    $s->report_one;

    $s->report_all;


=head1 ABSTRACT

WWW::Mechanize::SpamCop is used to automate spam reporting on spamcop.net's web
site.

=cut

=head1 DESCRIPTION

=cut

#---}}}

use WWW::Mechanize;
use strict;
use Carp;

use vars qw(@ISA $VERSION);

@ISA = qw(WWW::Mechanize);

$VERSION = '0.08';

#---[ sub new ]---{{{

=head2 new

Create a new WWW::Mechanize::SpamCop object

The required arguments are login and passwd, you can also pass it a host,
defaulting to 'www.spamcop.net:80' (the :80 is needed because of the
authentication), a realm, defaulting to 'your SpamCop account' which is the
domain's realm for autentication. and a report default to 'Report Now', which
is the name of the link on the web page.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %p     = @_;

    croak 'You must specify a login'
	unless ( exists( $p{login} ) );
    croak 'You must specify a passwd'
	unless ( exists( $p{passwd} ) );

    my $login  = delete( $p{login} );
    my $passwd = delete( $p{passwd} );

    my $self = $class->SUPER::new(%p);

    $self->{host}   = $p{host}   || 'www.spamcop.net:80';
    $self->{realm}  = $p{realm}  || 'your SpamCop account';
    $self->{report} = $p{report} || 'Report Now';
    $self->{regex_remove_unreported} = $p{regex_remove_unreported} || qr/^Remove all unreported/;
    $self->{regex_removed_count} = $p{regex_removed_count} || qr/Removed\s+([0-9]+)\s+unreported/i;
    $self->{sendformname} = $p{sendformname} || 'sendreport';
    $self->{login}  = $login;
    $self->{passwd} = $passwd;

    croak 'SomeThing went wrong'
	unless $self->get("http://$self->{host}/");

    $self->form_number(1);
    $self->field('username', $self->{login});
    $self->field('password', $self->{passwd});
    $self->click() or return undef;

    return $self;
}

#---}}}

#---[ sub report_one ]---{{{

=head2 report_one

Report one spam

returns :

=over

=item undef

no spam was found

=item 1

if a spam was reported

=item 2

if the spam was too old

=back

=cut

sub report_one {
    my $self = shift;

    if ( $self->follow_link( text => $self->{report} ) ) {
	# Probably makes no sense because currently there's a submission form instead of link:
	#if ( $self->find_link( text => $self->{report} ) ) {
	#    return 2;
	#}

	my @forms = $self->forms();
	# Look for "send report" form:
	if (scalar(@forms) < 1) { return undef };
	@forms = grep { defined ($_->attr("name")) && $_->attr("name") eq $self->{sendformname}} @forms;
	# If a form with the proper name is found, submit report:
	if (@forms) {
		$self->form_name($self->{sendformname});
		$self->click() or return undef;
		return 1;
	} else {
		return 2;
	}

    } else {
	return undef;
    }
}

#---}}}

#---[ sub report_all ]---{{{

=head2 report_all

Report all waiting spams

If called in a scalar context, returns the number of spam reported. If in an
array context, returns an array containing the number of reported spams and the
number of old spams (not reported).

=cut

sub report_all {
    my $self = shift;
    my ( $i, $j ) = ( 0, 0 );
    while ( my $r = $self->report_one ) {
	$i++ if ( $r == 1 );
	$j++ if ( $r == 2 );
    }

    return unless defined wantarray;
    return ( wantarray ? ( $i, $j ) : $i );
}

#---}}}

#---[ sub remove_unreported ]---{{{

=head2 remove_unreported


Removes all unreported spams. Returns the number of removed spams as scalar value.

=cut

sub remove_unreported {
    my $self = shift;
    my $count = 0;
    if ( $self->follow_link( text_regex => $self->{regex_remove_unreported} ) ) {
      my $content = $self->content( format => "text" );
      my $regex_removed_count = $self->{regex_removed_count};
      if ($content =~ qr/$regex_removed_count/si) {
        $count = $1;
      }
      return $count;
    } else {
      return 0;
    } 
}

#---}}}

1;
__END__

#---[ pod end ]---{{{

=head1 SEE ALSO

L<WWW::Mechanize>

=head1 AUTHOR

Mathieu Arnold, E<lt>mat@cpan.orgE<gt>
new maintainer: Aleksander Adamowski, E<lt>cpan@olo.org.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003,2007 by Mathieu Arnold, Aleksander Adamowski

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut

#---}}}
