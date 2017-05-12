package WebPresence::Profile::ICQ;
use WebPresence::Profile;
@ISA = ('WebPresence::Profile');

use LWP;
use URI::URL;
use HTML::PullParser;

use strict;

sub SetInfo {
    my $obj = shift;
    my $uin = shift;

    # We is a BIG LIAH saying we's Firefox. In British. On XP. Just what
    # they expect. But some of these sites act like assholes so screw it 
    # better that than this potentially not working if they block us
    my $web = LWP::UserAgent->new('Mozilla/5.0 (Windows; U; Windows NT 5.1;'.
				   ' en-GB; rv:1.8.0.3) Gecko/20060426 '.
				  'Firefox/1.5.0.3');
    my $url_base = 'http://www.icq.com/people/full_details_show.php?uin=';
    my $resp = $web->get($url_base.$uin);
    if ($resp->is_success) {
        my $p = HTML::PullParser->new(doc => $resp->content,
	                              start => 'tagname, event, attr',
                                      end => 'tagname, event, skipped_text',
				      ignore_elements => [qw(script style
				                             applet embed
							     object)],
                                      report_tags => ['div']);
        my ($curelem, $curtoken, $props, $curkey);
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
		if ($curtoken->{class} =~ /udu-/) {
		    if ($curtoken->{class} eq 'udu-flnm') {
		        my $key = $curtoken->{text};
			$key =~ s/\W+/_/g;
			$curkey = $key;
		    }
		    elsif ($curtoken->{class} eq 'udu-flvl') {
		        if ($curkey) {
			    if ($curtoken->{text}) {
			        if (defined $props->{$curkey}) {
				    $props->{$curkey} = [$props->{$curkey}];
				    push @{$props->{$curkey}},
				         $curtoken->{text};
				}
				else {
		                    $props->{$curkey} = $curtoken->{text};
                                }
			    }
			}
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
    else {
        return undef;
    }
}

1;
