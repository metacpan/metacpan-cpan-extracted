package Text::Editor::Easy::Events;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Events - Manage events linked to user code : specific code is referenced and called here.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

=head1 INTRODUCTION

'Editor' instances will stand for 'Text::Editor::Easy' instances.

'Editor' instances have already a default management for a few events : mouse clic (set new cursor position), key press (insert or delete text),
mouse drag (select text), resize.... What you may want to do when you define your special code in response to events must be explained :

=over 4

=item *

Link code to an event not managed by default (for instance, the mouse motion)

=item *

Add an action to an already managed event

=item *

Inhibit the default action and make your own instead

=item *

Just inhibit the default action (here you don't write code)

=item *

Have your specific code executed in an asynchronous way (by a specific thread) in order to make a non freezing huge task

=item *

Have you specific code executed by a specific thread in a synchronous way

=item *

Have all these possibilities defined during the 'editor' instance creation or later.

=item *

Link more code to an already linked event (more than one specific sub for only one event) ...

=back

As you see, event management is a nightmare. What could be the interface that would enable all this and would still be usable ?

As usual, easy things should be done lazily but difficult tasks should always be possible with, of course, a little more options to learn.

=head1 EASY THINGS

 my $editor = Text::Editor::Easy->new( 
    {                                     # start of editor new options
        'file'   => 'my_file.t3d',        # option 'file' has nothing to do with event management
        'events' => {                     # events declaration
            'clic' => {                   # first specific management, 'clic' event
                'sub' => 'my_clic_sub',
            },                            # end of clic event
            'motion' => {                 # second specific management, 'motion' event
                'sub' => 'my_motion_sub',
                'use' => 'My_module',     # as in perl 'use My_module' : without .pm extension
            },                            # end of motion event
        }                                 # end of events declaration
    }                                     # end of editor new options
 );                                       # end of new
 
 [...]
 
 sub my_clic_sub {
     my ( $editor, $clic_info_ref ) = @_;
 
     [...]
 }


=head2 'events' option

You can link your subs to events during the 'editor' instance creation with the 'events'
option. This option takes a hash as a value. The keys of this hash are the name of the
events : in the example, 'clic' and 'motion' events are managed. So, the first thing 
you have to know is the name of the events : 

=over 4

=item *

B<clic>, happens when you press the left button of your mouse in the editor

=item *

B<motion>, happens when you move your mouse above the editor

=item *

B<drag>, happens when you move your mouse above the editor with the left button of your mouse pressed

=item *

B<change>, happens when the text of the editor is changed (text added, deleted or replaced).

=item *

B<cursor_set>, happens when the cursor position is changed whatever the cause (insert,
clic, direction keys, program,...)

=item *

B<wheel>, happens when the user rolls the mouse wheel

=item *

B<right_clic> and B<double_clic>, other mouse events

=item *

key events have to be named more precisely (for instance, 'alt_b_key' or 'ctrl_e_key')

=back

=head2 'sub', 'use' and 'package' options of  one particular event in 'events' option

For each event managed, you have another hash which will contain, at least, the 'sub' option. Yes, this makes quite a lot of hashes, but they are
the best way to make easy interfaces : you don't have to learn arbitrary positions (just think of other major langages), if the key names are well
chosen, you learn the interface just reading an example and your code is auto-documented. I wonder how can other langages still exist without hashes...

Now, if you give nothing more than the 'sub' option, your sub should be visible and in the 'main' package. This point could be explained further.
For simple things, you write your 'sub' in the same perl program file that makes the 'use Text::Editor::Easy;' call and you don't use perl package instruction.

If your program is more complex with more than one file, you can add the 'use' option which should indicate the name of a module that contains your sub.
Be careful ! The default package is now assumed to have the same value as the module. If this is not true, you'll have to add 'package' option too :

 'motion' => {                     # 'motion' event of 'events' option
     'sub'     => 'my_motion_sub',
     'use'     => 'My_module',
     'package' => 'My_package',    # sub 'my_motion_sub' of 'My_module' is
                                   #     after a 'package My_package;' declaration
 },                                # end of 'motion' event

If you have used the perl 'package' instruction in your main program, you may use only the 'package' option without the 'use' option (in order not to
have the 'main' default package assumed).

=head2 What about your specific 'sub' ?

Here are the 2 remaining things that have to be known :

=over 4

=item *

What will your sub receive ?

=item *

What should return your sub ?

=back

=head3 received information

 sub my_clic_sub {
     my ( $editor, $info_ref ) = @_;             # $info_ref is a hash reference
 
     $editor->insert(
         ' useless text ',
         {
             'line' => $info_ref->{'line'},      # The insertion point will be
             'pos'  => $info_ref->{'pos'},       # the mouse clic position
         }
     );                                          # End of insert call
 }

You always receive 2 parameters :

=over 4

=item *

The 'editor' instance that has received the event.

=item *

A hash reference that contains information relative to the event.

=back

Of course, you can't expect the information to be the same for a key press and for a mouse motion. The number and names of the hash keys 
will then depend on the event itself. L<All keys are explained for each event here|/EVENT LIST>. But it's easier to see all the possibilities for
the keys and guess what you'll get for your event :

=over 4

=item *

'line' : a L<'line' instance|Text::Editor::Easy::Line>.

=item *

'pos' : a position in that line

=item *

'x' : an absisse (for 'hard' events)

=item *

'y' : an ordinate (for 'hard' events)

=back

=head3 return value, 'action' option introduction

For easy things, your return value is not used. After your specific sub has been executed, the default management will be done (if any) with the
same event information ($info_ref hash) that you have received.

But if you want your sub to be the last thing to be done in response to the event, you can add the 'action' option with the 'exit' value :

 my $editor = Text::Editor::Easy->new(
     {
         'events' => {
             'clic' => {
                 'sub'    => 'my_clic_sub',
                 'action' => 'exit',            # nothing will be done after 'my_clic_sub'
             },
         }
     }
 );

In this case, your sub will B<always> be the last executed action. Sometimes, you would like to decide, according to the event information (so
dynamically), if you want to go on or not. See here for L<dynamic exit|/'ACTION' OPTION>.

In a more vicious way, you may want to change the values of the event information in order to change the data on which the default management
will work. Again, the L<'action' option|/'ACTION' OPTION> gives you the power to lie.

A good easy thing would be that if 'action' option (with 'exit value) is present without the 'sub' option, then nothing is executed, just an exit is made :

 'events' => {
     'clic' => {
         'action' => 'exit',         # nothing will be done, no 'sub' option
     },
 }                                   # end of events declaration

As you see, 'sub' option is, in fact, not mandatory.

=head2 easy things conclusion

Nothing has been said about threads and dynamic event linking, but this is quite normal for the easy part of the interface.
Still you can do half of what has been introduced at L<the beginning|/INTRODUCTION>.

In an easy way, all events are done synchronously by the 'Graphic' thread : the 'Graphic' thread will have to complete your sub. So you may
feel desperate if you have a huge task to do in response to a user event and if you still want your application to remain responsive : which seems
incompatible, but...

=head1 EVENT INTERFACE SUM UP

=head2 Instance creation

There are 2 options in the 'new' method that deals with events :

=over 4

=item *

L<'events' option|/'events' option>. For each event described in the 'events' option,
here are all the possible keys :

=over 4

=item *

L<sub|/'sub', 'use' and 'package' options of one particular event in 'events' option>

=item *

L<use|/'sub', 'use' and 'package' options of one particular event in 'events' option>

=item *

L<package|/'sub', 'use' and 'package' options of one particular event in 'events' option>

=item *

L<action|/'ACTION' OPTION>

=item *

L<sequence|/'sequence' option in a 'true event'>

=item *

L<thread|/'thread' option>

=item *

L<create|/'create' option>

=item *

L<sync|/'sync' option>

=item *

L<code|/dynamic designing, 'code' option>

=item *

parm, to be done

=back

=item *

L<'sequences' option|/'sequences' key of the 'new' method>

=back

=head2 Instance update

In order to update event management, here are the methods :

=over 4

=item *

L<set_event method|/set_event method>

=item *

L<set_events method|/set_events method>

=item *

L<set_sequence method|/set_sequence method>

=item *

L<set_default method|/set_default class method>

=back

=head2 Information on events

In order to inquire the event management, here are the methods :

=over 4

=item *

L<events method|/events method>

=item *

L<sequences method|/sequences instance method>

=back

=head1 EVENT NAMES AND SEQUENCE

=head2 sequence of a 'true event', 'labels'

For each 'true event', a sequence of actions is done. Each action can be either an event action
(= user action = private label) or a default action, named with a 'label'. For instance, the 'clic' sequence of the 'clic' 'true event'
contains the following actions :

=over 4

=item *

B<_calc_line_pos>, default action, calculates 'line' and 'pos' from 'x' and 'y' coordinates of the 'clic'.

=item *

B<any_any_clic>, user action (generated event)

=item *

B<any_clic>, user action (generated event)

=item *

B<clic>, user action (generated event)

=item *

B<_test_resize>, default action, starts a drag sequence in order to resize the editor zone (only done
if the cursor shape looks like a double arrow, either vertical or horizontal).

=item *

B<_set_cursor>, default action, unselects previously selected text, positions cursor, sets the focus. 

=item *

B<any_after_clic>, user action (generated event)

=item *

B<after_clic>, user action (generated event)

=back

So there is a big difference between a 'true event' (the 'clic' made by the user) and an 'event
action' (code linked to an event but at a precise moment in the sequence). In the previous 'clic'
example, you have to choose between 5 event names to place your user action in the sequence.

Each user action is linked using the label of the generated event. For instance, if you want to use
the 'after_clic' event instead of 'clic' event, you just have to write :

 my $editor = Text::Editor::Easy->new( 
    {
        'events' => {
            'after_clic' => {             # 'after_clic' event, done after default
                'sub' => 'my_sub',        # management (generated 'clic' event is done before)
            },
        }
    }
 );

Still, the 'after_clic' is not a 'true event', it's just an action in the sequence. The difference
is important because you can L<define your own sequence|/changing the sequence> but you'll have to
use the 'true event' name to do that.

In the sequence, you can easily guess which is an event and which is a default action thanks to the
beginning : everything that begins with '_' is a default action otherwise, it's a generated event.

A generated event is just a predefined private label : the label is already defined in
the default sequence but you have to link your action to that label (no action by default).

When you create your own sequence, everything that does not start with a '_' is considered as a private
label and private code linked to that label is searched.

So event names used with the 'events' option are just private labels contained in a 'true event'
sequence.

In conclusion, by default, the 'true event' 'clic' is linked to a sequence that contains 5 possible 
private labels (named 'clic', 'after_clic', ...).

=head2 modifier keys

The modifier keys, which are 'alt', 'ctrl' or 'shift', bring complexity in a too simple event management.
In the following explanations 'modifier keys' will be called 'meta keys'...because it's shorter.

As you may know, these keys or any combination of these keys can be associated with a standard key
press, mouse clic, mouse motion, ... and you could think of that in 2 ways :

=over 4

=item *

the event mixed with a meta-key is the same, there is just more information

=item *

the event mixed with a meta-key is another one and should be named differently

=back

As a programmer, the first approach can lead to single sub managing different events (which is not very clear), but the second one can lead
to multi-declaration pointing to the same sub, which is too verbose (and not very clear in the end).

So let's have the 2 possible ways : it's your business to choose the one that is the more efficient according to your wish. For any combination of
'meta-keys', you'll have to add B<any_> prefix. For a particular combination, you'll have to add the 'combination string' as prefix, for instance 
B<alt_> or B<ctrl_shift_>. Note that in the 'combination string', 'meta-keys' are listed in alphabetic order : 'alt', 'ctrl' and then 'shift'.

As an example, you could press 'alt' when making a 'clic' with your mouse. The 'true event' name
will be 'alt_clic' and the sequence will be the following :

=over 4

=item *

B<_calc_line_pos>, default action, calculates 'line' and 'pos'

=item *

B<any_any_clic>, user event

=item *

B<any_clic>, user event, 'clic' with any combination of 'meta_keys'

=item *

B<alt_clic>, user event, only done when 'alt' key is pressed during the 'clic'

=item *

B<any_after_clic>, user event, 'after_clic' with any combination of 'meta_keys'

=back

In conclusion, the 'true event' 'alt_clic' is linked to a sequence that contains 4 private
labels (named 'any_clic', 'alt_clic', ...).

The 'any_clic' is then done for a simple 'clic' and for any combination of meta-keys (including 'alt').

 my $editor = Text::Editor::Easy->new( 
    {
        'events' => {
            'alt_clic' => {               # 'alt_clic' event, 'alt' key pressed
                'sub' => 'my_alt_sub',
            },
            'any_clic' => {               # 'any_clic' event, whatever meta-keys
                'sub' => 'my_any_sub',
            },
        }
    }
 );

=head2 about 'any_any_clic'

'clic' is in fact the left simple clic. Right simple clic and left double clic are often used too.
For instance, the true event 'shift right simple clic', named 'shift_right_clic',
has the following sequence :

=over 4

=item *

B<_calc_line_pos>, default action, calculates 'line' and 'pos'

=item *

B<any_any_clic>, user event, any type of 'clic', with any meta-keys

=item *

B<any_right_clic>, user event, 'right_clic' with any combination of 'meta_keys'

=item *

B<shift_right_clic>, user event, only done when shift meta-key is pressed

=back

B<any_any_clic> is then done whatever the 'clic' (simple, double or right) and whatever the meta-keys.

=head2 changing the sequence

=head3 'sequence' option in a 'true event'

During instance creation, if you want a different sequence from the default one, you can define
your own with the 'sequence' option in the 'true event' declaration.

In the sequence, each label that does not start with '_' is considered as an event (= private label).

So you can create your
own events in your sequence. But this is not a real event creation, because your event depends
on a 'true event' to be generated. Creating a 'true event' will be another matter.

 my $editor = Text::Editor::Easy->new( 
    {
        'events' => {
            'alt_clic' => {
                'sequence' => [            # changing 'alt_clic' sequence
                    '_calc_line_pos',      # getting 'line' and 'pos'
                    'my_foo_clic',         # private label (declared in this sequence)
                    '_set_cursor',         # not done by default 'alt_clic'
                ],
            },
            'my_foo_clic' => {             # 'my_foo_clic' label definition, whatever the sequence
                'sub'     => 'foo_sub',    # 
                'thread'  => 'Foo',        # complete interface possible as any predefined event
            },
        }
    }
 );

Defining such a sequence is somewhat 'static'. For each 'alt_clic' event of this instance, this
sequence will be used. You may want to have very specific sequences from time to time, and use 
the 'default' one or your 'static' one the rest of the time. These L<dynamic sequences|/'reentrant'
value> are possible thanks to the 'action' option.

=head3 'sequences' key of the 'new' method

The previous example could have been written like this as there is just a sequence defined for the
'alt_clic' event (no action is really done) :

 my $editor = Text::Editor::Easy->new( 
    {
        'sequences' => {
            'alt_clic' => [                # changing 'alt_clic' sequence
                '_calc_line_pos',
                'my_foo_clic',
                '_set_cursor',
            ],
        },                                 # End of 'sequences' declaration
        'events' => {
            'my_foo_clic' => {             # 'my_foo_clic' label definition
                'sub'     => 'foo_sub',
                'thread'  => 'Foo',
            },
        }
    }
 );

'sequences' key is at the same level as 'events' key. You can change sequences without writing event
code.

With this syntax, you can change as many sequences as you wish : the keys
of the 'sequences' hash are the true event names, and the values are
array references representing the sequences.

Note that if a sequence is defined both in a 'sequence' of a 'true event' and
as a sub-key of the 'B<sequences>' key, the 'B<sequences>' definition is taken.

=head1 'ACTION' OPTION

For each event, if 'action' option is used, its value must be one of the following.

=over 4

=item *

'exit' to exit from the sequence.

=item *

'change' to change event values

=item *

'jump' to go straight to a precise L<label|/EVENT NAMES AND SEQUENCE>

=item *

'reentrant' to create a dynamic sequence

=item *

'nop' to stop an interruptible thread

=back

With 'change', 'jump' and 'reentrant' values, the B<return value of your specific sub is used>.

=head2 'exit' value

L<As seen in the easy part of the interface|/return value, 'action' option introduction>, you can
put an 'exit' action alone or with a 'sub' option.
In the second case, your sub will be the last action executed in the event sequence.

=head2 'change' value

 my $editor = Text::Editor::Easy->new( 
     {
         'file'   => 'my_file.t3d',
         'events' => {
             'clic' => {
                 'sub'    => 'my_clic_sub',
                 'action' => 'change',     # event information can be changed by 'my_clic_sub'
             },
         }
     }
 );                                        # end of new
 
 [...]
 
 sub my_clic_sub {
     my ( $editor, $info_ref ) = @_;
 
     $info_ref->{'pos'} = 0;  # setting position to the beginning of the line
     return $info_ref;        # Returning a hash reference with the same keys,
                              #     'pos' value probably changed (was perhaps already 0)
 }

With 'change' value you can modify if you wish the values of the hash reference $info_ref
which contains your event information. The following labels of the sequence (including yours)
will use your new values (if there are no more change action).

Any hash reference returned will be considered as the new "info", any other return
value will be ignored : no change will be assumed. If you want to exit dynamically,
you have to use 'jump' value.

=head2 'jump' value

 my $editor = Text::Editor::Easy->new( 
     {
         'file'   => 'my_file.t3d',
         'events' => {
             'clic' => {
                 'sub'    => 'my_clic_sub',
                 'action' => 'jump',                     # a jump can be done
             },
         }
     }
 );
 
 [...]
 
 sub my_clic_sub {
     my ( $editor, $info_ref ) = @_;
 
     my $line = $info_ref->{'line'};
     if ( $line->text ) ) {
         $info_ref->{'pos'} = 0;
         return $info_ref;                               # no jump, values changed
     }
     while ( ! $line->text ) {
        $line = $line->next;
        if ( ! defined $line ) {
            $line = $editor->last;
            last;
        }
     }
     my %new_info = ( 
         'line' => $line,
         'pos'  => 0 ),
     );
                                                         # jump to '_set_cursor' label
     return [ '_set_cursor', \%new_info ];               # providing the hash required
                                                         # here, only '_test_resize' has been jumped
 }

