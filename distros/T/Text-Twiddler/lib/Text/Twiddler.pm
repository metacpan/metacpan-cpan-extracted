package Text::Twiddler;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

use Class::Std;
use Class::Std::Utils;
use Locale::Maketext::Pseudo;
use List::Cycle;

{
    my %output_ns  :ATTR( :get<output_ns> :init_arg<output_ns> :default<Text::Twiddler::CLI>);
    my %iterations :ATTR( :get<iterations> );
    my %longest    :ATTR( :get<longest> );
    my %start      :ATTR( :get<start>     :init_arg<start>     :default<Starting...> );
    my %text       :ATTR( :get<text>      :init_arg<text>      :default<Working...> );
    my %end        :ATTR( :get<end>       :init_arg<end>       :default<Done!> );
    my %lang       :ATTR(                 :init_arg<lang_obj>  :default<> );
    my %sway       :ATTR(                 :init_arg<sway>      :default<0>);
    my %frames     :ATTR( :get<frames> );
    my %cycle;

    sub START {
        my ($self, $ident, $arg_ref) = @_;

        $lang{ $ident } = ref $arg_ref->{'lang_obj'} && $arg_ref->{'lang_obj'}->can('maketext') 
            ? $arg_ref->{'lang_obj'} : Locale::Maketext::Pseudo->new();

        if( $arg_ref->{'output_ns'} ) {
            if( $arg_ref->{'output_ns'}->can('get_output_pre') 
                && $arg_ref->{'output_ns'}->can('get_output_str')
                && $arg_ref->{'output_ns'}->can('get_output_pst') 
            ) {
                $output_ns{ $ident } = $arg_ref->{'output_ns'};
            }
            else {
                carp $lang{ $ident }->maketext( q{'[_1]' does not have required '[_2]' method, defaulting to '[_3]'}, 'output_ns', 'get_output_*', $output_ns{ $ident } );
            }
        }

        {
            # just in case someone's turned on bytes...
            no bytes;
            $longest{ $ident } = length( $start{ $ident } ) >= length( $end{ $ident } ) ? length( $start{ $ident } ) : length( $end{ $ident } );
        
            my $twiddle_me_this = [];
            if ( ref $text{ $ident } eq 'ARRAY' ) {
                if ( @{ $text{ $ident } } > 1 ) {
                    @{ $twiddle_me_this } = @{ $text{ $ident } };
                    $text{ $ident } = [sort { length($b) <=> length($a) } @{ $twiddle_me_this } ]->[0]; # assign this the longest for length() calc below
                }
                else {
                    $text{ $ident } = $text{ $ident }->[0];
                }
            }

            $longest{ $ident }    = length( $text{ $ident } ) if length( $text{ $ident } ) > $longest{ $ident };
            $iterations{ $ident } = $longest{ $ident };
        
            if ( !@{ $twiddle_me_this } ) {
                $twiddle_me_this = Text::Twiddler::FX::standard($text{ $ident })
            }
        
            if ($sway{ $ident}) {
                push @{ $twiddle_me_this }, reverse @{ $twiddle_me_this } if $sway{ $ident };
                $iterations{ $ident } *= 2;
            }    

            @{ $frames{ $ident } } = @{ $twiddle_me_this }; # copy array, do not assign same ref
            $cycle{ $ident }  = List::Cycle->new({ 'values' => $twiddle_me_this });
        }
    }

    sub get_start_twiddler {
        my ($self) = @_;
        $| = 1; # TODO: this more robust or localized
        return $self->get_output_pre() . $self->get_output_str( $self->get_start() );
    }
  
    sub get_next_twiddler {
        my ($self) = @_;  
        return $self->get_output_str( $self->get_next_frame() );   
    }

    sub get_next_frame {
        my ($self) = @_; 
        return $cycle{ ident $self }->next();
    }

    sub get_end_twiddler {
        my ($self) = @_; 
        return $self->get_output_str( $self->get_end() ) . $self->get_output_pst();       
    }

    sub get_uniq_str {
        my ($self) = @_;
        return ref($self) . '-' . ident($self);        
    }

    sub get_output_pre { 
        my ($self) = @_;
        return $output_ns{ ident $self }->get_output_pre( $self );
    }

    sub get_output_str {
        my ($self, $string) = @_;
        return $output_ns{ ident $self }->get_output_str( $self, $string );
    }

    sub get_output_pst {
        my ($self) = @_;
        return $output_ns{ ident $self }->get_output_pst( $self );
    }

    sub get_blank_twiddler {
        my ($self) = @_;
        return $self->get_output_str('') . $self->get_output_pst();    
    }
}

