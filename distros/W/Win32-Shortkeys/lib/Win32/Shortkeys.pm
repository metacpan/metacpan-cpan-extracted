package Win32::Shortkeys;
#use lib qw( U:/docs/perl/mod/hg_Win32-Shortkeys-Kbh/lib);

=head1 NAME

Win32::Shortkeys - A shortkeys perl script for windows

=cut

our $VERSION = '0.05';

=head1 VERSION

0.05

=cut

use strict;
use warnings;
use Config::YAML::Tiny;
use Win32::Clipboard;
use  Win32::Shortkeys::Kbh  qw(:all);
use Win32::Shortkeys::Manager;
use XML::Parser;
#use Data::Dumper;
use Time::HiRes qw(usleep);
use Carp;
use Encode;

#my %data;

my %shk_use_clpbrd;

sub new {
    my ( $class, $file ) = @_;

    my $self = bless( {}, ref($class) || $class );
    my $usage = <<END;
    usage Win32::Shortkeys->new(config_file);
END
    die $usage unless ($file);

    $self->{config} = Config::YAML::Tiny->new( config => $file );
    return $self;
}

sub run {
    my $self    = shift;
    my $com_map = $self->{config}->get_vkcode_map
        or confess("vkcode_map undefined");

    for my $k ( keys %$com_map ) {

        # print "$k: ", eval $com_map->{$k}, "\n";
        $com_map->{$k} = eval $com_map->{$k} or confess($@);

    }
    
    #die eval $self->{config}->get_quit_key;
    $self->{quit_key} = eval $self->{config}->get_quit_key or confess($@);
    $self->{load_key} = eval $self->{config}->get_load_key or confess($@);
    $self->{usleep_delay} = eval $self->{config}->get_usleep_delay
        or confess($@);
    $self->{com_map} = $com_map;
    my $xml = $self->parse_file;
    $self->{shkm} = Win32::Shortkeys::Manager->new( $xml );

    #$self->{shkm}->print_all;

    set_key_processor( sub { $self->process_key(@_); } );

    #set_key_processor(sub { $self->test(@_);});

    register_hook();

    msg_loop();

}

sub parse_file {
    my $self     = shift;
    my $encoding = $self->{config}->get_file_encoding;
    $encoding = ( $encoding ? $encoding : "UTF-8" );
    my $path = $self->{config}->get_file_path
        or confess("path to shortkeys xml file undefined");
   
    # "<:raw:encoding($encoding):crlf:utf8",
    # open( my $FH, "<:encoding($encoding)", $path )        or die "can't open file: $!";

    #binmode(STDOUT, ":encoding(utf8)");
    my $p =
        XML::Parser->new( ErrorContext => 2, ProtocolEncoding => $encoding );

    #	'Default' => \&MySubs::def,
    #    'Final' => \&MySubs::final

    $p->setHandlers(
        'Start' => \&Win32::Shortkeys::MySubs::start,
        'Char'  => \&Win32::Shortkeys::MySubs::char,
        'End'   => \&Win32::Shortkeys::MySubs::end,
       

        # 'Default' => \&MySubs::def
    );

    #print "parsing\n"; 
   eval {$p->parsefile($path); };
   if ( $@ ){
        $@ =~ s/at \/.*?$//s;               # remove module line number
        print "\nERROR in '$path':\n$@\n";
   
    } else {
       print "'$path' parsed with success\n";

   }
    return  Win32::Shortkeys::MySubs::get_data();

}



sub process_key {
    my ( $self, $cup, $code, $alt, $ext ) = @_;

    return unless $cup;    #process key released, not key pressed
    # print "process_key : $code\n";

    if ( $code == $self->{quit_key} ) {
        unregister_hook();
        #Win32::Process::KillProcess( $$, -1 );
        quit();

    }
    elsif ( $code == $self->{load_key} ) {
        #%data = ();
        my $xml = $self->parse_file;
        $self->{shkm} = Win32::Shortkeys::Manager->new( $xml );
        #$self->{shkm}->print_all;

    }
    else {
        #  usleep($self->{usleep_delay});
        $self->{shkm}->listen($code);
    }

    if ( $self->{shkm}->is_ready ) {
        my $shk = $self->{shkm}->get_shortkey;
        unregister_hook();
        if ( $shk_use_clpbrd{$shk} ) {
            my $data = $self->{shkm}->get_data;
            $data =~ s/\n/\015\012/g;
            #utf8 required:
            #my $oct = Encode::encode("cp1250", $data);
            my $oct = Encode::encode("iso-8859-1", $data);
            Win32::Clipboard::Set($oct);
            #Win32::Clipboard::Set($data);
            usleep( $self->{usleep_delay} );
            # send length($shk) + 1 delete keys + ctrl + v
            paste_from_clpb( length($shk) + 1 );
        }
        else {
            my $rawdata = $self->{shkm}->get_data;

            # send_string("Key hitted " . chr ( $code ));
            $self->parse_raw_data( $rawdata, $shk );
            
        }
        register_hook();
        # print ("ERROR in register_hook $@\n") if ($@);

    }
}

