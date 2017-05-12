package WebPresence::Profile::AOL;
use WebPresence::Profile;
@ISA = ('WebPresence::Profile');

############################################
#
# IMPORTANT WARNING!!!
# 
# This module doesn't work yet!!!
#
############################################

use LWP;
use URI::URL;
use HTTP::Cookies;
use HTML::PullParser;

use strict;

sub SetInfo {
    my $obj = shift;
    my $user = shift;

    my $aol_login = $obj->{aol_login};
    my $aol_pass = $obj->{aol_pass};

    unless ($aol_login and $aol_pass) {
        $obj->{errstr} = 'AOL or AIM Screen Name and Password required to '.
	                 'access.';
        return undef;
    }


    # We is a BIG LIAH saying we's Firefox. In British. On XP. Just what
    # they expect. But some of these sites act like assholes so screw it 
    # better that than this potentially not working if they block us
    my $web = LWP::UserAgent->new('Mozilla/5.0 (Windows; U; Windows NT 5.1;'.
				   ' en-GB; rv:1.8.0.3) Gecko/20060426 '.
				  'Firefox/1.5.0.3');
    $web->cookie_jar(HTTP::Cookies->new(file => "/usr/local/WPCookies.lwp",
                                        autosave => 1,
                                        ignore_discard => 1));
    #$web->cookie_jar({});
    
    my $login = $web->post('https://my.screenname.aol.com/_cqr/login/login.psp',
                           [sitedomain => 'memberdirectory-beta.estage.aol.com',
			    siteId => '',
			    lang => 'en',
			    locale => 'us',
			    authLev => '1',
			    siteState => "OrigUrl%3Dhttp%253A%252F%252Fmemberdirectory.aol.com%252Faolus%252Fprofile%253Fsn%253D$user",
			    isSiteStateEncoded => 'true',
			    mcState => 'initialized',
			    usrd => '1889976',
			    loginId => $aol_login,
			    password => $aol_pass,
			    rememberMe => 'off']);
    unless ($login->is_success) {
        $obj->{errstr} = 'AOL login failed:'. $login->status_line;
	return undef;
    }
    $obj->{login_page} = $login->content;
    $obj->{ua} = $web;
#=stop
    $obj->{login_headers} = $login->as_string;
    $obj->{login_headers} =~ s/\n\n.*//gsm;
    $obj->{login_cookies} = [];
    for my $h (split /[\r\n]+/, $obj->{login_headers}) {
        my ($k, $v) = split /:\s+/, $h;
        push @{$obj->{login_cookies}}, {$k => $v} if lc $k eq 'set-cookie';
    }
#=cut
    if ($obj->{login_page}
      =~ /You have entered an invalid Screen Name or password/) {
        $obj->{errstr} = 'AOL login failed: invalid login info.';
	return undef;
    }

    $obj->{pull_success} = "Didn't try yet.";
    my $url_base = 'http://memberdirectory.aol.com/aolus/profile?sn=';
    my $req = HTTP::Request->new('GET',
                                 "$url_base$user",
				 [@{$obj->{login_cookies}},
				  
				 );
    my $resp = $web->request($req);

    if ($resp->is_success) {
        my $prof;
	$obj->{pull_success} = "Successful.";
	$obj->{page} = $resp->content;
        my $p = HTML::PullParser->new(doc => $resp->content,
	                              start => 'tagname, event, attr',
                                      end => 'tagname, event, skipped_text',
				      ignore_elements => [qw(script style
				                             applet embed
							     object)],
                                      report_tags => ['script']);
	while (my $token = $p->get_token) {
	    my $type = $token->[1];
	    next unless ($type eq 'end');
            my $script = $token->[2];
	    if ($script =~ /var\s+nameString\s*=/) {
	        # this is the right script with the data in it
		# that is easy to read
		$script =~ /var\s+memMessage\s*=\s*"I am (\w+)\."/;
                $prof->{online} = $1;
		$script =~ /var\s+nameDetails\s*=\s*"([^"]*)"/;
		$prof->{name} = $1;
		$script =~ /var\s+locDetails\s*=\s*"([^"]*)"/;
		$prof->{loc} = $1;
		$script =~ /var\s+genderDetails\s*=\s*"([^"]*)"/;
		$prof->{gender} = $1;
		$script =~ /var\s+maritalDetails\s*=\s*"([^"]*)"/;
		$prof->{marital} = $1;
		$script =~ /var\s+hobbiesDetails\s*=\s*"([^"]*)"/;
		$prof->{hobbies} = $1;
		$script =~ /var\s+gadgetsDetails\s*=\s*"([^"]*)"/;
		$prof->{gadgets} = $1;
		$script =~ /var\s+occDetails\s*=\s*"([^"]*)"/;
		$prof->{occ} = $1;
		$script =~ /var\s+quoteDetails\s*=\s*"([^"]*)"/;
		$prof->{quote} = $1;
		$script =~ /var\s+linksDetails\s*=\s*"([^"]*)"/;
		$prof->{links} = $1;
	    }
	    for my $k (keys %{$prof}) {
	        # Strip out annoying HTML tags in profiles
	        $prof->{$k} =~ s/<[^>]*>//gsm;
	    }
	    $obj->{profile} = $prof;
	}
    }
    else {
        $obj->{pull_success} = 'Failed';
        $obj->{errstr} = "Can't retrieve AOL  member page for $obj->{user}.\n";
        return undef;
    }
}

1;
