#!perl

=head1 Add/Search a User/Pass/Data entry/row
    
    Commandline, Windows Only

=head2 Synopsis

    Usage 

        .\up.pl ACTION DATA

        or 

        perl .\up.pl ACTION DATA

=head3 Add a record 
    
    \up.pl a "username|password|more|content"

=head3 Search a record 
    
    \up.pl s SEARCHTERM

=head3 Show Total Records 

    \up.pl t

=cut

=head2 Perl Strictures
=cut

use strict;
use warnings;

=head2 Perl 
    Enable/Disable Minimum Version
    default: 5.10.0
=cut

use 5.10.0;

=head3 Setup

    https://github.com/bislink/PCAccessFree

=cut

=head3 Download 

=head4 Strawberry Perl

    https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit.msi

=cut



=head2 User Changable Variables 

    Set/change Path to Powershell executable

=cut

my $POWERSHELL = "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";


=head2 Do not change anything beyond this point
    unless you know what you are doing
=cut

my $USERNAME = `$POWERSHELL \$Env:UserName`;
    chomp $USERNAME;

print qq{Hello $USERNAME\n};

=head2 File up.up
    File wherein all user/pass data is stored.
    Default
        C:/Users/USERNAME/up.up
=cut

my $up_file = "C:/Users/$USERNAME/up.up";

=head2 First Arugment
=cut

my $ACTION = $ARGV[0] || '';
    chomp $ACTION;

=head2 Second Argument
=cut

my $TERM = $ARGV[1] || '';
    chomp $TERM;

=head2 Date
=cut

my $DATE = `$POWERSHELL Get-Date -Format "yyyy-MM-dd-dddd-HH-mm-K"`;
    chomp $DATE;


=head2 Actions and Result 

=cut

if ($ACTION ne '') {
    # search/results 
    if ( $ACTION eq 's' ) {
        print &result ( term => "$TERM"); 
    } 
    # Add a row 
    elsif ( $ACTION eq 'a' ) {
        print add( cont => "$TERM", date => "$DATE" );
    }
    # show total 
    elsif ( $ACTION eq 't' ) {
        print total( date => "$DATE" ); 
    }
    #
} else {
    # no params 
    print &usage();
}


=head2 Result

    Subroutine Result

=cut

sub result {

    my %in = (
        term => '',
        @_,
    );
    #
    chomp $in{term};
    #
    my @matches; 
    #
    my $out;
    #
    my $error;
    #
    if ( -f "$up_file" and $in{term} ne '') {
    #
    if ( open( my $file, "<", "$up_file") ) {
        
        while ( my $line = <$file> ) {
            if ( $line =~ /$in{term}/i ) {
                #return qq{\t$. $line};
                #$line =~ s!\|!\t!g;
                push(@matches, qq{\t$. \t$line});
            } else {
                $error = qq{No Match for $in{term} };
            }
        }
        #
        close $file; 

        } else {
            $error = qq{Unable to open file #41};
        }
        #
    
    } else {
        $error = qq{Open: Not OK or no arguments provided #45};
    }
    #
    for (@matches) {
        $out .= qq{$_};
    }
    # 
    if ($error ne '' and $error !~ /^No Match for $in{term}/ ) {
        
        $out .= qq{$error\n};
    }
    #final output 
    return $out;

}
# end result 

=head2 Add a record
    to FDB
=cut

sub add {

    #
    my %in = (
        cont => '',
        date => '',
        @_,
    );

    #
    if ( -f "$up_file" and $in{cont} ne '') {
    #
    if ( open( my $file, ">>", "$up_file") ) {
        
        print $file qq{$in{cont}\|$in{date}\n};
        #
        close $file;

        return qq{$in{cont}\|$in{date} was added to FDB};

    } else {
        return "Unable to open file for writing #79";
    }
    
    } else {
        return "Open: Not OK or no arguments provided #80";
    }
}
# end add 

=head2 Usage 

    $0 s/a/t SearchTerm

=cut

sub usage {
    return "USAGE\n\t$0 s/a/t SEARCHTERM\n";
}


=head2 Show Total 

=cut

sub total {
    #
    my %in = (
        date => '',
        total => '',
        @_,
    );

    #
    if ( -f "$up_file" ) {
    #
    if ( open( my $file, "<", "$up_file") ) {
        
        my @lines = <$file>;
        #
        close $file;

        $in{total} = scalar @lines;

        return qq{\tTotal rows: $in{total}\n\t$in{date}};

    } else {
        return "Unable to open file for writing #79";
    }
    
    } else {
        return "Open: Not OK or no arguments provided #80";
    }

}



1;

