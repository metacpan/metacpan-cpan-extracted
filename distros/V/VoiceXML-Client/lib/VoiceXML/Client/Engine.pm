package VoiceXML::Client::Engine;

use VoiceXML::Client::Parser;
use strict;


=head1 COPYRIGHT AND LICENSE

	
	Copyright (C) 2007,2008 by Pat Deegan.
	All rights reserved
	http://voicexml.psychogenic.com

This library is released under the terms of the GNU GPL version 3, making it available only for 
free programs ("free" here being used in the sense of the GPL, see http://www.gnu.org for more details). 
Anyone wishing to use this library within a proprietary or otherwise non-GPLed program MUST contact psychogenic.com to 
acquire a distinct license for their application.  This approach encourages the use of free software 
while allowing for proprietary solutions that support further development.


This file is part of VoiceXML::Client.

 
 
    VoiceXML::Client is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VoiceXML::Client is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with VoiceXML::Client.  If not, see <http://www.gnu.org/licenses/>.


=cut

=head2 new 

=cut

sub new {
	my $class = shift;
	my $rootDocument = shift;
	my %params = @_;
	
	
	my $self = {};
        
        bless $self, ref $class || $class;
	

	$self->{'interpreter'} = new VoiceXML::Client::Engine::Component::Interpreter::JavaScript->new();
	$self->{'runtime'} = $self->{'interpreter'}->runtime();
	$self->{'parser'} = VoiceXML::Client::Parser->new();
	
	$self->{'VXMLRootDoc'} = $self->{'parser'}->parse($rootDocument, $self->{'runtime'}) if ($rootDocument);
	
	
	$self->init(\%params);
	
	return $self;
}


sub init {
	my $self = shift;
	my $params = shift;
	
	return 1;
}

sub componentRequest {
	my $self = shift;
	my $componentObj = shift;
	my $requestType = shift;
	my @params = @_;
	
	return 1;
}



sub FIA {
	my $self = shift;
	
	$self->initialize();
	
}

sub FIA_initialize {
	my $self = shift;
	
	

// 
// Initialization Phase 
// 

foreach ( <var> and form item variable, in document order ) 
   Declare the variable, initializing it to the value of
   the "expr" attribute, if any, or else to undefined. 

foreach ( field item ) 
   Declare a prompt counter and set it to 1. 

if ( there is an initial item ) 
   Declare a prompt counter and set it to 1. 

if ( user entered form by speaking to its 
     grammar while in a different form ) 
{ 
   Enter the main loop below, but start in
   the process phase, not the select phase:
   we already have a collection to process. 
} 

// 
// Main Loop: select next form item and execute it. 
// 

while ( true ) 
{ 
   // 
   // Select Phase: choose a form item to visit. 
   // 

   if ( the last main loop iteration ended
             with a <goto nextitem> ) 
       Select that next form item. 

   else if (there is a form item with an
             unsatisfied guard condition ) 
       Select the first such form item in document order. 

   else 
       Do an <exit/> -- the form is full and specified no transition. 

   // 
   // Collect Phase: execute the selected form item. 
   // 
   // Queue up prompts for the form item. 

   unless ( the last loop iteration ended with
            a catch that had no <reprompt> ) 
   { 
       Select the appropriate prompts for the form item. 

       Queue the selected prompts for play prior to
       the next collect operation. 

       Increment the form item's prompt counter. 
   } 

   // Activate grammars for the form item. 

   if ( the form item is modal ) 
       Set the active grammar set to the form item grammars,
       if any. (Note that some form items, e.g. <block>,
       cannot have any grammars). 
   else 
       Set the active grammar set to the form item
       grammars and any grammars scoped to the form,
       the current document, the application root 
       document, and then elements up the <subdialog>
       call chain. 

   // Execute the form item. 

   if ( a <field> was selected ) 
       Collect an utterance or an event from the user. 
   else if ( a <record> was chosen ) 
       Collect an utterance (with a name/value pair
       for the recorded bytes) or event from themuser.         
   else if ( an <object> was chosen ) 
       Execute the object, setting the <object>'s
       form item variable to the returned ECMAScript value. 
   else if ( a <subdialog> was chosen ) 
       Execute the subdialog, setting the <subdialog>'s
       form item variable to the returned ECMAScript value. 
   else if ( a <transfer> was chosen ) 
       Do the transfer, and (if wait is true) set the
       <transfer> form item variable to the returned
       result status indicator. 
   else if ( the <initial> was chosen ) 
       Collect an utterance or an event from the user. 
   else if ( a <block> was chosen ) 
   { 
       Set the block's form item variable to a defined value. 

       Execute the block's executable context. 
   } 

   // 
   // Process Phase: process the resulting utterance or event. 
   // 

   // Process an event. 

   if ( the form item execution resulted in an event ) 
   { 
       Find the appropriate catch for the event. 

       Execute the catch (this may leave the FIA). 

       continue 
   } 

   // Must have an utterance: process ones from outside grammars. 

   if ( the utterance matched a grammar from outside the form ) 
   { 
       if ( the grammar belongs to a <link> element ) 
          Execute that link's goto or throw, leaving the FIA. 

       if ( the grammar belongs to a menu's <choice> element ) 
          Execute the choice's goto or throw, leaving the FIA. 

       // The grammar belongs to another form (or menu). 

       Transition to that form (or menu), carrying the utterance
       to the other form (or menu)'s FIA. 
   } 

   // Process an utterance spoken to a grammar from this form. 
   // First copy utterance slot values into corresponding 
   // form item variables. 

   Clear all "just_filled" flags. 

   foreach ( slot in the user's utterance ) 
   { 
       if ( the slot corresponds to a field item ) 
       { 
          Copy the slot value into the field item's form item variable. 

          Set this field item's "just_filled" flag. 
       } 
   } 

   // Set <initial> form item variable if any field items are filled. 

   if ( any field item variable is set as a result of the user utterance ) 
       Set the <initial> form item variable. 

   // Next execute any <filled> actions triggered by this utterance. 

   foreach ( <filled> action in document order ) 
   { 
       // Determine the form item variables the <filled> applies to. 

       N = the <filled>'s "namelist" attribute. 

       if ( N equals "" ) 
       { 
          if ( the <filled> is a child of a form item ) 
            N = the form item's form item variable name. 
          else if ( the <filled> is a child of a form ) 
            N = the form item variable names of all the form
                items in that form. 
       } 

       // Is the <filled> triggered? 

       if ( any form item variable in the set N was "just_filled" 
              AND  (  the <filled> mode is "all"
                          AND all variables in N are filled 
                      OR the <filled> mode is "any"
                          AND any variables in N are filled) ) 
            Execute the <filled> action. 
   } 
}


1;

