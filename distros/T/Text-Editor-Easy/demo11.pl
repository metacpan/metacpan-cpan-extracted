#
# Inter-thread and eval traces.
#
# Well, this is not really a demo.
#
# If you have done demos 7 to 9, you shoud have obtained
# text printed in the "Eval" editor.
#
# Now that traces of the macro panel program begin to work,
# you can mouve your mouse over these displays, allways with
# shift key pressed.
#
# Well for the moment, maybe it will not work everywhere but
# it's not too bad : you should be able to obtain, for instance,
# the following historic in the "stack call Editor" that I explain here
# (mouse move with demo8, last printed characters on "Eval" editor) :
#
#     12|4_4980|STDOUT 
#          ==> the print was made by the thread with tid 12 on STDOUT while it was executing "call_id" 4_4980.
#     File eval E_4_4980__0|Line 3|Package Text::Editor::Easy::Program::Eval::Exec  
#          ==> the eval has been "traced" and saved, you can see it again
#     File lib/Text/Editor/Easy/Program/Eval/Exec.pm|Line 38|Package Text::Editor::Easy::Program::Eval::Exec
#
#     4_4980|0_10147 
#         ==> the call_id 4_4980 (made by thread with tid 4) was a consequence of the execution of the call_id 0_10147
#     File lib/Text/Editor/Easy/Program/Search.pm|Line 108|Package Text::Editor::Easy::Program::Search
#     File lib/Text/Editor/Easy/Motion.pm|Line 94|Package Text::Editor::Easy::Motion
#     
#     0_10147|U_4225 
#         ==> the call_id 0_10147 (made by thread with tid 0) was a consequence of user event U_4225
#     File lib/Text/Editor/Easy/Comm.pm|Line 1559|Package Text::Editor::Easy::Comm
#     File lib/Text/Editor/Easy/Abstract.pm|Line 2453|Package Text::Editor::Easy::Abstract
#     File lib/Text/Editor/Easy/Abstract.pm|Line 2231|Package Text::Editor::Easy::Abstract
#     
#     U_4225| 
#         ==> the user event U_4225 was the cause of all this (here, 3 threads worked together. A little more, in fact, for traces)
#     User pressed key F5
#
# I have or can have more information on call_id and printed text. You can look at
# the file "Editor.pl__2__Text_Editor_Easy_Data.trc" in the tmp directory. This file, written
# by the thread with tid 2 ("Data" thread), contains all the "calls", "starts" and "responses" of all threads.
# For instance, the following 3 lines :
#
#    "C|0_10147|4|1219572753|194885|manage_events"
# indicates that the call identified by the call_id "0_10147" was made by thread 0 at asbolute time 1219572753
# (194885 micro-seconds). The method called was "manage_events".
#
#    "S|4|0_10147|1219572753|456029|manage_events"
# indicates that the thread 4 "starts" to execute the call_id "0_10147" at time 1219572753,456029.
#
#    "R|4|0_10147|1219572753|812928|? (asynchronous call) : manage_events"
# indicates that the thread 4 "responds" to the call_id "0_10147" at time 1219572753,812928.
#
# Maybe you see know why this Editor is not so fast. Everything is traced. But as the final
# aim is dynamic designing, you'll agree that traces are very important : modifying code
# during execution will require tools and method...
#
# Anyway, it can help me to debug all this horrible code... I'm
# now going to understand what I've done !