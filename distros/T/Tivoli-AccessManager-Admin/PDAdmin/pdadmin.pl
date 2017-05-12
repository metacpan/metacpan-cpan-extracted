#!/usr/bin/perl
use strict;
use warnings;
#---
# $Id: pdadmin.pl 341 2006-12-13 18:19:24Z mik $
#---
$VERSION = '1.10';

use Tivoli::AccessManager::Admin;
use Term::ReadKey;
use Text::ParseWords;
use Tivoli::AccessManager::PDAdmin::PDAdmin;
BEGIN {
    $ENV{PERL_RL} = 'Zoid';
}
eval 'use Term::ReadLine';

# Do not look at the next three subs.  I am using soft references.  I am still
# not convinced it is the best way to go (AUTOLOAD maybe?), but damned if it
# doesn't work and make things much easier.

sub is_defined {
    # Reaches into a packages name space using symblic refs and figures out if
    # a subroutine is defined within that space
    my ($grp,$func) = @_;

    return 0 if ( $func =~ /^_/ or $func eq "BEGIN" );

    $func = 'iport' if $func eq 'import';
    no strict 'refs';
    my $nspace = "Tivoli::AccessManager::PDAdmin\:\:$grp\:\:";
    return exists( $nspace->{$func} ) || 0;
}

sub list_subs {
    # Reaches into a package's name space and generates a listing of all
    # defined subroutines.
    my ($grp) = @_;
    my @flist;

    my $nspace = "Tivoli::AccessManager::PDAdmin\:\:$grp\:\:";
    no strict 'refs';

    for ( sort keys %{$nspace} ) {
	next if /^_/;
	next if ( $_ eq 'fill' or $_ eq 'import' or $_ eq 'wrap' );
	next if ( $_ =~ /^[A-Z]/ );
	if ( $_ eq 'iport' ) {
	    push @flist, 'import';
	}
	else {
	    push @flist, $_;
	}
    }

    return @flist;
}

sub dispatch {
    # Calls a subroutine in a name space using symbolic refs
    my $grp = shift;
    my $func = shift;

    $func = 'iport' if $func eq 'import';
    my $nspace = "Tivoli::AccessManager::PDAdmin\:\:$grp\:\:$func";
    no strict 'refs';
    return unless defined &$nspace;
    return &$nspace;
}

# This needs to be global because I need the tab_complete function to see it,
# and I could find no way of passing it along.
my $tam;

sub tab_complete {
    my ($word, $buffer, $start) = @_;
    my @return = ();
    my @funcs = qw/acl authzrule group object objectspace policy pop rsrc rsrcgroup rsrccred server user/;

    $buffer =~ s/^\s*//;
    $buffer =~ s/\s*$//;
    my @tokens = shellwords($buffer);
    my $class = lc $tokens[0];

    # This function will handle the completion at the top level and the next
    # level ( e.g., ac<tab> will give you 'acl' and acl c<tab> will give you
    # 'acl create'.  After that, the individual modules will have to handle
    # the beast.
    if ( @tokens == 1 and $word ) {
	@return = grep { /^$word/ } @funcs;
    }
    elsif ( (@tokens == 2 and $word) or (@tokens == 1 and not $word) ) {
	@return = grep { /^$word/ } list_subs( $class );
    }
    else {
	my $tcomp = "TabComplete\:\:$class";
	if ( is_defined( $tcomp, 'complete' ) ) {
	    @return = dispatch( $tcomp,'complete',$tam,\@tokens,$word,$buffer,$start);
	}
	else {
	    $return[0] = "This is a stub.  It is only a stub\n";
	}
    }

    return @return;
}

sub get_passwd {
    my $uname = shift; 
    ReadMode 2;
    print "$uname password: ";
    my $pswd = <STDIN>;
    ReadMode 0;
    chomp $pswd;
    print "\n";

    return $pswd;
}

sub help {
    my ($action, $subact, $subcom) = @_;
    my %help = (
	acl       => 'Create and delete ACLs; attach and detach ACLs',
	authzrule => 'Create and delete authzrules; attach and detach authzrules',
	group     => 'Create and delete groups; add and delete members',
	object    => 'Create and delete objects; add and delete attributes',
	policy    => 'Control global password policies',
	'pop'     => 'Create and delete POPs; attach and detach POPs',
	user      => 'Create and delete users; add and remove users from groups; control password policies',
	rsrc      => 'Manipulate GSO Web credentials',
	rsrccred  => 'Manipulate GSO credentials',
	rsrcgroup => 'Manipulate GSO credential groups',
	server    => 'Control remote servers -- partially implemented'
    );

    # If the user said '<command> help', I need to make it look like they said
    # 'help <command>'
    if ( defined($subact) ) {
	if ($subact eq 'help' ) {
	    ($action,$subact) = ($subact,$action);
	}

	if ( is_defined($subact,'help') ) {
	    dispatch($subact,'help', $subcom);
	}
	else {
	    printf("  %-9s -- %s\n",$_,$help{$_}) for (sort keys %help);
	}
    }
    else {
	printf("  %-9s -- %s\n",$_,$help{$_}) for (sort keys %help);
    }
}

# Initialize context
my $uname = shift || "sec_master";
my $pswd = get_passwd($uname);

$tam = Tivoli::AccessManager::Admin->new( userid => $uname, password => $pswd );

#Initialize readline
my $term = Term::ReadLine->new("tamadmin");
my $OUT = $term->OUT || \*STDOUT;

$term->Attribs()->{completion_function} = \&tab_complete;

while ( my $line = $term->readline("tamadmin $uname> ") ) {
    $line =~ s/^\s*//;
    $line =~ s/\s*$//;
    my @tokens = shellwords($line);
    my $func = lc shift @tokens;
    my $comm = lc $tokens[0];

    exit 0 if $func eq 'exit' or $func eq 'quit';

    if ( $func eq 'help' or $comm eq 'help' ) {
	help( $func, @tokens );
	next;
    }

    if ( is_defined( $func,$comm ) ) {
	dispatch( $func,$comm,$tam,@tokens );
    }
    else {
	warn "Unknown $func command: $comm\n";
	dispatch($func,'help');
    }

}

=head1 NAME

pdadmin.pl

=head1 DESCRIPTION

An enhanced replacement for pdadmin.  This is not a complete replacement --
the local mode, the config commands and a few of the server commands are not
yet implemented.  Most of the real work, though, is done.

=head1 ENHANCEMENTS

=over 4

=item vi Key Bindings

I am an old man of UNIX.  Back in those days, we had vi and we had emacs.  For
one reason and another, I became a vi user.  The macros are very deep into my
fingers -- I think "go up a line" and my fingers hit <ESC>-k (which causes
problems when I am forced to use something like notepad).  It has always
bothered me that pdadmin only used the emacs key bindings.  Therefore, my
version does both.

=item Tab Complete

Yeah.  Tab complete.  Everywhere I could figure out what a tab complete would
do, I did it.  This may not be the best of things.  For example, you can hit
the TAB key several times while creating the user.  One of those times will
cause pdadmin.pl to search for every user in your LDAP.  If your LDAP is big,
that might take some time.

=item Misc

There are some other minor differences, but you will have to look to find
them.

=head1 REQUIREMENTS

Most of the magic of the enhancements comes from L<Term::ReadLine::Zoid> and
L<ENV::PS1>.  You will need to install both modules and all the requirements
to get the most out of my version.


