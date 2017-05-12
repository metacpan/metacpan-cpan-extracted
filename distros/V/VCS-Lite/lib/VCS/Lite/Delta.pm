package VCS::Lite::Delta;

use strict;
use warnings;
our $VERSION = '0.12';

#----------------------------------------------------------------------------

=head1 NAME

VCS::Lite::Delta - VCS::Lite differences

=head1 SYNOPSIS

  use VCS::Lite;

  # diff

  my $lit = VCS::Lite->new('/home/me/foo1.txt');
  my $lit2 = VCS::Lite->new('/home/me/foo2.txt');
  my $difftxt = $lit->delta($lit2)->diff;
  print OUTFILE $difftxt;

  # patch

  my $delt = VCS::Lite::Delta->new('/home/me/patch.diff');
  my $lit3 = $lit->patch($delt);
  print OUTFILE $lit3->text;

=head1 DESCRIPTION

This module provides a Delta class for the differencing functionality of
VCS::Lite

=cut

#----------------------------------------------------------------------------

#############################################################################
#Library Modules															#
#############################################################################

use Carp;

#----------------------------------------------------------------------------

# Error handling, use package vars to control it for now.
use vars qw($error_action $error_msg $error_line);

#----------------------------------------------------------------------------

#############################################################################
#Interface Methods   														#
#############################################################################

