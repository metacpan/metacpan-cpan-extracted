package Text::Diff::Parser;
# $Id: Parser.pm 530 2009-09-09 10:26:49Z fil $

use 5.00404;
use strict;
use warnings;
use vars qw( $VERSION );

use Carp;
use IO::File;

$VERSION = '0.1001';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

####################################################
sub new
{
    my( $package, @args ) = @_;

    my $self = bless { changes=>[], 
                       source=>'' }, $package;

    my $parms;
    if( 1==@args ) {
        if( 'HASH' eq ref $args[0] ) {
            $parms = $args[0];
        }
        else {
            my $diff = $args[0];
            if( ref $diff or $diff !~ /\n/ ) {
                $parms = { File => $diff };
            }
            else {
                $parms = { Diff => $diff };
            }
        }
    }
    else {
        $parms = { @args };
    }

    $self->__init( $parms );
    return $self;
}

sub __init 
{
    my( $self, $parms ) = @_;

    $self->{verbose}  = 1 if $parms->{Verbose};
    $self->{simplify} = $parms->{Simplify};
    $self->{strip}    = $parms->{Strip};
    $self->{trustatat} = 1;
    $self->{trustatat} = $parms->{TrustAtAt} if exists $parms->{TrustAtAt};

    if( $parms->{ File } ) {
        $self->parse_file( $parms->{File} );
    }
    elsif( $parms->{ Diff } ) {
        $self->parse( $parms->{Diff} );
    }
    return $self;
}

####################################################
sub source
{
    my( $self ) = @_;
    return $self->{source};
}

####################################################
sub changes
{
    my( $self, $file ) = @_;
    my $ret = $self->{changes};
    if( $file ) {
        $ret = [];
        foreach my $ch ( @{ $self->{changes} } ) {
            next unless $ch->filename1 eq $file or
                        $ch->filename2 eq $file;
            push @$ret, $ch;
        }
    }

    return @$ret if wantarray;
    return 0+@$ret;
}


####################################################
sub files
{
    my( $self ) = @_;
    my %ret;
    foreach my $ch ( $self->changes ) {
        $ret{$ch->filename1} = $ch->filename2;
    }
    return %ret;
}


####################################################
sub simplify
{
    my( $self ) = @_;

    my @keep;
    my $prev;
    foreach my $ch ( $self->changes ) {
        if( $ch->type eq '' ) {                 # skip no-change
            undef( $prev );
            next;
        }
    
        if( $prev ) {
            my $size = $prev->size;
            ## Combine ADD/REMOVE lines
            if( $prev->type ne $ch->type and # ADD->REMOVE or REMOVE->ADD
                $prev->filename1 eq $ch->filename1 and
                $prev->filename2 eq $ch->filename2 and
                           $size == $ch->size ) {  #close

                if( $prev->type eq 'REMOVE' and
                        $prev->line2 == $ch->line2 and
                        ($prev->line1+$size) == $ch->line1 ) {
                    $prev->{type} = 'MODIFY';
                    $prev->{lines} = $ch->{lines};
                    undef( $prev );
                    next;
                }
                elsif( $prev->type eq 'ADD' and
                        ($prev->line2+$size) == $ch->line2 and
                        $prev->line1 == $ch->line1 ) {
                    $prev->{type} = 'MODIFY';
                    undef( $prev );
                    next;
                }
                # same size, same file, but not at the same spot
            }
        }
        push @keep, $ch;
        $prev = $ch;
    }
    $self->{changes} = \@keep;
}


####################################################
sub parse_file
{
    my( $self, $file ) = @_;

    local $self->{count1};
    local $self->{count2};

    my $fh;
    if( ref $file ) {               # assume it's a file handle
        $self->{source} = 'user filehandle';
        $fh = $file;
    }
    else {
        $self->{source} = $file;
        $fh = IO::File->new;
        $fh->open( $file ) or croak "Unable to open $file: $!";
    }

    $self->{changes}=[];
    $self->{state}={ OK=>1 };

    while( <$fh> ) {
        $self->{state}{context} = "line $. of $self->{source}";
        $self->_parse_line( $_ );
    }
    my $ok = $self->{state}{OK};
    delete $self->{state};
    $self->simplify if $self->{simplify};
    return $ok;
}


####################################################
sub parse
{
    my( $self, $text ) = @_;
    $self->{source} = "user string";
    $self->{changes}=[];
    $self->{state}={ OK=>1 };
    local $self->{count1};
    local $self->{count2};

    my $l=1;
    while( $text =~ /(.+?\n)/g ) {
        $self->{state}{context} = "line $l of string";
        $self->_parse_line( $1 );
        $l++;
    }
    my $ok = $self->{state}{OK};
    delete $self->{state};
    $self->simplify if $self->{simplify};
    return $ok;

}

