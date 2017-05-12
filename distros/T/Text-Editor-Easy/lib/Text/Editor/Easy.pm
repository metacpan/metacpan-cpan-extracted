package Text::Editor::Easy;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy - A perl module to edit perl code with syntax highlighting and more.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

=head1 WHY ANOTHER EDITOR ?

There are IDE (or editors) that are currently in active development in perl : for instance, Padre and Kephra. Let's be confident that these projects
bring us good designing tools that will be, at last, written in perl.

Still, I would like a different IDE that what we can find now, and, as these IDE are still in development, perhaps they won't reach my
needs once finished. There are now lots of dynamic langages, like perl. The potential of these dynamic langages is not fully used with a 
standard IDE and static programmation.
I wish we could build a RAD tool (Rapid Application Development) which would generate "dynamic applications" : that is, applications that
you can modify while they are running. This editor module will try to be the first part of this tremendous task.

I want the editor to be programmer-oriented : you should be able to use it like a perl module from your perl programs.
And I would also like the generated applications from the IDE to be programmer-oriented : the code of these applications should
be accessible during execution and should be modifiable. Programmers should help themselves instead of constantly building "user-oriented"
applications (a "programmer-oriented" application can still be used by a simple user). Have a look at L<http://sgrommier.free.fr/perl/> if you
want more explanations about that.

This perl editor module comes with a perl editor program : 'Editor.pl' is an application that uses 'Text::Editor::Easy' instances to edit
perl code.

The module enables you to manipulate a highly multi-threaded graphical object. Several demos are provided
with the program. To run them and have a glance at the capabilities of this module, launch the perl program
"Editor.pl". See README file for installation instructions.

=head1 SYNOPSIS

The demos (10 demos to be tested from the "Editor.pl" program) will show you better examples of how to call this module.

 use Text::Editor::Easy;
 
 my $editor = Text::Editor::Easy->new;
 
 $editor->insert("Hello world\nSecond line\nlast line");
 
 $editor->save("my_file.tst");


=head1 WHY MULTI-THREAD ?

This module is object-oriented. Once an instance is created, numerous methods are accessible (maybe too much, for now !).
New methods can be added on the fly with, why not, new threads associated with these new methods.

Sometimes, you need to consume CPU to achieve your goal. But this shouldn't block the user who interactively
use your graphical module : the interface of the module (especially, method "create_new_server") allows
you to create threads as simply as you create a new variables. See module L<Text::Editor::Easy::Comm> for the thread
mecanism.

Using threads, you can make 'real interactive' applications : a 'Cancel' button that works, for instance. All
you have to do is to work in an L<interruptible way|Text::Editor::Easy::Comm/anything_for_me> which is not
possible in a mono-thread application. Thus, graphical applications (with interactive users) should always
be multi-threaded.

Threads are not only used for speed or interactivity. With private variables, they allow you to partition your code. So you don't
have a large program with a huge amount of data to manage but a lot of little threads, specialized in a much simpler
task with fewer variables to manage.
The only remaining problem is how to communicate with all these "working together threads" : the L<Text::Editor::Easy::Comm>
provide the solution. All you have to do is define a new thread associated with your new methods. When the new methods
are called (by any thread, the new created one or any other one), your new thread will be called automatically and the response will be automatically
provided to the initial calling thread (in the context of the caller). Easy, isn't it ! Again, see module L<Text::Editor::Easy::Comm> for the thread
mecanism.

=head1 GRAPHIC

The graphical part of the module is handled mainly by L<Text::Editor::Easy::Abstract>. The "Abstract" name has been given because,
even if I use Tk for now, there is no Tk calls in all the Abstract module. Tk calls are concentrated in L<Text::Editor::Easy::Graphic::Tk_Glue>
module : other "Graphic glue" modules are possible. I think of "Gtk", "Console", and why not "Qt" or "OpenGl" ? There is a limited 
communicating object (a "Text::Editor::Easy::Graphic") between the Abstract module and the glue module : this is the interface.
This interface may change a little in order to allow other "Glue module" to be written, but, of course, all graphic glue modules will
have to use the same interface.

You can see the "Text::Editor::Easy" as a super graphical layer above other layers. I imagine a generator where you design an
application in your preferred graphical user interface but the generated application could run (maybe in a limited way) in "Console mode".
Constant re-use is the key to hyper-productivity.

=head1 METHODS

=head2 NEW

 my $editor = Text::Editor::Easy->new(
     {
         'file'   => 'my_file.t3d',
         'events' => {
             'clic' => {
                 'sub' => 'my_clic_sub',
             },
         }
     }
 );


This function creates and returns a Text::Editor::Easy instance. A Text::Editor::Easy instance is a scalar reference so that you can't do anything
with it... except call any object method.
This function accepts either no parameter or a hash reference which defines the options for the creation. Here are these options :

=head3 zone

=head3 file

=head3 growing_file

=head3 save_info

=head3 bloc

=head3 focus

=head3 sub

=head3 'events' option, event management

If you want to define a special behavior in response to user events you have to write special code and reference this code so that it can be
executed. You can reference this code during the instance creation.

To have more information about 'Events', look at L<Text::Editor::Easy::Events>.

=head2 INSERT

    $editor->insert("Hello");    # Simple insert
    
    # Multi-lines insert with list context
    my @lines = $editor->insert("\n\nA non empty line\nAnother non empty line\n\n");
    
    # Using options
    my $last_line = $editor->insert(
        "...adding data\nLast line",
        {
            'line' => $lines[3],
            'cursor' => 'at_start',
        }
    );

