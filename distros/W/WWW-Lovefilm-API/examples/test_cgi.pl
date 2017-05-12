#!/usr/bin/perl

=pod

=head1 NAME

test_cgi.pl

=head1 DESCRIPTION

This is an incredibly simple (and awful) script to show new programmers
the OAuth steps required to connect to LOVEFiLM. Please use it as a guide
only as programming style has moved on since the 90's, however it does keep
the dependancies down.

Also, it will only work for one user.

=head1 RUNNING

Having a checkout/download version of the code, I setup apache to have a
virtual server with its cgi-bin set like this

    ScriptAlias /cgi-bin/ /the/full/path/WWW-Lovefilm-API/examples

The lib dir is at /the/full/path/WWW-Lovefilm-API/lib, and the required
package WWW::Lovefilm::API can be found in there. Hence you don't have
to install the package to run it since it is relative and it will be found.

Make sure "vars_tokenless.inc" in the examples directory has your consumer_key
and consumer_secret set for your app.

=head1 INTERNAL FUNCTIONS

=cut


use strict;
use warnings;
use CGI;
use Data::Dumper;
use Storable qw( freeze thaw );
use URI::Escape;
use XML::Simple;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Lovefilm::API;

# I've not tested this code on a Windows machine, so the below code may or may not work.
#
my $store_filename = '/tmp/store'; # UNIX/Linux only

if (! -e '/tmp') {
    if ($ENV{TEMP}) {
        $store_filename = $ENV{TEMP};
    }
    else {
        die "No /tmp or TEMP environment variable set.\n";
    }
}

my $q = CGI->new;

# Prepare various HTTP responses
print
    $q->header() .
    $q->start_html('My LOVEFiLM App Demo');

my %auth = (
    do('vars_tokenless.inc'),
);

my %store = _read();

my $lovefilm = WWW::Lovefilm::API->new({
    %auth,
    %store,
    content_filter => sub { XMLin(@_) },
});


if ( defined($store{access_token}) ) {
    # If we have a access_token the users account is linked to out app
    # 
    _user_logged_in_page();
}

elsif ( $q->param('myuser') ) {
    # Been redirect back to this script by LOVEFiLM, the param 'myuser' we asked to to be sent back to us
    #
    _redirect();
}
else {
    # Fresh request to talk to LOVEFiLM, get a token
    #
    _link_user_account();
}

print $q->end_html;


=head2 _store

This is a cheap way of storing state when the user gets redirected.

=cut

sub _store {
    my %data = @_;
    my $dd   = Data::Dumper->new([\%data], [ qw(data) ]);

    open my $handle, ">$store_filename" or die "ERROR: could not write to file $store_filename: $!";
    print $handle $dd->Dump();
    close $handle;
}

=head2 _append

This appends any new key values onto the existing state.

=cut

sub _append {
    my %append   = @_;
    my %data     = (_read(), %append);
    my $dd       = Data::Dumper->new([\%data], [ qw(data) ]);

    _store(%data, %append);
}

=head2 _read

return a hash of representing the stored state

=cut

sub _read {
    unless (-f $store_filename) {
        return;
    }

    my $data = do {
        if( open my $fh, '<', $store_filename ) { local $/; <$fh> }
        else { undef }
    };

    eval $data;

    return %{$data};
}

=head2 _redirect

Assume the user has accepted a use signup, hence get the access_token, store it, then display the titles
they have at home.

=cut

sub _redirect {
    print
        $q->p("You must have been redirected back from LOVEFiLM after authorising this app for your account ".
              "as I picked up the parameter I asked LOVEFiLM to send back to me.");

    my %data = $lovefilm->RequestAccessToken(
        oauth_token  => $store{token},
        token_secret => $store{token_secret},
    );

    unless (defined($data{access_token}) && $data{access_token} ) {
        print $q->p("Error: Please look at the error.log file to see what went wrong");
    }
    else {
        _store( %store, %data );

        %store = _read();

        print $q->p("The details we have are: " . $q->pre(Dumper(\%store)));
        _user_logged_in_page();
    }
}

=head2 _link_user_account

Create a link for the user to click on that will take them to the LOVEFiLM site.
In the link is the oauth_token (request token) which we asked the LOVEFiLM API for
first, hence when the user goes to their website they know our app sent them.

=cut

sub _link_user_account {
    my %data = $lovefilm->RequestToken(  );

    if ($data{token} && $data{login_url}) {
        _store( %data );
    
        my $encoded  = uri_escape('?myuser=123'); # params will be sent back to us
        my $this_url = $q->url();
        my $url      = $data{login_url} . '?oauth_token=' . $data{token}. ";oauth_callback=$this_url" . $encoded;

        print 
            $q->h1('Ask LOVEFiLM for permission...');

        print $q->p("You need to click this link and tell LOVEFiLM to give access to MyAppName : " .
                    $q->a({-href => $url}, "GOTO LOVEFiLM")
                    );
    }
    else {
        print 
            $q->h1('Error') .
            $q->p("Could not access LOVEFiLM! ") .
            $q->p("Have you updated vars_tokenless.inc in the examples directory with your ".
                  "consumer key and secret?");
    }
}

=head2 _user_logged_in_page

This function will only work if the user has given permission to your
app to access your account at LOVEFiLM.

=cut

sub _user_logged_in_page {
    # Who has authorised this app?
    #
    $lovefilm->REST->Users(); # user_id automatically added in i.e. /users/1234567
    $lovefilm->Get();

    my $content = $lovefilm->content;

    my $first_name = $content->{first_name};
    my $last_name  = $content->{last_name};

    print $q->p("Welcome $first_name $last_name, at_home you have:");

    # What discs do they have at home?
    #
    $lovefilm->REST->Users->at_home();
    $lovefilm->Get();
    $content = $lovefilm->content;

    if (!defined($content->{'at_home_item'})) {
        print "<p>Nothing yet! Please go and select some great films, games and shows!</p>"
    }
    else {
        print
            $q->start_table() .
            $q->Tr($q->th(), $q->th("Name"), $q->th("Rating"));

        foreach my $item (@{$content->{'at_home_item'}}) {
            my $catalog_title   = $item->{catalog_title};
            my $art_href =_get_artwork_href($catalog_title);
            print
                $q->Tr(
                    $q->td($q->img({src => $art_href, alt => $catalog_title->{title}->{clean}, rowspan => 2})),
                    $q->td($catalog_title->{title}->{clean}).
                    $q->td($catalog_title->{rating} . "/5")
                );
        }
    }

    print $q->end_table;;
}

=head2 _get_artwork_href

The images for a given film (title) are split into different directories so we can't construct
a URL by just knowing the ID of the title.

This function performs an API call to get the href of the correct image size.

=cut

sub _get_artwork_href {
    my $catalog_title = shift;
    my $size          = shift || 'small';
    my $type          = shift || 'title';
    my $href_id       = $catalog_title->{id};
    my ($id)          = ($href_id =~ /(\d+)$/ );

    $lovefilm->REST->catalog->title($id)->artworks; # user_id automatically added in i.e. /users/1234567
    $lovefilm->Get();
    my $content = $lovefilm->content;

    foreach my $arttype ( @{$content->{artwork}} ) {
        if ($arttype->{type} eq $type) { # title or hero

            foreach my $image_data ( @{$arttype->{image}} ) {

                if ($image_data->{size} eq $size) {
                    return $image_data->{href};
                }
            }
        }
    }

    return "";
}