You may return from your specific sub managing a 'jump' action in 3 different ways :

=over 4

=item *

returning undef or any scalar value will be ignored (no 'jump' action assumed).

=item *

returning a hash reference will just make a 'change' action with no jump. The hash given will be taken as the new <$info_ref> hash 
(for default management...) : a 'jump' action can encapsulate a 'change' action

=item *

returning an array reference will make a jump : the first position of the array is the label where to jump, the second one (optional)
is the new C<$info_ref> hash. With no second element, info is unchanged.
You can specify 'exit' or '_exit' for the label where to jump : in that case, you've made a dynamic
exit.

=back

=head3 smallest possible 'jump'

As you may L<link more than one sub|/Multiple subs for same event> to one event, the smallest possible jump is done when you give the label
following your own one. In this case, what you have jumped
are the possible other subs that were linked to the same label as yours, these subs should have been done after your own one (if no jump has
been made).

=head3 about info keys and labels

If the labels that you've jumped would have added keys to the information hash and if these keys are
needed for the labels you jump to, you may have to provide these keys yourself.

=head2 'reentrant' value

 my $editor = Text::Editor::Easy->new( 
     {
         'events' => {
             'clic' => {
                 'sub'    => 'my_clic_sub',
                 'action' => 'reentrant',     # dynamic sequence enabled
             },
             # Defining private labels
             'search_error'      => { 'sub' => 'search_error' },
             'highlight_error'   => { 'sub' => 'h_err', 'action' => 'reentrant' },
             'error_information' => { 'sub' => 's_info', 'thread' => 'Info' },
         }
     }
 );
 
 [...]
 
 sub my_clic_sub {
     my ( $editor, $info_ref ) = @_;

     if ( $info_ref->{'line'}->text =~ /error/i ) {
         return [ [ 'seach_error', 'highlight_error', 'error_information', '_exit' ] ];
     }
 }

'reentrant' value for action option includes all the 'jump' possibilities plus the dynamic sequence.

A dynamic sequence is just a sequence of labels (default or private ones). Note that this sequence
is done after your sub, then the normal sequence is going on (that's why the 'reentrant' name has been
given). You can make endless loops if a reentrant label calls itself.

If you want the 'dynamic sequence' functionality without the 'reentrant' one, you can add an '_exit'
label at the end of you dynamic sequence (last action to be done).

Action made according to 'reentrant' return value sub :

=over 4

=item *

 return;
 return 'foo';

With any scalar (maybe undef), nothing in particular is done (no event change, no jump...).

=item *

 return { 'x' => 125, 'y' => 12 };

A hash reference is interpreted as the new information hash. Here, a change action
is understood.

=item *

 return [ 'foo_label' ];
 return [ 'foo_label', { 'x' => 111, 'y' => 45 } ];
 
 return [ [ 'foo_label', 'bar_label' ] ];
 return [ [ 'foo_label', '_jump' ], { 'x' => 111, 'jump' => 'bar_lalel' } ];

With an array reference value, the second optional parameter is the new information hash
if a change action is needed (when not present, no information change is assumed).

For the first parameter, there are 2 possibilities :

=over 4

=item *

If it's a scalar, it's supposed to contain the next label to be executed (here, a jump 
action is assumed).

=item *

If it's an array reference, a 'reentrant' action is assumed : each element is
a label to be executed, the normal sequence will be continued after these dynamic labels.

=back

=back

=head2 'nop' value

This special value should always be used with the 'thread' option (read further, L<THREADS
CONTRIBUTION|/THREADS CONTRIBUTION>).

