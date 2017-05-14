
		Speech::Synthesiser - Speech Output for Perl
	        ============================================
			Richard Caley <R.Caley@ed.ac.uk>
			--------------------------------

This is a simple perl extension module which provides a way for perl
programs to speak using a speech synthesiser. The interface is
intended to allow any synthesiser to be plugged in. 

An implementation using the festival speech synthesiser is included. For
more information about festival, see:

	http://www.cstr.ed.ac.uk/projects/festival.html

If you have problemsw with or suggestions about this module, please
sign up for and mail to the festival-talk mailing list, see:

	http://www.cstr.ed.ac.uk/projects/festival/lists.html

In addition to the generic Speech::Synthesiser interface  specific
interface to festival is provided as Speech::Festival, thi allows more 
control of the synthesiser. 

Some simple example scripts are included to show how it works.

	festival_test.prl
		Uses the scheme interface.
	
			festival_test [auto|loop] scheme1 scheme2 ...

		Sends each of the scheme forms to festival

	synthesiser_test.prl
		Uses the text to speech interface.

			synthesiser_test text1 text2 ...

		Synthesizes each text in turn, choosing voices randomly.

	festival_panel.prl
		Is a Tk graphical interface allowing you to
		enter text, select a voice and hear the speech.
		
		Run with -q if you don't want it to be quite so
		chatty. 

		Dispite the name, it's not actually festival specific,
		if someone implements an interface to another
		synthesiser it would be trivial to allow access to it
		from this script.


