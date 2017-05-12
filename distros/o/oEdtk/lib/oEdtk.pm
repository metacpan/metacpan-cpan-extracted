package oEdtk ;

BEGIN {
		use Exporter;
		use vars 	qw($VERSION @ISA @EXPORT @EXPORT_OK); # %EXPORT_TAGS);
		use strict;

		# a.ammr a.a année d'existence, mm mois, r release
		$VERSION	= 0.8052; 
		my $YEAR	= '2013';
		@ISA		= qw(Exporter);
		@EXPORT	= qw(oEdtk_release);
}

#
# CODE - DOC AT THE END
#

sub oEdtk_release {
	# warn "DEBUG: >$?< \nDEBUG: >$@<\n";
	return "\n(c) 2005-2013 daunay\@cpan.org - edtk\@free.fr - oEdtk v$VERSION\n";
}


END {
	warn oEdtk_release();
}

1;

__END__

# This document is in Pod format.  To read this, use a Pod formatter, like
# "perldoc oEdtk".

=head1 NAME

oEdtk - A module for industrial printing processing

=head1 DESCRIPTION

This is the main module of the oEdtk toolkit. It's intended for documentation
purposes only.  You will find general information about the diferents tools
here.

=head1 SYNOPSIS

=head2 SIMPLE USE (fixed records)

    use oEdtk::Main;
    use strict;

    sub main() {
        # File input and output opening
        oe_new_job($ARGV[0], $ARGV[1]);

        # Application initialisation (user defined)
        &initApp();

        # Reading the input line by line
        while (my $ligne=<IN>) {
            chomp ($ligne);
            # testing if $line match pre declared records
            if (oe_process_ref_rec(0, 3, $ligne)) {
            } else {
                # If not, record is ignored
                warn "INFO IGNORE REC. line $.\n";
       	    }
        }

        # Closing input and output file
        oe_compo_link($ARGV[0], $ARGV[1]);
        return 1;
    }

    sub initApp() {
        # EXAMPLE : DECLARATION OF RECORD KEYED '016'
        # structure of record '016' for spliting/extraction
        # (could be delayed in 'pre_process' procedure)
        oe_rec_motif("016", "A67 A20 A*");

        # compuset output declaration (only if necessary)
        oe_rec_output("016", "<SK>%s<#DATE=%s><SK>%s");
        return 1;
    }

=head2 EXAMPLE 2 (fixed records)

    use oEdtk::Main;
    use strict;

    sub main() {
        # File input and output opening
        oe_new_job($ARGV[0], $ARGV[1]);

        # Application initialisation (user defined)
        &initApp();

        # Reading the input line by line
        while (my $ligne=<IN>) {
            chomp ($ligne);
            # Testing if $line match pre declared records
            if (oe_process_ref_rec(0, 3, $ligne)){
            } else {
            	# If not, record is ignored
            	warn "INFO IGNORE REC. line $.\n";
            }
        }

        # Closing input and output file
        oe_compo_link($ARGV[0], $ARGV[1]);
        return 1;
    }

    sub initApp() {
        # EXAMPLE : DECLARATION OF RECORD KEYED '016'
        # process '&initDoc' done when record '016' is found,
        # before to proceed the record
        # (mandatory only if no oe_rec_motif declared)
        oe_rec_pre_process("016", \&initDoc);

        # structure of record '016' for spliting/extraction
        # (could be delayed in 'pre_process' procedure)
        oe_rec_motif("016", "A67 A20 A*");

        # process '&format_date' after record is read
        # (only if necessary)
        oe_rec_process("016", \&format_date);

        # compuset output declaration (only if necessary)
        oe_rec_output("016", "<SK>%s<#DATE=%s><SK>%s");

        # process after building the output
        # (only if necessary)
        recEdtk_post_process("016", \&vars_prepared_for_next_Rec);
        return 1;
    }

=head1 CONVENTIONS

Scripts are developped in functional mode.  We try to use the Perl conventions,
we are listenning all your recommandations to make it better.

When a sub or a function comes from the user script it's written like this :

    &function_from_the_script();

Functions or 'methods' from perl modules are written like this :

    oe_rec_motif("016", "A67 A20 A*");

=head1 INTERFACE

=head2 oe_new_job

oe_new_job( input_file, output_file, [single_job_id] )

This function opens and shares the main filehandles IN and OUT.  The parameter
'single_job_id' is optional.  It is used to send the job id to the document
builder application.

=head2 oe_compo_link

oe_compo_link( input_file, output_file )

This function closes the main filehandles IN and OUT.  Filenames in parameters
are used for information, but they are mandatory.

=head2 oe_process_ref_rec

oe_process_ref_rec( offset_Key, key_Length, Record_Line, [offset_of_Rec, Record_length] )

This function process the record line referenced in parameters as described with
'recEdtk_' tools (see below). It's made for fixed size records.

Mandatory parameters:

=over 4

=item *

'offset_key' is the starting point position of the record key

=item *

'key_Length' is the the length of the record key you are looking for

=item *

'Record_Line' is a reference to the record line you are working on
(C<oe_process_ref_rec> uses the reference of the line)

=back

Optional parameters:

=over 4

=item *

'offset_of_Rec' is the starting point of the record from the beginning of
the line (if you want to cut down the begging of the line)

=item *

'Record_length' is the lenght of the record from the starting point of the record

=back