If a sub executed by a thread is huge, you may write it in an interruptible way
(writing instructions like B<return if anything_for_me;> from time to time). A 'nop' action
just sends a false task to your thread (there is something for it and it's ... nothing !) 
in order to interrupt its long task.

=head1 THREADS CONTRIBUTION

Just imagine the future : computers with more than one CPU... No sorry, that's just present : as for me, I have a dual core. But imagine that, as a
programmer, you could use your 2 (or maybe more) CPU very easily : for instance, just using threads...

As you can L<add threads|Text::Editor::Easy::Comm> to manage new methods with 'Text::Editor::Easy' objects, you can use (or create) as many
threads as you want to manage events. Of course, dividing a precisely defined job into more pieces than you have CPU won't be more efficient.
But very often, with interactive applications, we don't have a precise job to do : tasks to be done change sometimes so fast, depending on
user actions, that what was interesting to do at one moment could be useless just a few milliseconds later. With a multi-thread application, you not
only give yourself the power to use all of your CPU, but you also give yourself the power to interrupt useless tasks.

When you use the 'Graphic' default thread, your event sub is synchronous, that is the code of your event will freeze the user interface :
you should not use it for heavy tasks. For little tasks, this freeze won't be noticed.
If you have a huge task to do in response to an event, you can use another thread than the 'Graphic' one. In this case, the 'Graphic' thread 
still receive the initial event (you can't change that !) but as soon as enough information has been collected, your thread is called asynchronously
by the 'Graphic' thread (the 'Graphic' thread won't wait for your thread response). And here, if you make a heavy task, the user interface won't 
be freezed.

Still, with any thread, you should work in an interruptible way rather than make a huge task at once. Why ? Because the principle of
events is that you can't know when they occur and how many. Suppose your code responds to the mouse motion event : when the user
moves his mouse from left to right of your editor, you can have more than 10 mouse motion events generated in one second. And a perfect
response to the first event can be useless as soon as the second event has occured. Moreover, the 'Graphic' thread will send all asynchronous events
to your thread, even if it is busy working. Events will stack in a queue if your thread can't manage them quickly. If your code makes, in the end,
a graphical action visible by the user, there could be a long delay between the last event and its visible action.
And the user would consider your code as very slow. On the contrary, if you work in an interruptible way, that is, if you insert, from time to time,
little code like that :

 return if (anything_for_me);       # "me" stands for your thread executing your code

the user could have the feeling that your code is very fast : this is because you empty your thread queue more quickly and thus decrease the delay
between the last event and its answer. But you should add this line (that is, check your thread queue) when you are in a proper
state : just imagine that there is really something for you and that your code will be stopped and executed another time from the start.

The conclusion is :  "A good way to be fast is to give up useless tasks" and using more than one thread allows you to give up, so don't hesitate
to give up. This is the very power of multi-threaded applications : the ability to make huge tasks while remaining responsive. This does not mean
that programmers can still be worse than they are now (me included !) : they have to know where to interrupt.

=head2 'thread' option

 my $tid = Text::Editor::Easy->create_new_server(
     {
         ... # see Text::Editor::Easy::Comm for mandatory options
         'name' => 'My_thread_name',
     }
 );
 my $editor = Text::Editor::Easy->new( 
     {
         'file'   => 'my_file.t3d',
         'events' => {
             'clic' => {
                 'sub'    => 'my_clic_sub',
                 'thread' => 'My_thread_name',    # $tid could have been used
                                                  # instead of 'My_thread_name'
             },
         }
     }
 );

The value of the 'thread' option is the name of the thread you have chosen (should contain at least one letter), or the 'tid' 
(thread identification in perl ithread mecanism) that the program has chosen for you (it's an integer).

Note that by default, if you give the 'thread' option, an asynchronous call is assumed. The 'Graphic' thread asks your thread to execute your sub
but doesn't wait for its response.

=head2 'create' option

In the L<'thread' option example|/'thread' option>, the thread had already been created, but if you use 'thread' option with a name that is unknown, a new thread
will be created on the fly and will be named accordingly.

On the contrary, if you have written a bad name by mistake, you may want to prevent this auto-creation. The 'create' options has 3 possible values :

=over 4

=item *

'warning' : if the thread does not exist yet, the thread is created but a display is made on STDERR

=item *

'unlink' : if the thread does not exist yet, the thread is not created, the event is not linked to your sub but the 'editor' instance is still created

=item *

'error' (or any value different from 'warning' and 'unlink') : if the thread does not exist, the thread is not created, the 'editor' instance is not created

=back

Maybe you feel that the 'create' option should have been used to enable creation not to prevent it. But you are a perl programmer and should
feel responsible : the more irresponsible the languages assume the programmer is, the more verbose your programs have to be and the less
accessible the languages are. Langages should definitely consider programmers as responsible persons.

So you don't have to use the 'create' option if you want an auto-creation and that could be called lazyness or responsability.

=head2 'sync' option

 'events' => {
     'clic' => {
         'sub'    => 'my_clic_sub',
         'thread' => 'My_thread_name',
         'sync'   => 'true',              # A 'true' value : the call will be synchronous
     },
 }

Well, the benefit of threads seems to be brought only by asynchronous calls, but there is a reason why you could wish a synchronous call.
You may want to initialize data in your thread while changing values for the default event management. And the initialized data will be used
after the default management in an asynchronous way. So you don't have to share variables between threads just because you want some
events to be synchronous : variable 'scope' can then be limited. Read carefully the L<deadlock possibility|/deadlocks, 'pseudo' value for 'sync' option>
if you use this option.

This point is easier to understand when you know that, for instance, for a single mouse clic, you can L<manage up to 3 different events|/EVENT NAMES AND SEQUENCE>.

Now what about the 'sync' option with a 'false' value ?
You will force an asynchronous call and this could be used ... for the 'Graphic' thread ! This trick won't prevent you from freezing the user
interface if your code is huge, but if you know what you are doing...

 'events' => {
     'clic' => {
         'sub'    => 'my_clic_sub',
         'sync'   => 'false',           # the 'Graphic' thread 
                                        # will execute 'my_clic_sub' asynchronously
     },
 }

The 'Graphic' thread asks a task to itself (puts it in its thread queue) but doesn't execute it immediately : first it has to end this event management.
Once finished, it will execute its tasks in the order they have been queued... as well as manage other possible user events. Yes, the 'Graphic' thread
is very active and it's very difficult to know when it will have a little time for you.

You would get the same result with this :

 'events' => {
     'clic' => {
         'sub'    => 'my_clic_sub',
         'thread' => 'Graphic',         # 'thread' option present => asynchronous call assumed
     },
 }

=head2 'sync', 'thread' and 'action' incompatibilities

When you work in an asynchronous way, the 'Graphic' thread doesn't wait for your answer. Then it can't receive a label for a 'jump' action or a return
value for a 'change' action. So, only the 'exit' value of 'action' option is valid with asynchronous call.

=head2 deadlocks, 'pseudo' value for 'sync' option

When you use a thread in a synchronous way in an event management, you should understand what the 2 implied threads are doing :

=over 4

=item *

the 'Graphic' thread is pending, waiting for your thread response

=item *

your thread is working hard, trying to slow down the least it can the 'Graphic' thread

=back

So there is a very bad thing that could happen : if your thread asks for a service that is managed by the 'Graphic' thread... you know what follows...
As the 'Graphic' thread is waiting for your answer (synchronous call), it can't serve your request so your thread waits endlessly for
the 'Graphic' thread response and the 'Graphic' thread waits endlessly for your thread response. Everything is freezed forever (in fact some other
threads are still working, but the 'Graphic' thread is the visual one and the only one versus the window manager).

So, synchronous calls initiated by the 'Graphic' thread can't use a 'Graphic' service. This is quite limiting but you could have to work with this
limitation and find a solution : in the end, this is your job as a programmer.

Note that this is a general problem of multi-thread programmation : when a server thread asks another thread for a synchronous task, the executing
thread can't use any service of the calling thread. The limitation is not linked to graphics.

=head3 tracking deadlock

That kind of deadlocks could be checked and will be managed like that :

=over 4

=item *

a warning message, including the stack call, will be printed on STDERR

=item *

the executing thread will receive undef as an anwser : of course nothing will have been done by the initial calling server thread.

=back

...but it's not yet managed. So in case you have a permanent freeze, you'll have to guess from which call the deadlock was introduced. Of course
such a management will not be provided as a solution but as a help during development : this situation reveals a problem in conception.

=head3 'pseudo' value for 'sync' option

There is already a solution that could suit you : the 'Graphic' thread can make a 'pseudo-synchronous' call. It calls your thread
asynchronously getting the 'call_id' (see L<Text::Editor::Easy::Comm>). Then the 'Graphic' thread enters a loop where it checks 2 things
at the same time :

=over 4

=item *

I<Is there any task for me in the queue ?> If true, then I execute it. These queued tasks do not include other user events coming
from the window manager which will still remain pending.

=item *

I<Is the asynchronous call that I have asked for ended ?> Which means : I<is your event sub ended ?> If true, I exit the loop, get the answer and
go on with the event management.

=back

In order to have such a permissive management, you just have to use the 'pseudo' value for the 'sync' option :

 'events' => {
     'clic' => {
         'sub'    => 'my_clic_sub',
         'thread' => 'My_thread',
         'sync'   => 'pseudo',            # 'My_thread' can make calls to the 'Graphic' thread
         'action' => 'change',            # ... and can return a value to the 'Graphic' thread
     },
 }

So why should we keep the 'true' synchronous call ? Because with a pseudo-synchronous call, there is quite a big indetermination in the
order of execution of the different tasks and maybe there is a chance that your deterministic program produces, sometimes, chaotic results.
So 'pseudo' value for 'sync' option is provided but may lead, from time to time, to unexpected results, you are warned.

Note that chaotic reponses can be obtained with asynchronous calls too. Maybe a good thing to do is to change 'common data' thanks to
synchronous calls and only. Asynchronous calls should only be used for displaying common data or changing private data (private to a thread).
So using $editor->display or $line->select in an asynchronous called sub is OK but using $editor->insert or $line->set can lead to a race
condition with unpredictible result, see L<perlthrtut/"Thread Pitfalls: Races">. In fact, 'Text::Editor::Easy' manages editor data in a private way (only
'File_manager' thread knows about the file being edited) but as methods can be called by any thread, these data should be considered as shared :
if the cursor position is not the same when the event occurs as when you make your $editor->insert in your event sub (because an other thread
have changed this position between the event and your asynchronous sub), the result may look funny (still worse if a delete has removed 
the line you were expecting to work on !).

=head1 DYNAMIC CONTRIBUTION

=head2 updating events and sequences

Suppose that your program have several 'Text::Editor::Easy' instances running.
We've seen that you can add new instances with specific event management.
Thanks to 'dynamic contribution', you can change event management of already
running instances.
A generalization of this 'dynamic contribution' is to have a default set
of events used for future created instances.

The dynamic interface let you modify :

=over 4

=item *

A single event management of a single instance (instance call)

=item *

All events of a single instance (instance call)

=item *

A single event of a all instances (class call)

=item *

All events of all instances (class call)

=back

'Modify' event management should be understood as one of these possibilities :

=over 4

=item *

Adding an new event (no management before)

=item *

Changing an old event

=item *

Deleting an old event

=back

Moreover, as you can define your own sequences during instance creation, you can :

=over 4

=item *

Change sequences for one instance or all instances

=item *

Delete a sequence (return to default one) for one or all instances.

=back


=head2 set_event method

In order to change a single event, you have to use the 'set_event' method.

 Text::Editor::Easy->set_event( 
     'clic',                           # first parameter
     {                                 # second parameter, hash
         'sub'    => 'my_clic_sub',
         'thread' => 'My_thread',
     },
 };

In the previous example, the 'clic' event of 'all instances' (class call) will be changed.

The 'set_event' method accepts from 1 to 3 parameters :

=over 4

=item *

The first is the name of the event to be changed

=item *

The second contains the information that should have been given during the instance creation :
the interface is the same (you can create threads, eval a new module, ...).

This second parameter can then be a hash reference (for a single action linked to this event) 
or an array reference (for L<multiple actions|/Multiple subs for same event>).

If there is no second parameter (or an undef value), the event will be deleted.

=item *

L<A third optional parameter|/Single instance versus 'all instances', options for class calls> 
can add conditions to define if the event should be changed or not. These conditions
should be used with class calls.

=back

=head2 set_events method

The final 's' of 'set_eventB<s>' method makes all the difference : here you redefine all the events
at once (like 'events' option during instance creation)

 $editor->set_events( 
     {
         'clic', {
             'sub'    => 'my_clic_sub',
             'thread' => 'My_thread',
         },
         'motion', {
             'sub'    => 'my_motion_sub',
         },
     }
 };

In the previous example, B<all> specific event management have been re-set for the existing 
instance $editor. Of course, only 'clic' and 'motion' events are defined here, but if the 
'drag' or 'change' events were linked to specific subs, these old links are cut. If you want
to keep an old specific management with 'set_events' method, you'll have to repeat it in order not
to erase it.

The 'set_events' method accepts 1 parameter which exactly corresponds to the 'events' option
used during the instance creation. For class call of 'set_events', 
L<an optional second parameter|/Single instance versus 'all instances', options for class calls>
is possible.

Calling 'set_events' with no parameter (or an empty hash) will delete any specific event management.

=head2 set_sequence method

 # instance call
 $editor->set_sequence(
     {
         'clic' => [ 'my_action1', 'my_action2', '_set_cursor' ],
     }
 );
 
 # class call
 Text::Editor::Easy->set_sequence( 
     {
         'clic'   => [ 'my_action1', 'my_action2', '_set_cursor' ],
         'motion' => [ 'my_action2', 'motion', 'my_action3' ],
         'drag'   => [],
     },
     {
         'name'    => qr/\.pod$/,
     }
 );

You can change sequences after instance creation. There is no 's' at the end of 'set_sequence' :
you can give more than one sequence to change in the first hash parameter but only the keys
that you've given will be changed (different from 'set_events' principle).

=head2 Defining 'all instances', options for class calls

If you've read carefully the 2 previous examples, you already know that
an instance call changes only one instance and a class call changes 'all
 instances'.

But 'all instances' is not very clear : only existing instances, only the
ones that will be created from now, both, ... ?

Here, we're talking of class calls of 'set_event', 'set_events' and 'set_sequence' methods and we want to
precise the subset of instances to which the changes will apply.

 # 'set_event' class call example with options
 
 Text::Editor::Easy->set_event( 
     'clic',                             # First parameter
     {                                   # Second parameter
         'sub'    => 'my_clic_sub',
         'thread' => 'My_thread',
     },
     {                                   # Third optional parameter
         'instances' => 'future',
         'values'    => 'undefined',
     }                                   # End of third parameter
 };
 
 
 # 'set_events' class call example with options
 
 Text::Editor::Easy->set_events( 
     { 'clic' =>                         # First parameter
         {
             'sub'    => 'my_clic_sub',
             'thread' => 'My_thread',
         },
     }
     {                                   # Second parameter
         'names' => qr/\.pl$/,           # 'Regexp' object
     }                                   # End of second parameter
 };


You can add a third parameter to 'set_event' method or a second parameter
to 'set_events' and 'set_sequence' methods. This last parameter is an optional hash
with the following keys :

=over 4

=item *

'instances' key, possible values are :

=over 4

=item *

'existing', will affect only existing instances but not the ones to come.

=item *

'future', will affect only instances to come but not existing ones.

=item *

'all', will affect all instances, this is the default option.

=back

=item *

'values' key, possible values are :

=over 4

=item *

'undefined', will affect only undefined event(s) : won't override existing
management

=item *

'defined', will affect only defined event(s) : replace existing management,
but don't add management where there wasn't any.

=item *

'all', no matter if event(s) were defined before : this is the default option

=back

With a 'set_event' call (that is, when you define a particular named event,
for example, 'clic'), 'undefined' value means that, for each instance, a test
will be done : if a 'clic' event already exists for the tested instance,
it won't be updated.

With a 'set_events' call (when you want to set all events at once), 
'undefined' value means that there is not a single event managed in a 
specific way. You don't have used 'events' option during creation, or you
have deleted all events afterwards.

=item *

'names' key, this option accepts a 'Regexp' object that you can obtain with the qr// syntax.
If the name of an 'Editor instance' matches the regexp, the change will apply.

=back

=head3 'values' options with instance call

You can use the 'values' option with an instance call if you are too lazy to check what you've done before.

=head3 endless complexity with future instances

If you have made several class calls with 'set_event', 'set_events' and / or 'set_sequence' 
methods that affects new created instances, what will happen when a new instance will be 
created ? Which tests will be made, in which order ...?

The answer is : all tests will be done and in the order you have made the calls. As a joke, if you make
calls from different threads, the order will be undefined !

This is a very complex mecanism of default event management. The interface L<to get all these
default actions|/events method> (done at each instance creation) or L<set or unset all these default
actions in just one call|/set_default class method> follows.

=head2 events method

 my $events_ref = $editor->events;           # gets definition of all events in a single hash
                                             # (no parameter given)
 my $new_editor = Text::Editor::Easy->new;
 $new_editor->set_events( $events_ref );     # new editor with identical global event management
 
 
 my $event_ref = $editor->events('clic');    # gets definition of a single event (name given)
 my $new_editor = Text::Editor::Easy->new( {
     'events' => {
        'clic' => $event_ref,                # new editor with identical clic event management
     }
 } );

This method retrieves the event(s) definition of an instance (instance call). The first optional
parameter is the name of an event.

With a class call, what you get is an array reference of the different force actions that are done during
instance creation (ordered default event management with their options, according to class calls that
you've made before : 'set_event', 'set_events' or 'set_sequence' class calls).
For each element of the array, you've got :

=over 4

=item *

the action to be done :

=over 4

=item *

'sequence' for a previous 'set_sequence' class method call

=item *

'event' for a previous 'set_event' class method call

=item *

'events' for a previous 'set_events' class method call

=back

=item *

the parameters needed according to the method

=back

=head2 sequences instance method

 my $hash_ref  = editor->sequences;                    # gets all specific sequences
 
 my $array_ref = editor->sequences('clic');            # gets 'clic' specific sequence

This instance method retrieves specific sequence(s) : 

=over 4

=item *

with no parameter, all specific sequences are returned in a B<hash reference>

=item *

with a sequence name as first parameter, just this sequence is returned in an B<array reference>

=back

=head2 set_default class method

 my $default_ref = Text::Editor::Easy->events;       # gets all actions done by default
 
 Text::Editor::Easy->set_default( undef );           # deleting all default event management
 
 my $editor->Text::Editor::Easy->new;                # won't inherit former default event management
 
 Text::Editor::Easy->set_default( $default_ref );    # setting back default actions

You can make a list of 'set_event', 'set_events' and / or 'set_sequence' class calls that
will be applied for future instances in just one call with 'set_default' method.

=head2 dynamic designing, 'code' option

Perl is dynamic : you can 'eval' new code during execution and in the context of the running program.

Suppose your program is (or contains) an editor, that sounds great ! Your program can ask you for new 
code to edit (or old one to change) and will go on running using this very code ! You can call that the
way you want : a 'dynamic application', a limitless 'macro langage', the best configuration tool ever,
or the most dangerous thing (it's true that powerful things put in bad hands are dangerous, but skilled
people shouldn't be limited because of unskilled ones).

The 'code' option can replace 'sub', 'use' and 'package' options in L<standard and static
event definition|/'sub', 'use' and 'package' options of one particular event in 'events' option>.

This option accepts a string that represents the code of the event.

Note that you must not start your code with 'sub { ...' : you should consider that you are already  inside an unnamed sub.

 $editor->set_event( 
     'clic', { 
         'code' => 'print "Hello\n"';
     },
 );
 
 # is almost equivalent to
 
 $editor->set_event( 
     'clic', { 
         'sub' => 'hello';
     },
 );
 
 sub hello {
     print "Hello\n";
 }

About the differences :

=over 4

=item *

to use the 'sub' option, you need a named sub written somewhere in your program or in a module whereas
the 'code' option let you have your code in memory and nowhere else.

=item *

with the 'code' option, your code is 'checked' (or compiled) during the 'set_event'
call (with an eval). Moreover, for each event, the code is executed in an 'eval'. So, the
'code' option is dynamic but slower : you have nothing without nothing ! But 'dynamic
designing' should be considered as a faster way to design (as well as an extended
responsability in the code : programmer B<and> user; that is to say : an easier way to design)
with a future possibility to migrate 'dynamic tested code' to 'static code'. 

=back

On the paper, this 'code' option seems useless because you have to write the code anyway (some
furious programmers could think of 'computer generated' code, though).
But if the code is written after you have started your application ... and by the user himself :
see 'demo12' provided with the 'Editor.pl' program to understand.

=head1 PELL-MELL

=head2 Multiple subs for same event

You can link more than one sub to a single event. This can be interesting if you want to mix 
L<synchronous and asynchronous responses|/THREADS CONTRIBUTION> or just if you
have 2 very different things to do and don't want to hide them in a bad named sub.

 my $editor = Text::Editor::Easy->new( 
     {                                          # start of editor new options
         'events' =>                            # 'events' option
         {
             'clic' =>                          # 'clic' event management
             [                                  # array reference : more than one sub possible
                 {
                     'sub' => 'my_clic_sub_1',  # first sub to execute in response to 'clic' event
                 },
                 {
                     'sub' => 'my_clic_sub_2',  # second sub to execute in response to 'clic' event
                 },
             ],                                 # end of clic event
             'motion' =>
             {                                  # hash reference : single sub management
                 'sub' => 'my_motion_sub',
             },
         }                                 # end of 'events' option
     }                                     # end of editor new options
 );                                        # end of new

The sub declaration order is very important in your array : subs are called in this order. So, if you use the 'action' option in the first event, other
events could work with modified event information or could just be jumped.

=head2 Sending more data to your event sub

=head2 'execute_sequence' method

Sequences are powerful, so why should we limit them to event management ?

 $editor->execute_sequence( 
     [ '_show_editor', '_key_default', 'my_label' ],
     {
         'text' => "Text insertion without focus\n",
         'meta_hash' => {'alt' => 0, 'ctrl' => '0'}
     }
 );

This instance method needs at least one parameter :

=over 4

=item *

B<first parameter>, array reference (mandatory), contains the list of default
actions (labels) or events you want to execute.

=item *

B<second parameter>, hash reference (optional), should give information to the
labels or events you have chosen (if they need any).

=back

You could have done the first 2 actions of the example with the object interface :

 $editor->at_top;
 $editor->insert( "Text insertion without focus\n" );

=head2 saving event data

Suppose you've done complex things with the event management. Some events of a few instances are managed
in a static way with subs written in different modules but other events are managed in a dynamic way
with code in memory but saved nowhere... 

This is a real mess but that costed you a lot to come to this ugly point and you wouldn't like
to lose everything when your program will stop : either in a proper way or by a crash due to numerous
bugs.

The session management should help you save everything of your instances in order to get the 'same' 
state that you've had before quitting.

'Text::Editor::Easy' module should be considered as a low-level module. It will never know
anything about session. But there are enough possibilities to easily add this feature.

=head3 private keys

'events' options of the 'new' method and 'set_event(s)' method are insensitive
to an addition of private keys :

 $editor->set_event( 
    'clic',
    {
        'sub'       => 'my_clic_sub',
        'duration'  => 'endless',       # private key, just ignored by 'set_event'
    }
 );

Limitations : the 2 following keys are used for internal optimisation and
can't be private :

=over 4

=item *

B<cid>, compilation identification (for 'code' option)

=item *

B<tid>, thread tid, linked to 'thread' option

=back

=head3 'events' method, saving configuration

In order to save event management, you just have to call the 'events' method for each
editor and test your private key :

 use Data::Dump qw( dump );                # To save a hash in a file
 my $event_ref = $editor->events;
 while ( my ( $key, $value_ref ) = each %$event_ref ) {
     my $duration = $value_ref->{'duration'};
     if ( ! defined $duration or $duration ne 'endless' ) {
        delete $event_ref->{$key};         # session event : not to be saved
    }
 }
 print CFG dump( $event_ref );             # CFG <=> 'config.file'

=head3 loading configuration

 
 my $event_ref = {};
 if ( -f 'config.file' ) {
     $event_ref = do( 'config.file' );     # gets hash back from file
 }
 my $editor = Text::Editor::Easy->new(
     {
         'events' => $event_ref,
         ...
     }
 );

=head3 warning

You should only use names for editor instances and threads if you plan to save configuration.
tids (thread identification) or references (address of memory location) have almost no chance
to remain the same after a restart.

=head2 defining your own label (own default action)

You can create sequences as you wish (static ones or dynamic ones). In these sequences, every
label that does not start with '_' is considered as an event or a private label.

=head3 creating a private label ('set_event' method)

 # Instance label (known by only one instance)
 $editor->set_event( 'my_action',                    # label 'my_action'
     {
         'sub'    => 'my_sub',
         'action' =>  'change,
     }
 }
 
 # Class label (known by all instances)
 Text::Editor::Easy->set_event( 'my_class_action',   # label 'my_class_action'
     {
         'sub'    => 'my_other_sub',
         'thread' =>  'Foo',
     }
 }

=head3 using a private label

All you have to do is to define a sequence that contains one of your labels :

 $editor->set_sequence( {
    'shift_motion' => [ '_show_editor', 'my_action', 'my_class_action' ],
} );

The true event 'shift_motion' will then execute a predefined label (default action '_show_editor') and
your 2 private labels (these 2 newly defined labels can also be called : "generated events that
were not predefined").

=head2 simulating events...

Events can be simulated with method calls.

Here are examples :

 # true clic simulation
 $editor->clic( {'x' => 27, 'y' => 5 } );
 
 # true 'shift_motion' simulation
 $editor->motion( {'x' => 27, 'y' => 5, 'meta' => 'shift_' } );
 
 # true 'ctrl_drag' simulation
 $editor->drag( {'x' => 27, 'y' => 5, 'meta' => 'ctrl_' } );

Here are the usable methods :

=over 4

=item *

'key',

=item *

'clic',

=item *

'motion',

=item *

'drag',

=item *

'wheel',

=item *

'double_clic',

=item *

'right_clic',

=back

There is a little difference in L<the information that you get|/general keys of info_ref hash>. The 'caller' key won't be
starting with a 'U_' but with an integer (the tid of the thread that made the simulation
event call).

=head3 ...and forcing the sequence

All the previous methods accepts one parameter (the information hash) and an optional sequence.

 # true clic simulation with a private sequence (just for this simulated event)
 $editor->clic( {'x' => 27, 'y' => 5 }, [ '_set_cursor', 'my_foo_clic' ] );

This sequence is 'stronger' than any other (default or overloaded) but doesn't last after
the method call.

=head1 EVENT LIST

For each L<'true event', sequences|/EVENT NAMES AND SEQUENCE> are explained.

For each event, the hash information you 
L<receive as second parameter in your sub|/received information> is explained.

L<Labels|/sequence of a 'true event', 'labels'> defining a default action are
L<explained here|/LABEL DETAILS (DEFAULT ACTIONS)>.

Lots of events are not yet managed ('save', 'resize', 'destroy', 'lost_focus', 'get_focus', ...).

=head2 general prefixes

Thanks to modifier keys, events can be very numerous. See
L<modifier keys|/modifier keys> for explanations.

Here are the 9 usable prefixes with most events :

=over 4

=item *

no prefix ('' = empty string = q{})

=item *

any_

=item *

alt_

=item *

ctrl_

=item *

shift_

=item *

alt_ctrl_

=item *

alt_shift_

=item *

ctrl_shift_

=item *

alt_ctrl_shift_ (applications designed for pianists only !)

=back

=head2 general keys of info_ref hash

Whatever the event, the second parameter of your event sub is a hash containing,
at least, the following keys :

=over 4

=item *

B<true>, name of the 'true event' that has generated the sequence

=item *

B<label>, name of the current label that is executed (generated event)

=item *

B<meta>, string containing the modifier key combination ('', 'shift_', 'alt_ctrl_', ...)

=item *

B<meta_hash>, hash containing the keys 'alt', 'ctrl' and 'shift' : values are true if the corresponding modifier key was pressed.

=item *

B<caller>, 'event id' ('U_\d+') or 'call_id' if the event is simulated by a call

=back

'meta_hash' and 'meta' can be interesting for 'any_.*' events :

 my $editor = Text::Editor::Easy->new( 
    {
        'file'   => 'my_file.t3d',
        'events' => {
            'any_clic' => {                   # clic for any modifier key combination
                'sub'    => 'my_clic_sub',
            },                         
        }
    }
 );
 
 [...]
 
 sub my_clic_sub {
     my ( $editor, $info_ref ) = @_;
 
     if ( $info_ref->{'meta_hash'}{'alt'} ) {
         print "You pressed the alt key during the clic\n";
     }
     print "Meta combination string is ", $info_ref->{'meta'}, "\n";
 }


=head2 clic subset

There are 27 predefined 'clic' event labels (3 x L<9|/general prefixes>) given the 3 following suffixes :

=over 4

=item *

clic

=item *

right_clic

=item *

double_clic

=back

Here are examples of event names that you could use as keys of the 'events' hash during
editor instance creation :

 clic
 ctrl_clic
 alt_shift_right_clic
 any_right_clic
 alt_ctrl_shift_double_clic   # for a hidden functionality !

There are also 3 more 'clic' events :

=over 4

=item *

'any_any_clic', event that happens whatever the 'clic' (simple, double
or right) and whatever the meta-keys pressed.

=item *

'after_clic', happens after the default management of a clic sequence

=item *

'any_after_clic', shouldn't be very useful...

=back

=head3 information received in clic subset events

The information received by your sub is a hash containing the following keys :

=over 4

=item *

B<x>, abscisse of the clic

=item *

B<y>, ordinate of the clic

=item *

B<line>, line instance receiving the clic

=item *

B<pos>, position of the clic in characters in the line instance (from the left)

=back

=head3 'clic' sequence

The sequence depends on the meta-keys. With no meta-keys pressed :

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_any_clic>, generated event

=item *

B<any_clic>, generated event

=item *

B<clic>, generated event

=item *

L<_test_resize|/_test_resize>, default action

=item *

L<_set_cursor|/_set_cursor>, default action

=item *

B<any_after_clic>, generated event

=item *

B<after_clic>, generated event

=back

With meta-keys pressed, here is the sequence :

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_any_clic>, generated event

=item *

B<any_clic>, generated event

=item *

B<${meta}clic>, generated event

=item *

B<any_after_clic>, generated event

=back

Scalar $meta represents one of the following 7 possibilities :

 'alt_'
 'ctrl_'
 'shift_'
 'alt_ctrl_'
 'alt_shift_'
 'ctrl_shift'
 'alt_ctrl_shift'

As you can see, there are no default action if a meta-key is pressed ('_calc_line_pos' adds
just 'pos' and 'line' keys to the information hash).

=head3 'right_clic' sequence

There is just one sequence (no real default actions) : 

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_any_clic>, generated event

=item *

B<any_right_clic>, generated event

=item *

B<${meta}right_clic>, generated event

=back

$meta represents one of the following 8 possibilities :

 ''
 'alt_'
 'ctrl_'
 'shift_'
 'alt_ctrl_'
 'alt_shift_'
 'ctrl_shift'
 'alt_ctrl_shift'


=head3 'double_clic' sequence

There is just one sequence (no real default actions) : 

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_any_clic>, generated event

=item *

B<any_double_clic>, generated event

=item *

B<${meta}double_clic>, generated event

=back

Be careful, a double clic is... 2 clics !

=over 4

=item *

The first clic generates a 'true clic' event :
this is quite normal because for your ultra fast computer, there is very long delay 
between your 2 clics, and as it can't guess the future, it generates a clic event.

=item *

Then the second clic is interpreted as a 'double clic' (according to the maximum
delay you've configured in your window manager, or, rather, mouse manager).

=back

=head2 motion subset

=head3 motion information

The information received by your sub is a hash containing the same keys as clic events :

=over 4

=item *

B<x>, abscisse of the motion (mouse cursor)

=item *

B<y>, ordinate of the motion (mouse cursor)

=item *

B<line>, line instance under the mouse cursor

=item *

B<pos>, position of the mouse cursor in characters in the line instance (from the left)

=back

=head3 motion sequence

In fact, it's said in the introduction that the motion event is not managed by default, and
this is wrong.

Without meta-keys pressed, here is the sequence :

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_motion>, generated event

=item *

B<motion>, generated event

=item *

L<_show_editor|/_show_editor>, default action

=item *

L<_update_cursor|/_update_cursor>, default action

=item *

B<any_after_motion>, generated event

=item *

B<after_motion>, generated event

=back

With, meta-keys, it's true that there is no default management :

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_motion>, generated event

=item *

B<${meta}motion>, generated event

=item *

B<any_after_motion>, generated event

=back

So you have a possible of 11 motion events.

=head2 drag subset

=head3 drag information

=over 4

=item *

B<shape>, mouse cursor shape (double arrow for a resize command or simple arrow for
a select command)

=item *

B<x>, abscisse of the mouse cursor

=item *

B<y>, ordinate of the mouse cursor

=item *

B<line>, line instance under the mouse cursor

=item *

B<pos>, position of the mouse cursor in characters in the line instance (from the left)

=back

=head3 drag sequence

As there are default actions for the drag, there are 2 different sequences according
to meta-keys. With no meta-keys pressed, the sequence is :

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_drag>, generated event

=item *

B<drag>, generated event

=item *

L<_zone_resize|/_zone_resize>, default action

=item *

L<_drag_select|/_drag_select>, default action

=item *

B<any_after_drag>, generated event

=item *

B<after_drag>, generated event

=back

With any meta-keys, the sequence is :

=over 4

=item *

L<_calc_line_pos|/_calc_line_pos>, default action

=item *

B<any_drag>, generated event

=item *

B<${meta}drag>, generated event

=item *

B<any_after_drag>, generated event

=back

=head2 key subset

=head3 key information

Don't expect too much about these informations. If there are all right,
it's just that you have an american keyboard.

=over 4

=item *

B<text>, this is the printable information. With some keys (like backspace)
you shouldn't consider this information valid.

=item *

B<key>, should give the 'key code'. For my french keyboard, all 'AltGr'
keys are wrong (#, {, [, |, \, ...)

=item *

B<ascii>, should give the ascii code.

=item *

B<uni>, should give the unicode.

=item *

B<key_code>, concatenation of $meta and 'key' key (for instance 'alt_ctrl_b',
or 'ctrl_space'). Almost identical to general 'true' key ('true event' name): 'true' key has an
additionnal '_key' suffix in the end.

=back

=head3 key sequence

=over 4

=item *

B<any_any_key>, generated event

=item *

B<any_${key}_key>, generated event

=item *

B<${key_code}_key>, generated event

=item *

L<_key_code|/_key_code>, default action

=item *

L<_key_default|/_key_default>, default action

=back

'any_any_key' happens whatever the key pressed and whatever meta_keys (similar to 'any_any_clic').

=head2 wheel subset

=head3 wheel information

=over 4

=item *

B<unit>, represents how much the user have rolled the wheel mouse (can be negative)

=item *

B<move>, represents the number of pixels (or lines in future console mode) the editor will
be moved to (the move is only vertical)

=back

=head3 wheel sequence

There are 2 sequences depending on meta-keys. With no meta-key pressed, the sequence is :

=over 4

=item *

B<any_wheel>, generated event

=item *

B<wheel>, generated event

=item *

L<_wheel_move|/_wheel_move>, default action

=item *

B<after_wheel>, generated event

=back

With any meta-key pressed, the sequence is :

=over 4

=item *

B<any_wheel>, generated event

=item *

B<${meta}wheel>, generated event

=back

=head2 change event

At present, this is rather an 'after_change' because it happens once changes have been applied.
This is just a start. Meta-keys can't be used to create numerous 'change' events.

No sequence is done (will belong to other sequences : it is not a true event).

=head2 cursor_set event

As change event, this is rather an 'after_cursor_set' event. Meta-keys have no sense too.

No sequence is done (will belong to other sequences : it is not a true event).

=head1 LABEL DETAILS (DEFAULT ACTIONS)

All these actions can be used in L<your specific sequences|/changing the sequence>.
Every label that does not start with a '_' is considered as a generated event (= private label).

For each default action, keys needed in the information hash are explained
as well as keys added.

=head2 _calc_line_pos

This sub needs 'x' and 'y' keys.

Adds 'line' and 'pos' keys to the information hash.

This label could be used in a L<user sequence|/changing the sequence> where an event
changes 'x' and 'y' coordinates and wants to have 'line' and 'pos' keys coherent
with the new 'x' and 'y'.

=head2 _test_resize

This sub needs 'x' and 'y' keys.

Adds 'resize' key.

If the cursor has a double arrow shape, then
the clic is considered as a resize command (rather than a "set cursor" one) : in this case, 
the 'resize' key is added to the information hash with a true value (value is 1) and
'_set_cursor' label is jumped (label is set to 'any_after_clic' in case there are 
'after_clic' events).

If the clic is not considered as a resize command, then the 'resize' key
is still added but with a false value (value is 0). Of course, there is no jump.

=head2 _set_cursor

This sub needs 'pos' and 'line' keys.

4 little actions are done :

=over 4

=item *

editon cursor is set accordinly

=item *

focus is given to the editor

=item *

if there was selected text, it's un-selected

=item *

a little adjustment of the editor look is possible (when cursor is too close to a
border)

=back

=head2 _update_cursor

Needs 'x' and 'y' keys.

Sets mouse cursor shape according to its position versus the editor borders (in order to
initiate a resize command, double arrow, or a cursor set command, simple arrow).

=head2 _show_editor

This sub does not need any key.

It places the editor on top of all the other ones (in case, some parts of the editor is under
other ones).

=head2 _zone_resize

Needs keys 'shape', 'x' and 'y'.

According to 'shape' key, resizes editor.

=head2 _drag_select

Needs 'line' and 'pos' keys.

Selects text.

=head2 _wheel_move

Needs 'move' key.

Scrolls the editor.

=head2 _key_code

Needs 'key_code' key.

There are in fact 2 different systems of event management for key pressed events. The general one, using
'events' option (or 'set_event(s)' methods) and another one using method 'bind_key' (with
a class call, for a global binding, or an instance call).

L<Threads|/THREADS CONTRIBUTION> and L<code|/'code' option> are usable only with the general 
event management. With 'bind_key' method, you can use 'sub_ref' option (a sub reference) but
you have to call the 'bind_key' method from the thread with tid 0 : 'bind_key' user subs are always
executed by thread 0.

Maybe these 2 systems of key event management will go on living together...

The '_key_code' action is just a call to the good 'bind_key' sub : first, a specific (to the instance)
'bind_key' sub is looked for. If no specific binding is found, a global binding is looked for.

=head2 _key_default

Needs 'text' and 'meta_hash' keys.

Insert 'text' provided that no 'ctrl' or 'alt' key is pressed.

=head2 _exit

No key needed.

Could be used in a dynamic sequence (in order to avoid other following actions).

=head2 _jump

'jump' key needed.

Could be used in a dynamic sequence to make a dynamic jump according to previous actions.
(The 'jump' value is just the next label to be done, see L<jump action|/'jump' value>).

=head1 EVENTS LINKED TO A ZONE INSTANCE

Events can be linked to a L<'zone' instance|Text::Editor::Easy::Zone> rather than to a 
'Text::Editor::Easy' instance.

2 events are acessible for a 'zone' instance :

=over 4

=item *

top_editor_change : happens each time a new 'editor' instance is on top of the zone.

=item *

editor_destroy : happens each time a 'editor' instance belonging to the zone is destroyed.

=back

=head1 CONCLUSION

Maybe the interface seems a little complex in the end, still complexity have not been added freely. If this interface is adapted to programs
that change, then the goal will be reached : 

=over 4

=item *

first, you use synchronous events executed by the 'Graphic' thread

=item *

second, your application is growing (and your event code too), becoming more interesting and ... slower

=item *

Then you add threads where you feel it would help, keeping your code and your declarations but adding a few 'thread' options and and a few
C<return if anything_for_me;> instructions.

=back

=cut

require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(execute_events);

use threads;
use Text::Editor::Easy::Comm qw(anything_for_me have_task_done);
use Devel::Size qw(size total_size);
use Data::Dump qw(dump);

use constant {
    SUB_REF => 0,
    PACKAGE => 1, 
    MODULE => 2,
    SUB => 3,
};

sub reference_events {
    my ( $id, $events_ref ) = @_;
    
    if ( ! ref $events_ref or ref $events_ref ne 'HASH' ) {
        print STDERR "'events' option should be a hash reference\n";
        return;
    }
    for my $event_name ( keys %$events_ref ) {
        my $event_list_ref = $events_ref->{$event_name};
        if ( ref $event_list_ref eq 'HASH' ) {
            #print "Single event declaration\n";
            $event_list_ref->{'name'} = $event_name;
            my $answer = reference_event($id, $event_list_ref);
            if ( ! ref $answer ) {
                return if ( $answer eq 'error' );
                delete $events_ref->{$event_name};
            }
            else {
                $events_ref->{$event_name} = $answer;
            }
        }
        else {
            if ( ref $event_list_ref ne 'ARRAY' ) {
                print STDERR "Can't manage event $event_name : should be array or hash reference\n";
                return;
            }
            #print "Multiple event declaration\n";
            my @new_list;
            while ( my $event_ref = shift @$event_list_ref ) {
                $event_ref->{'name'} = $event_name;
                my $answer = reference_event($id, $event_ref);
                if ( ! ref $answer ) {
                    return if ( $answer eq 'error' );
                }
                else {
                    push @new_list, $answer;
                }
            }
            $events_ref->{$event_name} = \@new_list;
        }
    }
    return $events_ref;
}

my %possible_action = (
    'exit'      => 1,
    'change'    => 1,
    'jump'      => 1,
    'nop'       => 1,
    'reentrant' => 1,
);

my %possible_sync = (
    'true'     => 1,
    'false'    => 1,
    'pseudo'   => 1,
);


sub reference_event {
    my ( $id, $event_ref ) = @_;

    if ( ! $event_ref or ref $event_ref ne 'HASH' ) {
        print STDERR "Event definition should be a hash reference\n";
        return 'error';
    }
    delete $event_ref->{'cid'};
    delete $event_ref->{'tid'};

    my $package = 'main';
    #print "REF de event_ref : ", ref $event_ref, "\n";
    my $use = $event_ref->{'use'};
    my $thread = $event_ref->{'thread'};
        # Faux : l'appel à reference_event peut être fait par autre chose que le thread Graphic ...
        
    my $thread_defined = 1;
    if ( ! defined $thread ) {
        $thread_defined = 0;
        #eval "use $use";
        #if ( $@ ) {
        #    print STDERR "Wrong code for module $use :\n$@";
        #    return 'error';
        #}
        $thread = 0;
    }
    if ( $use ) {
        $package = $use;
        

    }
    my $action = $event_ref->{'action'};
    if ( defined $action ) {
        #print "Action définie à $action pour event_ref = $event_ref\n";
        if ( ! $possible_action{$action} ) {
            print STDERR "Unknown action value $action, instance not created\n";
            return 'error';
        }
    }
    my $sync = $event_ref->{'sync'};
    if ( defined $sync and ! $possible_sync{$sync} ) {
        print STDERR "Unknown sync value $sync, instance not created\n";
        return 'error';
    }

    if ( ! defined $event_ref->{'package'} ) {
        $event_ref->{'package'} = $package;
    }
    else { # A supprimer
        $package = $event_ref->{'package'};
    }
    if ( defined $thread ) {
        my $answer_ref = thread_use( $id, $thread, $use, $event_ref->{'create'}, $event_ref->{'init'}, $package );
        return $answer_ref if ( ! ref $answer_ref );
        if ( $thread_defined ) {
            $event_ref->{'tid'} = $answer_ref->{'tid'}; 
            if ( $action ) {
                if ( $action ne 'exit' and $action ne 'nop' ) {
                    if ( ! defined $sync or $sync eq 'false' ) {
                        print STDERR "Action $action forbidden with asynchronous call to thread $thread\n";
                        delete $event_ref->{'action'};
                    }
                }
            }
        }
    }
    
    my $sub_ref = $event_ref->{'sub'};
    if ( defined $sub_ref ) {
        my $sub = ref $sub_ref;
        if ( $sub ) {
            if ( $sub ne 'ARRAY' ) {
                print STDERR "'sub' option in 'event' declaration should be a string or an array reference\n";
                return 'error';
            }
            $sub = $sub_ref;
        }
        else {
            $sub = [ $sub_ref ];
        }
        $event_ref->{'sub'} = $sub;
        return $event_ref;
    }

    $event_ref->{'sub'} = [ ];
    
    if ( my $string = $event_ref->{'code'} ) {
        my $sub_ref = eval "sub { $string }";
        if ( $@ ) {
            print STDERR "Wrong code for event '$event_ref->{'name'}' : $@\n";
            my $indice = 1;
            for ( split( "\n", $string ) ) {
                print STDERR "\t$indice - $_\n";
                $indice += 1;
            }
            return 'unlink';
        }
        else {
            my $id = $event_ref->{'cid'};
            my $tid = $event_ref->{'tid'};

            # Trop simple ! Vrai tant que seul le thread 0 est générateur d'évènement
            $tid = 0 if ( ! defined $thread ) ;
            
            if ( defined $tid ) {
            # L'évaluation  peut avoir lieu à tort dans le thread 0 (si thread 'File_manager' : plus lent au premier appel...)
                $event_ref->{'cid'} = Text::Editor::Easy->ask_thread(
                    'Text::Editor::Easy::Events::thread_eval',
                    $tid,
                    $string,
                    $id
                );
                #print STDERR "Fin de l'évaluation 1, id = ", $event_ref->{'cid'}, "\n";
            }
            #print "Bonne évaluation, code = $string\n";
        }
        return $event_ref;
    }
    
    if ( ! defined $action ) {
        if ( ! defined $event_ref->{'sequence'} ) {
            print STDERR "No action defined and no sub provided, event cancelled\n";
            return 'unlink';
        }
        else {
            return $event_ref;
        }
    }
    return $event_ref if ( $action eq 'exit' );
    if ( $action ne 'nop' ) {
        print STDERR "Action $action not correct when no sub is provided, event cancelled\n";
        return 'unlink';
    }
    if ( ! defined $thread ) {
        print STDERR "Action nop should be linked with a thread option, event cancelled\n";
        return 'unlink';
    }
    #print "Pour event $event_ref package = $package\n";
    return $event_ref;
}

sub thread_use {
    my ( $id, $thread, $use, $create, $init, $package ) = @_;

    my $tid = $thread;
    if ( $thread =~ /\D/ ) {
        $tid = Text::Editor::Easy::Comm::get_tid_from_name_and_instance( $id, $thread );
        $tid = 0 if ( $thread eq 'Graphic' );
        if ( ! defined $tid and $thread ne 'File_manager' ) {
            if ( defined $create ) {
                if ( $create eq 'warning' ) {
                    print STDERR "Thread $thread will be created by event management\n";
                }
                elsif ( $create eq 'unlink' ) {
                    print STDERR "Thread $thread won't be created by event management, event not linked\n";
                    return 'unlink';
                }
                else {
                    print STDERR "Thread $thread doesn't exit, object creation aborted\n";
                    return 'error';
                }
            }
            $tid = Text::Editor::Easy->create_new_server( {
                'methods' => [],
                'object' => {},
                'name' => $thread,
            } );
        }
    }
    if ( defined $tid ) {
        Text::Editor::Easy::Async->ask_thread( 'use_module', $tid, 'Text::Editor::Easy::Events' );
        if ( defined $use ) {
            Text::Editor::Easy::Async->ask_thread( 'use_module', $tid, $use );
        }
        if ( defined $init and ref $init eq 'ARRAY' ) {
            my @init = @$init;
            my $sub = shift @init;
            #print "Avant appel $sub : package = $package\n";
            Text::Editor::Easy::Async->ask_thread( $sub, $tid, @init );
        }
    }
    return { 'tid' => $tid }; # $tid maybe undef
}

my %sub_ref;
my $sub_ref_id = 0;

sub thread_eval {
    my ( $self, $ref, $string, $id ) = @_;
    
    #print "Dans thread_eval : tid = ", threads->tid, ", code = $string\n";
    if ( ! defined $id ) {
        $sub_ref_id += 1;
        $id = $sub_ref_id;
    }
    $sub_ref{$id} = eval "sub { $string }";
    if ( $@ ) {
        print STDERR "Wrong 'compilation' during evaluation of :\nsub { $string } :\n$@\n";
        return;
    }
    #print "Fin de thread eval OK, id = $id\n";

    return $id;
}

sub execute_events {
    my ( $events_ref, $object, $info_ref ) = @_;

    my $events_list_ref;
    
    # possible si l'évènement était incorrect lors du référencement
    return if ( ! ref $events_ref );
    
    if ( ref $events_ref ne 'ARRAY' ) {
        # ==> ref $events_ref eq 'HASH'
        #print "Evènement simple\n";
        $events_list_ref = [ $events_ref ];
    }
    else {
        #print "Multiples évènements\n";
        $events_list_ref = $events_ref;
    }
    
    my $copy_info_ref;
    %$copy_info_ref = %$info_ref;
    EVENT: for my $event ( @$events_list_ref ) {
        my $action = $event->{'action'};
        #print "Event $event\n";
        #if ( ! defined $action ) {
        #    print "    ... action non définie pour objet = ", $object->name, "\n";
        #}
        #else {
        #    print "    ... action $action\n";
        #}
        my $new_info_ref = execute_event($event, $object, $copy_info_ref);
        next EVENT if ( ! defined $action or $action eq 'nop' );
        return if ( $action eq 'exit' );

        #print STDERR "Dans execute_events action = $action\n";
        #print "   ...ref de new_info_ref : ", ref( $new_info_ref ), "\n";
        if ( ! defined $new_info_ref or ! ref $new_info_ref ) {
            next EVENT;
        }
        #print STDERR "new_info_ref est une référence\n";
        my $ref_new_info = ref $new_info_ref;
        if ( $ref_new_info eq 'ARRAY' ) {
            #print STDERR "Dans execute_events, saut détecté\n";
            if ( $action ne 'jump' and $action ne 'reentrant' ) {
                print STDERR "Should use 'jump' or 'reentrant' value for 'action' option to make a jump\n";
                next EVENT;
            }
            my $label = $new_info_ref->[0];
            if ( ! defined $label ) {
                print STDERR "Undefined label in jump event\n";
                $label = q{};
            }
            my $ref_label = ref $label;
            if ( $ref_label ) {
                if ( $ref_label ne 'ARRAY' ) {
                    print STDERR "Label should be an array reference instead of '$ref_label' reference\n";
                    next EVENT;
                }
                elsif ( $action eq 'jump' ) {
                    print STDERR "Should use 'reentrant' value instead of 'jump' one to allow dynamic sequence\n";
                    next EVENT;
                }
            }
            elsif ( $label eq '_exit' or $label eq 'exit' ) {
                return;
            }
            my $new_ref = $new_info_ref->[1];
            $new_ref = $info_ref if ( ! defined $new_ref );
            return ( $new_ref, $label );
        }
        if ( $ref_new_info ne 'HASH' ) {
            next EVENT;
        }
        # No key checks : default labels should be robust
        $info_ref = $new_info_ref;
        %$copy_info_ref = %$info_ref;
    }
    return ( $info_ref, q{} );
}

sub execute_event {
    my ( $event_ref, $editor, $info_ref ) = @_;

    my $package = $event_ref->{'package'};
    my ( $sub, @user ) = @{$event_ref->{'sub'}};
    #print "EXECUTE_EVENT : PAckage $package, sub = $sub\n";
    my $action = $event_ref->{'action'};
    if ( ! defined $sub ) {
        if ( defined $action ) {
            return if ( $action eq 'exit' );
            if ( $action eq 'nop' ) {
                #print "Avant exécution d'une action nop pour ", $editor->name, "\n";
                thread_nop( $editor, $event_ref );
                return;
            }
        }
    }    
    my $thread = $event_ref->{'thread'};
    #print "On met ", $event_ref->{'cid'}, " dans event_ref->{'cid'}\n";
    my $code = [ $event_ref->{'code'}, $event_ref->{'cid'} ];
    if ( defined $thread ) {
        #print "Appel de thread execute avec thread = $thread\n";
        #if ( ! defined $action ) {
        #    print "1 Avant appel transform and execute pour thread : action = undef\n";
        #}
        #else {
        #    print "1 Avant appel transform and execute pour thread : action = $action\n";
        #}
        return thread_execute( $thread, $event_ref, $editor, $info_ref, $package, $sub, $code, @user );
    }
    else  {
        my $sync = $event_ref->{'sync'};
        if ( defined $sync and $sync eq 'false' ) {
            $event_ref->{'tid'} = 0;
            #print "Avant thread_execute pour tid = 0\n";
            #print "Avant appel thread_execute pour tid = 0 : editor = $editor\n";
            return thread_execute( $thread, $event_ref, $editor, $info_ref, $package, $sub, $code, @user );
        }
        #print "Dans execute event, avant appel transform... editor = $editor\n";
        my $answer = transform_and_execute( $editor, $info_ref, $package, $sub, $code, @user );
        #print "Dans execute_event ref de answer = ", ref( $answer ), "\n";
        return untransform( $answer, $action );
    }
}

sub thread_execute {
    my ( $thread, $event_ref, $object, $info_ref, $package, $sub, $code, @user ) = @_;

    my $tid = $event_ref->{'tid'};
    
    my $type = ref $object;
    my $id = '';
    if ( ref $object and $object->isa('Text::Editor::Easy') ) {
        $id = $object->id;
    }
    if ( ! defined $tid ) {
        if ( $thread ne 'File_manager' ) {
            print STDERR "Can't execute event : unknown tid for thread $thread\n";
            return;
        }
        else {
            $tid = Text::Editor::Easy::Comm::get_tid_from_name_and_instance( $id, 'File_manager' );
            #print "Récupéré le tid $tid pour le thread File_manager\n";
            if ( ! defined $tid ) {
                print STDERR "Can't find tid for thread 'File_manager'\n";
                return;
            }
            # Utiliser l'interface dynamique pour modifier l'évènement... ?
        }
    }
    my $object_ref;
    if ( $id eq '' ) {
        $object_ref = [ $type, $object ];
    }
    else {
        $object_ref = [ 'Text::Editor::Easy', $id ];
    }
    
    my $sync = $event_ref->{'sync'};
    my $sub_name = 'Text::Editor::Easy::Events::thread_transform';
    my @param = ( $sub_name, $tid, $object_ref, $package, $sub, $info_ref, $event_ref->{'action'}, $code, @user );
    $sync = 'false' if ( ! defined $sync );
    if ( $sync eq 'true' ) {
        return Text::Editor::Easy->ask_thread( @param );
    }
    elsif ( $sync eq 'pseudo' ) {
        my $call_id = Text::Editor::Easy::Async->ask_thread( @param );
        while ( 'not_ended' ) {
            # Is there any task for me in the queue ?
            if ( Text::Editor::Easy::Comm::anything_for_me() ) {
                Text::Editor::Easy::Comm::have_task_done();
            }
            
            my $status = Text::Editor::Easy->async_status( $call_id );
            # Is the asynchronous call that I have asked for ended ?
            last if ( $status eq 'ended' );
        }
        return Text::Editor::Easy->async_response( $call_id );
    }
    else {
        #print "Appel en asynchrone pour tid = $tid\n";
        Text::Editor::Easy::Async->ask_thread( @param );        
    }        
}

sub thread_nop {
    my ( $editor, $event_ref ) = @_;
        
    my $tid = $event_ref->{'tid'};

    my $type = ref $editor;  
    my $id = '';
    if ( $type eq 'Text::Editor::Easy' ) {
        $id = $editor->id;
    }
    
    if ( ! defined $tid ) {
        if ( $event_ref->{'thread'} ne 'File_manager' ) {
            print STDERR "Can't execute event : unknown tid for thread $event_ref->{'thread'}\n";
            return;
        }
        else {
            $tid = Text::Editor::Easy::Comm::get_tid_from_name_and_instance( $id, 'File_manager' );
            #print "Récupéré le tid $tid pour le thread File_manager\n";
            # Utiliser l'interface dynamique pour modifier l'évènement... ?
        }
    }
    my $sub_name = 'Text::Editor::Easy::Events::nop';
    my @param = ( $sub_name, $tid );
    Text::Editor::Easy::Async->ask_thread( @param );
}

sub nop {
    my ( $self, $reference ) = @_;
    
    #print "Dans nop, thread = ", threads->tid, ", self = $self, reference = $reference\n";
    return;
}

sub thread_transform {
    my ( $self, $ref, $object_ref, $package, $sub, $info_ref, $action, $code, @user ) = @_;
    
    my $object;
    if ( $object_ref->[0] eq 'Text::Editor::Easy::Zone' ) {
        # Cas à gérer 
        # $object = $type -> get_from_id;  ==> $type eq 'Text::Editor::Easy' ou 'Text::Editor::Easy::Zone' ou '...Window' ou ...
        $object = $object_ref->[1];
    }
    else {
        $object = Text::Editor::Easy->get_from_id( $object_ref->[1] );
        #print "Dans thread_transform, récupération pour id ", $object_ref->[1], " de object = $object\n";
    }
    
    #print "Appel transform_and_execute pour tid = ", threads->tid, "\n";
    my $answer = transform_and_execute( $object, $info_ref, $package, $sub, $code, @user);
    return untransform( $answer, $action );
}

sub transform_and_execute {
    my ( $editor, $info_ref, $package, $sub, $code, @user ) = @_;

    KEY: for my $key ( keys %$info_ref ) {
        if ( $key eq 'line' ) {
            my $line = Text::Editor::Easy::Line->new( $editor, $info_ref->{'line'} );
            $info_ref->{'line'} = $line;
            next KEY;
        }
        if ( $key eq 'display' ) {
            my $display = Text::Editor::Easy::Display->new( $editor, $info_ref->{'display'} );
            $info_ref->{'display'} = $display;
            next KEY;
        }
        if ( $key =~ /editor$/ ) {
            my $value = $info_ref->{$key};
            if ( defined $value ) {
                my $editor = Text::Editor::Easy->get_from_id( $info_ref->{$key} );
                #print "Dans transform_and_execute, récupération de editor = $editor\n";
                $info_ref->{$key} = $editor;
            }
            next KEY;
        }
    }
    
    if ( defined $sub ) {
        no strict "refs";
        return &{"${package}::$sub"}( $editor, $info_ref, @user );
    }
    else {
        # A optimiser : récupérer la référene de sub dans le contexte du thread pour ne permettre qu'une seule évaluation
        my ( $string, $cid ) = @$code;
        if ( ! defined $cid ) {
            #print "'Compilation' à la première exécution\n";
            $cid = thread_eval(0,0, $string);
            return if ( ! defined $cid ); # Erreur de 'compilation'

            #print "Compilation à la volée réussie, id = $cid| sub_ref = ", $sub_ref{$cid}, "\n";
            # Sauvegarde de la compilation
            my $id = $editor->id;
            my $name = $info_ref->{'label'};
            my ( $thread_ref, $event_ref ) 
                = Text::Editor::Easy->event_threads( $id, $info_ref->{'label'} );
            if ( defined $thread_ref ) {
                # Mise à jour de 'évènement
                $event_ref->{'cid'} = $cid;
                my $current_tid = threads->tid;
                for my $tid ( @$thread_ref ) {
                    if ( $tid == $current_tid ) {
                        Text::Editor::Easy->ask_thread( 'update_events', $tid, [ $id ], {
                            'event' => $event_ref,
                            'name'  => $name,
                        } );
                    }
                    else {
                        Text::Editor::Easy->ask_thread( 'update_events', $tid, [ $id ], {
                            'event' => $event_ref,
                            'name'  => $name,
                        } );
                    }
                }
            }
        }
        #print "Exécution avec id = $cid | sub_ref = ", $sub_ref{$cid}, "\n";
        my $answer = eval {
            $sub_ref{$cid}->( $editor, $info_ref, @user );
        };
        if ( $@ ) {
            print STDERR "Wrong 'execution' during evaluation of :\nsub { $code } :\n$@\n";
            return;
        }
        return $answer;
    }
}

sub untransform {
    my ( $info_ref, $action ) = @_;
    
    if ( ! defined $action or $action eq 'exit' ) {
        #print "Action non définie, retour vide\n";
        return;
    }
    my $ref_info = ref $info_ref;
    if ( ! $ref_info ) {
        return;
    }
    my $hash_ref = $info_ref;
    my $jump = 0;
    if ( $ref_info eq 'ARRAY' ) {
        #print "Jump, dans untransform\n";
        $hash_ref = $info_ref->[1];
        $jump = 1;
        return $info_ref if ( ! defined $hash_ref );
    }
    return if ( ref $hash_ref ne 'HASH' );
    if ( my $line = $hash_ref->{'line'} ) {
        $hash_ref->{'line'} = $line->ref;
    }
    if ( my $display = $hash_ref->{'display'} ) {
        $hash_ref->{'display'} = $display->ref;
    }
    if ( $jump ) {
        #print "Jump, retour d'une référence de tableau\n";
        return [ $info_ref->[0], $hash_ref ];
    }
    return $info_ref;
}

sub set_sequence {
    my ( $self, $sequence_ref, $options_ref ) = @_;

    my $id = '';
    # Pour l'instant, les méthodes 'set_event(s)' ne marchent pas avec les faux objets zone (méthode id non définie, plus d'autres choses à voir, ...)
    if ( ref $self ) {
        $id = $self->id;
    }

    my ( $id_ref, $thread_ref, $new_options_ref ) 
        = Text::Editor::Easy->data_set_sequence( $id, $sequence_ref, $options_ref );
    
    #print STDERR "Dans set_sequence new_options_ref = ", dump( $new_options_ref ), "\n";
    
    return if ( ! defined $id_ref );
    
    my $current_tid = threads->tid;
    for my $tid ( keys %$thread_ref ) {
        if ( $tid == $current_tid ) {
            #print STDERR "On modifie dans le thread $current_tid en synchrone\n";
            Text::Editor::Easy->ask_thread( 'update_events', $tid, $id_ref, $new_options_ref );
        }
        else {
            #print STDERR "On modifie dans le thread $tid en ASYNCHRONE\n";
            Text::Editor::Easy::Async->ask_thread( 'update_events', $tid, $id_ref, $new_options_ref );
        }
    }
}

sub set_event {
    my ( $self, $name, $event_ref, $options_ref ) = @_;

    return if ( ! defined $name );
    
    #print STDERR "Dans set_event '$name'\n";
    
    my $id = '';
    if ( ref $self and ( ref $self eq 'Text::Editor::Easy'   # Zone event...
    or ref $self eq 'Text::Editor::Easy::Async' ) ) {
        $id = $self->id;
    }
    if ( defined $event_ref ) {
        if ( ref $event_ref eq 'HASH' ) {
            $event_ref->{'name'} = $name;
        }
        elsif ( ref $event_ref eq 'ARRAY' ) {
            for my $ev_ref ( @$event_ref ) {
                if ( ref $ev_ref ne 'HASH' ) {
                    print STDERR "In a multi-sub declaration, single element must be hash reference\n";
                    return;
                }
                $ev_ref->{'name'} = $name;
            }
        }
        else {
            print STDERR "Event should be a hash or array reference\n";
            return;
        }
        $event_ref = reference_event( $id, $event_ref );
        return if ( ! ref $event_ref );
    }
    my ( $id_ref, $thread_ref, $new_options_ref ) 
        =  Text::Editor::Easy->data_set_event( $id, $name, $event_ref, $options_ref );
        
    return if ( ! defined $id_ref );
    
    my $current_tid = threads->tid;
    for my $tid ( keys %$thread_ref ) {
        if ( $tid == $current_tid ) {
            Text::Editor::Easy->ask_thread( 'update_events', $tid, $id_ref, $new_options_ref );
        }
        else {
            Text::Editor::Easy::Async->ask_thread( 'update_events', $tid, $id_ref, $new_options_ref );
        }
    }
}

sub set_events {
    my ( $self, $events_ref, $options_ref ) = @_;
    
    #print STDERR "Dans set_events\n";
    
    my $id = '';
    if ( ref $self and ( ref $self eq 'Text::Editor::Easy'   # Zone event...
    or ref $self eq 'Text::Editor::Easy::Async' ) ) {
        $id = $self->id;
    }
    if ( defined $events_ref ) {
        $events_ref = reference_events( $id, $events_ref );
        return if ( ! ref $events_ref );
    }
    my ( $id_ref, $thread_ref, $new_options_ref ) 
        =  Text::Editor::Easy->data_set_events( $id, $events_ref, $options_ref );
        
    return if ( ! defined $id_ref );
    
    my $current_tid = threads->tid;
    for my $tid ( keys %$thread_ref ) {
        if ( $tid == $current_tid ) {
            Text::Editor::Easy->ask_thread( 'update_events', $tid, $id_ref, $new_options_ref );
        }
        else {
            Text::Editor::Easy::Async->ask_thread( 'update_events', $tid, $id_ref, $new_options_ref );
        }
    }
}

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


1;















