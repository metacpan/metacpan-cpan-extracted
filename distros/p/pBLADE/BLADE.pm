package BLADE;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

$VERSION = '0.10';

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
	     blade_hr
	     blade_br
	     blade_b
	     blade_i
	     blade_u
	     blade_s
	     blade_h1
	     blade_h2
	     blade_h3
	     blade_h4
	     blade_h5
	     blade_h6
	     blade_ul
	     blade_ol
	     blade_li
	     blade_dir
	     blade_dd
	     blade_center
	     blade_p
	     blade_pre
	     blade_big
	     blade_em
	     blade_small
	     blade_sub
	     blade_sup
	     blade_titlebox
	     blade_tt
	     blade_table
	     blade_tr
	     blade_td
	     blade_form
	     blade_input
	     blade_select
	     blade_option
	     blade_textarea
	     blade_div
	     blade_span
	     blade_font
	     blade_a
	     blade_img
	     blade_link
	     blade_tag
	     blade_disp
	     blade_color
	     blade_hash_new
	     blade_hash_free
	     blade_hash_dup
	     blade_hash_get
	     blade_hash_get_nodup
	     blade_hash_get_num
	     blade_hash_get_num_nodup
	     blade_hash_get_num_name
	     blade_hash_get_num_name_nodup
	     blade_hash_load_file
	     blade_hash_load_string
	     blade_hash_set
	     blade_hash_set_nodel
	     blade_hash_exists_in
	     blade_web_vars_count
	     blade_web_vars_get
	     blade_web_vars_get_nodup
	     blade_web_vars_get_all
	     blade_web_vars_get_num
	     blade_web_vars_get_num_nodup
	     blade_web_vars_get_num_name
	     blade_web_vars_get_num_name_nodup
	     blade_auth
	     blade_return_buffer
	     blade_destroy
	     blade_destroy_no_env
	     blade_obj
	     blade_link_file
	     blade_url_decode
	     blade_url_encode
	     blade_session_set_var
	     blade_session_get_var
	     blade_session_get_set
	     blade_orb_run
	     blade_page_init
	     blade_run
	     blade_obj_simple_init
	     blade_theme_simple_init
	     blade_accept
	     blade_page
	     );

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined BLADE macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap BLADE $VERSION;

1;
__END__

=head1 NAME

pBLADE - Perl interface to the BLADE library.

=head1 SYNOPSIS

  use BLADE;

=head1 DESCRIPTION

Provides an interface to the BLADE library. See
http://www.thestuff.net/bob/projects/blade for
more information.

=head1 API

Most functions from libblade are available, and the arguments
are identical to those one would use in the C language.

Functions in the C library that accept arguments of type C<CORBA_char*> should
be given normal Perl strings. Likewise, any function that returns
a C<CORBA_char*> in C, will instead return a normal Perl string
in pBLADE.

The C datatype C<blade_env*> is represented as a Perl object
blessed into the C<BLADEENV> class. One obtains a C<BLADEENV> object
by calling C<blade_page_init()>, which is then suitable for
passing to any other functions that would require a C<blade_env*>
in the C library.
Such functions may also be used in an object-oriented manner, with the
leading 'blade_' stripped off. For example, if C<$blade> is an object
of type C<BLADEENV>, then the following two lines are equivalent:

	blade_hr( $blade );   # traditional function name

	$blade->hr;           # pBLADE's additional OO interface

=head2 blade_env* fields

The C C<blade_env> struct datatype has several data which application programmers
might find useful. These data are made available to C<BLADEENV> objects
via various methods. The methods are listed below.

=over 4

=item links( )

=item colors( )

=item tags( )

=item web_vars( )

=item web_root( )

=item header( )

=item sysconfdir( )

=item bladeconfdir( )

=item web_page_name( )

=item page_name( )

=item web_context( )

=item user( )

=item passwd( )

=back

=head2 Functions requiring (int *argc, char **argv)

C<blade_page()>, C<blade_page_init()>, C<blade_obj_simple_init()>
and C<blade_theme_simple_init()>
in libblade expect to be given the command-line
argument count and values,
in the event that any of them are of use to libblade.
In pBLADE, however, these arguments are replaced with a single array
reference, usually C<\@ARGV>, representing the command line arguments given
to the Perl script. Note that C<@ARGV> may come back modified if libblade
found any of the arguments to its liking. An example:

	# 
	# Initialize BLADE, get returned BLADEENV object.
	# libblade may modify @ARGV in this case.
	#
	my $blade = blade_page_init(\@ARGV, '', 'en');

=head2 BLADE hashes

The C datatype C<blade_hash*> is represented in pBLADE as a Perl object
blessed into the C<BLADEHASH> class. One obtains such an object from
C<blade_hash_new()>, C<blade_hash_dup()> and C<blade_web_vars_get_all()>.

=head2 Callbacks

C<blade_page()>, C<blade_run()>, C<blade_obj_simple_init()>
and C<blade_theme_simple_init()>
each require callbacks to be specified. In C, these are the addresses
of functions of certain types. In pBLADE, these are Perl code references.

The Perl subroutine referenced, when called, will be given arguments just
as one would expect from the C function prototypes. Also in these functions,
another argument, C<$data>, is given which is a Perl scalar that will be passed
to the callback function. Use undef if you don't wish to use this feature.

An example:

	blade_obj_simple_init(\@ARGV, \&draw, undef);
	blade_orb_run();

	sub draw {
            my ($blade, $name, $args, $data) = @_;
            $blade->disp('Hello World');
	}

=head1 AUTHOR

Pete Ratzlaff <pratzlaff@cfa.harvard.edu>

=head1 SEE ALSO

perl(1).

=cut