The C<oe_process_ref_rec> function works by ordered key size, from the left to the
right.  You should use it by working first with the biggest record to the
smallest one.

Examples :

	record 'abc'  :	abcvalue_1 value_2 value_3
 	record 'zzza' :	zzza**value_1 value_2 value_3
 	record 'ywba' :	ywba**value_AAAAAAAAA value_B
	record '016'  :	***016-value_A1 value_B2 value_C3
 	record '600'  :	***600-value_A4 value_B5 value_C6

	record definitions (in fact, the order is not important here) :
		oe_rec_motif	("zzza","A4 A2 A8  A8 A7 A*");
		oe_rec_motif	("ywba","A4 A2 A16 A7 A*");
		oe_rec_motif	("abc", "A3 A8 A8  A7 A*");
		oe_rec_motif	("016", "A3 A3 A1  A9 A9 A7 A*");
		oe_rec_motif	("600", "A3 A1 A9  A9 A7 A*");

	you will process from left to right, from bigest to smallest :
		if (oe_process_ref_rec(0, 4, $ligne)) {
			# this will process both records 'zzza' and 'ywba' .

		} elsif (oe_process_ref_rec(0, 3, $ligne, 3)) {
			# this will process records 'abc'
			# (and cut away first 3 caracters of the record line).

		} elsif (oe_process_ref_rec(3, 3, $ligne, 6)) {
			# this will process both records '016' and '600'
			# (and cut away first 6 caracters of the record line).

		} else {
			# if not, record is ignored
			warn "INFO IGNORE REC. line $.\n";
		}

The C<oe_process_ref_rec> function returns 1 when it recognizes and processes the
record (including the output if C<oe_rec_output> is defined). Values extracted
from the record are split into the C<@DATATAB> oEdtk global array.
C<oe_process_ref_rec> returns 0 when it could not recognize the record.

The C<oe_process_ref_rec> function makes these differents steps :

=over 4

=item 1.

look if there is a record key corresponding

=item 2.

run the pre-process function if defined (see L</oe_rec_pre_process>)

=item 3.

unpack the record according to oe_rec_motif definition into C<@DATATAB>

=item 4.

run the process function if defined (see L</oe_rec_process>)

=item 5.

build output if oe_rec_output is defined

=item 6.

run the post-process function if defined (see L</recEdtk_post_process>)

=back

=head2 oe_rec_motif

oe_rec_motif( Record_Key_ID, Record_Template )

Create a record with the 'Record_Key_ID' identifier or type.  This key
identifier should be in the record.  This function defines the 'Record_Template'
used to expand / extract the record (see L<unpack|perlfunc/unpack> for template
description).  This function is mandatory, but cannot be defined after
C<oe_rec_pre_process>.

Example :

    oe_rec_motif("016", "A2 A10 A15 A10 A15 A*");

It is recommended to add 'A*' at the end of the template to cut away any
unexpected data that will remain at the end of the record.

=head2 oe_rec_process

oe_rec_process( Record_Key_ID, \&user_sub_reference )

This function links the record 'Record_Key_ID' with a process sub. This sub is
called after the extraction / expanding of the record.  When this process is
defined, it's called before the building of the output (if defined, see
L</oe_rec_output>).  You can access the expanded data by reading/writing global
tab C<@DATATAB>.  This function is optional.

=head2 oe_rec_output

oe_rec_output( Record_Key_ID, Output_Template )

This function defines an 'Output_Template' for the record 'Record_Key_ID'. This
template is used to build the output file (see L<sprintf|perlfunc/sprintf> for
the template description).  The output is built after the record process
(L</oe_rec_process> if this one is defined).  You can access the expanded data
by reading/writing global tab C<@DATATAB>.  This function is optional.  If no
C<oe_rec_output> is defined for the 'Record_Key_ID', the record would be erased
at the next record process.

Example :

    oe_rec_output("016", "<SK>%s<#DATE=%s><SK>%s");

=head2 recEdtk_post_process

recEdtk_post_process( Record_Key_ID, \&user_sub_reference )

This function links the record 'Record_Key_ID' with a process sub. This sub is
called after the building of the output.  When this process is defined, it's
called before the next record read.  You can access the expanded data by
reading/writing global tab C<@DATATAB>.  This function is optional.

=head2 recEdtk_erase

recEdtk_erase( Record_Key_ID )

This function will erase all the descriptions made for the record
'Record_Key_ID'.  This is useful when you want to ignore a record (this will
cause a message 'Record Unknown' as if it has never been declared before) or
when you want to redefine a record during the process.

=head2 recEdtk_redefine

recEdtk_redefine( Record_Key_ID, Record_Template )

This function will erase (as above) AND redefine the record 'Record_Key_ID' and
its template 'Record_Template'.  With this function, you define the necessary to
start processing the record.  It's the less you can do.

Example :

    recEdtk_redefine("016", "A2 A10 A15 A10 A15 A*");

=head1 AUTHORS

oEdtk by D Aunay, GJ Chaillou Domingo, M Henrion, G Ballin 2005-2013.

This pod text by GJ Chaillou Domingo, M Henrion and others.
Perl by Larry Wall and the C<perl5-porters>.

=head1 COPYRIGHT

The oEdtk module is Copyright (c) 2005-2013 D Aunay, GJ Chaillou Domingo, M Henrion, G Ballin.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SUPPORT / WARRANTY

The oEdtk is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
