package Text::ParseAHD;
#use base qw(BASE);
use Text::ParseAHD::Word;
use Text::ParseAHD::Definition;
use Class::Std;
use Class::Std::Utils;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

{
        my %html_of  :ATTR( :get<html>   :set<html>   :default<''>    :init_arg<html> );
        my %word_of  :ATTR( :get<word>   :set<word>   :default<''>    :init_arg<word> );
        my %pos_of  :ATTR( :get<pos>   :set<pos>   :default<''>    :init_arg<pos> );
        my %syllables_of  :ATTR( :get<syllables>   :set<syllables>   :default<''>    :init_arg<syllables> );
        my %defs_of  :ATTR( :get<defs>   :set<defs>   :default<''>    :init_arg<defs> );
        my %text_of  :ATTR( :get<text>   :set<text>   :default<''>    :init_arg<text> );
        my %word_obj_obj_of  :ATTR( :get<word_obj>   :set<word_obj>   :default<''>    :init_arg<word_obj> );
	
	
        sub START {
                my ($self, $ident, $arg_ref) = @_;
                #$html_of{$ident} = $arg_ref->{html}; 
		#$word_of{$ident} = $arg_ref->{word};
       		#$Word_of{$ident} = Text::ParseAHD::Word->new({'word',$word_of{$ident}}); 
       		$self->set_word_obj( Text::ParseAHD::Word->new({word => $self->get_word() }) ); 
		return;
        }
	
	sub parse_html { 
	        my ( $self ) = @_; 
		my $ident = ident $self;
		my $html = $html_of{$ident};
		while ( $html =~ m/<!--\s+begin\s+ahd4\s+-->(.*?)<!--\s+end\s+ahd4\s+-->/gsix ) {
                        my $definition_text = $1;
                           $definition_text =~ s/<b>(.*?)<\/b>//i;
                        my $word            = $self->clean_word( $1 );

#                       print "  STATUS: AHD4 definition " . ++$count . " found\n";

                        if ($word eq $word_of{$ident}) {
                                $definition_text =~ s/\n//g;                                      # Remove newlines
                                $definition_text =~ s/\&nbsp;//g;                                 # Remove nbsp
                                $definition_text =~ s/<br \/>//g;                                 # Remove br
                                $definition_text =~ s/^(.*?)<!--BOF_HEAD-->/<!--BOF_HEAD-->/six;  # Remove leading
                                $definition_text =~ s/<\/td>.*$//six;                             # Remove trailing

                                my @defs         = $self->split_defs( $definition_text );
				my $i=1;
				foreach my $def (@defs) { 
					print $i . "\n\n" . $def . "\n\n\n\n";
					$self->parse_definition( $def ); 
					$i++;
				}
			}
			#print $definition_text."\n\n\n";
                }
		$self->report_word();	
		return; 
	}

	sub clean_word {
                my ($self, $word) = @_;
                my $A             = chr(194);
                my $bullet        = chr(183);
                   $word          =~ s/://g;
                   $word          =~ s/$A//g;
                   $word          =~ s/$bullet//g;
                   $word          =~ s/<sup>.*?<\/sup>//;          # RH 080719
                   $word          =~ s/^\s+//;                     # RH 080719
                   $word          =~ s/\s+$//;                     # RH 080719
                return $word;
        }
	
	sub split_defs {
                my ($self, $text) = @_;
                my @defs          = split(/<!--BOF_HEAD-->/, $text ); shift @defs;
                return @defs;
        }

	sub parse_definition {
		my ($self, $text)  = @_;
                my $ident          = ident $self;
                my $pos            = '';
                my @word_forms     = ();
                my @definitions    = ();
		$text           =~ s/(.*?)<!--EOF_HEAD-->//six;
		$pos=$1;
		$text           =~ s/<!--BOF_SUBHEAD-->(.*?)<!--EOF_SUBHEAD-->//six;
                my $subhead        = $1;
		if (defined $subhead) {
                        #while ($subhead =~ m/<b>(.*?)<\/b>/gisx) { push @word_forms, $self->syllables( $1 ); }
                        while ($subhead =~ m/<b>(.*?)<\/b>/gisx) { push @word_forms, $1; }
                        	
			if    ($subhead =~ m/<i>(.*?)<\/i>/i)    { $pos = $1;  $pos =~ s/\.//g; }    # Subtype
                }
		#print "WORD FORMS: " . join(' ', @word_forms) ."\n\n\n";
		while ($text =~ m/<!--BOF_DEF-->(.*?)<!--EOF_DEF-->/gsix) {
                        my $def_text = $1;
                        my $new_defs;
			if ($def_text =~ m/<ol/) { $new_defs = $self->parse_list( $def_text, $pos ); }
                        else                     { $new_defs = [$self->parse_single( $def_text )]; }

                        foreach my $definition (@{ $new_defs }) {push @definitions, $definition; }
                }
		foreach my $definition (@definitions){
                        $self->get_word_obj()->add_definition($definition->{text}, $definition->{example}, $pos);	
		}

 	}

	sub parse_list {
                my ($self, $text, $pos ) = @_;
                    $text  =~ s/<ol\s+type="(\w+)">/\[/ig;
                    $text  =~ s/<\/ol>/]/ig;
                    $text  =~ s/<li>/{ text => '/ig;
                    $text  =~ s/<\/li>/'}, /ig;
                    $text  =~ s/'\[/\[/ig;
                    $text  =~ s/,\s]/]/ig;
                    $text  =~ s/]'/]/ig;
		    $text =~ s/<i>Informal<\/i>//ig;#added by Nathan
		    $text =~ s/<i>Slang<\/i>//ig;#added by Nathan
                    $text =~ s/text => '? ?\[{ text => '/text => '/ig;
		    $text =~ s/{ text => '<i>.*<\/i> \[{ text/{ text/ig;
		    $text =~ s/}\]}/}/ig;
		    $text =~ s/({ text => '[-\.\w\s]*)'([-\.\w\s]*'},)/$1$2/ig;
		    #$text  =~ s/<ol\s+type="(\w+)">//ig;
                    #$text  =~ s/<\/ol>/]/ig;
                    #$text  =~ s/<li>/{ text => '/ig;
                    #$text  =~ s/<\/li>/'}, /ig;
                    #$text  =~ s/'\[/\[/ig;
                    #$text  =~ s/,\s]/]/ig;
                    #$text  =~ s/]'/]/ig;

		print "LIST TEXT: $text\n";
                my $definitions = eval "return $text;";
                #my $definitions = [{ text => 'A domesticated carnivorous mammal <i>(Canis familiaris)</i> related to the foxes and wolves and raised in a wide variety of breeds.'}, { text => 'Any of various carnivorous mammals of the family Canidae, such as the dingo.'}, { text => 'A male animal of the family Canidae, especially of the fox or a domesticated breed.'}, { text => 'Any of various other animals, such as the prairie dog.'}, { text => '<i>Informal</i> [{ text => 'A person: <i>You won, you lucky dog.</i>'}, { text => 'A person regarded as contemptible: <i>You stole my watch, you dog.</i>'}, { text => 'A person regarded as unattractive or uninteresting.'}, { text => 'Something of inferior or low quality: <i>"The President had read the speech to some of his friends and they told him it was a dog"</i> <i>(John P. Roche).</i></font>'}, { text => 'An investment that produces a low return or a loss.'}]}, { text => '<i>Slang</i> [{ text => 'A person regarded as unattractive or uninteresting.'}, { text => 'Something of inferior or low quality: <i>"The President had read the speech to some of his friends and they told him it was a dog"</i> <i>(John P. Roche).</i></font>'}, { text => 'An investment that produces a low return or a loss.'}]}, { text => '<b>dogs</font></b> <i>Slang</i>  The feet.'}, { text => 'See <a href="/browse/andiron">andiron</a>.'}, { text => '<i>Slang</i>  A hot dog; a wiener.'}, { text => 'Any of various hooked or U-shaped metallic devices used for gripping or holding heavy objects.'}, { text => '<i>Astronomy</i>  A sun dog.'}];
		#while($text=~m/[
		
my @definitions;
                foreach my $definition ( @$definitions ) {
                #foreach my $definition ( @definitions ) {
                       #print "HELLO: $definition->{text}\n\n"; 
		       if ( $definition->{text} =~ m/^ARRAY/ ) {
                                foreach my $sub_list ( @{ $definition->{text} } ) {
                                        push @definitions, $self->parse_single( $sub_list->{text} );
                                }
                        } else {
                                push @definitions, $self->parse_single( $definition->{text} );
                        	#$self->get_word_obj()->add_definition($definitions[-1]{text}, $definitions[-1]{example}, $pos);	
				#my $list= $self->get_word_obj()->get_defs();
			        #my @list2 = @$list;	
				#$self->report_word(-1);
			}
                }
		
                return \@definitions;
        }
	
	sub report_word{
		my ($self, $i)=@_;
		my $word = $self->get_word_obj();
		
		print "WORD: " . $word->get_word() . "\n";
		my $list = $word->get_defs();
		my @list2 = @$list;
		if($i eq ''){
			$i=1;
			foreach my $def (@list2){
				print "DEF#$i:\n  text: " . $def->get_text() . "\n  example: " . $def->get_example() . "\n  pos: " . $def->get_pos() . "\n\n";
				$i++;
			}
		}else{
			my $def = $list2[$i];
			 print "DEF#$i:\n  text: " . $def->get_text() . "\n  example: " . $def->get_example() . "\n  pos: " . $def->get_pos() . "\n\n";
		}
	}
	
	sub parse_single {
                my ($self, $text ) = @_;
                my $ident          = ident $self;
                while ( $text      =~ m/<b>(.*?)<\/b><i>(.*?)<\/i>/gi ) {
                        my ($word_form, $pos) = ($self->syllables( $1 ), $2);  $pos =~ s/\.//g;  $pos =~ s/ //g;
                        #$self->_insert_word_form( $word_form, $pos );
                }
                my (@keys)         = ();
                my (@roots)        = ();
                my (%word_forms)   = ();
                   $text           =~ s/<tt>(.*?)<\/tt>//i;
                my $root='';
		#$root           = $1;  if ($root eq $text) { $root = ''; }

                # Check for additional word forms
                while ( $text      =~ s/<b>(.*?)<\/b><i>(.*?)<\/i>//gi ) {
                        my ($word_form, $pos) = ($self->syllables($1), $2);  $pos =~ s/\.//g;  $pos =~ s/ //g;
                        $word_forms{$word_form} = $pos;
                }
                if (keys %word_forms) { 
                        foreach my $key (sort keys %word_forms) { $self->_insert_word_form( $key, $word_forms{$key} ); }
                } else {
                        # No word forms, parse definition, root, example
			#print "SINGLE TEXT: $text \n";
                        my $example = '';
			$text =~ m/()/ig; #resetting $1
			$text           =~ s/<i>(.*?)<\/i>//i; 
                        $example        = $1;  
			
			#print "EXAMPLE: $example\n";
			
			if ($text eq $example) 
					{ $example = ''; }
			   $example        =~ s/["']//i;
                           $example        =~ s/\.//i; 
                           $text           =~ s/\[.*?]//i;
                        
                        if ($root) { 
                                if ($root =~ m/<font.*?>(.*?)<\/font>/g) { $root = $1; }
                                while ($root =~ m/<b>(.*?)<\/b>/g) { push @roots, $1; }
                                if (@roots) { $root = join(',', @roots); }
                                $root =~ s/'/:/g; }
                           $text           =~ s/<\/font>//i; 
                           $text           =~ s/<i>(.*?)<\/i>//i; 
                           $text           =~ s/<sup>.*?<\/sup>//i;
                           $text           =~ s/://i; 
                           $text           =~ s/["']//i; 
                           $text           =~ s/See Synonyms at <a.*?>.*?<\/a>\.//i;
                           $text           =~ s/See <a.*?>.*?<\/a>//i;
                           $text           =~ s/<b.*?>.*?<\/b>//i; 
                           $text           =~ s/<font.*?>.*?<\/font>//i;
                           $text           =~ s/<i.*?>.*?<\/i>//i;
                           $text           =~ s/\.//i;
                        
                       # push @keys, "word_id => '$word_id_of{$ident}'";
                        push @keys, "word    => '$word_of{$ident}'"; 
                        if ($pos_of{$ident} && !$root) { push @keys, "pos     => '$pos_of{$ident}'"; } 
                        if    ( $root && $example)     { push @keys, "root    => '$root'"; push @keys, "root_def => '" . $self->_sql_escape($example) . "'"; $example = ''; }
                        elsif ( $root )                { push @keys, "root    => '$root'"; }
                        #if ($example)                  { push @keys, "example => '" . $self->_sql_escape($example) . "'"; }
                        if ($example)                  { push @keys, "example => '$example'"; }
                        #if ($text)                     { push @keys, "text    => '" . $self->_sql_escape($text) . "'"; }
                        if ($text)                     { push @keys, "text    => '$text'"; }
                }
                
                return eval "return { " . join(', ', @keys) . " };";
	}
}
1; # Magic true value required at end of module
__END__

=head1 NAME

Text::ParseAHD - reads American Heritage Dictionary HTML file and returns word object with definitions


=head1 VERSION

This document describes Text::ParseAHD version 0.0.2


=head1 SYNOPSIS

    use Text::ParseAHD;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Text::ParseAHD requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-parseahd@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Crabtree, Nathan  C<< <crabtree@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Crabtree, Nathan C<< <crabtree@cpan.org> >>. All rights reserved.

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
