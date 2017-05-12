package Text::Todo::Entry;

# $AFresh1: Entry.pm,v 1.29 2010/02/14 06:08:07 andrew Exp $

use warnings;
use strict;
use Carp;

use Class::Std::Utils;

use version; our $VERSION = qv('0.2.1');

{

    my @attr_refs = \(
        my %text_of,

        my %tags_of,
        my %priority_of,
        my %completion_status_of,
        my %known_tags_of,
    );

    # XXX Should the completion (x) be case sensitive?
    my $priority_completion_regex = qr{
        ^ \s*
        (?i:(x \s* [\d-]* ) \s*)?
        (?i:\( ([A-Z]) \)   \s*)?
    }xms;

    sub new {
        my ( $class, $options ) = @_;

        my $self = bless anon_scalar(), $class;
        my $ident = ident($self);

        $text_of{$ident} = q{};

        if ( !ref $options ) {
            $options = { text => $options };
        }
        elsif ( ref $options ne 'HASH' ) {
            croak 'Invalid parameter passed!';
        }

        my %tags = (
            context => q{@},
            project => q{+},
        );

        if ( exists $options->{tags} && ref $options->{tags} eq 'HASH' ) {
            %tags = ( %tags, %{ $options->{tags} } );
        }

        for my $tag ( keys %tags ) {
            $self->learn_tag( $tag, $tags{$tag} );
        }

        $self->replace( $options->{text} );

        return $self;
    }

    sub _parse_entry {
        my ($self) = @_;
        my $ident = ident($self);

        delete $tags_of{$ident};
        delete $completion_status_of{$ident};
        delete $priority_of{$ident};

        my $text       = $self->text       || q{};
        my $known_tags = $self->known_tags || {};

        foreach my $tag ( keys %{$known_tags} ) {
            next if !defined $known_tags->{$tag};
            next if !length $known_tags->{$tag};

            my $sigal = quotemeta $known_tags->{$tag};
            $tags_of{$ident}{$tag}
                = { map { $_ => q{} } $text =~ / (?:^|\s) $sigal (\S*)/gxms };
        }

        my ( $completed, $priority )
            = $text =~ / $priority_completion_regex /xms;

        $completion_status_of{$ident} = _clean_completed($completed);
        $priority_of{$ident}          = $priority;

        return 1;
    }

    sub _clean_completed {
        my ($completed) = @_;

        $completed ||= q{};
        $completed =~ s/^\s+|\s+$//gxms;

        if ( !$completed ) {
            return;
        }

        if ( $completed =~ s/(x)\s*//ixms ) {
            my $status = $1;
            if ($completed) {
                return $completed;
            }
            else {
                return $status;
            }
        }

        return;
    }

    sub replace {
        my ( $self, $text ) = @_;
        my $ident = ident($self);

        $text = defined $text ? $text : q{};

        $text_of{$ident} = $text;

        return $self->_parse_entry;
    }

    sub learn_tag {
        my ( $self, $tag, $sigal ) = @_;
        $known_tags_of{ ident $self}{$tag} = $sigal;

        ## no critic strict
        no strict 'refs';    # Violates use strict, but allows code generation
        ## use critic

        if ( !$self->can( $tag . 's' ) ) {
            *{ $tag . 's' } = sub {
                my ($self) = @_;
                return $self->_tags($tag);
            };
        }

        if ( !$self->can( 'in_' . $tag ) ) {
            *{ 'in_' . $tag } = sub {
                my ( $self, $item ) = @_;
                return $self->_is_in( $tag . 's', $item );
            };
        }

        return $self->_parse_entry;
    }

    sub _tags {
        my ( $self, $tag ) = @_;
        my $ident = ident($self);

        my @tags;
        if ( defined $tags_of{$ident}{$tag} ) {
            @tags = sort keys %{ $tags_of{$ident}{$tag} };
        }
        return wantarray ? @tags : \@tags;
    }

    sub _is_in {
        my ( $self, $tags, $item ) = @_;
        return if !defined $item;
        foreach ( $self->$tags ) {
            return 1 if $_ eq $item;
        }
        return 0;
    }

    sub pri {
        my ( $self, $new_pri ) = @_;
        my $ident = ident($self);

        if ( $new_pri !~ /^[a-zA-Z]?$/xms ) {
            croak "Invalid priority [$new_pri]";
        }

        $priority_of{$ident} = $new_pri;

        return $self->prepend();
    }

    sub prepend {
        my ( $self, $addition ) = @_;

        my $new = $self->text;
        my @new;

        $new =~ s/$priority_completion_regex//xms;

        if ( $self->done ) {
            if ( $self->done !~ /^x/ixms ) {
                push @new, 'x';
            }
            push @new, $self->done;
        }

        if ( $self->priority ) {
            push @new, '(' . $self->priority . ')';
        }

        if ( defined $addition && length $addition ) {
            push @new, $addition;
        }

        return $self->replace( join q{ }, @new, $new );
    }

    sub append {
        my ( $self, $addition ) = @_;
        return $self->replace( join q{ }, $self->text, $addition );
    }

    ## no critic 'homonym'
    sub do {    # This is what it is called in todo.sh
        ## use critic
        my ($self) = @_;
        my $ident = ident($self);

        if ( $self->done ) {
            return 1;
        }

        $completion_status_of{$ident} = sprintf "%04d-%02d-%02d",
            ( (localtime)[5] + 1900 ),
            ( (localtime)[4] + 1 ),
            ( (localtime)[3] );

        return $self->prepend();
    }

    sub done {
        my ($self) = @_;
        return $completion_status_of{ ident($self) };
    }
    sub known_tags { my ($self) = @_; return $known_tags_of{ ident($self) }; }
    sub priority   { my ($self) = @_; return $priority_of{ ident($self) }; }
    sub text       { my ($self) = @_; return $text_of{ ident($self) }; }
    sub depri      { my ($self) = @_; return $self->pri(q{}) }

    sub DESTROY {
        my ($self) = @_;
        my $ident = ident $self;
        foreach my $attr_ref (@attr_refs) {
            delete $attr_ref->{$ident};
        }
    }
}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Text::Todo::Entry - An object for manipulating an entry on a Text::Todo list