####################################################
sub _parse_line
{
    my( $self, $line ) = @_;
    $self->{verbose} and warn "Parsing $line";

    my $state = $self->{state};

    if( $state->{unified} ) {
        $self->_unified_line( $line );        
        return if $state->{unified};
    }
    elsif( $state->{standard} ) {
        $self->_standard_line( $line );        
        return if $state->{standard};
    }

    my $file = '(?:-r\d(?:\.\d+)+)|(?:[^-].+)';

    if( $line =~ /^diff\s+($file)\s+($file)\s*$/ ) {
        my @match = ( $1, $2 );
        $self->{verbose} and warn "Diff $1 $2";
        $state->{filename1} = $self->_filename( $match[0] );
        $state->{filename2} = $self->_filename( $match[1] );
    } 
    elsif( $line =~ /^(\d+)(?:,\d+)?[acd](\d+)(?:,\d+)?$/  ) {
        $state->{standard} = 1;
        push @{ $self->{changes} }, bless {
                            at1 => $1, line1 => $1,
                            at2 => $2, line2 => $2,
                            filename1 => $state->{filename1},
                            filename2 => $state->{filename2},
                            timestamp1 => '',
                            timestamp2 => ''
                        }, 'Text::Diff::Parser::Change';        
        $self->{verbose} and warn "Standard diff line1=$1 line2=$2";
    }
    elsif( $line =~ /^--- (.+?)\t(.+)$/ or 
            $line =~ /^--- ([^\s]+)\s+(.+)$/ or
            $line =~ /^--- ([^\s]+)$/ ) {           # kernel.org style
        $self->{count1} = 0;
        $self->{count2} = 0;
        $state->{unified} = 1;
        my $stamp = $2;
        my $name = $self->_filename( $1 );
        $self->{verbose} and warn "Unified diff";
        push @{ $self->{changes} }, bless {
                            filename1   => $name,
                            timestamp1  => $stamp,
                        }, 'Text::Diff::Parser::Change';
    }
    elsif( $line =~ /^\*\*\* (.+?)\t(.+)$/ or 
            $line =~ /^\*\*\* ([^\s]+)\s+(.+)$/) {
        die "Context diff not yet supported at $state->{context}";
    }
}

####################################################
sub _filename
{
    my( $self, $file ) = @_;
    return $file unless $self->{strip};
    my $n = $self->{strip};
    $file =~ s(^[^/]+/)() while $n--;
    return $file;
}

####################################################
sub _standard_line
{
    my( $self, $line ) = @_;

    my %types = ( ' '=>'', '>'=>'ADD', '<'=>'REMOVE' );

    my $change = $self->{changes}[-1];
 
    if( $line =~ /^([<>])(.+)$/ ) {
        my( $mod, $text ) = ( $1, $2 );
        $mod = $types{$mod};
        $self->_new_line( $mod, $text );
        return;
    }
    if( $line =~ /^---$/ ) {            # pivot
        $self->{verbose} and warn "Pivot";
        return;
    }
    delete $self->{state}{standard};    # let _parse_file deal with it
}

####################################################
sub _unified_line
{
    my( $self, $line ) = @_;
 
    my %types = ( ' '=>'', '+'=>'ADD', '-'=>'REMOVE' );

    my $change = $self->{changes}[-1];
    if( $line =~ /^\+\+\+ (.+?)\t(.+)$/ or 
            $line =~ /^\+\+\+ ([^\s]+)\s+(.+)$/ or
            $line =~ /^\+\+\+ ([^\s]+)$/ ) {           # kernel.org style
        $change->{timestamp2} = ($2||'');
        $change->{filename2} = $self->_filename( $1 );
        $change->{lines} = [];
        return;
    }
    die "Missing +++ line before $line" unless $change->{filename2};
    if( $line =~ /^\@\@ -(\d+)(?:,(\d+))? [+](\d+)(?:,(\d+))? \@\@\s*(.+)?$/ ) {
        my @match = ($1, ($2||0), $3, ($4||0), ($5||''));
        if( @{ $change->{lines} } ) {
            $change = $self->_new_chunk;
        }
        @{ $change }{ qw( line1 size1 line2 size2 function ) } = @match;
        $change->{at1} = $change->{line1};
        $change->{at2} = $change->{line2};
        $self->{count1} = 0;
        $self->{count2} = 0;
        return;
    }
    die "Missing \@\@ line before $line at $self->{state}{context}\n" 
                        unless defined $change->{line1};

#    use Data::Dumper;
#    die "No size1 in ", Dumper $change unless defined $change->{size1};
#    die "No size2 in ", Dumper $change unless defined $change->{size2};
#    warn "$change->{size1} > $self->{count1} $change->{size2} > $self->{count2}";

    my $done = 1;
    if( $self->{trustatat} and ( $change->{size1} > $self->{count1} or
                                 $change->{size2} > $self->{count2} ) ) {
        $done = 0;
    }

    if( $done and $line =~ /^---/ ) {
        $self->{state}{unified} = 0;
        return;
    }

    if( $line =~ /^([-+ ])(.*)?$/) {
        my( $mod, $text ) = ( $1, $2 );
        $mod = $types{$mod};
        $self->_new_line( $mod, $text );
        return;
    }
    # Anything else is the end of the diff, so fall through to the
    # diff detection bit
    $self->{state}{unified} = 0;
}