package Text::Twiddler::HTML;

sub get_output_pre {
    my ( $output_ns, $twid ) = @_;
    my $id = $twid->get_uniq_str();
    return qq{<div id="$id"></div>\n};
}

sub get_output_str {
    my ( $output_ns, $twid, $string ) = @_;
    my $id = $twid->get_uniq_str();
    
    require HTML::Entities;
    $string = HTML::Entities::encode( $string );
    
    return qq{<script type="text/javascript">document.getElementById("$id").innerHTML ="$string"</script>\n};    
}

sub get_output_pst {
    my ( $output_ns, $twid ) = @_;
    return ''; # no-op since in HTML since we always write to the same div
}
 
package Text::Twiddler::CLI;

sub get_output_pre {
    my ( $output_ns, $twid ) = @_;
    return '';
}

sub get_output_str {
    my ( $output_ns, $twid, $string ) = @_;
    my $len = $twid->get_longest();
    my $bs = '';
    
    if( $string ne $twid->get_start() ) {
        $bs     = "\b" x $len;
    }

    return  $bs . sprintf('%-' . $len .'s', $string);
}

sub get_output_pst {
    my ( $output_ns, $twid ) = @_;
    return "\n";
}

package Text::Twiddler::FX;

sub standard {
    my ($string) = @_;

    my @twiddle_me_this;
    my @letters = split '', $string;
    for my $lidx ( 0 .. $#letters ) {
        my $part = $letters[0];
        for my $nxt ( 1 .. $lidx ) {
            $part .= $letters[$nxt];
        }
        push @twiddle_me_this, $part;
    }
    
    return \@twiddle_me_this;
}

sub secret_decoder {
    my ($string) = @_;

    my @twiddle_me_this;
    my @letters = split '', $string;
    
    return \@twiddle_me_this;        
}

1; 

__END__

=head1 NAME

Text::Twiddler - Twiddle text for any type of output

=head1 VERSION

This document describes Text::Twiddler version 0.0.1

=head1 SYNOPSIS

    use Text::Twiddler;
    my $twiddler = Text::Twiddler->new(\%options);

    # print animated text while we do a long operation so the 
    # user knows we're still running without the messy details

    print $twiddler->get_start_twiddler() if !$verbose;

    my($wtr, $rdr);
    my $pid = open3($wtr, $rdr, $rdr, @long_command);

    while( <$rdr> ) {
        if ( $verbose ) {
            print $_;
        } 
        else {
            print $twiddler->get_next_twiddler();
        }
    }

    print $twiddler->get_start_twiddler() if !$verbose;

=head1 DESCRIPTION

Show a 'twiddled' (IE animated) message, perhaps during a long running operation or for a neat effect.

What is nice is that, in the example in the synopsis, the animation is approximated to the actual state of the process.

In other words, if the command is blazing through its task (Eg many lines of output very rapidly), then the 'animation' is very quick.

If the command is working hard at one point and lags between outputting lines, then the animation also slows.

In this way the twiddler, hides all the details of the output while still giving some idea of how its coming along.

=head1 INTERFACE 

=head2 METHODS

=head3 new()

Create a twiddler object, can take a hashref of these, optional, arguments:

=over 4

=item output_ns

