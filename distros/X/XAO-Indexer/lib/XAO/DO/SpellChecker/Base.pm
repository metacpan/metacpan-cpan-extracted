=head1 NAME

XAO::DO::SpellChecker::Base - base class for spellcheckers

=head1 SYNOPSIS

    my $server=XAO::Objects->new(
        objname     => 'SpellChecker::Aspell',
    });
    $server->server_run;

    my $speller=XAO::Objects->new(
        objname     => 'SpellChecker::Aspell',
    );
    $speller->switch_index($index_id);
    my $pairs=$speller->suggest_replacements("speling bee");

    my $speller=XAO::Objects->new(
        objname     => 'SpellChecker::Aspell',
    );
    my $wlist=$speller->dictionary_create;
    $speller->dictionary_add($wlist,'perl');
    $speller->dictionary_close($wlist);

=head1 DESCRIPTION

Provides spell-checker base functions -- server, client, utility
functions. The actual spellchecker should be implemented independently
on top of it.

Methods are:

=over

=cut

###############################################################################
package XAO::DO::SpellChecker::Base;
use strict;
use IO::File;
use IO::Socket;
use IO::Select;
use Error qw(:try);
use POSIX qw(:errno_h);
use XAO::Utils;
use XAO::Objects;
use XAO::Projects qw(get_current_project get_current_project_name);
use base XAO::Objects->load(objname => 'Atom');

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Base.pm,v 1.4 2005/12/06 05:04:15 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $self=$proto->SUPER::new(
        objname     => $args->{'objname'},
        role        => $args->{'role'} || 'spellchecker',
    );

    my $config=$args->{'config'};
    if(!$config) {
        my $siteconfig=get_current_project() ||
            throw $self "new - no config and no current project";
        $config=$siteconfig->get('spellchecker') || { };
    }
    $self->{'config'}=$config;

    return $self;
}

###############################################################################

=item server_run ()

Runs the spellchecker server that clients can connect to. Never returns.

=cut