sub parse_raw_data {
    my ( $self, $raw, $shk ) = @_;
    my @chunks  = split( /#/, $raw );
    $chunks[0] = $raw unless (@chunks); #do the loop below even if $raw is a zero length string
    my $delkeys = length($shk) + 1;
    my $pos     = 0;
    my $last    = @chunks;
    my %seen;
    my %chunk_seen;
    #print "last: $last\n";
    #print "chunks: ", join( "*", @chunks ), "\n";

    # my ($com, $text, $has_next, $next, $how_much);
    for my $raw (@chunks) {
        $chunk_seen{ $pos++ } = 0;
    }
    $pos = 0;
    for my $raw (@chunks) {
        my $com      = undef;
        my $text     = undef;
        my $has_next = ( $pos + 1 < $last ? 1 : 0 );
        my $next     = ( $has_next ? $chunks[ $pos + 1 ] : undef );
        my $how_much = 1;
        my $seen     = $pos;
        #print "raw: ", ( defined $raw ? $raw : " undef " ), " has_next: ", $has_next,
        #    " pos: ", $pos, " next: ", ( $next ? $next : " undef" ), "\n";
        if ( $pos == 0 ) {

            if ( !$raw && $has_next ) {
                if ( !$next ) {
                    #print "jump over *", $next, "*\n";
                    next;
                }
            }
            else {
                # print "*** $raw $pos\n";
                $text = $raw;
            }
        }
        else {
            #si l'élément en cours est vide et que le suivant existe
            #la chaine contenait ##

            if ( !$raw && $has_next ) {
                $text = "#";
                if ( $next && $has_next ) {
                    $text = "#" . $next;
                }
                $seen = $pos + 1;
            }
            else
            {    #sinon c'est une commande éventuellement suivie par du texte
                $how_much = substr( $raw, 1, 2 );
                $com      = substr( $raw, 0, 1 );
                if ( length($raw) > 3 ) {
                    $text = substr( $raw, 3 );
                }
            }
        }
        next if $chunk_seen{$seen};
        if ($com) {
            if ($delkeys) {
                usleep( $self->{usleep_delay} );
                send_cmd( $delkeys, VK_BACK );
            }

            #$com doit etre traduit par evmap \t
            if ( exists $self->{com_map}->{$com}) {
                my $vkcode = $self->{com_map}->{$com};
                send_cmd( $how_much, $vkcode );
            } elsif ($com eq "z"){
                usleep ( $how_much * 100_000 );
            } else {
                carp ("undefined command abreviation: ", $com);
            }
        }
        if (defined $text) { # send the delkeys even is text is a zero length string
            if ($delkeys) {
                usleep( $self->{usleep_delay} );
                send_cmd( $delkeys, VK_BACK );
            }
            send_string($text);
        }
        $chunk_seen{$seen} = 1;
        $delkeys = 0;
    }    #for
    continue { $pos++; }
}

sub parse_raw_data_old {
    my ( $self, $raw, $shk ) = @_;
    my @chunks = split( /#/, $raw );

    #my $text;
    my $delkeys = length($shk) + 1;

    #my $pos = 0;
    #my $com = undef;

    my $last = @chunks;
    #print "last: $last\n";
    #print "chunks: ", join( "*", @chunks ), "\n";
    my %com_map = %{ $self->{com_map} };

    #for $raw (@chunks) {
    for ( my $pos = 0; $pos < $last; $pos++ ) {

        #my $raw= $chunks[$pos];
        my $com      = undef;
        my $text     = undef;
        my $how_much = 1;
        print "raw: ", ( $chunks[$pos] ? $chunks[$pos] : " undef " ),
            " pos: $pos\n";

#print "defined ", ( defined $chunks[$pos] ? $chunks[$pos] : " undef "), "\n";
#print "length ", (length $chunks[$pos] ? $chunks[$pos] : " length : 0 "), "\n";
        if ( $pos == 0 ) {
            if ( !$chunks[$pos] && ( $pos + 1 < $last ) ) {

                #die "here";
                if ( !$chunks[ $pos + 1 ] ) {
                    print "jump over *", $chunks[ $pos + 1 ], "*\n";

                    #$pos++;
                    next;
                }
            }
            else {
                $text = $chunks[$pos];

            }

        }
        else {
            #si l'élément en cours est vide et que le suivant existe
            #la chaine contenait ##
            if ( !$chunks[$pos] && ( $pos + 1 < $last ) ) {
                $text = "#";

                # (copies.length>i+1 && copies[i+1].length()>0)
                if ( $chunks[ $pos + 1 ] && ( $pos + 1 < $last ) ) {
                    $text = "#" . $chunks[ $pos + 1 ];

                }

                #print "jumpover *", $chunks[$pos + 1], "*\n";
                $pos++;

                #next;
            }
            else
            {    #sinon c'est une commande éventuellement suivie par du texte
                $how_much = substr( $chunks[$pos], 1, 2 );
                $com      = substr( $chunks[$pos], 0, 1 );
                if ( length( $chunks[$pos] ) > 3 ) {
                    $text = substr( $chunks[$pos], 3 );
                }
            }
        }
        # print "text: ", ( $text ? $text : " undef" ), "\n";
        # print "com: ",  ( $com  ? $com  : " undef" ), "\n";
        if ($com) {
            if ($delkeys) {
                usleep( $self->{usleep_delay} );
                send_cmd( $delkeys, VK_BACK );
                $delkeys = 0;
            }

            #$com doit etre traduit par evmap \t
            my $vkcode = $com_map{$com};

            #die $com;
            send_cmd( $how_much, $vkcode );

        }
        if ($text) {
            # print "delkeys: $delkeys\n";
            if ($delkeys) {
                usleep( $self->{usleep_delay} );

                #die $delkeys;
                send_cmd( $delkeys, VK_BACK );
            }

            #usleep($self->{usleep_delay});
            send_string($text);
            $delkeys = 0;
        }

    }
}

package Win32::Shortkeys::MySubs;
#use Data::Dumper;

my $shk;
my $current_text;
my %data;
sub start {
    my ( $p, $el, %atts ) = @_;

    my $key;
    if ( $el eq "data" ) {
        $shk          = $atts{k};
        $shk_use_clpbrd{$shk}   = 0;
        $current_text = undef;
            if ( $atts{"use.ctrl_v"} ) {

        # push @clpelems, $shk;
            $shk_use_clpbrd{$shk} = 1;
        }

    }
    elsif ( $el eq "dataref" ) {
        $key = $atts{"id"};
        $current_text .= $data{$key} if ( $data{$key} );

    }

}


sub end {
    my ( $p, $el ) = @_;
    #if ( $current_text && $el eq "data" ) {
     if ($el eq "data") {
        # print "end\nshk : $shk : $current_text\n";
        $data{$shk} = ( defined $current_text ? $current_text : "");
        # if ( $shk eq "a" ) { print( "end : ", $current_text, "\n" ); }
        $current_text = undef;

    }

}

sub char {
    my ( $p, $s ) = @_;
    return unless $shk;
    # $s =~ s/^[\f\t ]+//;    # Replace leading tab  with nothing
    # $s =~ s/[\f\t ]+$//; #don't substitute in order to preserve space between datarefs elements
     $s =~ s/[\f\t ]+/ /g;
    $s =~ s/^\n$//g unless ( $shk_use_clpbrd{$shk} );

    #print("char: $s L:", length($s), "\n");
    $current_text .= $s if ( defined $s );


}

sub get_data{
    return \%data;
}


=head1 SYNOPSIS

  use Win32::Shortkeys;
  my $s = Win32::Shortkeys->new("kbhook.properties");
  $s->run;

Depending on the the sorkeys.xml file, some keystroke are replaced with string or keys command (enter, tab, cursor right ...) taken from this file.

=head1 DESCRIPTION

Since the synopsis above is short, the main things to describe are in the file pass to C<Win32::Shortkeys->new($file)>.

=head2 Properties file

It must follow the Config::YAML::Tiny syntax. Mine looks like

    file_path: shortkeys_utf8.xml
    file_encoding: UTF-8
    use_ctrl_v: 1
    load_key: VK_HOME
    quit_key: VK_F12
    usleep_delay: 400_000
    vkcode_map: 
        t: VK_TAB
        e: VK_RETURN
        d: VK_DOWN
        l: VK_LEFT
        r: VK_RIGHT
        x: VK_BACK
        s: VK_SHIFT
        c: VK_CONTROL
        a: VK_MENU
        w: VK_SPACE
        h: VK_HOM

The key given in the load_key property is used to reload the shorkeys.xml file (without exiting the script).
The key  given in the quit_key property is used to terminate the script.

=head2 The xml file

It's name is given by the C<file_path> property.
It's xml syntax is:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE shortkey SYSTEM "dtd/shk.dtd">
    <shortkey>
    <data k='t'>Recent advances in biochemical and molecular diagnostics for the rapid detection of antibiotic-resistant Enterobacteriaceae: a focus
     </data>
    <data k='j'>Expert Review of Molecular Diagnostics
    </data>
    ....

    </shortkey>

The values of the k attribute are a-z string composed of lower case character(s) (a string can have two or more characters).
I call those strings shortkeys and when press on the keyboard after they < key with the script running, the key pressed are replaced by the content of the corresponding data element.

For example, with the cursor in an opened notepad file, hitting the two keys <j when the script is running will replace this 
two characters with the value of the corresponding <data> element: Expert Review of Molecular Diagnostics.

The shortkeys.xml file should be utf-8 encoded, even if the encoding can be defined in the properties.

With the key <, the script enter a "search mode" for a shortkey sequence. This key is hard coded and can't be changed (unless you edit the code).

The text from the shortkeys file is sent to the keyboard using the send_input API function. With using the C<use.ctrl_v='1'> attribute in a data element, the text will be place in the clipboard and paste (with sending the keys ctlr + v) at the cursor position.

    <data k= 'a' use.ctrl_v= '1'>
     This text will be copied and paste. 
     And the new line will be preserved.
    </data>


In the xml file, data elements can be combine using a dataref element.

    <data k='qu'>10.1080/14737159.2017.1289087</data>
    <data k= 'u'>
        Published version; http://dx.doi.org/<dataref id= 'qu'></dataref>
    </data>

When hitting <u, the text that will be subtitued will be Published version; http://dx.doi.org/10.1080/14737159.2017.1289087

=head2 Commands syntax in shortkey.xml

=over 

=item * a command keystroke start with  # (to diplay # as a character, it has to be enter has ##), next you have to give

=item * the command itself, set by a character (only one character) listed in the map defined with the property vkcode_map

    vkcode_map: 
        t: VK_TAB
        e: VK_RETURN
        ...

The character z is hardcoded to indicate a waiting time : in the shortkeys_utf8.xml file C<#z04>
will calls the code

    usleep ( 4 * 100_000 );

If z is used to indicate a key in vkcode_map, this will be overriden.

=item * how much you want to repeat that command,  on two position, with a padding 0 if necessary (01)

=item * the next characters are treated as text (unless a new command keystroke is defined with #)

=item * The shift, control and alt keys are released 

=over
            
=item * after a non-command key has been given. For example ctr+shift+a (written as #c01#s01a) will send the following event: key press for the keys control and shift, key press and released for the a key, key release for shift and control

=item * at the end of a command keystroke, if the keys have not been released. For example a sequence of shit+tab, shift+tab, shift+tab (#s01#t01#t01#t01) will release the shift key at the end. On the contrary #s01#t01#t01#t01abc will call three back tab and will write Abc.

=back
  
=back    

=head1 INSTALLATION

To install this module type the following:

	perl Makefile.PL
	make
	make test
	make install

On windows use nmake or dmake instead of make.

=head1 DEPENDENCIES

The following modules are required in order to use this module

  Test::Simple => 0.44,
  Win32::Shortkeys::Kbh => 0.01,
  Config::YAML::Tiny => 1.42,
  Win32::Clipboard => 0.58,
  XML::Parser => 2.44,
  Encode => 2.84,
  Time::HiRes => 1.9733,
  Carp => 1.40

=head1 SEE ALSO

L<Win32::Shortkeys::Ripper>

L<Win32::Shortkeys::Kbh>

=head1 SUPPORT

Any questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from

L<http://sourceforge.net/projects/win32-shortkeys/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

1;



