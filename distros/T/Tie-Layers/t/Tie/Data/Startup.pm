#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package Data::Startup;

use strict;
use 5.001;
use warnings;
use warnings::register;
use attributes;

use vars qw( $VERSION $DATE $FILE);
$VERSION = '0.08';
$DATE = '2004/05/28';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(config override);

#######
# Object used to set default, startup, options values.
#
sub new
{
     my $class = shift;
     $class = ref($class) ? ref($class) : $class;

     #########
     # Create a new hash in hopes of not to
     # mangle, which may be a reference outside,
     # inputs to this subroutine.
     #
     my %startup_options;
     my $ref = ref($_[0]);
     $ref = attributes::reftype($_[0]) if($ref);
     if($ref eq 'HASH') {
         %startup_options = %{$_[0]};
         shift;
     }
     elsif($ref eq 'ARRAY') {
         %startup_options = @{$_[0]};
         shift;
     }
     else {
         %startup_options = @_;
     }
  
     bless \%startup_options,$class;
}


######
# Replace the current values in $self hash
#
sub config
{
     my $self = shift;
     my @return;

     #########
     # For empty input return the sorted
     # key, value pairs for all the options
     #
     unless(@_) {
         foreach (sort keys %$self) {
             push @return, $_, $self->{$_};
         }
         return @return;    
     }

     ######
     # Move hash reference into $options_override,
     # array references and \@_ into $array
     #
     my $options_override = {};
     my $array = [];
     my $ref = ref($_[0]);
     $ref = attributes::reftype($_[0]) if($ref);
     if($ref) {
         if($ref eq 'HASH') {
             $options_override = $_[0];
         }
         elsif($ref eq 'ARRAY') {
             $array = $_[0];
         }
     }
     else {
         $array = \@_;
     }

     ######
     # Move $array into %options_override
     # For problem arrays with odd members greater
     # than one, return an undef. 
     #
     # Arrays with one member, the key value using
     # the single member as a key.
     #
     if(@$array == 1)  {
         return ($array->[0], $self->{$array->[0]});
     }
     elsif(@$array && ${$array}[0]) {
         if(@$array %  2 == 0) {
            my %hash = @$array;
            $options_override = \%hash;
         }
         else {
            return undef;
         }
     }

     ######
     # Override the $self options, returning
     # the sorted key, value of the replaced options
     #
     foreach (sort keys %$options_override) {
         push @return, $_, $self->{$_};
         $self->{$_} = $options_override->{$_};
     }
     @return;
}


#######
# Override the options in a default object and create
# a new object with the override options, perserving
# the default object.
# 
sub override
{
     my $self = shift;
     return bless {},'Data::Startup' unless ref($self);

     #####
     # Return if no override values
     #
     return $self unless (@_);

     #########
     # Create a duplicate object keeping the
     # the default object intact.
     my %options = %$self;

     #####
     # Process options hash
     #     
     if(ref($self) eq 'HASH') {
         Data::Startup::config(\%options,@_);
         return \%options;
     }

     #####
     # Process a object with hash underlying data
     # 
     $self = bless \%options,ref($self);

     ##############
     # Do not want to gyrate around to any other
     # config in @ISA. Go directly to the one in this
     # program module.
     #
     $self->Data::Startup::config(@_);
     $self

}

=head1 NAME

Data::Startup - startup options class, override, config methods

=head1 SYNOPSIS

 ######
 # Subroutine interface
 #
 use Data::Startup qw(config override);
 
 $options = override(\%default_options, @option_list );
 $options = override(\%default_options, \@option_list );
 $options = override(\%default_options, \%option_list );

 @options_list = config(\%options );

 ($key, $old_value) = config(\%options, $key);
 ($key, $old_value) = config(\%options, $key => $new_value ); 

 @old_options_list = config(\%options, @option_list);
 @old_options_list = config(\%options, \@option_list);
 @old_options_list = config(\%options, \%option_list);

 ######
 # Object interface
 #
 use Data::Startup

 $startup_options = $class->Data::Startup::new( @option_list );
 $startup_options = $class->Data::Startup::new( \@option_list );
 $startup_options = $class->Data::Startup::new( \%option_list );

 $options = $startup_options->override( @option_list );
 $options = $startup_options->override( \@option_list );
 $options = $startup_options->override( \%option_list );

 @options_list = $options->config( );

 ($key, $old_value) = $options->config($key);
 ($key, $old_value) = $options->config($key => $new_value ); 

 @old_options_list = $options->config(@option_list);
 @old_options_list = $options->config(\@option_list);
 @old_options_list = $options->config(\%option_list);

 # Note: May use [@option_list] instead of \@option_list
 #       and {@option_list} instead of \%option_list

=head1 DESCRIPTION

Many times there is a group of subroutines that can be tailored by
different situations with a few, say global variables.
However, global variables pollute namespaces, become mangled
when the functions are multi-threaded and probably have many 
other faults that it is not worth the time discovering.

