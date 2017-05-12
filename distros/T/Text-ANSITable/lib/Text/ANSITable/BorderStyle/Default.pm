package Text::ANSITable::BorderStyle::Default;

our $DATE = '2016-03-11'; # DATE
our $VERSION = '0.48'; # VERSION

use 5.010;
use strict;
use utf8;
use warnings;

our %border_styles = (

    # none

    none_ascii => {
        summary => 'No border',
        chars => [
            ['','','',''],     # 0
            ['','',''],        # 1
            ['','','',''],     # 2
            ['','',''],        # 3
            [' ','-','-',' '], # 4
            ['','','',''],     # 5
        ],
    },

    none_boxchar => {
        summary => 'No border',
        chars => [
            ['','','',''],     # 0
            ['','',''],        # 1
            ['','','',''],     # 2
            ['','',''],        # 3
            ['','q','q',''],   # 4
            ['','','',''],     # 5
        ],
        box_chars => 1,
    },

    none_utf8 => {
        summary => 'No border',
        chars => [
            ['','','',''],     # 0
            ['','',''],        # 1
            ['','','',''],     # 2
            ['','',''],        # 3
            ['','─','─',''],   # 4
            ['','','',''],     # 5
        ],
        utf8 => 1,
    },


    # space

    space_ascii => {
        summary => 'Space as border',
        chars => [
            [' ',' ',' ',' '], # 0
            [' ',' ',' '],     # 1
            [' ',' ',' ',' '], # 2
            [' ',' ',' '],     # 3
            [' ','-','-',' '], # 4
            [' ',' ',' ',' '], # 5
        ],
    },

    space_boxchar => {
        summary => 'Space as border',
        chars => [
            [' ',' ',' ',' '], # 0
            [' ',' ',' '],     # 1
            [' ',' ',' ',' '], # 2
            [' ',' ',' '],     # 3
            [' ','q','q',' '], # 4
            [' ',' ',' ',' '], # 5
        ],
        box_chars => 1,
    },

    space_utf8 => {
        summary => 'Space as border',
        chars => [
            [' ',' ',' ',' '], # 0
            [' ',' ',' '],     # 1
            [' ',' ',' ',' '], # 2
            [' ',' ',' '],     # 3
            [' ','─','─',' '], # 4
            [' ',' ',' ',' '], # 5
        ],
        utf8 => 1,
    },

    spacei_ascii => {
        summary => 'Space, inner-only',
        chars => [
            ['','','',''],   # 0
            ['',' ',''],     # 1
            ['',' ',' ',''], # 2
            ['',' ',''],     # 3
            ['','-','-',''], # 4
            ['','','',''],   # 5
        ],
    },

    spacei_boxchar => {
        summary => 'Space, inner-only',
        chars => [
            ['','','',''],   # 0
            ['',' ',''],     # 1
            ['',' ',' ',''], # 2
            ['',' ',''],     # 3
            ['','q','q',''], # 4
            ['','','',''],   # 5
        ],
        box_chars => 1,
    },

    spacei_utf8 => {
        summary => 'Space, inner-only',
        chars => [
            ['','','',''],   # 0
            ['',' ',''],     # 1
            ['',' ',' ',''], # 2
            ['',' ',''],     # 3
            ['','─','─',''], # 4
            ['','','',''],   # 5
        ],
        utf8 => 1,
    },

    # single

    single_ascii => {
        summary => 'Single',
        chars => [
            ['.','-','+','.'], # 0
            ['|','|','|'],     # 1
            ['+','-','+','+'], # 2
            ['|','|','|'],     # 3
            ['+','-','+','+'], # 4
            ['`','-','+',"'"], # 5
        ],
    },

    single_boxchar => {
        summary => 'Single',
        chars => [
            ['l','q','w','k'], # 0
            ['x','x','x'],     # 1
            ['t','q','n','u'], # 2
            ['x','x','x'],     # 3
            ['t','q','n','u'], # 4
            ['m','q','v','j'], # 5
        ],
        box_chars => 1,
    },

    single_utf8 => {
        summary => 'Single',
        chars => [
            ['┌','─','┬','┐'], # 0
            ['│','│','│'],     # 1
            ['├','─','┼','┤'], # 2
            ['│','│','│'],     # 3
            ['├','─','┼','┤'], # 4
            ['└','─','┴','┘'], # 5
        ],
        utf8 => 1,
    },


    # single, horizontal only

    singleh_ascii => {
        summary => 'Single, horizontal only',
        chars => [
            ['-','-','-','-'], # 0
            [' ',' ',' '],     # 1
            ['-','-','-','-'], # 2
            [' ',' ',' '],     # 3
            ['-','-','-','-'], # 4
            ['-','-','-','-'], # 5
        ],
    },

    singleh_boxchar => {
        summary => 'Single, horizontal only',
        chars => [
            ['q','q','q','q'], # 0
            [' ',' ',' '],     # 1
            ['q','q','q','q'], # 2
            [' ',' ',' '],     # 3
            ['q','q','q','q'], # 4
            ['q','q','q','q'], # 5
        ],
        box_chars => 1,
    },

    singleh_utf8 => {
        summary => 'Single, horizontal only',
        chars => [
            ['─','─','─','─'], # 0
            [' ',' ',' '],     # 1
            ['─','─','─','─'], # 2
            [' ',' ',' '],     # 3
            ['─','─','─','─'], # 4
            ['─','─','─','─'], # 5
        ],
        utf8 => 1,
    },


    # single, vertical only

    singlev_ascii => {
        summary => 'Single border, only vertical',
        chars => [
            ['|',' ','|','|'], # 0
            ['|','|','|'],     # 1
            ['|',' ','|','|'], # 2
            ['|','|','|'],     # 3
            ['|','-','|','|'], # 4
            ['|',' ','|','|'], # 5
        ],
    },

    singlev_boxchar => {
        summary => 'Single, vertical only',
        chars => [
            ['x',' ','x','x'], # 0
            ['x','x','x'],     # 1
            ['x',' ','x','x'], # 2
            ['x','x','x'],     # 3
            ['x','q','x','x'], # 4
            ['x',' ','x','x'], # 5
        ],
        box_chars => 1,
    },

    singlev_utf8 => {
        summary => 'Single, vertical only',
        chars => [
            ['│',' ','│','│'], # 0
            ['│','│','│'],     # 1
            ['│',' ','│','│'], # 2
            ['│','│','│'],     # 3
            ['│','─','│','│'], # 4
            ['│',' ','│','│'], # 5
        ],
        utf8 => 1,
    },


    # single, inner only

    singlei_ascii => {
        summary => 'Single, inner only (like in psql command-line client)',
        chars => [
            ['','','',''],     # 0
            [' ','|',' '],     # 1
            [' ','-','+',' '], # 2
            [' ','|',' '],     # 3
            [' ','-','+',' '], # 4
            ['','','',''],     # 5
        ],
    },

    singlei_boxchar => {
        summary => 'Single, inner only (like in psql command-line client)',
        chars => [
            ['','','',''],     # 0
            [' ','x',' '],     # 1
            [' ','q','n',' '], # 2
            [' ','x',' '],     # 3
            [' ','q','n',' '], # 4
            ['','','',''],     # 5
        ],
        box_chars => 1,
    },

    singlei_utf8 => {
        summary => 'Single, inner only (like in psql command-line client)',
        chars => [
            ['','','',''],     # 0
            [' ','│',' '],     # 1
            [' ','─','┼',' '], # 2
            [' ','│',' '],     # 3
            [' ','─','┼',' '], # 4
            ['','','',''],     # 5
        ],
        utf8 => 1,
    },


    # single, outer only

    singleo_ascii => {
        summary => 'Single, outer only',
        chars => [
            ['.','-','-','.'], # 0
            ['|',' ','|'],     # 1
            ['|',' ',' ','|'], # 2
            ['|',' ','|'],     # 3
            ['+','-','-','+'], # 4
            ['`','-','-',"'"], # 5
        ],
    },

    singleo_boxchar => {
        summary => 'Single, outer only',
        chars => [
            ['l','q','q','k'], # 0
            ['x',' ','x'],     # 1
            ['x',' ',' ','x'], # 2
            ['x',' ','x'],     # 3
            ['t','q','q','u'], # 4
            ['m','q','q','j'], # 5
        ],
        box_chars => 1,
    },

    singleo_utf8 => {
        summary => 'Single, outer only',
        chars => [
            ['┌','─','─','┐'], # 0
            ['│',' ','│'],     # 1
            ['│',' ',' ','│'], # 2
            ['│',' ','│'],     # 3
            ['├','─','─','┤'], # 4
            ['└','─','─','┘'], # 5
        ],
        utf8 => 1,
    },


    # curved single

    csingle => {
        summary => 'Curved single',
        chars => [
            ['╭','─','┬','╮'], # 0
            ['│','│','│'],     # 1
            ['├','─','┼','┤'], # 2
            ['│','│','│'],     # 3
            ['├','─','┼','┤'], # 4
            ['╰','─','┴','╯'], # 5
        ],
        utf8 => 1,
    },


    # bold single

    bold => {
        summary => 'Bold',
        chars => [
            ['┏','━','┳','┓'], # 0
            ['┃','┃','┃'],     # 1
            ['┣','━','╋','┫'], # 2
            ['┃','┃','┃'],     # 3
            ['┣','━','╋','┫'], # 4
            ['┗','━','┻','┛'], # 5
        ],
        utf8 => 1,
    },


    #boldv => {
    #    summary => 'Vertically-bold',
    #},


    #boldh => {
    #    summary => 'Horizontally-bold',
    #},


    # double

    double => {
        summary => 'Double',
        chars => [
            ['╔','═','╦','╗'], # 0
            ['║','║','║'],     # 1
            ['╠','═','╬','╣'], # 2
            ['║','║','║'],     # 3
            ['╠','═','╬','╣'], # 4
            ['╚','═','╩','╝'], # 5
        ],
        utf8 => 1,
    },


    # brick

    brick => {
        summary => 'Single, bold on bottom right to give illusion of depth',
        chars => [
            ['┌','─','┬','┒'], # 0
            ['│','│','┃'],     # 1
            ['├','─','┼','┨'], # 2
            ['│','│','┃'],     # 3
            ['├','─','┼','┨'], # 4
            ['┕','━','┷','┛'], # 5
        ],
        utf8 => 1,
    },

    bricko => {
        summary => 'Single, outer only, '.
            'bold on bottom right to give illusion of depth',
        chars => [
            ['┌','─','─','┒'], # 0
            ['│',' ','┃'],     # 1
            ['│',' ',' ','┃'], # 2
            ['│',' ','┃'],     # 3
            ['├','─','─','┨'], # 4
            ['┕','━','━','┛'], # 5
        ],
        utf8 => 1,
    },

);

