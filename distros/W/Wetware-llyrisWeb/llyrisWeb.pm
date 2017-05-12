package Wetware::llyrisWeb;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

use CGI qw/:standard/;

# This allows declaration    use Wetware::llyrisWeb ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#    dtk_lyris_init dtk_lyris_get_players 
#   parse_cmd_line
our %EXPORT_TAGS = ( 'all' => [ qw(
    dtk_show_query_page show_answerPage 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    
);
our $VERSION = '0.01';

use vars qw/@lyris_mailing_lists/ ;

# Preloaded methods go here.

#-----------------------
# dtk_lyris_init - used to initialize the lyris stuff and set lists to check
#   this is skanky Hiding a Require inside of the sub - but for the moment
#   it allows us to do other games
# as an TODO thing - we may want to load the security stuff here
# so that we return only those lists that the person is allowed to
# see to begin with - rather than them all - 

sub dtk_lyris_init {

    require 'lyrislib.pl';
    &lyris::init;
    
    #
    # we really need something that based upon the user
    # to select the Right Lists - something with
    # $user = $ENV{'REMOTE_USER'};

    @lyris_mailing_lists=&lyris::ListAll;
        
} # end sub dtk_lyris_init

#-----------------------
# dtk_lyris_get_players - check the lists to see if a player is in it
#            return the Hash of things that were found

sub dtk_lyris_get_players {

    my ($name)  = @_;

    my %retHash = ();   

    my @players = ();
    
    dtk_lyris_init;

    foreach my $list_name (@lyris_mailing_lists) {
        my %fields = &lyris::MemberAllNameEmail($list_name);
        while ( my ($key, $val) = each %fields ) { 
            push(@players, ( $key , $val ) ) 
                   if ( $key =~ m/$name/i or $val =~ m/$name/i );
        }

        # now the funk 
        if (@players) { 
                my %tmpHash = @players; 
                $retHash{ $list_name } = \%tmpHash; 
                @players = ();
        }
    } # end the foreach

    %retHash ;

} # end dtk_lyris_get_players


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Wetware::llyrisWeb - PM for lyris mailserver support

=head1 SYNOPSIS

  use Wetware::llyrisWeb;
  
  dtk_show_query_page($PageTitle);

  show_answerPage($PageTitle, @string);

  &Wetware::llyrisWeb::parse_cmd_line(@ARGV);

=head1 DESCRIPTION

This is the start of how to extend the lyris web front end
to solve a problem for our list admin types. 

the first two are simple CGI based tricks. The first
puts up a brain stoopid query page. The submit button
will set the param('ourInputStrings');

The second is the response page portion - given @strings
to go searching through the lyris emaillists for, it will
construct the results of that query in html and ship it back.

The third is for command line running on your Lyris Host so
that one merely passes in at the command line the $tokens
that you wish to search for.

TIMTOWTDI

=head1 EXAMPLES

The simple CGI front end would be something like:
   
  if ( $request =~ /GET/ ) {

    dtk_show_query_page($QUERY_PAGE_TITLE);

   } elsif ( $request =~ /POST/) {

    my $stuff = param('ourInputStrings');
    my @string = split(' ', $stuff);
    show_answerPage($RESPONSE_PAGE_TITLE, @string);

  }

The simple Command Line Script Would Be:

    #!/usr/bin/perl -w
    use Wetware::llyrisWeb qw/parse_cmd_line/;
    parse_cmd_line(@ARGV);
 
=head1 EXPORT

None by default.

=head1 COREQUISITES

CGI

C<'lyrislib.pl'>

=head1 AUTHOR

drieux, just drieux, E<lt>drieux@wetware.com<gt>

=head1 SEE ALSO

L<perl>.

L<CGI>.

=head1 OS TRIED ON

=pod OSNAMES

Solaris, Linux Redhat 7.2

=cut

##################################################################
# down here - where the AutoLoadables Begin

#-----------------------
# dtk_show_query_page - Answers the GET side - and puts up the
#               simple form to get our basic Answers.

sub dtk_show_query_page {

    my ($PageHeader) = @_;
    my $script_name = $ENV{'SCRIPT_NAME'};

    my $page = start_html( $PageHeader );
    $page .= h1({-align=>'center'},$PageHeader);
    $page .= start_form; #take the defaults

    $page .=  submit;
    $page .= textfield( -name => 'ourInputStrings',
                        -size => 50,
                        -maxlength => 80 );
    $page .= end_form;

    $page .= end_html;

    print header, $page ;

} # end dtk_show_query_page

#-----------------------
# the theory here is that we are where we need to be
# technically I do not need to pass the @ARGV - but thought
# it best to do so for safety sake and all. Ok, so I also wanted
# to have the flexibility if needed of doing pre-parsing of the @ARGV.

sub parse_cmd_line {

    my (@args)  = @_;

    print "\n";

    foreach my $name (@args) {

        my %rethash = dtk_lyris_get_players($name);

        print "#------------\n# did not find $name\n\n"
                    unless(%rethash);

        while ( my ($key, $val) = each %rethash ) {
            print "found $name in $key\n";
            while ( my ($k,$v) = each %{$val} ) {
                print "\t $k : $v\n";
            }
        }

        %rethash =();
        print "#-------\n";

    } # end the for each arg

} # end parse_cmd_line

#-----------------------
# show_answerPage - answer to the PUT call, and takes in
#           the listOfTokens to be checked through the lists

sub show_answerPage {

    my ($PageHeader, @listsOfTokens) = @_;

    my $page = start_html( $PageHeader );
    $page .= h1({-align=>'center'},$PageHeader);

    $page .= "<hr>";

    my @tableRows = ();
    foreach $token (@listsOfTokens) {

        @tableRows = ();

        my %foundHash = dtk_lyris_get_players($token);

        $page .= "<p align=center>$token Not found</p><hr><br>"
            unless(%foundHash);

        while ( my ($key, $val) = each %foundHash ) {
                # $key is the listname
            my $tableMsg = " = $token found in $key =";
            while ( my ($k,$v) = each %{$val} ) {
                             push(@tableRows , td([$k , $v]));
            }
            $page .= table({-align=>'center', -width=>'60%'},
                        Tr({-valign=>TOP},
                        [
                            th({-align=>'center', -colspan=>2 }, $tableMsg),
                            @tableRows
                        ]
                        )
            ); # right - the end of the table function call....

            $page .= '<br><hr align="center" width="50%"><br>';

            #Clean UP before we check the Next List this $toke n is in
            @tableRows = ();  

        } # end while we scope which lists this $oken is in
    } # end forEach list to grovel

    $page .= end_html;

    print header, $page ;

} # end show_answerPage


#-------------------------------------------------------
# End of the world as I knew it - drieux@wetware.com
#-------------------------------------------------------
