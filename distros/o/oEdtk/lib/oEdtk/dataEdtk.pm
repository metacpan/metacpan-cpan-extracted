package oEdtk::dataEdtk;

use strict;

BEGIN {
	use oEdtk::Main 0.42;
	use oEdtk::libDev 0.3094;
	use oEdtk::logger 1.03;

	use Exporter ();
	use vars     qw ($VERSION @ISA @EXPORT @EXPORT_OK);

	$VERSION = 2.1126;
	@ISA     = qw (Exporter);
	@EXPORT  = qw (unpackCopygroup cpyOccurs);
}

sub unpackCopygroup () {    # NO LONGER USED? dependency on the old gen_appEdtk.pl
							# receives a reference to a cobol Picture string (no comment line)
							# reformats the cobol pictures according to their type
							# PIC X  : alphanumeric type variable
							# PIC 9  : numeric type variable
							# PIC S9 : signed numeric type variable

	# V99
	# V9(m)

	# PIC X                    -> %s
	# PIC X(n)                 -> %s
	# PIC XXXX                 -> %s
	# PIC 9                    -> %1.0f
	# PIC 9(n)                 -> %n.0f
	# PIC 9999                 -> %4.0f
	# PIC S9                   -> %1.0f
	# PIC S9(n)                -> %n.0f
	# PIC S9999                -> %4.0f

	# OCCURS nn
	# VALUE 'X'
	# VALUE ZERO

	my $rRecord  = shift;
	my $rangCol  = 0;
	my $nomCol   = "";
	my $lenCol   = 0;
	my $typCol   = "";
	my $signCol  = 0;
	my $decimCol = 0;
	my $colOccur = 1;

	# SIMPLIFY THE HANDLING OF FIELD NAMES:
	#   THE '_' CHARACTER IS PART OF THE \w CHARACTER CLASS
	${$rRecord} =~ s/\-/\_/g;
	oe_trimp_space($rRecord);

	if ( ${$rRecord} =~ /^\s*(\d{1,2})\s+(\w+)(.*)/ ) {

		# 01  ACPDB_RECORD.
		#     05  ACPDB_FD_TRANS_CN   PIC XX.
		$rangCol = $1;
		$nomCol  = $2;
		${$rRecord} = $3;
	}

	# OCCURS HANDLING CHECK
	if ( ${$rRecord} =~ /(.*)OCCURS\s+(\d+)/ ) {
		${$rRecord} = $1;
		$colOccur = $2;
		die &logger( $NOK, "The data descriptor contains an unhandled OCCURS clause" );
	}

	if ( ${$rRecord} =~ /(.*)V9\((\d+)\)(.*)/ ) {

		# V9(m)
		${$rRecord} = "$1 $3";
		$decimCol = $2;
	}
	elsif ( ${$rRecord} =~ /(.*)V(9+)(.*)/ ) {

		# V9999
		${$rRecord} = "$1 $3";
		$decimCol = length($2);
	}

	if ( ${$rRecord} =~ /PIC\s+X(.*)/ ) {

		# PIC X                    -> %s
		${$rRecord} = $1;
		$lenCol = 1;
		$typCol = "s";
		if ( ${$rRecord} =~ /\((\d+)\)(.*)/ ) {

			# PIC X)(n) ...        -> %s
			$lenCol = $1;
			${$rRecord} = $2;
		}
		elsif ( ${$rRecord} =~ /(X+)(.*)/ ) {

			# PIC X)XXX ...        -> %s
			$lenCol = length($1) + 1;
			${$rRecord} = $2;
		}

	}
	elsif ( ${$rRecord} =~ /PIC\s+9(.*)/ ) {

		# PIC 9                    -> %1.mf
		${$rRecord} = $1;
		$lenCol = 1 + $decimCol;
		$typCol = "1.${decimCol}f";
		if ( ${$rRecord} =~ /\((\d+)\)(.*)/ ) {

			# PIC 9)(n) ...       -> %n.mf
			$lenCol = $1 + $decimCol;
			${$rRecord} = $2;
			$typCol = "$lenCol.${decimCol}f";
		}
		elsif ( ${$rRecord} =~ /(9+)(.*)/ ) {

			# PIC 9)999 ...       -> %n.mf
			$lenCol = length($1) + 1 + $decimCol;
			${$rRecord} = $2;
			$typCol = "$lenCol.${decimCol}f";
		}

	}
	elsif ( ${$rRecord} =~ /PIC\s+S(.*)/ ) {

		# PIC S9                   -> %1.mf
		${$rRecord} = $1;
		$lenCol  = 1 + $decimCol;
		$typCol  = "1.${decimCol}f";
		$signCol = 1;
		if ( ${$rRecord} =~ /\((\d+)\)(.*)/ ) {

			# PIC S)[9](n) ...    -> %n.mf
			$lenCol = $1 + $decimCol;
			${$rRecord} = $2;
			$typCol = "$lenCol.${decimCol}f";
		}
		elsif ( ${$rRecord} =~ /(9+)(.*)/ ) {

			# PIC S)9999 ...      -> %n.mf
			$lenCol = length($1) + $decimCol;
			${$rRecord} = $2;
			$typCol = "$lenCol.${decimCol}f";
		}
	}

	return $rangCol, $nomCol, $lenCol, $typCol, $decimCol, $signCol, ${$rRecord}, $colOccur;
}