1;
# ABSTRACT: Default border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::BorderStyle::Default - Default border styles

=head1 VERSION

This document describes version 0.48 of Text::ANSITable::BorderStyle::Default (from Perl distribution Text-ANSITable), released on 2016-03-11.

=head1 BORDER STYLES

Below are the border styles included in this package:

=head2 Default::bold

Bold (utf8: yes, box_chars: no).

 ┏━━━━━━━━━┳━━━━━━━━━┓
 ┃ column1 ┃ column2 ┃
 ┣━━━━━━━━━╋━━━━━━━━━┫
 ┃ row1.1  ┃ row1.2  ┃
 ┃ row2.1  ┃ row3.2  ┃
 ┣━━━━━━━━━╋━━━━━━━━━┫
 ┃ row3.1  ┃ row3.2  ┃
 ┗━━━━━━━━━┻━━━━━━━━━┛


=head2 Default::brick

Single, bold on bottom right to give illusion of depth (utf8: yes, box_chars: no).

 ┌─────────┬─────────┒
 │ column1 │ column2 ┃
 ├─────────┼─────────┨
 │ row1.1  │ row1.2  ┃
 │ row2.1  │ row3.2  ┃
 ├─────────┼─────────┨
 │ row3.1  │ row3.2  ┃
 ┕━━━━━━━━━┷━━━━━━━━━┛


