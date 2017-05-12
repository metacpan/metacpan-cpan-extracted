package WWW::RobotRules::Extended;

use URI;

# The following methods must be provided by the subclass.
sub agent;
sub is_me;
sub visit;
sub no_visits;
sub last_visits;
sub fresh_until;
sub push_rules;
sub clear_rules;
sub rules;
sub dump;



=head1 NAME

WWW::RobotRules::Extended - database of robots.txt-derived permissions.
This is a fork of WWW::RobotRules 

You should use WWW::RobotsRules::Extended if you want
to act as Googlebot : Google accept some improvments like "allow" directives
or wildcards "*" into rules


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Quick summary of what the module does.


 use WWW::RobotRules::Extended;
 use LWP::Simple qw(get);
 
 my $rules = WWW::RobotRules::Extended->new('MOMspider/1.0');

 {
   my $url = "http://some.place/robots.txt";
   my $robots_txt = get $url;
   $rules->parse($url, $robots_txt) if defined $robots_txt;
 }

 {
   my $url = "http://some.other.place/robots.txt";
   my $robots_txt = get $url;
   $rules->parse($url, $robots_txt) if defined $robots_txt;
 }

 # Now we can check if a URL is valid for those servers
 # whose "robots.txt" files we've gotten and parsed:
 if($rules->allowed($url)) {
     $c = get $url;
     ...
 }


=head1 DESCRIPTION

This module parses F</robots.txt> files as specified in
"A Standard for Robot Exclusion", at
<http://www.robotstxt.org/wc/norobots.html>

It also parses rules that contains wildcards '*' and allow directives
like Google does.

Webmasters can use the F</robots.txt> file to forbid conforming
robots from accessing parts of their web site.

The parsed files are kept in a WWW::RobotRules::Extended object, and this object
provides methods to check if access to a given URL is prohibited.  The
same WWW::RobotRules::Extended object can be used for one or more parsed
F</robots.txt> files on any number of hosts.


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head2 new
This is the constructor for WWW::RobotRules::Extended objects.  The first
argument given to new() is the name of the robot.
=cut

sub new {
    my($class, $ua) = @_;

    # This ugly hack is needed to ensure backwards compatibility.
    # The "WWW::RobotRules::Extended" class is now really abstract.
    $class = "WWW::RobotRules::Extended::InCore" if $class eq "WWW::RobotRules::Extended";

    my $self = bless { }, $class;
    $self->agent($ua);
    $self;
}


=head2 parse
The parse() method takes as arguments the URL that was used to
retrieve the F</robots.txt> file, and the contents of the file.

 $rules->allowed($uri)

Returns TRUE if this robot is allowed to retrieve this URL.
=cut

