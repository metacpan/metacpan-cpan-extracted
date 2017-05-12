.___.          .__.                  .__         ,
  |  * _  *  * [__]._.._. _.  . *  * [__) _ *._ -+- _ ._.
  |  |(/, *  * |  |[  [  (_]\_| *  * |   (_)|[ ) | (/,[
                            ._|


                            the xs-friendly way
                            to tie perl arrays
			    to c arrays


  # Perl

      tie my @palette, 'Tie::Array::Pointer', {
	length => 256 * 3,  # 768
	type   => 'C',      # unsigned chars (see perldoc -f pack)
      }

      do_something_with_palette(\@palette);


  # perl sub

	sub do_something_with_palette {
	  my $array = shift;

	  # .**** this is how we share *******.
	  # *                                 *

	  my $address = tied(@$array)->address;

	  # *                                 *
	  # `*********************************'

	  xsub_manipulate_palette($address, scalar(@$array));
	}



  # XSUB

		    void
		    xsub_manipulate_palette(addr, len)
			unsigned char *addr;
			int            len;
		      CODE:
			memfrob(addr, len); /* man 3 memfrob */


  # Back in Perl Land

      foreach (@palette) {
	$_; # has been manipulated by funky gnu c code.
      }




# # # # # # # # # # # # # # # # # # # # # # # ## yet another buppu creation ##