The NS to use for output methods. (If it's not one listed in 'OUTPUT TYPE DRIVERS' you will need to use() or require() it first)

default: Text::Twiddler::CLI

=item start

Start text

default: Starting...

=item text

String or array ref of strings (AKA "frames") to twiddle. 

(Note array's of one item get that item used as if it was passed as a string)

default: Working...

=item end

End text

default: Done!

=item sway

If true, the frames get appended a reversed version of the frames. The effect is a "sway".

For example, by default the string will appear one character at a time from left to right. When complete it start over from the left.

If sway is true, once it reaches the end it will start disappearing once character at a time from the right.

default: 0

=item lang_obj

A language object that can() maketext(), see "LOCALIZATION" below and L<Locale::Maketext::Pseudo>

=back

=head3 get_start_twiddler()

Returns the string to start the twiddler.

=head3 get_next_twiddler()

Returns the string that is the next "frame" in the twiddle.

=head3 get_blank_twiddler()

Returns a line that blanks out the twiddler and does a new line in the context of the output ns.

    if ( $found_it ) {
        print $twid->get_blank_twiddler();
        print "We found it! -$found_it-\n";
    }

    print $twid->get_next_twiddler();

=head3 get_end_twiddler()

Returns the string that ends the twiddler.

=head3 Other misc methods

=over

=item START()

Internal for L<Class::Std>

=item get_uniq_str()

Mostly internal, returns a unique identifier.

=item get_next_frame()

Internal, don't use it directly.

=item get_output_ns()

Get the object's 'output_ns'

=item get_iterations()

The number of iterations needed to complete one cycle of "frames"

=item get_longest()

The number of characters in the longest "frame"

=item get_start()

Get the object's 'start'

=item get_text()

Get the object's 'text'

=item get_end()

Get the object's 'end'

=item get_frames()

Returns an array ref of the frames as calculated by the 'FX' function used.

=back

=head2 OUTPUT TYPE DRIVERS

Support for twiddling for different types of output is provided by specific output type drivers.

Included in Text::Twiddler are two common ones described below:

=head3 Text::Twiddler::CLI

'output_ns' for twiddling to a Command Line Interface, generally a terminal

=head3 Text::Twiddler::HTML

'output_ns' for twiddling in HTML, generally to a browser.

=head3 Creating new ones

You could create your own for any type of output by providing a 'output_ns' package name that has these methods (even if they are a no-op for your output medium):

=over 4

=item * get_output_pre()

=item * get_output_str()

=item * get_output_pst()

=back

They are very simple methods. See the source for how these are used if you'd like to 
implement your own, More detailed 'how to' POD may be added depending on nice feedback :)

Here is what using you're custom one to twiddle a few messages across the sky might look like:

    require Text::Twiddler::LazerLightShow;
    print {$lazer_beam} "And now for a few messages...\n";

    for my $msg (qw(
	    'Welcome to Pink Floyd lazer light show!',
	    q{Please turn off cell phones as you won't be able to hear them anyway},
	    'No pictures please, your camera will be destroyed',
	    'Sit back relax and enjoy the show...',
	)) {	
        my $twid = Text::Twiddler->new({
            'output_ns' => 'Text::Twiddler::LazerLightShow',	
            'start'     => '',
            'text'      => $msg,
            'end'       => '',
        });

        # - no need for start or end text with this use
        # - we use get_iterations() instead of length() in $msg, because the type 
        #     of 'effect' may be different length than the text.

        for ( 1 .. $twid->get_iterations() ) {
            print {$lazer_beam} $twid->get_next_twiddler();   	
        }
    }

=head2 FX functionality

'FX' can stand for "Effects" or "Frame Expander", take your pick.

These 'FX' functions come with Text::Twiddler.

=head3 Text::Twiddler::FX::standard()

This is what is used internally by default. The string builds one character at a time from left to right.

'sway' will make it disappear one character at a time from right to left

=head3 Text::Twiddler::FX::secret_decoder()

This is a fun animation that makes it look like the string is gradually being decoded by a super secret spy computer.

'sway' will make it look like it was re-encoded by said super secret spy computer

    my $twid = Text::Twiddler->new({
        'text' => Text::Twiddler::FX::secret_decoder('Your misson should you choose to accept it...'),
    });

=head3 Creating new ones

These functions should return a string or array ref suitable for new()'s 'text' attribute.

The documentaton should be clear about whether or not 'sway' looks good, bad, or neutral.

They should be under the Text::Twiddler::FX name space, for example:

  Text::Twiddler::FX::Reveal

might have these functions:

     inside_out('abcd')   # ' b  ', ' bc ', 'abc ', 'abcd'  
     outside_in('abcd')   # 'a   ', 'a   d', 'ab d', 'abcd'
     random_fill('abcd')  # same idea as above but w/ random appearance

=head1 DIAGNOSTICS

=over

=item C<< '%s' does not have required 'get_output_*' method, defaulting to 'Text::Twiddler::CLI' >>

This means that the namespace you passed in 'output_ns' is not a Text::Twiddler 
output driver since its missing one or more required 'get_output' methods

=back

=head1 LOCALIZATION

This module uses L<Locale::Maketext::Pseudo> as a default if nothing else is 
specified to support localization in harmony with the apps using it.

See "DESCRIPTION" at L<Locale::Maketext::Pseudo> for more info on why this is 
good and why you should use this module's language object support at best and, 
at worst, appreciate it being there for when you will want it later.

=head1 CONFIGURATION AND ENVIRONMENT

Text::Twiddler requires no configuration files or environment variables (see below for %ENV note).

=over 4

=item localization  

Lexicon keys:

  '[_1]' does not have required '[_2]' method, defaulting to '[_3]'

Tip: set $ENV{'maketext_obj'} to an object that can() maketext(), see "LOCALIZATION" above and L<Locale::Maketext::Pseudo>

=back

=head1 DEPENDENCIES

L<Class::Std>, L<Class::Std::Utils>, L<Locale::Maketext::Pseudo>, L<List::Cycle>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-twiddler@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.