sub server_run ($) {
    my $self=shift;

    my $server_conf=$self->{'config'}->{'server'} ||
        throw $self "server_run - no 'server' in the config";

    my $server_host=$server_conf->{'address'} || '127.0.0.1';
    my $server_port=$server_conf->{'port'} ||
        throw $self "server_run - no server/port in the config";

    dprint "Listening on $server_host:$server_port";
    my $server_socket=IO::Socket::INET->new(
        LocalAddr       => $server_host,
        LocalPort       => $server_port,
        Proto           => 'tcp',
        Reuse           => 1,
        Listen          => 10,
    ) || throw $self "server_run - error creating server socket ($!)";

    my $server_fno=$server_socket->fileno;

    my $rsel=IO::Select->new($server_socket);

    my $eol="\015\012";

    ##
    # Keyed by fileno clients and helpers, to quickly find out who's
    # ready to read.
    #
    my %clients;
    my %helpers;

    ##
    # These are input and output buffers per descriptor. We use them to
    # avoid blocking.
    #
    my %output;
    my %input;

    ##
    # Sending something to the output stream.
    #
    my $output_sub=sub ($$) {
        my ($sock,$text)=@_;
        my $fno=$sock->fileno;
        $output{$fno}='' unless exists $output{$fno};
        $output{$fno}.=$text;
    };

    my $have_buffered_input;
    while(1) {

        ##
        # Are we ready to output something?
        #
        my $wsel=IO::Select->new;
        foreach my $fno (keys %output) {
            my $outtext=$output{$fno};
            next unless defined $outtext && length($outtext);
            my $sock=$clients{$fno} || $helpers{$fno};
            if(!$sock) {
                dprint "Discarding unsent output to fno=$fno";
                delete $output{$fno};
                next;
            }
            ### dprint "OUT: $fno has backlog of ".length($outtext);
            $wsel->add($sock);
        }

        ##
        # Waiting for some action
        #
        ### dprint "rsel=",join('|',$rsel->handles);
        ### dprint "wsel=",join('|',$wsel->handles);
        my @ready=IO::Select->select($rsel,$wsel,undef,$have_buffered_input ? 0.25 : undef);
        @ready ||
            throw $self "run - select error ($!)";

        ##
        # Going through sockets ready to give us something.
        #
        my $rrdy=$ready[0];
        foreach my $fh (@$rrdy) {
            my $fno=$fh->fileno;
            ### dprint "Reading from $fno (server $server_fno)";

            if($fno == $server_fno) {
                my $sock=$server_socket->accept;
                if($sock) {
                    $sock->autoflush(0);
                    $sock->blocking(0);
                    $clients{$sock->fileno}=$sock;
                    $rsel->add($sock);
                    dprint "Accepted from ".inet_ntoa($sock->peeraddr).":".$sock->peerport;
                }
                next;
            }
            else {
                use bytes;
                my $intext;
                $fh->clearerr;
                my $len=$fh->sysread($intext,4096);
                if(!$len) {
                    dprint "Writer disconnected: $fno ($!)";
                    delete $clients{$fno};
                    delete $helpers{$fno};
                    delete $input{$fno};
                    delete $output{$fno};
                    $rsel->remove($fh);
                    $fh->close;
                    next;
                }
                $input{$fno}='' unless exists $input{$fno};
                $input{$fno}.=$intext;
                ### dprint "Read $len bytes from $fno, total is ".length($input{$fno});
            }
        }

        ##
        # Going through sockets ready to accept some output
        #
        my $wrdy=$ready[1];
        foreach my $fh (@$wrdy) {
            my $fno=$fh->fileno;
            defined $fno || next;
            ### dprint "Writing to $fno";

            use bytes;
            my $outtext=$output{$fno};
            defined $outtext ||
                throw $self "run - internal error, $fno is ready to read, but we've got nothing buffered"; 

            my $len=$fh->syswrite($outtext,length($outtext));
            if(!$len) {
                dprint "Reader disconnected: $fno ($!)";
                delete $clients{$fno};
                delete $helpers{$fno};
                delete $input{$fno};
                delete $output{$fno};
                $rsel->remove($fh);
                $fh->close;
                next;
            }

            $output{$fno}=substr($outtext,$len);
            ### dprint "Sent $len bytes to $fno (out of ".length($outtext).")";
        }

        ##
        # Now checking if there are some complete records in
        # input-buffers. Processing them.
        #
        $have_buffered_input=undef;
        foreach my $fno (keys %input) {
            my $intext=$input{$fno};
            ### dprint "Checking input for $fno, length=".length($intext);

            if(my $fh=$clients{$fno}) {
                next unless defined $intext && 
                            $intext =~ m/^(.*?)\015?\012(.*)$/s;
                my $cmd=$1;
                $input{$fno}=$2;

                $have_buffered_input=1 if length($2);

                if($cmd=~/^spelling\s+(\w+)\s+(\w+)\s+(.*?)\s*$/) {
                    my $sitename=$1;
                    my $index_id=$2;
                    my $words=$3;
                    dprint "SPELLING($sitename,$index_id): '$words'";

                    if($sitename ne '_default_') {
                        $output_sub->($fh,"500 Multiple site names not supported$eol.$eol");
                        next;
                    }

                    $self->switch_index($index_id eq '_default_' ? '' : $index_id);

                    my $pairs=$self->local_suggest_replacements($words);
                    foreach my $word (keys %$pairs) {
                        foreach my $alt (@{$pairs->{$word}}) {
                            $output_sub->($fh,"250-<<$word||$alt>>$eol");
                        }
                    }
                    $output_sub->($fh,"200 .$eol");
                }
                elsif($cmd=~/^quit\s*$/) {
                    $fh->syswrite("221 Good bye!$eol");
                    dprint "Client disconnected: $fno";
                    delete $clients{$fno};
                    delete $helpers{$fno};
                    delete $input{$fno};
                    delete $output{$fno};
                    $rsel->remove($fh);
                    $fh->close;
                    next;
                }
                else {
                    dprint "UNKNOWN($cmd)";
                    $output_sub->($fh,"400 Unknown command$eol");
                }
            }
            elsif($fh=$helpers{$fno}) {
                dprint "UNSUPPORTED";
            }
            else {
                dprint "Have input from unknown source ($fno)";
                delete $input{$fno};
            }
        }
    }
}