sub parse {
    my($self, $robot_txt_uri, $txt, $fresh_until) = @_;
    $robot_txt_uri = URI->new("$robot_txt_uri");
    my $netloc = $robot_txt_uri->host . ":" . $robot_txt_uri->port;

    $self->clear_rules($netloc);
    $self->fresh_until($netloc, $fresh_until || (time + 365*24*3600));

    my $ua;
    my $is_me = 0;		# 1 iff this record is for me
    my $is_anon = 0;		# 1 iff this record is for *
    my @me_alloweddisallowed = ();	# rules allowed or disallowed for me
    my @anon_alloweddisallowed = ();	# rules allowed or disallowed for *

    # blank lines are significant, so turn CRLF into LF to avoid generating
    # false ones
    $txt =~ s/\015\012/\012/g;

    # split at \012 (LF) or \015 (CR) (Mac text files have just CR for EOL)
    for(split(/[\012\015]/, $txt)) {

	# Lines containing only a comment are discarded completely, and
        # therefore do not indicate a record boundary.
	next if /^\s*\#/;

	s/\s*\#.*//;        # remove comments at end-of-line

        if (/^\s*User-Agent\s*:\s*(.*)/i) {
	    $ua = $1;
	    $ua =~ s/\s+$//;

	    if ($ua eq '*') {   # if it's directive for all bots
		$is_anon = 1;
	    }
	    elsif($self->is_me($ua)) { #if it's directives for this bot
		$is_me = 1;
	    } 
	    else {
		$is_me   = 0;
		$is_anon = 0;
	    }
	}
	elsif (/^\s*(Disallow|Allow)\s*:\s*(.*)/i) {
	    unless (defined $ua) {
		warn "RobotRules <$robot_txt_uri>: Disallow without preceding User-agent\n" if $^W;
		$is_anon = 1;  # assume that User-agent: * was intended
	    }
	    my $verb     = $1;
	    my $allowdisallow = $2;
	    $allowdisallow =~ s/\s+$//;
	    if (length $allowdisallow) {
		my $ignore;
		eval {
		    my $u = URI->new_abs($allowdisallow, $robot_txt_uri);
		    $ignore++ if $u->scheme ne $robot_txt_uri->scheme;
		    $ignore++ if lc($u->host) ne lc($robot_txt_uri->host);
		    $ignore++ if $u->port ne $robot_txt_uri->port;
		    $allowdisallow = $u->path_query;
		    $allowdisallow = "/" unless length $allowdisallow;
		};
		next if $@;
		next if $ignore;
	    }

	    # transform rules into regexp 
	    # for instance : /shared/* => ^\/shared\/.*
	    my $rule = "^".$allowdisallow;
            $rule=~ s/\//\\\//g;
            $rule=~ s/\*/\.*/g;
            $rule=~ s/\[/\\[/g;
            $rule=~ s/\]/\\]/g;
            $rule=~ s/\?/\\?/g;
            $rule=~ s/\./\\./g;

	    if (length $allowdisallow) {
	    	if ($is_me) {
			push(@me_alloweddisallowed, $verb." ".$rule);
	    	}
	    	elsif ($is_anon) {
			push(@anon_alloweddisallowed, $verb." ".$rule);
	    	}
            }
	}
        elsif (/\S\s*:/) {
             # ignore
        }
	else {
	    warn "RobotRules <$robot_txt_uri>: Malformed record: <$_>\n" if $^W;
	}
    }

    if ($is_me) {
	$self->push_rules($netloc, @me_alloweddisallowed);
    }
    else {
	$self->push_rules($netloc, @anon_alloweddisallowed);
    }
}

=head2 is_me

=cut


=head2 allowed

Returns TRUE if this robot is allowed to retrieve this URL.

=cut

sub allowed {
    my($self, $uri) = @_;
    $uri = URI->new("$uri");

    return 1 unless $uri->scheme eq 'http' or $uri->scheme eq 'https';
     # Robots.txt applies to only those schemes.

    my $netloc = $uri->host . ":" . $uri->port;

    my $fresh_until = $self->fresh_until($netloc);
    return -1 if !defined($fresh_until) || $fresh_until < time;

    my $str = $uri->path_query;
    my $rule;
    my $verb;
    my $rline;

    my $result=1;    # by default, all is allowed
    for $rline ($self->rules($netloc)) {
	if ($rline =~ /^(Disallow|Allow)\s*(.*)/i) {	
		$verb=lc($1);
		$rule=$2;
		if ($str =~ /$rule/) {
			if ($verb eq "allow") { # here, the rule allows, so i return now
				return 1;
			};
			if ($verb eq "disallow") { # here, the rule is disallowed, but we need to verify further 
						   # if another "allow" rule is present for this url
				$result=0;
			}
		}
		$rule="";
	}
    }
    return $result; # the rules have all been verified, if there is a matching disallow rule, $result should be 0
}


=head1 SUBROUTINES/METHODS



=head1 AUTHOR

Yannick Simon, C<< <yannick.simon at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-robotrules-extended at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-RobotRules-Extended>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::RobotRules::Extended


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-RobotRules-Extended>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-RobotRules-Extended>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-RobotRules-Extended>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-RobotRules-Extended/>

=back

=head1 Extended ROBOTS.TXT EXAMPLES

The following example "/robots.txt" file specifies that no robots
should visit any URL starting with "/cyberworld/map/" or "/tmp/":

  User-agent: *
  Disallow: /cyberworld/map/ # This is an infinite virtual URL space
  Disallow: /tmp/ # these will soon disappear