As well documented in literature, object oriented programming do not have
these faults.
This program module class of objects provide the objectized options
for a group of subroutines or encapsulated options by using
the methods directly as in an option object.

The C<Data::Startup> class provides a way to input options
in very liberal manner of either

=over 4

=item *

arrays, reference to an array, or reference to hash to a

=item *

reference to an array or reference to a hash

=item *

reference to a hash

=item *

referene to an array

=item *

many other combos

=back

without having to cut and paste specialize, tailored
code into each subroutine/method.

Some of the possiblities follows.

A subroutine may be utilize either as a subroutine or a method
of a object by processing the first argument of @_ by the 
following:

 sub my_suroutine
 {
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);

     # ....

 }

The C<Data::Startup> class may be used to provide various 
options syntax for a dual methods/subroutines as follows:

 my $default_options = new( @default_options_list);

 # SYNTAX: my_subroutine1($arg1 .. $argn, @options)
 #         my_subroutine1($arg1 .. $argn, \@options)
 #         my_subroutine1($arg1 .. $argn, \%options)
 #
 

 sub my_subroutine1
 {
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::Startup->new() unless $default_options;
     my ($arg1 .. $argn, @options) = @_
     my $options = $default_options->override(@options);

     # ....
 }

 # SYNTAX: my_subroutine2(\@options, @args)
 #         my_subroutine2(\%options, @args)
 #
 # !ref($args[0])

 sub my_subroutine2
 {
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::Startup->new() unless $default_options;
     my $options = $default_options->override(shift @_) if ref($_[0]);

     # ....
 }

 # SYNTAX: my_subroutine3(\%options, @args)
 #
 # ref($args[0]) ne 'HASH'

 sub my_subroutine3
 {
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options = Data::Startup->new() unless $default_options;
     my $options = $default_options->override(shift @_) if ref($_[0] eq 'HASH');
     my (@args) = @_;

     # ....
 }

If program module does not require program module wide global 
default options, than still use C<Data::Startup> to provide
liberal options syntax as follows

 # SYNTAX: my_subroutine1($arg1 .. $argn, @options)
 #         my_subroutine1($arg1 .. $argn, \@options)
 #         my_subroutine1($arg1 .. $argn, \%options)
 #
 
 sub my_subroutine4
 {
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($arg1 .. $argn, @options) = @_
     my $options = new Data::Startup(@options);

     # ....
 }

This technique may be extended to many more different subroutine with
a similar style syntax.

The C<Data::Startup> class may be used 
may also be used to create objects off a base C<$default_object> as follows:

 use Data_Startup;
 unshift @ISA,'Data_Startup'; # first among classes
 use vars qw($default_object);
 $default_object = new Data::Startup( @default_list);

 sub new
 {
     $default_options->override( @_ );
 
 }  

 my $object = new my_package;
  
 my @old_options = object->config( @_ );
 my @old_default_options = $my_package::$default_object->config( @_ );

 sub method
 {
    $self = shift;
    $value1 = $self->{$key1};

 }
 
And then there are the hybrid subroutine, class syntax and 
probably some other possibilies that are not readily apparent.

=head1 METHODS

=head2 new

The C<new> method c<bless> the input C<@option_list> creating
a default options hash object.

=head2 config

The C<config> method reads and writes individual key,value pairs
or groups of key,value pairs in the C<$option> object.

The method response with no inputs with all the C<$key,$value>
pairs in C<$options>; a single C<$key> input with the C<$key,$value>
for that C<$key>; and, a group of C<$key, $value> pairs, C<@option_list>
by replacing all the C<$option> C<$key> in the group by the paired <$value> returning
the C<@old_options_list> of old C<$key,$value> pairs.
The C<config> method does not care if the C<@option_list> is an
array, a reference to an array or a reference to a hash.

=head2 override

The C<override> method takes a default options object, C<$startup_options>,
creates a new duplicate object, C<$options>, keeping C<$startup_options>
intact, and replaces selected optioins in C<$options> with override
values, C<@option_list>.

=head1 REQUIREMENTS

Coming.