=head2 Default::bricko

Single, outer only, bold on bottom right to give illusion of depth (utf8: yes, box_chars: no).

 ┌───────────────────┒
 │ column1   column2 ┃
 │                   ┃
 │ row1.1    row1.2  ┃
 │ row2.1    row3.2  ┃
 ├───────────────────┨
 │ row3.1    row3.2  ┃
 ┕━━━━━━━━━━━━━━━━━━━┛


=head2 Default::csingle

Curved single (utf8: yes, box_chars: no).

 ╭─────────┬─────────╮
 │ column1 │ column2 │
 ├─────────┼─────────┤
 │ row1.1  │ row1.2  │
 │ row2.1  │ row3.2  │
 ├─────────┼─────────┤
 │ row3.1  │ row3.2  │
 ╰─────────┴─────────╯


=head2 Default::double

Double (utf8: yes, box_chars: no).

 ╔═════════╦═════════╗
 ║ column1 ║ column2 ║
 ╠═════════╬═════════╣
 ║ row1.1  ║ row1.2  ║
 ║ row2.1  ║ row3.2  ║
 ╠═════════╬═════════╣
 ║ row3.1  ║ row3.2  ║
 ╚═════════╩═════════╝


=head2 Default::none_ascii

No border (utf8: no, box_chars: no).

  column1  column2 
  row1.1   row1.2  
  row2.1   row3.2  
  ------------------- 
  row3.1   row3.2  


=head2 Default::none_boxchar

No border (utf8: no, box_chars: yes).

=head2 Default::none_utf8

No border (utf8: yes, box_chars: no).

  column1  column2 
  row1.1   row1.2  
  row2.1   row3.2  
 ───────────────────
  row3.1   row3.2  


=head2 Default::single_ascii

