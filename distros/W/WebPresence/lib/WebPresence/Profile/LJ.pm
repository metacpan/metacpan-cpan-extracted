package WebPresence::Profile::LJ;
use WebPresence::Profile;
@ISA = ('WebPresence::Profile');

use LWP;
use URI::URL;
use HTML::PullParser;

use strict;

sub SetInfo {
    my $obj = shift;
    my $user = shift;
    $user =~ s/_/-/g;

    # Livejournal specifically allows bots
    # and since this fetches things automatically, we follow their
    # rules. If you'd rather lie, pass the wp_user_agent to the
    # constructor when you start up the object

    my $wp_admin_email = $obj->{wp_admin_email} || $ENV{SERVER_ADMIN};

    unless ($wp_admin_email) {
        $wp_admin_email = ($ENV{LOGNAME}||$ENV{USER}).'@'.
	                  (`dnsdomainname` || `hostname`);
    }

    my $script_name = $ENV{SCRIPT_NAME} || $0;
    $script_name =~ s/.*[\/\\:]//;

    my $uastring = $obj->{wp_user_agent};
    $uastring ||= "$script_name (".
                  (($ENV{HTTP_HOST}.$ENV{SCRIPT_NAME}) || $0).
                  "; email:$wp_admin_email".
                  ") WebPresence/1.0 LWP/$LWP::VERSION Perl/$]".
		  ($ENV{GATEWAY_INTERFACE} ? " $ENV{GATEWAY_INTERFACE}" : '');

    $obj->{wp_user_agent} ||= $uastring;

    my $web = LWP::UserAgent->new($obj->{wp_user_agent});
    my $resp = $web->get("http://$user.livejournal.com/profile?mode=full");
    if (not ($resp->is_success)
        and (    $resp->as_string =~ /500/
	     and $resp->as_string =~ /Bad hostname/)) {
        $user =~ s/-/_/g;
	$resp = $web->get("http://users.livejournal.com/$user/profile".
	                  "?mode=full");
    }
    if ($resp->is_success) {
        my $props;

        $obj->{page_source} = $resp->content;
	$obj->{page_source} =~ s/.*\*\*\*\*\*\*\*\*\s+-->//gsm;
	$obj->{page_source} =~ s/<!-- \/Content -->.*//gsm;

	$obj->{profile}->{success} = 1;

        my $p = HTML::PullParser->new(doc => $obj->{page_source},
	                              start => 'tagname, event, attr',
                                      end => 'tagname, event, skipped_text',
				      ignore_elements => [qw(script style
				                             applet embed
							     object)],
                                      report_tags => ['td']);
        my ($curelem, $curtoken, $curkey);
	my $started = 0;
	my $getemail = 0;
	my $stillFriendsToDo = 0;
	my $emailaddy;
        while (my $token = $p->get_token) {
	    my $elem = $token->[0];
	    my $type = $token->[1];
	    if ($type eq 'start') {
	        $curelem = $elem;
		$curtoken->{tag} = $elem;
		for my $k (keys %{$token->[2]}) {
		    $curtoken->{$k} = $token->[2]->{$k};
		}
	    }
	    elsif ($type eq 'end') {
	        next unless ($curelem eq $elem);
		$curtoken->{text} = $token->[2];
		next unless $curtoken->{text};

		if ($curtoken->{text} =~ /User:/) {
		    $started = 1;
		}
		if ($started) {
		    my $orig = $curtoken->{text};
		    $curtoken->{text} =~ s/&nbsp;/ /igsm;
		    $curtoken->{text} =~ s/<br\s*\/?>/ /igsm;
		    $curtoken->{text} =~ s/<[^>]*>//gsm;
		    $curtoken->{text} =~ s/^\s*//gsm;
		    $curtoken->{text} =~ s/\s*$//gsm;
		    $curtoken->{text} =~ s/View all userpics//igsm;
		    next unless $curtoken->{text};
		    if ($orig =~ /font-size: 1\.2em/) {
		        $orig =~ /<span style='font-size: 1.2em'><b>([^<]*)<\/b><br \/><i>([^(]*)<\/i>/;
# <span style='font-size: 1.2em'><b>love and other dangerous things</b><br /><i>in my head there remains so much left to be said</i></span>
			$props->{title} = $1;
			$props->{subtitle} = $2;
		    }
		    elsif ($getemail) {
		        if ($orig =~ /mailto/) {
			    $getemail = 0;
			    $props->{email} = $curtoken->{text};
			}
			else {
		            $getemail++;
			    $curtoken->{text} =~ s/&#64;/@/;
			    $emailaddy .= $curtoken->{text};
			    if ($getemail == 4) {
			        $props->{email} = $emailaddy;
			        $getemail = 0;
			    }
			    undef $curtoken;
			    undef $curkey;
			    next;
			}
		    }
		    elsif ($curtoken->{text} =~ /:$/ and $curtoken->{text} =~ /[a-zA-Z]/) {
		        my $key = $curtoken->{text};
			$key =~ s/\s+/_/g;
			$key =~ s/\W//g;
			if ($key eq 'Email') {
			    $getemail = 1;
			    undef $curkey;
			    undef $curtoken;
			    next;
			}
		        $curkey = $key;
		    }
		    elsif ($curkey eq 'Website') {
		        $props->{Website_name} = $curtoken->{text};
			$orig =~ /<a href='([^']+)'>/;
                        my $weburl = $1;
			$props->{Website_url} = $weburl;
			$props->{Website_link} = "<a href=\"$weburl\">".
			                         "$curtoken->{text}</a>"
		    }
		    else {
		        unless ($curkey) {
			    undef $curtoken;
			    next;
			}
		        my $val = $curtoken->{text};
			if (   $curkey eq 'Interests'
			    or $curkey eq 'Friends'
			    or $curkey eq 'Friend_of'
			    or $curkey eq 'Member_of'
			    or $curkey eq 'Also_Friend_of'
			    or $curkey eq 'Mutual_Friends'
			    or $curkey eq 'Posting_Access') {
                            if ($val eq 'None listed') {
                                undef $curkey;
                                undef $curtoken;
                                next;
                            }
                            my ($num, $what) = split /:\s*/, $val, 2;
			    if ($stillFriendsToDo) {
			        $num = $props->{Friends_num};
			        $what = $val;
			    }
			    my @whatlist = split /,\s*/, $what;
			    $val = \@whatlist;
			    $props->{$curkey.'_num'} = $num;
			    if ($curkey eq 'Friends') {
			        if ($stillFriendsToDo) {
			            $stillFriendsToDo = 0;
				}
				else {
				    $stillFriendsToDo = 1;
				}
				if ($stillFriendsToDo) {
				    undef $curelem;
				    next;
				}
			    }
			}
			elsif ($curkey eq 'Date_updated') {
			    my ($date, $rel) = split /,\s*/, $val;
			    $val = $date;
			    $props->{Updated_rel} = $rel;
			}
			elsif ($curkey eq 'Comments') {
			    my ($posted, $received) = split /\s*-\s*/, $val;
			    $posted =~ s/Posted:\s*//;
			    $received =~ s/Received:\s*//;
			    $props->{Comments_posted} = $posted;
			    $props->{Comments_received} = $received;
			    undef $curkey;
			    undef $curtoken;
			    next;
			}
			elsif ($curkey eq 'Text_Message') {
			    undef $curkey;
			    undef $curtoken;
			    next;
			}
			elsif ($curkey eq 'User') {
			    $orig =~ /<a href='[^']*'><b>([^<]+)<\/b><\/a> \((\d+)\)/;

			    $val = $1;
			    $props->{userid} = $2;
			}
			elsif ($curkey eq 'ICQ_UIN') {
			    $val =~ s/\s*\(User Profile\)//;
			}
			elsif ($curkey eq 'Yahoo_ID') {
			    $val =~ s/\@yahoo\.com.*$//;
			}
			elsif ($curkey eq 'AOL_IM') {
			    $val =~ s/\s*\(Add Buddy.*$//;
			}

		        $props->{$curkey} = $val;
			undef $curkey;
		    }
		}
		undef $curtoken;
	    }
	}
        for my $prop (keys %{$props}) {
            my $val = ref($props->{$prop}) =~ /ARRAY/ ? '['.join(', ', @{$props->{$prop}}).']' : "'$props->{$prop}'";
            if (ref $props->{$prop} eq 'ARRAY') {
                my %vals;
                for my $v (@{$props->{$prop}}) {
                    next unless $v;
                    $vals{$v}++;
                }
                if (scalar keys %vals == 1) {
                    $obj->{profile}->{$prop} = (keys %vals)[0];
                }
                elsif (scalar keys %vals == 0) {
                    delete $obj->{profile}->{$prop};
                }
                else {
                    $obj->{profile}->{$prop} = [keys %vals];
	        }
            }
            else {
                $obj->{profile}->{$prop} = $props->{$prop};
            }
	}
    }
}

1;