=head1 DEMONSTRATION

 #########
 # perl Startup.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     my $uut = 'Data::Startup';

     my ($result,@result); # provide scalar and array context
     my ($default_options,$options) = ('$default_options','$options');

 ##################
 # create a Data::Startup default options
 # 

 ($default_options = new $uut(
        perl_secs_numbers => 'multicell',
        type => 'ascii',   
        indent => '',
        'Data::SecsPack' => {}
    ))

 # bless( {
 #                 'perl_secs_numbers' => 'multicell',
 #                 'Data::SecsPack' => {},
 #                 'type' => 'ascii',
 #                 'indent' => ''
 #               }, 'Data::Startup' )
 #

 ##################
 # read perl_secs_numbers default option
 # 

 [$default_options->config('perl_secs_numbers')]

 # [
 #          'perl_secs_numbers',
 #          'multicell'
 #        ]
 #

 ##################
 # write perl_secs_numbers default option
 # 

 [$default_options->config(perl_secs_numbers => 'strict')]

 # [
 #          'perl_secs_numbers',
 #          'multicell'
 #        ]
 #

 ##################
 # restore perl_secs_numbers default option
 # 

 [$default_options->config(perl_secs_numbers => 'multicell')]

 # [
 #          'perl_secs_numbers',
 #          'strict'
 #        ]
 #

 ##################
 # create options copy of default options
 # 

 $options = $default_options->override(type => 'binary')

 # bless( {
 #                 'perl_secs_numbers' => 'multicell',
 #                 'Data::SecsPack' => {},
 #                 'type' => 'binary',
 #                 'indent' => ''
 #               }, 'Data::Startup' )
 #

 ##################
 # verify default options unchanged
 # 

 $default_options

 # bless( {
 #                 'perl_secs_numbers' => 'multicell',
 #                 'Data::SecsPack' => {},
 #                 'type' => 'ascii',
 #                 'indent' => ''
 #               }, 'Data::Startup' )
 #

 ##################
 # array reference option config
 # 

 [@result = $options->config([perl_secs_numbers => 'strict'])]

 # [
 #          'perl_secs_numbers',
 #          'multicell'
 #        ]
 #

 ##################
 # array reference option config
 # 

 $options

 # bless( {
 #                 'perl_secs_numbers' => 'strict',
 #                 'Data::SecsPack' => {},
 #                 'type' => 'binary',
 #                 'indent' => ''
 #               }, 'Data::Startup' )
 #

 ##################
 # hash reference option config
 # 

 [@result = $options->config({'Data::SecsPack'=> {decimal_fraction_digits => 30} })]

 # [
 #          'Data::SecsPack',
 #          {}
 #        ]
 #

 ##################
 # hash reference option config
 # 

 $options

 # bless( {
 #                 'perl_secs_numbers' => 'strict',
 #                 'Data::SecsPack' => {
 #                                       'decimal_fraction_digits' => 30
 #                                     },
 #                 'type' => 'binary',
 #                 'indent' => ''
 #               }, 'Data::Startup' )
 #

 ##################
 # verify default options still unchanged
 # 

 $default_options

 # bless( {
 #                 'perl_secs_numbers' => 'multicell',
 #                 'Data::SecsPack' => {},
 #                 'type' => 'ascii',
 #                 'indent' => ''
 #               }, 'Data::Startup' )
 #

 ##################
 # create a hash default options
 # 

   my %default_hash = (
        perl_secs_numbers => 'multicell',
        type => 'ascii',   
        indent => '',
        'Data::SecsPack' => {}
    );
 $default_options = \%default_hash

 # {
 #          'perl_secs_numbers' => 'multicell',
 #          'Data::SecsPack' => {},
 #          'type' => 'ascii',
 #          'indent' => ''
 #        }
 #

 ##################
 # override default_hash with an option array
 # 

 Data::Startup::override($default_options, type => 'binary')

 # {
 #          'perl_secs_numbers' => 'multicell',
 #          'Data::SecsPack' => {},
 #          'type' => 'binary',
 #          'indent' => ''
 #        }
 #

 ##################
 # override default_hash with a reference to a hash
 # 

 Data::Startup::override($default_options, {'Data::SecsPack'=> {decimal_fraction_digits => 30}})

 # {
 #          'perl_secs_numbers' => 'multicell',
 #          'Data::SecsPack' => {
 #                                'decimal_fraction_digits' => 30
 #                              },
 #          'type' => 'ascii',
 #          'indent' => ''
 #        }
 #

 ##################
 # override default_hash with a reference to an array
 # 

 Data::Startup::override($default_options, [perl_secs_numbers => 'strict'])

 # {
 #          'perl_secs_numbers' => 'strict',
 #          'Data::SecsPack' => {},
 #          'type' => 'ascii',
 #          'indent' => ''
 #        }
 #

 ##################
 # return from config default_hash with a reference to an array
 # 

 [@result = Data::Startup::config($default_options, [perl_secs_numbers => 'strict'])]

 # [
 #          'perl_secs_numbers',
 #          'multicell'
 #        ]
 #

 ##################
 # default_hash from config default_hash with a reference to an array
 # 

 $default_options

 # {
 #          'perl_secs_numbers' => 'strict',
 #          'Data::SecsPack' => {},
 #          'type' => 'ascii',
 #          'indent' => ''
 #        }
 #

=head1 QUALITY ASSURANCE

Running the test script C<Startup.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Startup.t> test script, C<Startup.d> demo script,
and C<t::Data::Startup> program module POD,
from the C<t::Data::Startup> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Startup.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::Data::Startup> program module
is in the distribution file
F<Data-Startup-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.


=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::Data_Startup|Docs::Site_SVD::Data_Startup>

=item L<Test::STDmaker|Test::STDmaker> 

=back

=cut

### end of script  ######