Single (utf8: no, box_chars: no).

 .---------+---------.
 | column1 | column2 |
 +---------+---------+
 | row1.1  | row1.2  |
 | row2.1  | row3.2  |
 +---------+---------+
 | row3.1  | row3.2  |
 `---------+---------'


=head2 Default::single_boxchar

Single (utf8: no, box_chars: yes).

=head2 Default::single_utf8

Single (utf8: yes, box_chars: no).

 ┌─────────┬─────────┐
 │ column1 │ column2 │
 ├─────────┼─────────┤
 │ row1.1  │ row1.2  │
 │ row2.1  │ row3.2  │
 ├─────────┼─────────┤
 │ row3.1  │ row3.2  │
 └─────────┴─────────┘


=head2 Default::singleh_ascii

Single, horizontal only (utf8: no, box_chars: no).

 ---------------------
   column1   column2  
 ---------------------
   row1.1    row1.2   
   row2.1    row3.2   
 ---------------------
   row3.1    row3.2   
 ---------------------


=head2 Default::singleh_boxchar

Single, horizontal only (utf8: no, box_chars: yes).

=head2 Default::singleh_utf8

Single, horizontal only (utf8: yes, box_chars: no).

 ─────────────────────
   column1   column2  
 ─────────────────────
   row1.1    row1.2   
   row2.1    row3.2   
 ─────────────────────
   row3.1    row3.2   
 ─────────────────────


=head2 Default::singlei_ascii

Single, inner only (like in psql command-line client) (utf8: no, box_chars: no).

   column1 | column2  
  ---------+--------- 
   row1.1  | row1.2   
   row2.1  | row3.2   
  ---------+--------- 
   row3.1  | row3.2   


=head2 Default::singlei_boxchar

Single, inner only (like in psql command-line client) (utf8: no, box_chars: yes).

=head2 Default::singlei_utf8

Single, inner only (like in psql command-line client) (utf8: yes, box_chars: no).

   column1 │ column2  
  ─────────┼───────── 
   row1.1  │ row1.2   
   row2.1  │ row3.2   
  ─────────┼───────── 
   row3.1  │ row3.2   


=head2 Default::singleo_ascii

Single, outer only (utf8: no, box_chars: no).

 .-------------------.
 | column1   column2 |
 |                   |
 | row1.1    row1.2  |
 | row2.1    row3.2  |
 +-------------------+
 | row3.1    row3.2  |
 `-------------------'


=head2 Default::singleo_boxchar

Single, outer only (utf8: no, box_chars: yes).

=head2 Default::singleo_utf8

Single, outer only (utf8: yes, box_chars: no).

 ┌───────────────────┐
 │ column1   column2 │
 │                   │
 │ row1.1    row1.2  │
 │ row2.1    row3.2  │
 ├───────────────────┤
 │ row3.1    row3.2  │
 └───────────────────┘


=head2 Default::singlev_ascii

Single border, only vertical (utf8: no, box_chars: no).

 |         |         |
 | column1 | column2 |
 |         |         |
 | row1.1  | row1.2  |
 | row2.1  | row3.2  |
 |---------|---------|
 | row3.1  | row3.2  |
 |         |         |


=head2 Default::singlev_boxchar

Single, vertical only (utf8: no, box_chars: yes).

=head2 Default::singlev_utf8

Single, vertical only (utf8: yes, box_chars: no).

 │         │         │
 │ column1 │ column2 │
 │         │         │
 │ row1.1  │ row1.2  │
 │ row2.1  │ row3.2  │
 │─────────│─────────│
 │ row3.1  │ row3.2  │
 │         │         │


=head2 Default::space_ascii

Space as border (utf8: no, box_chars: no).

                      
   column1   column2  
                      
   row1.1    row1.2   
   row2.1    row3.2   
  ------------------- 
   row3.1    row3.2   
                      


=head2 Default::space_boxchar

Space as border (utf8: no, box_chars: yes).

=head2 Default::space_utf8

Space as border (utf8: yes, box_chars: no).

                      
   column1   column2  
                      
   row1.1    row1.2   
   row2.1    row3.2   
  ─────────────────── 
   row3.1    row3.2   
                      


=head2 Default::spacei_ascii

Space, inner-only (utf8: no, box_chars: no).

  column1   column2 
  row1.1    row1.2  
  row2.1    row3.2  
 -------------------
  row3.1    row3.2  


=head2 Default::spacei_boxchar

Space, inner-only (utf8: no, box_chars: yes).

=head2 Default::spacei_utf8

Space, inner-only (utf8: yes, box_chars: no).

  column1   column2 
  row1.1    row1.2  
  row2.1    row3.2  
 ───────────────────
  row3.1    row3.2  

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-ANSITable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-ANSITable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-ANSITable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
