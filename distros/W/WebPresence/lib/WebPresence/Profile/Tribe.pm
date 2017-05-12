package WebPresence::Profile::Tribe;
use WebPresence::Profile;
@ISA = ('WebPresence::Profile');

use LWP;
use URI::URL;
use HTML::PullParser;

use strict;

sub SetInfo {
    my $obj = shift;
    my $user = shift;
    $user =~ s/-/_/g;

    # We is a BIG LIAH saying we's Firefox. In British. On XP. Just what
    # they expect. But some of these sites act like assholes so screw it 
    # better that than this potentially not working if they block us
    my $web = LWP::UserAgent->new('Mozilla/5.0 (Windows; U; Windows NT 5.1;'.
				   ' en-GB; rv:1.8.0.3) Gecko/20060426 '.
				  'Firefox/1.5.0.3');
    my $url_base = 'http://people.tribe.net/';
    my $resp = $web->get($url_base.$user);
    if ($resp->is_success) {
        my $props;

        $obj->{page_source} = $resp->content;
	$obj->{page_source} =~ /(         <div class="moduleBodyContent" id="_8960795"  >.*)/gsm;
	my $tribeslist = $1;
	$tribeslist =~ s/<\/div>.*//gsm;
	$tribeslist =~ s/<table.*//gsm;
	$tribeslist =~ s/<!--.*-->//gsm;
	$tribeslist =~ s/<div class="moduleBodyContent" id="_8960795"  >//;
	$tribeslist =~ s/^\s*//gsm;
	$tribeslist =~ s/\s*$//gsm;
	$tribeslist =~ s/,$//;
	$tribeslist =~ s/[\r\n]+//gsm;

	my @tribeslist = split /,/, $tribeslist;
	my (@tnames, @turls);
	$props->{tribes} = [];
	$props->{tribeurls} = [];

	for my $t (@tribeslist) {
	    $t =~ /<a href="([^"]+)">([^<]+)<\/a>/;
	    my $turl = $1;
	    my $tname = $2;
	    push @tnames, $tname;
	    push @turls, $turl;
	}

        $props->{tribes} = \@tnames;
	$props->{tribeurls} = \@turls;

        my $p = HTML::PullParser->new(doc => $resp->content,
	                              start => 'tagname, event, attr',
                                      end => 'tagname, event, skipped_text',
				      ignore_elements => [qw(script style
				                             applet embed
							     object)],
                                      report_tags => ['div','td']);
        my ($curelem, $curtoken, $curkey);
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
		if (    $curtoken->{class} eq 'label'
		    and $curtoken->{tag} eq 'div') {
		    my $key = $curtoken->{text};
		    $key =~ s/<[^>]*>//gsm;
		    $key =~ s/^\s+//gsm;
		    $key =~ s/\s+$//gsm;
		    $key =~ s/\W+/_/gsm;
		    $curkey = $key;
		}
		elsif (    $curtoken->{class} eq 'value'
		       and $curtoken->{tag} eq 'div') {
		    next unless $curkey;
		    my $val = $curtoken->{text};
		    $val =~ s/<[^>]*>//gsm;
		    $val =~ s/^\s+//gsm;
		    $val =~ s/\s+$//gsm;
		    next unless $val;
		    if ($curkey eq 'Interests') {
		        my @interests = split /,\s+/, $val;
			$props->{Interests} = \@interests;
		    }
		    else {
		        if (defined $props->{$curkey}) {
		            unless (ref $props->{$curkey} eq 'ARRAY') {
			        $props->{$curkey} = [$props->{$curkey}];
			    }
			    push @{$props->{$curkey}}, $val;
		        }
		    else {
		        $props->{$curkey} = $val;
                    }
		    }
		    undef $curkey;
		}
		elsif ($curtoken->{tag} eq 'td') {
		    if ($curtoken->{class} eq 'status') {
		        my $status = $curtoken->{text};
			$status =~ s/^\s+//gsm;
			$status =~ s/\s+$//gsm;
			next unless $status;
			$props->{status} = $status;
		    }
		    if ($curtoken->{class} eq 'friendCount') {
		        my $friendCount = $curtoken->{text};
			$friendCount =~ s/<[^>]*>//g;
			$friendCount =~ s/^\s+//gsm;
			$friendCount =~ s/\s+$//gsm;
			$friendCount =~ s/\s+friends//gsm;
			next unless $friendCount;
			$props->{num_friends} = $friendCount;
		    }
		}
		elsif ($curtoken->{tag} eq 'div') {
		    if ($curtoken->{class} eq 'stats photos') {
		        my $statsPhotos = $curtoken->{text};
			$statsPhotos =~ s/<[^>]*>//g;
			$statsPhotos =~ s/^\s+//gsm;
			$statsPhotos =~ s/\s+$//gsm;
			$statsPhotos =~ s/\s+photo in album//gsm;
			next unless $statsPhotos or $statsPhotos eq '0';
			$statsPhotos += 0;
			$props->{num_photos} = $statsPhotos;
		    }
		    if ($curtoken->{class} eq 'stats dates') {
		        my $statsDates = $curtoken->{text};
			$statsDates =~ s/[\r\n]+//gsm;
			$statsDates =~ s/^\s*//gsm;
                        $statsDates =~ s/\s*$//gsm;
			$statsDates =~ s/joined on //;
			$statsDates =~ s/last updated //;
			my ($join, $update) = split /<br\/>/, $statsDates;
			if ($join) {
			    $props->{join_date} = $join;
			}
			if ($update) {
			    $props->{update_date} = $update;
			}
		    }
		    if ($curtoken->{class} eq 'name') {
		        my $friend = $curtoken->{text};
			my $tempfriend = $friend;
			$friend =~ s/<[^>]*>//g;
			$friend =~ s/[\r\n]+//gsm;
			$friend =~ s/^\s*//gsm;
                        $friend =~ s/\s*$//gsm;
			if ($friend =~ /\.\.\.$/) {
			    $tempfriend =~ /view (.*)'s profile/;
			    $friend = $1;
			}
			if (defined $props->{friends}) {
			    unless (ref $props->{friends} eq 'ARRAY') {
			        $props->{friends} = [$props->{friends}];
			    }
			    push @{$props->{friends}}, $friend;
			}
			else {
			    $props->{friends} = $friend;
			}
		    }
		}
		undef $curtoken;
	    }
	}
        for my $prop (keys %{$props}) {
	    if ($prop eq 'tribes' or $prop eq 'tribeurls') {
	        $obj->{profile}->{$prop} = $props->{$prop};
	    }
	    else {
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
    else {
        return undef;
    }
}

1;