sub _new_type
{
    my( $self, $mod ) = @_;
    my $change = $self->{changes}[-1];

    push @{ $self->{changes} }, bless { 
                                    filename1 => $change->{filename1},
                                    filename2 => $change->{filename2},
                                    line1 => $change->{at1},
                                    line2 => $change->{at2},
                                    size1 => $change->{size1},
                                    size2 => $change->{size2},
                                    at1 => $change->{at1},
                                    at2 => $change->{at2},
                                    function => $change->{function},
                                    type => $mod,
                                    lines => []
                                }, 'Text::Diff::Parser::Change';
    return $self->{changes}[-1];
}

sub _new_chunk
{
    my( $self ) = @_;
    my $change = $self->{changes}[-1];
    push @{ $self->{changes} }, bless {
                                    type => '',
                                    filename1 => $change->{filename1},
                                    filename2 => $change->{filename2},
                                    lines => []
                                }, 'Text::Diff::Parser::Change';
    return $self->{changes}[-1];
}

sub _new_line
{
    my( $self, $mod, $text ) = @_;

    $self->{count1}++ if $mod ne 'ADD';
    $self->{count2}++ if $mod ne 'REMOVE';

    $self->{verbose} and warn "_new_line";
    my $change = $self->{changes}[-1];
    if( defined $change->{type} ) {
        if( $change->{type} ne $mod ) {
            $self->{verbose} and warn "_new_type";
            $change = $self->_new_type( $mod );
        }
    }
    else {
        $change->{type} = $mod;
    }

    $change->{at1}++ unless $mod eq 'ADD';    # - or ' ', advance in file1
    $change->{at2}++ unless $mod eq 'REMOVE'; # + or ' ', advance in file2
    push @{ $change->{lines} }, $text;
}

######################################################################
package Text::Diff::Parser::Change;

use strict;

sub filename1 { $_[0]->{filename1} }
sub filename2 { $_[0]->{filename2} }
sub line1 { $_[0]->{line1} }
sub line2 { $_[0]->{line2} }
sub function { $_[0]->{function} }
sub size  { 0+@{$_[0]->{lines}} }

sub type  
{ 
    my( $self ) = @_;

    return $self->{type} if $self->{type} eq 'ADD' or
                            $self->{type} eq 'REMOVE' or
                            $self->{type} eq 'MODIFY';
    return '';
}
    
sub text
{
    my( $self, $n ) = @_;
    return @{ $self->{lines} } if 1==@_;

    return $self->{lines}[$n];
}
    


1;
__END__

=head1 NAME

Text::Diff::Parser - Parse patch files containing unified and standard diffs

=head1 SYNOPSIS

    use Text::Diff::Parser;

    # create the object
    my $parser = Text::Diff::Parser->new();

    # With options
    $parser = Text::Diff::Parser->new( Simplify=>1, # simplify the diff
                                       Strip=>2 );  # strip 2 directories

    # Create object.  Parse $file
    $parser = Text::Diff::Parser->new( $file );
    $parser = Text::Diff::Parser->new( File=>$file );

    # Create object.  Parse text
    my $parser = Text::Diff::Parser->new( $text );
    $parser = Text::Diff::Parser->new( Diff=>$text );

    # parse a file
    $parser->parse_file( $filename );

    # parse a string
    $parser->parse( $text );
    
    # Remove no-change lines.  Combine line substitutions
    $parser->simplify;

    # Find results
    foreach my $change ( $parser->changes ) {
        print "File1: ", $change->filename1;
        print "Line1: ", $change->line1;
        print "File2: ", $change->filename2;
        print "Line2: ", $change->line2;
        print "Type: ", $change->type;
        my $size = $change->size;
        foreach my $line ( 0..($size-1) ) {
            print "Line: ", $change->text( $line );
        }
    }

    # In scalar context, returns the number of changes
    my $n = $parser->changes;
    print "There are $n changes", 

    # Get the changes to a given file
    my @changes = $parser->changes( 'Makefile.PL' );

    # Get list of files changed by the diff
    my @files = $parser->files;


=head1 DESCRIPTION

C<Text::Diff::Parser> parses diff files and patches.  It allows you to
access the changes to a file in a standardized way, even if multiple patch
formats are used.