sub new {
    my $class = shift;
    my $src   = shift;

    # DWIM logic, based on $src parameter.

    # Case 0: string. Use $id as file name, becomes case 2
    if ( !ref $src ) {
        open my $fh, $src or croak("failed to open '$src': $!");
        $src = $fh;    # becomes case 2 below
    }
    my $atyp = ref $src;

    # Case 1: $src is arrayref
    return bless {
        id1  => $_[0],
        id2  => $_[1],
        sep  => $_[2],
        diff => [@$src]
      },
      $class
      if $atyp eq 'ARRAY';

    my $sep = shift;
    my %proto;

    # Decode $sep as needed

	if (ref($sep) eq 'HASH') {
	    %proto = %$sep;
	    $sep = $proto{in};
        delete $proto{in};
	}

    $sep ||= $/;
    local $/ = $sep if $sep;
    $sep ||= '';
    my @diff;

    # Case 2: $src is globref (file handle) - slurp file
    if ( $atyp eq 'GLOB' ) {
        @diff = <$src>;
    }

    # Case 3: $src is scalar ref (string)
    elsif ( $atyp eq 'SCALAR' ) {
        @diff = split /(?=$sep)/, $$src;
    }

    # Case otherwise is an error.
    else {
        croak "Invalid argument to VCS::Lite::Delta::new";
    }

    # If we have reached this point, we have been passed something in a
    # text/diff format. It could be diff or udiff format.

    my ( $id1, $id2 ) = @_;
    my @out;

    if ( $diff[0] =~ /^---/ ) {    # udiff format
        my $state = 'inputdef';
        my ( $a_line, $a_count, @a_hunk, $b_line, $b_count, @b_hunk );
        for my $lin ( 0 .. $#diff ) {
            local $_ = $diff[$lin];
            chomp if $proto{chomp};
            # inputdef = --- and +++ to identify the files being diffed

            if ( $state eq 'inputdef' ) {
                $id1 = $1 if /^---	# ---
						\s
						(\S+)/x;                     # file => $1
                $id2 = $1 if /^\+{3}	# +++
						\s
						(\S+)/x;                     # file => $1
                $state = 'patch' if /^\@\@/;
            }

            # patch expects @@ -a,b +c,d @@

            if ( $state eq 'patch' ) {
                next unless /^\@\@
						\s+
						-
						(\d+)	# line of file 1 => $1
						,
						(\d+)	# count of file 1 => $2
						\s*
						\+
						(\d+)	# line of file 2 => $3
						,
						(\d+)	# count of file 2 => $4
						\s*
						\@\@/x;
                $a_line  = $1 - 1;
                $a_count = $2;
                $b_line  = $3 - 1;
                $b_count = $4;
                $state   = 'detail';
                next;
            }

            # detail expects [-+ ]line of text

            if ( $state eq 'detail' ) {
                my $ind = substr $_, 0, 1, '';
                _error( $lin, 'Bad diff' ), return undef
                  unless $ind =~ /[ +\-i\\]/;

                next if $ind eq '\\';

                #[- ]line, add to @a_hunk
                if ( $ind ne '+' ) {
                    my $lead = '-';
                    if (($lin < $#diff) && $diff[$lin+1] =~ /^\\/) {
                        $lead .= '/';
                        s/$sep$//s;
                    }
                    push @a_hunk, [ $lead, $a_line++, $_ ];
                    $a_count--;
                    _error( $lin, 'Too large diff' ), return undef
                      if $a_count < 0;
                }

                #[+ ]line, add to @b_hunk
                if ( $ind ne '-' ) {
                    my $lead = '+';
                    if (($lin < $#diff) && $diff[$lin+1] =~ /^\\/) {
                        $lead .= '/';
                        s/$sep$//s;
                    }
                    push @b_hunk, [ $lead, $b_line++, $_ ];
                    $b_count--;
                    _error( $lin, 'Too large diff' ), return undef
                      if $b_count < 0;
                }

                # are we there yet, daddy?
                if ( !$a_count and !$b_count ) {
                    push @out, [ @a_hunk, @b_hunk ];
                    @a_hunk = @b_hunk = ();
                    $state = 'patch';
                }
            }
        }    # next line of patch
        return bless {
            id1  => $id1,
            id2  => $id2,
            sep  => $sep,
            diff => \@out,
            %proto
        }, $class;
    }

    # not a udiff mode patch, assume straight diff mode

    my $state = 'patch';
    my ( $a_line, $a_count, @a_hunk, $b_line, $b_count, @b_hunk );
    for my $lin ( 0 .. $#diff ) {
        local $_ = $diff[$lin];
        chomp if $proto{chomp};

        # patch expects ww,xx[acd]yy,zz style

        if ( $state eq 'patch' ) {
            next unless /^(\d+)	# start line of file 1 => $1
				(?:,(\d+))?	# end line of file 1 => $2
				([acd])		# Add, change, delete => $3
				(\d+)		# start line of file 2 => $4
				(?:,(\d+))?	# end line of file 2 => $5
				/x;
            $a_line  = $1 - 1;
            $a_count = $2 ? ( $2 - $a_line ) : 1;
            $b_line  = $4 - 1;
            $b_count = $5 ? ( $5 - $b_line ) : 1;
            $a_count = 0 if $3 eq 'a';
            $b_count = 0 if $3 eq 'd';
            $state   = 'detail';
            next;
        }

        # detail expects < lines --- > lines

        if ( $state eq 'detail' ) {
            next if /^---/;    # ignore separator
            my $ind = substr $_, 0, 2, '';
            _error( $lin, 'Bad diff' ), return undef
              unless $ind =~ /[<>\\] /;

            # < line goes to @a_hunk
            if ( $ind eq '< ' ) {
                my $lead = '-';
                if (($lin < $#diff) && $diff[$lin+1] =~ /^\\/) {
                    $lead .= '/';
                    s/$sep$//s;
                }
                push @a_hunk, [ $lead, $a_line++, $_ ];
                $a_count--;
                _error( $lin, 'Too large diff' ), return undef
                  if $a_count < 0;
            }

            # > line goes to @b_hunk
            if ( $ind eq '> ' ) {
                my $lead = '+';
                if (($lin < $#diff) && $diff[$lin+1] =~ /^\\/) {
                    $lead .= '/';
                    s/$sep$//s;
                }
                push @b_hunk, [ $lead, $b_line++, $_ ];
                $b_count--;
                _error( $lin, 'Too large diff' ), return undef
                  if $b_count < 0;
            }

            # are we there yet, daddy?
            if ( !$a_count and !$b_count ) {
                push @out, [ @a_hunk, @b_hunk ];
                @a_hunk = @b_hunk = ();
                $state = 'patch';
            }
        }
    }
    return bless {
        id1  => $id1,
        id2  => $id2,
        sep  => $sep,
        diff => \@out,
        %proto
    }, $class;
}

sub _error {
    ( $error_line, my $msg ) = @_;

    $error_msg = "Line $error_line: $msg";

    goto &$error_action if ref($error_action) eq 'CODE';
    confess $error_msg  if $error_action      eq 'raise';

    print STDERR $error_msg, "\n" unless $error_action eq 'silent';
}

sub _diff_hunk {

    my $sep           = shift;
    my $r_line_offset = shift;

    my @ins;
    my ( $ins_firstline, $ins_lastline ) = ( 0, 0 );
    my @del;
    my ( $del_firstline, $del_lastline ) = ( 0, 0 );
    my $op;
    my $shortins = '';
    my $shortdel = '';
    
    # construct @ins and @del from hunk

    for (@_) {
        my ( $typ, $lno, $txt ) = @$_;
        my $short = substr($typ, 1, 1, '');
        $lno++;
        if ( $typ eq '+' ) {
            push @ins, $txt;
            $ins_firstline ||= $lno;
            $ins_lastline = $lno;
            $shortins = "\n\\ No newline at end of file\n" if $short;
        }
        else {
            push @del, $txt;
            $del_firstline ||= $lno;
            $del_lastline = $lno;
            $shortdel = "\n\\ No newline at end of file\n" if $short;
        }
    }

    # Work out whether we are a, c or d

    if ( !@del ) {
        $op            = 'a';
        $del_firstline = $ins_firstline - $$r_line_offset - 1;
    }
    elsif ( !@ins ) {
        $op            = 'd';
        $ins_firstline = $del_firstline + $$r_line_offset - 1;
    }
    else {
        $op = 'c';
    }

    $$r_line_offset += @ins - @del;

    $ins_lastline ||= $ins_firstline;
    $del_lastline ||= $del_firstline;

    # Make the header line

    my $outstr =
      "$del_firstline,$del_lastline$op$ins_firstline,$ins_lastline\n";
    $outstr =~ s/(^|\D)(\d+),\2(?=\D|$)/$1$2/g;

    # < deletions
    for (@del) {
        $outstr .= '< ' . $_ . $sep;
    }
    $outstr .= $shortdel;
    
    # ---
    $outstr .= "---\n" if @ins && @del;

    # > insertions
    for (@ins) {
        $outstr .= '> ' . $_ . $sep;
    }
    $outstr .= $shortins;

    $outstr;
}

sub diff {
    my $self = shift;
    my $sep  = shift || $self->{sep} || '';

    my $off = 0;

    join '', map { _diff_hunk( $sep, \$off, @$_ ) } @{ $self->{diff} };
}

sub udiff {
    my $self = shift;
    my $sep  = shift || $self->{sep} || '';

    my ( $in, $out, $diff ) = @{$self}{qw/id1 id2 diff/};

    # Header with file names

    my @out = ( "--- $in \n", "+++ $out \n" );

    my $offset = 0;

    for (@$diff) {
        my @t1 = grep { $_->[0] =~ /^\-/ } @$_;
        my @t2 = grep { $_->[0] =~ /^\+/ } @$_;

        my $short1 = '';
        $short1 = "\n\\ No newline at end of file\n" 
            if grep { $_->[0] eq '-/' } @t1;
        my $short2 = '';
        $short2 = "\n\\ No newline at end of file\n" 
            if grep { $_->[0] eq '+/' } @t2;
            
        # Work out base line numbers in both files

        my $base1 = @t1 ? $t1[0][1] : $t2[0][1] - $offset;
        my $base2 = @t2 ? $t2[0][1] : $t1[0][1] + $offset;
        $base1++;
        $base2++;    # Our lines were 0 based
        $offset += @t2 - @t1;
        my $count1 = @t1;
        my $count2 = @t2;

        # Header line
        push @out, "@@ -$base1,$count1 +$base2,$count2 @@\n";

        # Use Algorithm::Diff::sdiff to munge out any lines in common inside
        # the hunk
        my @txt1 = map { $_->[2] } @t1;
        my @txt2 = map { $_->[2] } @t2;

        my @ad = Algorithm::Diff::sdiff( \@txt1, \@txt2 );
        my @defer;

 # for each subhunk, we want all the file1 lines first, then all the file2 lines

        for (@ad) {
            my ( $ind, $txt1, $txt2 ) = @$_;

     # we want to flush out the + lines when we run off the end of a 'c' section

            ( push @out, @defer ), @defer = () unless $ind eq 'c';

            # unchanged lines, just wack 'em out
            ( push @out, ' ' . $txt1 . $sep ), next if $ind eq 'u';

            # output original line (- line)
            push @out, '-' . $txt1 . $sep unless $ind eq '+';

            # defer changed + lines
            push @defer, '+' . $txt2 . $sep unless $ind eq '-';
        }
        push @out, $short1;
        
        # and flush at the end
        push @out, @defer, $short2;
    }
    wantarray ? @out : join '', @out;
}

sub id {
    my $self = shift;

    if (@_) {
        $self->{id1} = shift;
        $self->{id2} = shift;
    }

    @{$self}{qw/id1 id2/};
}

sub hunks {
    my $self = shift;

    @{ $self->{diff} };
}

1;

__END__

#----------------------------------------------------------------------------

=head1 API

=head2 new

The underlying object of VCS::Lite::Delta is an array of difference 
chunks (hunks) such as that returned by Algorithm::Diff. 

The constructor takes the following forms:

  my $delt = VCS::Lite::Delta->new( '/my/file.diff',$sep); # File name
  my $delt = VCS::Lite::Delta->new( \*FILE,$sep);	# File handle
  my $delt = VCS::Lite::Delta->new( \$string,$sep); # String as scalar ref
  my $delt = VCS::Lite::Delta->new( \@foo, $id1, $id2) # Array ref

$sep here is a regexp by which to split strings into tokens. 
The default is to use the natural perl mechanism of $/ (which is emulated 
when not reading from a file). The arrayref form is assuming an array of 
hunks such as the output from L<Algorithm::Diff::diff>.

The other forms assume the input is the text form of a diff listing, 
either in diff format, or in unified format. The input is parsed, and errors
are reported.

=head2 diff

  print OUTFILE $delt->diff

This generates a standard diff format, for example:

4c4
< Now wherefore stopp'st thou me?
---
> Now wherefore stoppest thou me?

=head2 udiff

  print OUTFILE $delt->udiff

This generates a unified diff (like diff -u) similar to the form in which
patches are submitted.

=head2 id

  my ($id1,$id2) = $delt->id;
  $delt2->id('foo.pl@@1','foo.pl@@3')

The I<id> method allows get and set of the names associated with the two 
elements being diffed. The id is set for delta objects returned by 
VCS::Lite->diff, to the element IDs of the VCS::Lite objects being diffed.

Diff format omits the file names, hence the IDs will not be populated by
new. This is not the case with diff -u format, which includes the file
names which are passed in and available as IDs.

=head2 hunks

  my @hunklist = $delt->hunks

A hunk is a technical term for a section of input containing a difference.
Each hunk is an arrayref, containing the block of lines. Each line is 
itself an arrayref, for example:

  [
    [ '+', 9, 'use Acme::Foo;'],
    [ '-', 9, 'use Acme::Bar;'],
  ]

See the documentation on L<Algorithm::Diff> for more details of this structure.

=head1 SEE ALSO

L<Algorithm::Diff>.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (see link below). However, it would help greatly if you are able to 
pinpoint problems or even supply a patch.

http://rt.cpan.org/Public/Dist/Display.html?Name=VCS-Lite

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Original Author: Ivor Williams (RIP)          2002-2009
  Current Maintainer: Barbie <barbie@cpan.org>  2009-2015

=head1 COPYRIGHT

  Copyright (c) Ivor Williams, 2002-2006
  Copyright (c) Barbie,        2009-2015

=head1 LICENCE

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