=head1 VERSION

Since the $VERSION can't be automatically included, 
here is the RCS Id instead, you'll have to look up $VERSION.

    $Id: Entry.pm,v 1.30 2010/02/16 01:13:12 andrew Exp $


=head1 SYNOPSIS

    use Text::Todo::Entry;

    my $entry = Text::Todo::Entry->new('text of entry');

    $entry->append('+project');

    if ($entry->in_project('project') && ! $entry->priority) {
        print $entry->text, "\n";
    }


=head1 DESCRIPTION

This module creates entries in a Text::Todo list.
It allows you to retrieve information about them and modify them.

For more information see L<http://todotxt.com>


=head1 INTERFACE 

=head2 new

Creates an entry that can be manipulated.

    my $entry = Text::Todo::Entry->new([
    'text of entry' | { 
        [ text => 'text of entry' ,]  
        [ tags => { additional_arg => 'identfier' }, ]
    } ]);

If you don't pass any text, creates a blank entry. 

See tags below for a description of additional tags.

=head2 text

Returns the text of the entry.  

    print $entry->text, "\n";

=head2 pri

Sets the priority of an entry. If the priority is set to an empty string,
clears the priority.

    $entry->pri('B');

Acceptible entries are an empty string, A-Z or a-z. Anything else will cause
an error.

=head2 depri

A convenience function that unsets priority by calling pri('').

    $entry->depri;

=head2 priority

Returns the priority of an entry which may be an empty string if it is 

    my $priority = $entry->priority;

=head2 tags

Each tag type generates two accessor functions {tag}s and in_{tag}.

Default tags are context (@) and project (+).

When creating a new object you can pass in new tags to recognize.

    my $entry = Text::Todo::Entry->new({ 
        text => 'do something DUE:2011-01-01',
        tags => { due_date => 'DUE:' } 
    });

    my @due_dates = $entry->due_dates;

then @due_dates is ( '2011-01-01' );

and you could also:

    if ($entry->in_due_date('2011-01-01')) {
        # do something
    }


=over

=item {tag}s

    @tags = $entry->{tag}s;

=item in_{tag}

returns true if $entry is in the tag, false if not.

    if ($entry->in_{tag}('tag')) {
        # do something
    }

=back

=head2 learn_tag($tag, $sigal)

    $entry->learn_tag('due_date', 'DUE:');

Teaches the entry about an additional tag, same as passing a tags argument to
new(). See tags()

You can simulate forgetting a tag by setting the sigal to undef or an empty
string.

=head2 known_tags

    $known_tags = $entry->known_tags;

$known_tags by default would be: 

    { context => '@',
      project => '+',
    }


=head3 context

These are matched as a word beginning with @.

=over

=item contexts

=item in_context

=back

=head3 project

This is matched as a word beginning with +.

=over

=item projects

=item in_project

=back

=head2 replace

Replaces the text of an entry with completely new text.  Useful if there has
been manual modification of the entry or just a new direction.

    $entry->replace('replacment text');

=head2 prepend

Attaches text (with a trailing space) to the beginning of an entry.  Puts it
after the done() "x" and the priority() letter.

    $entry->prepend('NEED HELP');

=head2 append

Adds text to the end of an entry.  
Useful for adding tags, or just additional information.

    $entry->append('@specific_store');

=head2 do

Marks an entry as completed.

    $entry->do;

Does this by prepending "x `date '%Y-%m-%d'`" to the beginning of the entry.

=head2 done

Returns true if an entry is marked complete and false if not.
    
    if (!my $status = $entry->done) {
        # remind me to do it
    }

If the entry starts as 'x date', for example 'x 2010-01-01', $status is now
'2010-01-01'.  
If the entry just starts with 'x', then $status will be 'x'.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Text::Todo::Entry requires no configuration files or environment variables.


=head1 DEPENDENCIES 

Class::Std::Utils
List::Util
version


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Known limitations:

Sometimes leading whitespace may get screwed up when making changes.  It
doesn't seem to be particularly a problem, but if you use whitespace to indent
entries for some reason it could be.

Please report any bugs or feature requests to
C<bug-text-todo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Andrew Fresh  C<< <andrew@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Andrew Fresh C<< <andrew@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