{    # OCCURS HANDLING
	 # DEFINE VARIABLES LOCAL TO OCCURS HANDLING

	my $flagOccur   = 0;
	my $occurBuff   = 1;
	my $buff        = "";
	my $buffComment = "";
	my $rLignesTab;

	sub cpyOccurs {    # NO LONGER USED? dependency on the old gen_appEdtk.pl
		$rLignesTab = shift;
		my $ligne              = "";
		my $rangCol            = 0;
		my $lastRangCol        = 0;
		my $nbOccursImbriquees = 0;

		push( @{$rLignesTab}, " * START TRT IN $rLignesTab" );

	DEFS: while ( $ligne = shift @{$rLignesTab} ) {
			&logger( 7, " 150 line=$ligne" );
			if ( $ligne eq " * START TRT IN $rLignesTab" ) {
				last DEFS;
			}

			$ligne =~ /^\s*(\d+)/;
			&logger( 7, " 156 line=$ligne" );
			$rangCol = $1 if $1;

			if ( $flagOccur > 0 && $rangCol <= $lastRangCol ) {
				&cpyEditOccurs();
			}

			if ( $flagOccur == 0 && $ligne =~ /OCCURS\s+(\d+)/i ) {
				$occurBuff = $1;
				$flagOccur = 1;
				&logger( 7, "Nesting=$nbOccursImbriquees flagOcc=$flagOccur && OCC line" );
				&logger( 7, " 167 line=$ligne" );
				$ligne =~ s/(.*)(OCCURS\s+\d+)(.*)/$1$3/io;
				push( @{$rLignesTab}, $ligne );
				$lastRangCol = $rangCol;

			}
			elsif ( $flagOccur > 0 && $rangCol > $lastRangCol ) {
				if ( $ligne =~ /^\s*\*+/ ) {

					# COMMENTED LINES COME BEFORE THE FIELD DESCRIPTORS,
					# KEEP THEM IN MEMORY TO OUTPUT THEM WITH THE OCCURS
					$buffComment .= $ligne;
					&logger( 7, " 177 line=$ligne" );
				}
				else {
					if ( $ligne =~ /OCCURS/ ) {
						$nbOccursImbriquees++;
						&logger( 7, " * Nesting=$nbOccursImbriquees : $ligne" );
					}
					$buff .= $ligne;
					&logger( 7, " 184 line=$ligne" );
				}

			}
			else {
				push( @{$rLignesTab}, $ligne );
				&logger( 7, " 189 line=$ligne" );
			}
		}

		&cpyEditOccurs() if ($buff);
		&logger( 7, "nbOccursImbriquees = $nbOccursImbriquees" );
		return $nbOccursImbriquees;
	}

	sub cpyEditOccurs() {    # NO LONGER USED? internal dependency
		$buff .= "\t*\n";
		push( @{$rLignesTab}, split( /\n/, $buffComment ) . "\n" );

		# for each line of $buff, insert into the array
		#push (@{$rLignesTab}, split (/\n/, $buff x $occurBuff)."\n");
		foreach my $element ( split( /\n/, $buff x $occurBuff ) ) {
			push( @{$rLignesTab}, "$element\n" );
			&logger( 7, " 205 element=$element" );
		}

		$buffComment = "";
		$buff        = "";
		$flagOccur   = 0;
		1;
	}
}

END { }
1;

=head1 NAME

oEdtk::dataEdtk - legacy COBOL descriptor helpers

=head1 SYNOPSIS

    use oEdtk::dataEdtk qw(unpackCopygroup cpyOccurs);

=head1 DESCRIPTION

Legacy helpers that reformat COBOL C<PIC> descriptors into Perl C<unpack> and
C<printf> descriptions and expand C<OCCURS> blocks. They depend on the old
C<gen_appEdtk.pl> generator and are believed to be no longer used; they are
kept for reference.

=head1 FUNCTIONS

=head2 unpackCopygroup

    my @parts = unpackCopygroup(\$record);

Read a COBOL C<PIC> string (C<X>, C<9> or C<S9>, with C<V9(n)> and C<OCCURS>
clauses) and return the column rank, name, length, Perl type, decimals, sign,
remaining text and occurrence count. An unhandled C<OCCURS> clause is an error.

=head2 cpyOccurs

    my $n = cpyOccurs($rLignesTab);

Expand the C<OCCURS> blocks in the array of lines referenced by C<$rLignesTab>
and return the number of nested C<OCCURS>. The internal helper C<cpyEditOccurs>
duplicates the buffered lines; it is not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