The insert method encapsulates horrible code for you (and believe me, my code is terrible !).
It accepts one or 2 parameters : the first is the string to be inserted, the second, optional, is a hash reference that may change default behavior.

The string can be a single character or several millions of them. Only, you should know that, from time to time, a carriage return (or line feed, 
or both : just "\n" in perl) should separate your string in reasonably short lines. Perl has no limit except your memory, but the Text::Editor::Easy
module would slow down badly if it had to display lines of several thousands characters.

By default, the insertion is made at the cursor position and the cursor position is updated to the last character of the string you have inserted. If the
cursor is visible before the insertion, the cursor remains visible at the end of the insertion (maybe at the bottom of the screen). Note that insert
method may replace text too if the "Inser" key have been pressed (or set) for the editor instance, but this happens only for the first line.

This method returns L<Text::Editor::Easy::Line> instance(s). In scalar context, only the last inserted line is returned. In list context, all
inserted or changed lines are returned. If your string does not contain any "\n", then scalar and list context return the same thing as only one line
is changed. You shouldn't use list context for huge string (the 'line' instance creation consumes memory and CPU).

The hash reference, with its options, allows you to modify default behavior :

=over 4

=item *

insertion point before the insertion

=item *

how to insert text

=item *

cursor position after the insertion

=item *

how to display things after the insertion

=back

Why have all these options been added to the basic 'insert' method ? Because an 'insert' call is all that : an insertion point is chosen, text is inserted in
a precise way, cursor position is changed and, if text is long enough, your editor may look quite different.
As all these things are done implicitly, it seems legitim that options let you define each step explicitly.

=head3 insertion point, 'line' and 'pos' options

By default, the insertion is made at the cursor position. You can change that using 'line' and 'pos' options. The 'line' option must specify
a valid 'line' instance. The 'pos' option indicates the position of the insertion point in the line. You may use only one of these 2 options :

=over 4

=item *

if only the 'pos' option is provided, the line remains the line where the cursor was before insertion : you just change the position in that line.

=item *

if only the 'line' option is provided, the default position is the end of the line you have given.

=back

Note that if you use an insertion point option (either 'pos' or 'line', or both), the cursor position is no more changed by default : it remains where it was
before the insertion unless you specify a cursor position.

=head3 how to insert text, 'replace' option

    'replace' => 1, # will replace text (only in the first line)

By default, the editor uses the current "insert" config to insert the text. The config is linked to the "Inser" key and if the user have pressed it.
You can force your "insert" config using the 'replace' option. Set to 1 (or true), existing text will be replaced (only in the first line and according
to the length of your first inserted line too). Set to 0 (or false), text will be inserted.

=head3 cursor position, 'cursor' option

This option tells where to set the cursor after the insertion has been made :

 'cursor' => 'at_start',

will set the cursor before the first character that has been inserted. In fact, this option souldn't move the cursor unless you have used an insertion point.

 'cursor' => 'at_end',

will set the cursor after the last character that has been inserted. This is the default behavior of insert method (only useful when you have changed the 
default insertion point).

You can also use a reference of array with 2 values (the second is optionnal) to set the cursor position.

 'cursor' => [ 'line_0', 3 ];      # will set the cursor at the position 3 in the first line modified by insert
                                  # 'line_' is followed by the number of the inserted line
 'cursor' => [ 'line_2', 0 ];      # will position the cursor at the beginning of the 3rd inserted line
 'cursor' => [ 'line_2' ];         # will position the cursor at the end of the 3rd inserted line
 'cursor' => [ 'line_end', 0 ];    # will position the cursor at the beginning of the last inserted line
 'cursor' => [ $line, $number ];   # will position the cursor in line $line (line instance), position $number (integer)

Thanks to B<line_$number> syntax, you can indicate cursor position on lines that do not exist before your call (because the call is creating them).
You can still use an already existing line to set the cursor position (last example). In that case, you provide the L<'line' instance|Text::Editor::Easy::Line>
in first position.
With no second parameter, cursor will be set at the end of the line.
Note that 'line_0' is not really useful as the first line always exists before insertion (it's either $editor->cursor->line or the insertion
point you have chosen).

=head3 displaying after insertion, 'display' option

 'display' => [ 'line_2', { 'at' => 20, 'from' => 'middle' } ]; # the reference line is the second inserted line
 'display' => [ $editor->number(10) ];  # It's the line number 10 before the call ! Insertion can change this order...

Display option is an integrated call to the display method. As for the 'cursor' option, you may use a B<line_$number> syntax to give the reference
line that will be used for the display. Otherwise, the syntax is the same as the original display method : as 2 parameters may be provided, the
'display' option of the insert method is an array reference.

=head3 other options

There is an 'assist' option that can call specific sub to make special action each time a particular text have been inserted 
(typically, adding other text...). But the interface of this option is not yet fixed. In the same way, there will be a way to inhibit the event management
as, at present, there is one event generated by an insert (the 'change' event). Maybe 'assist' option will be replaced by a generalized
event management...

=head2 DISPLAY

    $editor->display( 
        $editor->number(23),
        {
            'at' => 'middle',
            'from' => 'middle',
        }
    );

The display method needs at least one parameter : the L<'line' instance|Text::Editor::Easy::Line> or L<'display' instance|Text::Editor::Easy::Display>.
The second, a hash reference, is optionnal.