This example "/robots.txt" file specifies that no robots should visit
any URL starting with "/cyberworld/map/", except the robot called
"cybermapper":

  User-agent: *
  Disallow: /cyberworld/map/ # This is an infinite virtual URL space

  # Cybermapper knows where to go.
  User-agent: cybermapper
  Disallow:

This example indicates that no robots should visit this site further:

  # go away
  User-agent: *
  Disallow: /

This is an example of a malformed robots.txt file.

  # robots.txt for ancientcastle.example.com
  # I've locked myself away.
  User-agent: *
  Disallow: /
  # The castle is your home now, so you can go anywhere you like.
  User-agent: Belle
  Disallow: /west-wing/ # except the west wing!
  # It's good to be the Prince...
  User-agent: Beast
  Disallow:

This file is missing the required blank lines between records.
However, the intention is clear.


This is an example of an extended robots.txt file
tou have a real example of this kind of rules on http://www.google.com/robots.txt

  # Block every url that contains &p=
  User-agent: *
  Disallow: /*&p=
  
This is an example of an extended robots.txt file.

  # Block every url but the ones that begin with /shared
  User-agent: *
  Disallow: /
  Allow: /shared/



=head1 SEE ALSO

L<LWP::RobotUA>, L<WWW::RobotRules::AnyDBM_File>, L<WWW::RobotRules>


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

  Copyright 2011, Yannick Simon
  Copyright 1995-2009, Gisle Aas
  Copyright 1995, Martijn Koster

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::RobotRules::Extended




package WWW::RobotRules::Extended::InCore;

use vars qw(@ISA);
@ISA = qw(WWW::RobotRules::Extended);


sub is_me {
    my($self, $ua_line) = @_;
    my $me = $self->agent;

    # See whether my short-name is a substring of the
    #  "User-Agent: ..." line that we were passed:

    if(index(lc($me), lc($ua_line)) >= 0) {
      return 1;
    }
    else {
      return '';
    }
}


sub agent {
    my ($self, $name) = @_;
    my $old = $self->{'ua'};
    if ($name) {
        # Strip it so that it's just the short name.
        # I.e., "FooBot"                                      => "FooBot"
        #       "FooBot/1.2"                                  => "FooBot"
        #       "FooBot/1.2 [http://foobot.int; foo@bot.int]" => "FooBot"

	$name = $1 if $name =~ m/(\S+)/; # get first word
	$name =~ s!/.*!!;  # get rid of version
	unless ($old && $old eq $name) {
	    delete $self->{'loc'}; # all old info is now stale
	    $self->{'ua'} = $name;
	}
    }
    $old;
}


sub visit {
    my($self, $netloc, $time) = @_;
    return unless $netloc;
    $time ||= time;
    $self->{'loc'}{$netloc}{'last'} = $time;
    my $count = \$self->{'loc'}{$netloc}{'count'};
    if (!defined $$count) {
	$$count = 1;
    }
    else {
	$$count++;
    }
}


sub no_visits {
    my ($self, $netloc) = @_;
    $self->{'loc'}{$netloc}{'count'};
}


sub last_visit {
    my ($self, $netloc) = @_;
    $self->{'loc'}{$netloc}{'last'};
}


sub fresh_until {
    my ($self, $netloc, $fresh_until) = @_;
    my $old = $self->{'loc'}{$netloc}{'fresh'};
    if (defined $fresh_until) {
	$self->{'loc'}{$netloc}{'fresh'} = $fresh_until;
    }
    $old;
}


sub push_rules {
    my($self, $netloc, @rules) = @_;
    push (@{$self->{'loc'}{$netloc}{'rules'}}, @rules);
}


sub clear_rules {
    my($self, $netloc) = @_;
    delete $self->{'loc'}{$netloc}{'rules'};
}


sub rules {
    my($self, $netloc) = @_;
    if (defined $self->{'loc'}{$netloc}{'rules'}) {
	return @{$self->{'loc'}{$netloc}{'rules'}};
    }
    else {
	return ();
    }
}


sub dump
{
    my $self = shift;
    for (keys %$self) {
	next if $_ eq 'loc';
	print "$_ = $self->{$_}\n";
    }
    for (keys %{$self->{'loc'}}) {
	my @rules = $self->rules($_);
	print "$_: ", join("; ", @rules), "\n";
    }
}