A diff may be viewed a series of operations on a file, either adding,
removing or modifying lines of one file (the C<from-file>) to produce
another file (the C<to-file>).  Diffs are generaly produced either by hand
with diff, or by your version control system (C<cvs diff>, C<svn diff>,
...).  Some diff formats, notably unified diffs, also contain null
operations, that is lines that

C<Text::Diff::Parser> currently parses unified diff format and standard diff
format.

Unified diffs look like the following.

    --- Filename1 2006-04-12 18:47:22.000000000 -0400
    +++ Filename2 2006-04-12 19:21:16.000000000 -0400
    @@ -1,4 +1,6 @@
     ONE
     TWO
    -THREE
    +honk
     FOUR
    +honk
    +honk

Standard diffs look like the following.

    diff something something.4
    3c3
    < THREE
    ---
    > honk
    4a5,6
    > honk
    > honk

The diff line isn't in fact part of the format but is necessary to find
which files the chunks deal with.  It is output by C<cvs diff> and C<svn
diff> so that isn't a problem.

=head1 METHODS

=head2 new

    $parser = Text::Diff::Parser->new;
    $parser = Text::Diff::Parser->new( $file );
    $parser = Text::Diff::Parser->new( $handle );
    $parser = Text::Diff::Parser->new( %params );
    $parser = Text::Diff::Parser->new( \%params );

Object constructor.  



=over 4

=item Diff

String that contains a diff.  This diff will be parse before C<new> returns.

=item File

File name or file handle that is parsed before C<new> returns.

=item Simplify

Simplifying a patch involves dropping all null-operations and converting and
remove operation followed by an add operation (or an add followed by a
remove) of the same size on the same lines into a modify operation.

=item Strip

Strip N leading directories from all filenames.  Less then useful for
standard diffs produced by C<cvs diff>, because they don't contain directory
information.

=item TrustAtAt

In a unified diff, various chunks are introduced with @@.  By default, we
trust these to reference the right line count.  If you set this to 0, the
lines will not be trust and a chunk must end with another @@ line or ---
(which introduces a new file).  Note that not trusting @@ means you can not
parse a diff that removes a line that begins with --, because that also
start with '---'.

=item Verbose

If true, print copious details of what is going on.

=back





=head2 parse_file

    $parser->parse_file( $file );
    $parser->parse_file( $handle );

Read and parse the file or file handle specified.  Will C<die> if it fails, 
returns true on sucess.  Contents of the file may then be accessed with
C<changes> and C<files>.

=head2 parse

    $parser->parse( $string );

Parses the diff present in $string.  Will C<die> if it fails, returns true
on sucess.  Contents of the file may then be accessed with C<changes> and
C<files>.

=head2 files

    %files = $parser->files;

Fetch a list of all the files that were referenced in the patch.  The keys
are original files (C<from-file>) and the values are the modified files
(C<to-file>).

=head2 changes

    @changes = $parser->changes;
    $n = $parser->changes;
    @changes = $parser->changes( $file );
    $n = $parser->changes( $file );

Return all the operations (array context) or the number of operations in the
patch file.  If C<$file> is specified, only returns changes to that file
(C<from-file> or C<to-file>).

Elements of the returned array are change objects, as described in 
C<CHANGE METHODS> below.

=head2 simplify

    $parser->simplify;

Simplifies the diff.  Removes no-change lines.  Combine line substitutions.
Automatically called if you supply Simplify to ->new().

=head2 source

    my $file = $parser->source

Returns the filename of the last file that was parsed.  Returns "user
filehandle" if you supplied a file handle.


=head1 CHANGE METHODS

The C<changes> method returns an array of objects that describe each
operation.  You may use the following methods to find out details of the
operation.

=head2 type

Returns the type of operation, either C<'ADD'>, C<'REMOVE'>, C<'MODIFY'> or
C<''> (null operation).

=head2 filename1

Filename of the C<from-file>.

=head2 filename2

Filename of the C<to-file>.

=head2 line1

Line in the C<from-file> the operation starts at.

=head2 line2

Line in the C<to-file> the operation starts at.

=head2 size

Number of lines affected by this operation.

=head2 text

    $line  = $ch->text( $N );
    @lines = $ch->text;

Fetch the text of the line C<$N> if present or all lines affected by this
operation.  For C<''> (null) and C<'REMOVE'> operations, these are the lines
present before the operation was done (C<'from-file'>.  For C<'ADD'> and
C<'MODIFY'> operations, these are the lines present after the operation was
done (C<'to-file'>.


=head1 BUGS

I'm not 100% sure of standard diff handling.

Missing support for context diffs.

=head1 SEE ALSO

L<Text::Diff>, L<Arch>, L<diff>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut


