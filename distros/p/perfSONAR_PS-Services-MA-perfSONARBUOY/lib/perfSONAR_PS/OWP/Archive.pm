package perfSONAR_PS::OWP::Archive;

require 5.005;
use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::OWP::Archive

=head1 DESCRIPTION

TBD 

=cut

use File::Path;
use DBI;
use English qw( -no_match_vars );
use perfSONAR_PS::OWP;
use perfSONAR_PS::OWP::Utils;

#$Archive::REVISION = '$Id: Archive.pm 1877 2008-03-27 16:33:01Z aaron $';
#$Archive::VERSION='1.0';

=head2 new()

TDB

=cut

sub new {
    my ( $class, @initialize ) = @_;
    my $self = {};

    bless $self, $class;

    $self->init(@initialize);

    return $self;
}

=head2 init()

TDB

=cut

sub init {
    my ( $self, %args ) = @_;
    my ($datadir);

    #
    # This is bogus at the moment. Need to figure out what vars
    # the arch stuff is going to need.
    #
ARG:
    foreach ( keys %args ) {
        my $name = $_;
        $name =~ tr/a-z/A-Z/;
        if ( $name ne $_ ) {
            $args{$name} = $args{$_};
            delete $args{$_};
        }

        # Add each "init" var here
        /^datadir$/oi and $self->{$name} = $args{$name}, next ARG;
        /^archdir$/oi and $self->{$name} = $args{$name}, next ARG;
        /^suffix$/oi  and $self->{$name} = $args{$name}, next ARG;
    }

    die "DATADIR undefined" if ( !defined $self->{'DATADIR'} );
    die "ARCHDIR undefined" if ( !defined $self->{'ARCHDIR'} );

    return;
}

=head2 add()

basically, this function should add a link to the
datafile in an archive staging area.
my $newfile = "$self->{'ARCHDIR'}/$args{'MESH'}/$args{'RECV'}/$args{'SEND'}/$args{'START'}_$args{'END'}$self->{'SUFFIX'}";

=cut

sub add {
    my ( $self, %args ) = @_;
    my (@argnames) = qw(DBH DATAFILE TESTID MESH RECV SEND START END);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    scalar %args || return 0;

    my ( $start, $end );
    $start = new Math::BigInt $args{'START'};
    $end   = new Math::BigInt $args{'END'};

    my $newfile = "$self->{'ARCHDIR'}/" . owptstampdnum($start) . "/$args{'MESH'}_$args{'RECV'}_$args{'SEND'}";

    eval { mkpath( [$newfile], 0, 0775 ) };
    if ($EVAL_ERROR) {
        warn "Couldn't create dir $newfile:$@:$?";
        return 0;
    }
    $newfile .= "/$args{'START'}_$args{'END'}$self->{'SUFFIX'}";

    my $sql = "
		INSERT INTO pending_files
		VALUES(?,?,?,?)";
    my $sth = $args{'DBH'}->prepare($sql) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi($start), owptstampi($end), $newfile ) || return 0;

    link $args{'DATAFILE'}, $newfile
        || return 0;

    return 1;
}

=head2 rm()

TDB

=cut

sub rm {
    my ( $self, %args ) = @_;
    my (@argnames) = qw(DBH DATAFILE TESTID MESH RECV SEND START END);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    %args || return 0;
    my ( $start, $end );
    $start = new Math::BigInt $args{'START'};
    $end   = new Math::BigInt $args{'END'};

    my $sql = "
		SELECT filename FROM pending_files
		WHERE
			test_id = ? AND
			si = ? AND
			ei = ?";
    my $sth = $args{'DBH'}->prepare($sql) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi($start), owptstampi($end) )
        || return 0;
    my ( @row, @files );
    while ( @row = $sth->fetchrow_array ) {
        push @files, @row;
    }
    if ( @files != 1 ) {
        warn "perfSONAR_PS::OWP::Archive::rm called on non-existant session";
        return 0;
    }

    $sql = "
		DELETE pending_files
		WHERE
			test_id=? AND
			si=? AND
			ei=?";
    $sth = $args{'DBH'}->prepare($sql) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi($start), owptstampi($end) )
        || return 0;

    unlink @files || return 0;

    return 1;
}

=head2 delete_range()

TDB

=cut

sub delete_range {
    my ( $self, %args ) = @_;
    my (@argnames) = qw(DBH TESTID FROM TO);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    scalar %args || return 0;

    my $from = new Math::BigInt $args{'FROM'};
    my $to   = new Math::BigInt $args{'TO'};
    my $sql  = "
		SELECT filename FROM pending_files
		WHERE
			test_id = ? AND
			si>? AND ei<?";
    my $sth = $args{'DBH'}->prepare($sql) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi($from), owptstampi($to) )
        || return 0;
    my ( @row, @files );
    while ( @row = $sth->fetchrow_array ) {
        push @files, @row;
    }

    if (@files) {
        $sql = "
			DELETE FROM pending_files
			WHERE
				test_id = ? AND
				si>? AND ei<?";
        $sth = $args{'DBH'}->prepare($sql) || return 0;
        $sth->execute( $args{'TESTID'}, owptstampi($from), owptstampi($to) ) || return 0;

        unlink @files || return 0;
    }

    return 1;
}

=head2 validate()

TDB

=cut

sub validate {
    my ( $self, %args ) = @_;
    my (@argnames) = qw(DBH TESTID TO);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    scalar %args || return 0;

    my $to = new Math::BigInt $args{'TO'};

    my $sql = "
		DELETE FROM pending_files
		WHERE
			test_id = ? AND
			ei<?";
    my $sth = $args{'DBH'}->prepare($sql) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi($to) ) || return 0;

    return 1;
}

1;

__END__

=head1 SEE ALSO

L<File::Path>, L<DBI>, L<English>, L<perfSONAR_PS::OWP>,
L<perfSONAR_PS::OWP::Utils>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: Archive.pm 1877 2008-03-27 16:33:01Z aaron $

=head1 AUTHOR

Jeff Boote, boote@internet2.edu
Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2002-2008, Internet2

All rights reserved.

=cut
