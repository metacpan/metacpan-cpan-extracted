package WebPresence::Profile::Yahoo;
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
    my $url_base = 'http://profiles.yahoo.com/';
    my $resp = $web->get($url_base.$uin.'?warn=1');
    if ($resp->is_success) {
        my $p = HTML::PullParser->new(doc => $resp->content,
	                              start => 'tagname, event, attr',
                                      end => 'tagname, event, skipped_text',
				      ignore_elements => [qw(script style
				                             applet embed
							     object)],
                                      report_tags => ['dt','dd','div']);
        my ($curelem, $curtoken, $props, $curkey);
	my $inRightDiv = 0;
        while (my $token = $p->get_token) {
	    my $elem = $token->[0];
	    my $type = $token->[1];
	    if ($type eq 'start') {
	        $curelem = $elem;
		$curtoken->{tag} = $elem;
		for my $k (keys %{$token->[2]}) {
		    $curtoken->{$k} = $token->[2]->{$k};
		}
		if ($curtoken->{tag} eq 'div') {
		    if (   $curtoken->{id} eq 'ypfl-basics'
		        or $curtoken->{id} eq 'ypfl-more'
                        or $curtoken->{id} eq 'ypfl-mylinks') {
                        $inRightDiv = 1;
                    }
		    else {
		        $inRightDiv = 0;
		    }
		}
	    }
	    elsif ($type eq 'end') {
	        next unless ($curelem eq $elem);
		$curtoken->{text} = $token->[2];
		if ($inRightDiv) {
		    if ($curtoken->{tag} eq 'div') {
		        $inRightDiv = 0;
		    }
		    else {
		        if ($curtoken->{tag} eq 'dt') {
			    $curkey = $curtoken->{text};
                            $curkey =~ s/:\s*$//;
			    $curkey =~ s/^\s*//;
			    $curkey =~ s/&nbsp;/_/g;
			    $curkey =~ s/&amp;/&/g;
			    $curkey =~ s/\W+/_/g;
			}
			else {
			    my $val = $curtoken->{text};
			    $val =~ s/&nbsp;/ /g;
			    $val =~ s/^\s*//;
			    $val =~ s/\s*$//;
			    $val =~ s/<[^>]*>//g;
			    $val =~ s/&amp;/&/g;
			    next unless $val;
			    next if $val eq 'No Answer';
			    next if $val =~ /No .+ specified/;

			    if (defined $props->{$curkey}) {
				unless (ref $props->{$curkey} eq 'ARRAY') {
				    $props->{$curkey} = [$props->{curkey}];
				}
				push @{$props->{$curkey}}, $val;
			    }
			    else {
			        $props->{$curkey} = $val;
			    }
			}
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