###############################################################################

=item switch_index ($)

Switches the spellchecker to a different index. This has an effect of
creating another copy of spellchecker where supported, possibly
connected to a different dictionary.

By default it simply stores new index into
$self->{'current_index'}. Returns old index value.

=cut

sub switch_index ($$) {
    my ($self,$index_id)=@_;

    my $oldindex=$self->{'current_index'};
    $self->{'current_index'}=$index_id;

    return $oldindex;
}

###############################################################################

=item client_connect ()

Internal method. Connects to the spelling server.

=cut

sub client_connect ($) {
    my $self=shift;

    my $server_socket=$self->{'server_socket'};
    return $server_socket if $server_socket;

    my $server_addr=$self->{'config'}->{'server'}->{'address'} ||
        throw $self "client_connect - no server/address";
    my $server_port=$self->{'config'}->{'server'}->{'port'} ||
        throw $self "client_connect - no server/address";

    $server_socket=IO::Socket::INET->new(
        PeerAddr        => $server_addr,
        PeerPort        => $server_port,
        Proto           => 'tcp',
    );

    $server_socket->autoflush(1) if $server_socket;

    $self->{'server_socket'}=$server_socket;

    return $server_socket;
}

###############################################################################

sub client_disconnect ($) {
    my $self=shift;

    my $server_socket=$self->{'server_socket'};

    if($server_socket) {
        dprint "Disconnecting from spelling server";
        $server_socket->close;
    }
}

###############################################################################

sub client_suggest_replacements ($$) {
    my ($self,$phrase)=@_;

    my %pairs;

    my $server=$self->client_connect;
    if(!$server) {
        eprint "Can't connect to spelling server: $!";
        return \%pairs;
    }

    try {
        my $cmd='spelling _default_ '.
                ($self->{'current_index'} || '_default_') .
                ' ' .
                $phrase .
                "\015\012";

        $server->blocking(1);
        $server->print($cmd);

        my $time_limit=time+2;

        my $rsel=IO::Select->new($server);
        $server->blocking(0);

        my $status=500;
        my $text='';

        while($status!=200) {
            my @ready=IO::Select->select($rsel,undef,undef,$time_limit-time+0.9);
            last unless @ready;

            my $len=$server->sysread($text,8192,length($text));
            $len || throw $self "Got a EOF";

            while($text =~ m/^(.*?)\015?\012(.*)$/s) {
                my $line=$1;
                $text=$2;

                if($line=~/^250-<<(.*?)\|\|(.*?)>>$/) {
                    push(@{$pairs{$1}},$2);
                }
                elsif($line=~/^200 /) {
                    $status=200;
                    last;
                }
                else {
                    throw $self "Spelling Server Error ($line)";
                }
            }
        }
    }
    otherwise {
        my $e=shift;
        eprint "SPELLING: $e";
        $self->client_disconnect;
    };

    return \%pairs;
}

###############################################################################

=item local_suggest_replacements ()

Pure virtual method, needs to be overriden by a specific spellchecker.

=cut

sub local_suggest_replacements ($) {
    my $self=shift;
    throw $self "local_suggest_replacements - pure virtual method called";
}

###############################################################################

sub suggest_replacements ($$) {
    my ($self,$phrase)=@_;

    if($self->{'config'}->{'server'}) {
        return $self->client_suggest_replacements($phrase);
    }
    else {
        return $self->local_suggest_replacements($phrase);
    }
}

###############################################################################

sub dictionary_create ($) {
    my $self=shift;
    throw $self "dictionary_create - pure virtual method called";
}

###############################################################################

sub dictionary_add ($$$$) {
    my ($self,$wh,$word,$count)=@_;
    throw $self "dictionary_add - pure virtual method called";
}

###############################################################################

sub dictionary_close ($$) {
    my ($self,$wh)=@_;
    throw $self "dictionary_close - pure virtual method called";
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Indexer>,
L<XAO::DO::Indexer::Base>,
L<XAO::DO::Data::Index>.

=cut