If your editor is not visible because it's under another one (see L<Text::Editor::Easy::Zone>), you'll make it visible using L</FOCUS> 
or L</AT_TOP> methods.
The display method is used to show the editor in a precise way. Displaying an editor doesn't mean much if you don't take a reference. The reference
is the first parameter which is a line or a part of it with wrap mode enabled ('display'). When you have defined this reference, you can add options
to precise where to put this reference in the screen.

By default (with no second parameter), the top of the 'line' (or 'display) will be at the 'middle of the top', that is, it's top ordinate will be one quarter 
of the screen height.

You can change where to display the reference line with 'at' and 'from' options.

=head3 'at' option

This option gives the ordinate (which is, by default, one quarter of the screen height). You can use 'top', 'bottom' or 'middle' values or an integer.
The integer value will position the line precisely in the screen. But you should have receveid the number you give
by another method rather than have chosen it yourself : this integer is the number of pixels from the top for graphical interface but
will be the line number in console mode (in console mode, you can't be more precise than a line height).

    $editor->display( 
        $editor->number(23), { 'at' => $my_ordinate } # $my_ordinate should be an integer (or 'bottom', 'middle' or 'top')
    );

=head3 'from' option

As lines have a height, displaying a line at a precise ordinate doesn't tell what part of the line will be located at this ordinate.
By default, it's the top of the line. For the 'from' option, you can use 'top', 'middle' and 'bottom'. Note that this option may
change things a lot if the reference line is a multi-line : wrap mode and several displays for this line.

=head3 'no_check' option

By default, there may be adjustments. If the first line of the editor is under the top, or the last line over the bottom with sufficient lines to fill the screen,
your precise positioning will be changed. You can avoid adjustments by setting the 'no_check' option to true.

=head2 FOCUS

Set the focus to the editor. It will be placed on top of the screen to be visible and will have the 'focus'. Any pressed key will be redirected to it : if
the cursor belongs to a line that is displayed, it should be visible.

=head2 AT_TOP

Place the editor on top of the screen to make it visible. No action is made if editor was already on top or had the focus.

=head1 TRACE MECANISM

You can redirect standard prints and make special prints on debug files.

=head2 STANDARD PRINTS (STDOUT / STDERR)

There are 3 possible states for standard prints :

=over 4

=item *

No redirection

=item *

Redirection in a file with no default action, but specific user actions 
are possible.

=item *

Redirection in a file with a complete analysis which is saved and can be checked
later. Specific user actions are still possible.

=back

A specific user action is just a user sub that is called each time a print matches some user
conditions.

By default, there is no redirection.

With a complete analysis, a trace thread is created : this thread managed a small
database (with SDBM_File) of all prints. A link is made between the exact
position of the print in the redirection file and data (saved in other
files) explaining the print :

=over 4

=item *

Destination (STDOUT or STDERR)

=item *

Complete stack call at the time of the print

=item *

Which thread made the print and for what L<call_id|Text::Editor::Easy::Comm>.

=back

Moreover, with a complete analysis, all calls between threads are traced
the same way : an other small database, managed by the same thread, saves
information on each 'call_id'.

If we use these 2 databases together, all prints can be traced in a 'multi-threaded'
way.

=head3 Tracing STDIN / STDOUT from the start

 # Tracing from the very start : in a BEGIN bloc
 
 use Text::Editor::Easy { 
     'trace' => {
         'print' => {
             # Interface to be written
         }
     }
 };


Another possibility when redirection is not so urgent :

 use Text::Editor::Easy;
 
 # Tracing from the start of the execution (no instruction between the use and the configure)
 
 Text::Editor::Easy->configure( { 
     'trace' => {
         'print' => {
            # Configure method to be written
         }
     }
 } );

In the first case, the redirection is made in a BEGIN bloc (executed as soon as parsed) wheras in the second case, it's made during execution.

Generally, whith the "use" syntax, after the name of the module to use, you put a list of words that will 
be imported in your name space. But if the list contains just one parameter and if this parameter is a 
hash, you can do more than just import names : you can configure lots of things in a BEGIN bloc. This 
might be useful to have 'prints' from further BEGIN blocs (other 'use' calls...) catched for further 
analysis...

So, the 'configure' class method accepts a hash as single parameter. The 'configure' method can be called
automatically with the 'use' syntax : the 'use' parameter is the same as the one in the configure method.

For the 'trace mecanism', only the 'trace' key is used. The value of this key is another hash. This inside
hash accepts 'print' and 'full' keys :

=over 4

=item *

print :

=item *

full :

=back

=head3 Changing STDIN / STDOUT state

=head3 User action for 'selected prints'

=head2 SPECIAL PRINTS ON DEBUG FILES

In order to debug a special module, you can add 'special prints' on a special 'file handle'.
Let's call this file a 'debug file'.

This special file has the following properties :

=over 4

=item *

If you don't want traces any more, you can use a global option to unswitch
all the 'debug prints' without deleting the print sentences.

=item *

You can trace modules as a whole (no traces in all modules, traces in all module),
or trace them independantly (trace 'Foo.pm' and 'Bar.pm' only).

=item *

There can be 'redirection sequences' in order to debug a special function of 
the module : in this case, a new single file will contain the 'debug prints'
of the function and for only one call. After the sequence, prints are made
as usual on the global 'debug file' of the module.

=back

To sum up, a print on the 'debug file' makes one the following action :

=over 4

=item *

nothing, if traces are 'off' for this module (and if no sequence has been started)

=item *

a print on the global 'debug file' of the module (traces are 'on' for this module and no
sequence has been started)

=item *

a print on a 'debug sequence file', the number of these files being linked
to the module activity

=back

The interface is too light at present ('manage_debug_file' funtion) and 
should be set.

=cut

use Scalar::Util qw(refaddr);
use Data::Dump qw(dump);
use threads;
use threads::shared;

use Text::Editor::Easy::Comm;
use Text::Editor::Easy::Zone;
use Text::Editor::Easy::Cursor;
use Text::Editor::Easy::Screen;
use Text::Editor::Easy::Window;

my $main_loop_launched : shared;

package Text::Editor::Easy::Async;
our @ISA = 'Text::Editor::Easy';

package Text::Editor::Easy;

#Text::Editor::Easy::Comm::verify_model_thread();
my $shortcut : shared = undef;

sub import {
    my ( $self, $options_ref ) = @_;
    
    my $trace_ref = undef;

    if ( defined $options_ref ) {
        #print "Dans import options_ref = ", dump( $options_ref ), "\n";
        if ( my $ref = ref $options_ref ) {
            if ( $ref eq 'HASH' ) {
                $trace_ref = $options_ref->{'trace'};
                $shortcut = $options_ref->{'short'};
            }
        }
    }
    #print "Dans import trace_ref = ", dump( $trace_ref ), "\n";
    Text::Editor::Easy::Comm::verify_model_thread( $trace_ref );
    
    if ( defined $shortcut ) {
        eval "package $shortcut;our \@ISA = 'Text::Editor::Easy'";
    }
    
    if ( defined $options_ref ) {
        Text::Editor::Easy->configure( $options_ref );
    }
}

sub new {
    my ( $classe, $hash_ref ) = @_;

    if ( ! defined $hash_ref or ref $hash_ref ne 'HASH' ) {
        $hash_ref = {};
    }

    my $editor = bless \do { my $anonymous_scalar }, $classe;
    my $ref = refaddr $editor;

    #print "Début new : editor = $editor, ref = $ref\n";

    Text::Editor::Easy::Comm::set_ref($editor, $ref);

    my $zone = $hash_ref->{'zone'};
    if ( defined $zone and ! ref $zone ) {
        $hash_ref->{'zone'} = Text::Editor::Easy::Zone->whose_name($zone);
    }

    # Référencement de l'éditeur avec forçage éventuel de certaines données
    $hash_ref = Text::Editor::Easy->reference_editor( $ref, $hash_ref );
    
    #print "hash_ref events vaut : ", dump( $hash_ref->{'events'} ), "\n";
    
    return if ( ! defined $hash_ref->{'events'} );

    if ( ! Text::Editor::Easy::Comm::verify_graphic( $hash_ref, $editor ) ) {
        print STDERR 'Error during graphic creation of Text::Editor::Easy object\n';
        return;
    }

    #if ( defined $hash_ref->{'growing_file'} ) {
    #    print "GROWING FILE ..$hash_ref->{'growing_file'}\n";
    #}
    #print "Avant appel pour création d'un nouveau thread file_manager\n";

    my $file_tid = $editor->create_new_server(
        {
            'use'     => 'Text::Editor::Easy::File_manager',
             'package' => 'Text::Editor::Easy::File_manager',
             'methods' => [
                'delete_line',
                'get_line',
                'line_text',
                'modify_line',
                'new_line',
                'next_line',
                'previous_line',
                'save_internal',
                'query_segments',
                'revert_internal',
                'read_next',
                'read_until',
                'read_until2',
                'create_ref_current',
                'init_read',
                'ref_of_read_next',
                'save_action',
                'save_line_number',
                'get_line_number_from_ref',
                'get_ref_for_empty_structure',
                'line_seek_start',
                'line_set_info',
                'line_get_info',
                'empty_internal',
                'save_info',
                'load_info',
                'close',
                'editor_number',
                'editor_search',
                'save_info_on_file',
                'growing_update',
                'line_add_seek_start',
                'dump_file_manager',
                'insert_bloc',
            ],
            'object' => [],
            'init'   => [
                'Text::Editor::Easy::File_manager::init_file_manager',
                $ref,
                $hash_ref->{'file'},
                $hash_ref->{'growing_file'},
                $hash_ref->{'save_info'},
                $hash_ref->{'bloc'},
            ],
            'name' => 'File_manager',
        }
    );
    
    $editor->set_synchronize();
    my $focus = $hash_ref->{'focus'};
    if ( ! defined $focus ) {
        #print "Création de l'éditeur ", $editor->name, " : mise au premier plan (appel at_top)\n";
        #print "    ===> id de cet éditeur avant appel at_top : ", $editor->id, "\n";
        $editor->at_top($hash_ref);
        #print "Fin de la mise au premier plan pour $editor\n";
    }
    elsif ( $focus eq 'yes' ) {
        $editor->focus($hash_ref);
    }

    my $tid = threads->tid;
    if ( $hash_ref->{sub} ) {

        # On demande la création d'un thread supplémentaire
        my $thread = $editor->create_client_thread( $hash_ref->{sub} );
        #$editor->set_synchronize();
        if ( $tid == 0 and ! $main_loop_launched) {
            $main_loop_launched = 1;
            #print "Appel de la main loop (méthode new)\n";
            Text::Editor::Easy->manage_event;
            #print "Fin de la main loop (méthode new)\n";
            Text::Editor::Easy::Comm::untie_print;
            return $editor;
        }
    }
    
    if ( $tid == 0 and ! $hash_ref->{'sub'} and ! $main_loop_launched ) {
        # Initialisations to allow the normal use of the interface with the object returned
        my $height = $hash_ref->{'height'};
        my $width = $hash_ref->{'width'};
        if ( defined $height and defined $width ) {
            $editor->resize( $width, $height );
        }
        else { # Il faut vérifier la taille de la zone éventuellement donnée
            $editor->resize( 1, 1 );
        }
    }

    return $editor;
 }

sub kill {
    my ( $self ) = @_;
    
    $self->graphic_kill;
    # Suppression des données sauvegardées pour cet éditeur dans Data
    # Suppression de toutes les lignes stockées pour cet éditeur dans tous les threads... dur
    # Fermeture du fichier et destruction du thread File_manager
}

 sub file_name {
    my ($self) = @_;

    return Text::Editor::Easy->data_file_name($self->id);
}

sub name {
    my ($self) = @_;

    return Text::Editor::Easy->data_name($self->id);
}

sub events {
    my ($self, $name) = @_;
    
    my $id = '';
    $id = $self->id if ( ref $self );

    return Text::Editor::Easy->data_events($id, $name);
}

sub sequences {
    my ($self, $name) = @_;
    
    my $id = '';
    $id = $self->id if ( ref $self );

    return Text::Editor::Easy->data_sequences($self->id, $name);
}

sub revert {
    my ( $self, $line_number ) = @_;

#print "Demande de restauration du fichier ", $file_name{ refaddr $self }, "\n";
    my $wait = $self->revert_internal;

    if ( $line_number eq 'end' ) {
        return
          $self->previous_line;    # On renvoie la référence à la dernière ligne
    }
    else {
        return $self->go_to($line_number)
          ;    # On renvoie la référence du numéro de la ligne demadée
    }
}

sub save_action {
    my ( $self, $line_number, $pos, $insert, $key, $replace ) = @_;

    print "Après appel :$line_number:$pos:$insert:$key;$replace:\n";

    #print "Dans save_action :$who:$line_number:$pos:$key:$insert\n";
    $self->append(
        "line $line_number,$pos ,$insert :" . $key . ":, :" . $replace . ":" );
}

sub save {
    my ( $self, $file_name ) = @_;

    return $self->save_internal($file_name);

# A revoir dans le principe : il faut référencer ce changement dans Data qui doit générer un nouveau type d'évènement
# Cet évènement doit être catché par le Tab principal qui changera le titre de la fenêtre principale
# Mais Data pourra décider de le faire lui-même (changer le titre) si il n'y a aucune redirection de cet évènement
# et une seule zone (que faire si plusieurs zones sans redirection ?....)

    #if ( $file_name ) {
    #        $self->change_title($file_name);
    #}
}

sub regexp {

# entrée :
#        - regexp : expression régulière perl à rechercher
#        - line_start : ligne fichier de début de recherche
#        - pos_start : position de début de la recherche dans la ligne fichier de début de recherche
#        - line_stop : ligne fichier de fin de recherche (si égale à line_start, on fait un tour complet : pas d'arrêt immédiat)
#        - pos_stop : position de fin de la recherche dans la ligne fichier de fin de recherche

    my ( $self, $exp, $options_ref ) = @_;

    return if ( !defined $exp );

    #print "Demande de recherche de $exp\n";
    my $ref;
    my $cursor = $self->cursor;
    my $line   = $options_ref->{'line_start'};
    if ( defined $line ) {
        $ref = $line->ref if ( ref $line eq 'Text::Editor::Easy::Line' );
    }
    if ( !defined $ref ) {
        $line = $cursor->line;
        $ref  = $line->ref;
    }

    #print "LINE $line\n";
    my $text = $self->line_text($ref);
    return
      if ( !defined $text )
      ;    # La ligne indiquée a été supprimée ... on ne peut pas s'y référer
           #print "Ligne de départ de la recherche |$text|\n";

    my $pos = $options_ref->{'pos_start'};
    if ( !defined $pos ) {
        $pos = $cursor->get;
    }
    else {    # Vérification de la cohérence
        if ( $pos > length($text) ) {
            $pos = length($text);
        }
    }

    #print "Position de départ de la recherche |$pos|\n";

    #my $regexp = qr/$exp/i;
    my $regexp = $exp;
    print "REGEXP $regexp\n";

    my $end_ref;
    my $line_stop;
    if ( defined( $line_stop = $options_ref->{'line_stop'} ) ) {
        if ( ref $line_stop eq 'Text::Editor::Easy::Line' ) {
            $end_ref = $line_stop->ref;
        }
    }
    if ( !defined $line_stop ) {
        $line_stop = $line;
    }

    #print "LINE_STOP : $line_stop\n";
    my $ref_editor = refaddr $self;
    pos($text) = $pos;
    if ( $text =~ m/($regexp)/g ) {
        my $length    = length($1);
        my $end_pos   = pos($text);
        my $start_pos = $end_pos - $length;

#print "Trouvé dans la ligne de la position $start_pos à la position $end_pos\n";

        #print "SELF $self\n";
        my $line = Text::Editor::Easy::Line->new( $self, $ref, );

        return ( $line, $start_pos, $end_pos );
    }

    #print "Pas trouvé à partir de la position souhaitée\n";

    $end_ref = $ref if ( !defined $end_ref );
    my $desc = threads->tid;
    $text =
      $self->read_until2( $desc,
        { 'line_start' => $ref, 'line_stop' => $end_ref } );

    pos($text) = 0;
    while ( defined($text) ) {

        #print "$text\n";
        if ( $text =~ m/($regexp)/g ) {
            my $length    = length($1);
            my $end_pos   = pos($text);
            my $start_pos = $end_pos - $length;

#print "Trouvé dans la ligne de la position $start_pos à la position $end_pos\n";
# Récupération de la référence de la ligne à faire
#print "TEXTE de la ligne trouvée : $text\n";
            my $new_ref = $self->create_ref_current($desc);

            #print "Référence de la ligne trouvée : $new_ref\n";

            my $line = Text::Editor::Easy::Line->new( $self, $new_ref, );
            return ( $line, $start_pos, $end_pos );
        }
        $text = $self->read_until2( $desc, { 'line_stop' => $end_ref } );
    }

    # Début de la ligne $ref à faire ici...

    return;    # Rien trouvé...
}

sub search {
    my ( $self, $exp, $options_ref ) = @_;

   if ( ! ref $exp ) {
     return if ( $exp eq q{} );
     $exp =~ s/\\/\\\\/g;
     $exp =~ s/\//\\\//g;
     $exp =~ s/\(/\\\(/g;
     $exp =~ s/\[/\\\[/g;
     $exp =~ s/\{/\\\{/g;
     $exp =~ s/\)/\\\)/g;
     $exp =~ s/\]/\\\]/g;
     $exp =~ s/\}/\\\}/g;
     $exp =~ s/\./\\\./g;
     $exp =~ s/\^/\\\^/g;
     $exp =~ s/\$/\\\$/g;
     $exp =~ s/\*/\\\*/g;
     $exp =~ s/\+/\\\+/g;
     $exp = qr/$exp/;
    }
    else {
        return if ( $exp == qr// );
   }
   my ( $start_line, $stop_line );
    if ( ! defined $options_ref or ref $options_ref ne 'HASH' ) {

        if ( ! defined $options_ref ) {
            $options_ref = {};
        }
        $start_line = $options_ref->{'start_line'};
        $stop_line = $options_ref->{'stop_line'};
    }
    else {
        $start_line = $options_ref->{'start_line'};
        $stop_line = $options_ref->{'stop_line'};
        if ( defined $start_line and ref $start_line eq 'Text::Editor::Easy::Line' ) {
            $start_line = $start_line->ref;
            $options_ref->{'start_line'} = $start_line;
        }
        if ( defined $stop_line and ref $stop_line eq 'Text::Editor::Easy::Line' ) {
            $stop_line = $stop_line->ref;
            $options_ref->{'stop_line'} = $stop_line;
        }
    }
    
    my $pos = 0;
    if ( ! defined $start_line ) {
        # On utilise AUTOLOAD pour récupérer une référence à une ligne directement
        ( $options_ref->{'start_line'}, $pos ) = cursor_get( $self );
    }
    if ( ! defined $options_ref->{'start_pos'} ) {
        $options_ref->{'start_pos'} = $pos;
    }

    print "Avant appel editor_search : $exp\n", dump($options_ref), "\n";;
    my ( $ref, $start_pos, $end_pos ) = $self->editor_search( $exp, $options_ref );
    my $line = Text::Editor::Easy::Line->new( $self, $ref, );
    return ( $line, $start_pos, $end_pos, $exp );
}

sub visual_search {
        my ( $self, $exp, $line, $start ) = @_;

        
        return $self->editor_visual_search($exp, $line->ref, $start );
}

sub next_search {
    my ($self) = @_;

    my $ref_editor = refaddr $self;
    my $hash_ref   = $self->ask2('load_search');

    return if ( !defined $hash_ref );
    my $ref_start = $hash_ref->{'line_start'};
    $hash_ref->{'line_start'} =
      Text::Editor::Easy::Line->new( $self, $ref_start, );
    my $ref_stop = $hash_ref->{'line_stop'};
    $hash_ref->{'line_stop'} =
      Text::Editor::Easy::Line->new( $self, $ref_stop, );

    my ( $line, $start, $end ) = $self->regexp( $hash_ref->{'exp'}, $hash_ref );
    if ($line) {
        $self->display($line);
        $self->cursor->set( $end, $line );
    }
}

sub number {
# First step, integration in File_manager (only one traced call)
# But not yet optimized in File_manager : the file is not yet read once at start

    my ( $self, $line, $options_ref ) = @_;

    my $ref_line = $self->editor_number( $line, $options_ref );
    return if ( ! defined $ref_line );
    return Text::Editor::Easy::Line->new( $self, $ref_line, );
    
    my $desc = threads->tid;
    
    $self->init_read($desc);
    my $text = $self->read_next($desc);

    my $current;
    while ( defined($text) ) {
        $current += 1;
        if ( $current == $line ) {
            my $new_ref = $self->create_ref_current($desc);
            $self->save_line_number( $desc, $new_ref, $line );
            my $ref = refaddr $self;
            return Text::Editor::Easy::Line->new( $self, $new_ref, );
        }
        return if ( anything_for_me() );
        $text = $self->read_next($desc);
    }

# La ligne n'a pas été trouvée : elle n'existe pas (pas assez de lignes dans le fichier)
    return;
}

sub append {
    my ( $self, $text ) = @_;

    my ( $ref, $new_text ) = $self->previous_line();
    my $OK = $self->new_line( $ref, "after", $text );
}

sub AUTOLOAD {
    return if our $AUTOLOAD =~ /::DESTROY/;

    my ( $self, @param ) = @_;

    my $what = $AUTOLOAD;
    #$what =~ s/^Text::Editor::Easy:://;
    #$what =~ s/^Async:://;
    #$what =~ s/^${shortcut}::// if ( defined $shortcut );
    $what =~ s/^.*:://;
    
    # Following call not to be shown in trace
    return Text::Editor::Easy::Comm::ask2( $self, $what, @param );
}

sub delete_key {
    my ( $self, $text, $pos, $ref ) = @_;

    if ( $pos == length($text) ) {

        # Caractère supprimé : <Return>
        my ( $next_ref, $next_text ) = $self->next_line($ref);

        $text .= $next_text;

        $self->modify_line( $ref, $text );

        print "Avant appel delete_line, next_ref = $next_ref\n";
        $self->delete_line($next_ref);
        my $concat = "yes";
        return ( $text, $concat );
    }
    else {
        $text = substr( $text, 0, $pos ) . substr( $text, $pos + 1 );

        $self->modify_line( $ref, $text );
        return ( $text, "false" );    # $concat vaut "false"
    }
}

sub erase_text {                      # On supprime un ou plusieurs caractères
    my ( $self, $number, $text, $pos, $ref ) = @_;

    if ( length($text) - $pos > $number ) {
        $text = substr( $text, 0, $pos ) . substr( $text, $pos + $number );

        $self->modify_line( $ref, $text );
        return ( $text, "false" );    # $concat vaut "false"
    }
    else {
        $text = substr( $text, 0, $pos );
        $self->modify_line( $ref, $text );
        return ( $text, "false" );    # $concat vaut "false"
    }
}

my %cursor;                           # Référence au "sous-objet" cursor
# Danger : il n'y a qu'un seul curseur par objet "Text::Editor::Easy"
# ==> enlever cette limite

sub cursor {
    my ($self) = @_;

    my $ref    = refaddr $self;
    my $cursor = $cursor{$ref};
    return $cursor if ($cursor);

    $cursor = Text::Editor::Easy::Cursor->new($self);

    $cursor{$ref} = $cursor;
    return $cursor;
}

my %screen;    # Référence au "sous-objet" window
# Objet screen à migrer vers zone et window

sub screen {
    my ($self) = @_;

    my $ref    = refaddr $self;
    my $screen = $screen{$ref};
    return $screen if ($screen);

    $screen = Text::Editor::Easy::Screen->new($self);

    $screen{$ref} = $screen;
    return $screen;
}

my %window;    # Référence au "sous-objet" window

sub window {
    my ($self) = @_;

    my $ref    = refaddr $self;
    $ref = '' if ( ! defined $ref );
    my $window = $window{$ref};
    return $window if ($window);

    $window = Text::Editor::Easy::Window->new($self);

    $window{$ref} = $window;
    return $window;
}


# Méthode insert : renvoi d'objets "Line" au lieu de références numériques (cas du wantarray)
sub insert {
    my ( $self, $text, $options_ref ) = @_;

    if ( defined $options_ref ) {
        if ( my $line = $options_ref->{'line'} ) {
            if ( ref $line eq 'Text::Editor::Easy::Line' ) {
                $options_ref->{'line'} = $line->ref
            }
        }
        if ( my $cursor_ref = $options_ref->{'cursor'} ) {
            if ( ref $cursor_ref eq 'ARRAY' ) {
                my $line = $cursor_ref->[0];
                if ( $line =~ /^(\d+)$/ ) {
                    $line = "line_$1";
                }
                elsif ( ref $line eq 'Text::Editor::Easy::Line' ) {
                    $line = $line->ref;
                }
                $options_ref->{'cursor'}[0] = $line;
            }
        }
        if ( my $display_ref = $options_ref->{'display'} ) {
            if ( ref $display_ref eq 'ARRAY' ) {
                my $line = $display_ref->[0];
                if ( $line =~ /^(\d+)$/ ) {
                    $line = "line_$1";
                }
                elsif ( ref $line eq 'Text::Editor::Easy::Line' ) {
                    $line = $line->ref;
                }
                $options_ref->{'display'}[0] = $line;
            }
        }
    }

    if ( !wantarray ) {
        my $ref_last =  $self->ask2( 'insert', $text, $options_ref );
        return Text::Editor::Easy::Line->new( $self, $ref_last );
    }
    elsif ( ref($self) eq 'Text::Editor::Easy::Async' )
    {    # Appel asynchrone, insert ne renvoie pas une référence de ligne
        return $self->ask2( 'insert', $text, $options_ref );
    }
    else {
        my @refs = $self->ask2( 'insert', $text, $options_ref );
        my @lines;
        for (@refs) {

# Création d'un objet ligne pour chaque référence (dans le thread de l'appelant)
            push @lines, Text::Editor::Easy::Line->new(
                $self,
                $_,
            );
        }
        return @lines;
    }
}

sub display {
    my ( $self, $line, $options_ref ) = @_;

    $self->ask2( 'display', $line->ref, $options_ref );
}

sub last {
    my ($self) = @_;

    my ($id) = $self->previous_line;

    return Text::Editor::Easy::Line->new( $self, $id, );
}

sub first {
    my ($self) = @_;

    my ( $id, $text ) = $self->next_line;

    #print "Dans first : $self|", $self->id, "|$id|$text|\n";
    return Text::Editor::Easy::Line->new(
        $self,
        $id,
    );
}

# Ecrasement de la méthode async du package thread mais pas moyen de la
# désimporter (no threads 'async') et pas de meilleur nom que async...
# ==> Avertissement prototype mismatch
no warnings;

sub async {
    my ($self) = @_;

    my $async = bless \do { my $anonymous_scalar }, 'Text::Editor::Easy::Async';
    my $id = Text::Editor::Easy::Comm::id($self);
    Text::Editor::Easy::Comm::set_ref($async, $id);
    return $async;
}
use warnings;

sub slurp {
    my ($self) = @_;

    # This function is not safe in a multi-thread environnement :
    # you may have in return something that has never existed
    # But if you know what you are doing...
    my $file;

    my $line   = $self->first;
    $file = $line->text;
    $line = $line->next;
    while ($line) {
        $file .= "\n" . $line->text;
        $line = $line->next;
    }
    return $file;
}

sub get_in_zone {
    my ( $self, $zone, $number ) = @_;

    my @ref = Text::Editor::Easy->list_in_zone($zone);
    if ( scalar @ref < $number + 1 ) {
        return;
    }
    return Text::Editor::Easy->get_from_id( $ref[$number] );
}

sub whose_name {
    my ( $self, $name ) = @_;

    my $id = Text::Editor::Easy->data_get_editor_from_name($name);
    return Text::Editor::Easy->get_from_id( $id );
}

sub whose_file_name {
    my ( $self, $file_name ) = @_;

    my $id = Text::Editor::Easy->data_get_editor_from_file_name($file_name);
    return Text::Editor::Easy->get_from_id( $id );
}

sub last_current {
    my ( $self ) = @_;

    my $id = Text::Editor::Easy->data_last_current();
    return Text::Editor::Easy->get_from_id( $id );
}

sub zone {
    my ( $self ) = @_;
    
    my $id = $self->id;
    return Text::Editor::Easy->data_zone($id);
}

=head1 FUNCTIONS

=head2 append

Insert text at the end of the "Text::Editor::Easy" instance. Not yet finished (only one line can be inserted, now).

=head2 cursor

Returns a Cursor object from a "Text::Editor::Easy" instance. See "Text::Editor::Easy::Cursor" for a list of methods
available for the Cursor object. 

=head2 delete_key

Delete one character. Used with "Text::Editor::Easy::Abstract". Should not be part of the interface...

=head2 display

Allow the use of Line object with the "display" instance method : the internal reference of the Line object, an integer, 
is given to the display sub of "Text::Editor::Easy::Abstract". Line objects are scalar reference (for encapsulation),
and they can't be recovered between threads after a dump of the structure (the substitution is done by the calling
thread but the "display execution" is done by the graphical thread with the help of the "File_manager" thread).

=head2 erase_text

Delete one or more characters. Used with "Text::Editor::Easy::Abstract". Should not be part of the interface...

=head2 file_name

In scalar context, this method returns the name of the file (without the path) if any (undef if the Text::Editor::Easy instance
is a memory edition).
In list context, returns the absolute path, the file name (without path), the relative path (to current path) and the name of the instance.

=head2 first

Returns a Line object that represents the first line of the "Text::Editor::Easy" instance.

=head2 get_in_zone

Given the name of a Zone object and a number, this class method returns the instance of the Text::Editor::Easy object
if it is found. Undef otherwise : 

=head2 get_line_number_from_ref

=head2 last

=head2 last_current

Class method : returns the editor instance who had the focus when ctrl-f was pressed.

=head2 manage_event

=head2 name

=head2 next_search

=head2 number

=head2 regexp

=head2 revert

=head2 save

=head2 save_action

=head2 screen

=head2 search

=head2 slurp

=head2 visual_search

Call to editor_visual_search : replacement of line object (scalar reference, memory adress specific to one thread) by the internal reference of the line (common for all threads).

=head2 whose_file_name

Class method. Returns a "Text::Editor::Easy" object whose file name is the parameter given.

=head2 whose_name

Class method. Returns a "Text::Editor::Easy" object whose name is the parameter given.

=head2 kill

Maybe destroy would be a better name...

=cut

=head1 AUTHOR

Sebastien Grommier, C<< <sgrommier at free.fr> >>

=head1 BUGS

This module is moving fast. Bugs are not yet managed.

Maybe you'd like to know that I started writing this Editor from scratch. I didn't take a single line to any existing editor. The very few
editors I had a glance at were too tightly linked to a graphical user interface. Maybe you obtain faster execution results like that,
but you do not recycle anything. I wanted an engine which you could plug to, a little like perl has been designed.

=head1 SUPPORT

The best support for this module is the "Editor.pl" program. Read the README file to install the module
and launch the "Editor.pl" program.

To be in an editor allows you to display information interactively. Full documentation will be accessible from here with version 1.0.

In future versions, there will be a "video mode" : perl code to make the images and ogg files for the sound. These videos will cost almost
nothing in space compared to actual compressed videos (the sound will be, indeed, the heaviest part of them).

All softwares should include "help videos" like what I describe : it would prove that what you are about to use is easy to manipulate and it
would give you a quick interactive glance of all the possibilities. But most softwares are awfully limited (or just don't have the ability) when
you want to drive them from a private program (yet, interactively, it's often very pretty, but I don't mind : I want POWER !). In my ill
productive point of view, most softwares should be written again...

This is the reason why I'm designing the editor module and the editor program at the same time : the program asks for new needs, and the
editor module grows according to these needs. When the editor program will be usable, the module should be powerful enough to be used
by anybody, including the RAD tool and the applications generated by the RAD tool.

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;