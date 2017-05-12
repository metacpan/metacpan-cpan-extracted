package App::HWD::Work;

=head1 NAME

App::HWD::Work - Work completed on HWD projects

=head1 SYNOPSIS

Used only by the F<hwd> application.

Note that these functions are pretty fragile, and do almost no data
checking.

=cut

use warnings;
use strict;
use DateTime::Format::Strptime;

=head1 FUNCTIONS

=head2 App::HWD::Work->parse()

Returns an App::HWD::Work object from an input line

=cut

sub parse {
    my $class = shift;
    my $line = shift;

    my @cols = split " ", $line, 5;
    die "Invalid work line: $line" unless @cols >= 4;

    my ($who, $when, $task, $hours, $comment) = @cols;
    my $parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' );
    $when = $parser->parse_datetime( $when );
    my $completed;
    if ( defined $comment ) {
        if ( $comment =~ s/\s*X\s*//i ) {
            $completed = 1;
        }
        $comment =~ s/^#\s*//;
        $comment =~ s/\s+$//;
    }
    else {
        $comment = '';
    }
    if ( $hours =~ s/h$// ) {
        # nothing
    }
    elsif ( $hours =~ /^(\d+)m$/ ) {
        $hours = $1/60;
    }
    elsif ( $hours != $hours+0 ) {
        die "Invalid hours: $hours\n";
    }

    die "Invalid task: $task\n" unless ($task =~ /^\d+$/ || $task eq "^");

    my $self =
        $class->new( {
            who => $who,
            when => $when,
            task => $task,
            hours => $hours,
            comment => $comment,
            completed => $completed,
        } );

    return $self;
}

=head2 App::HWD::Work->new( { args } )

Creates a new task from the args passed in.  They should include at
least I<level>, I<name> and I<id>, even if I<id> is C<undef>.

=cut

sub new {
    my $class = shift;
    my $args = shift;

    my $self = bless { %$args }, $class;
}


=head2 $work->set( $key => $value )

Sets the I<$key> field to I<$value>.

=cut

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    die "Dupe key $key" if exists $self->{$key};
    $self->{$key} = $value;
}

=head2 $work->who()

Returns who did the work

=head2 $work->when()

Returns the when of the work as a string.

=head2 $work->when_obj()

Returns the when of the work as a DateTime object.

=head2 $work->task()

Returns the ID of the work that was worked on.

=head2 $work->hours()

Returns the hours spent.

=head2 $work->completed()

Returns a boolean that says whether the work was completed or not.

=head2 $work->comment()

Returns the comment from the file, if any.

=cut

sub who         { return shift->{who} }
sub task        { return shift->{task} }
sub hours       { return shift->{hours} }
sub completed   { return shift->{completed} || 0 }
sub comment     { return shift->{comment} }
sub when_obj    { return shift->{when} }
sub when {
    my $self = shift;

    my $obj = $self->{when} or return '';

    return $obj->strftime( "%F" );
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::HWD::Task
