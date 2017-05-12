package VCI::VCS::Bzr::History;
use Moose;

use XML::Simple qw(:strict);

extends 'VCI::Abstract::History';

sub x_from_xml {
    my ($class, $xml_string, $project) = @_;
    # XXX We *really* should to do this with SAX, for performance reasons.
    # Right now, though, when we're using straight parsing, XML::Parser
    # parses bzr's simple XML faster than the SAX modules do.
    local $XML::Simple::PREFERRED_PARSER = 'XML::Parser';
    my $xs = XML::Simple->new(ForceArray => [qw(file directory log)],
                              KeyAttr => []);
    my $xml = $xs->xml_in($xml_string);
    
    my @commits;
    foreach my $log (@{$xml->{log}}) {
        $log->{message} ||= '';
        chomp($log->{message});
        # For some reason bzr adds a single space to the start of messages
        # in XML format.
        $log->{message} =~ s/^ //;
        
        my $commit = $project->commit_class->new(
            revision  => $log->{revisionid},
            revno     => $log->{revno},
            committer => $log->{committer},
            time      => $log->{timestamp},
            message   => $log->{message},
            project   => $project,
        );
        
        push(@commits, $commit);
    }
    
    return $class->new(commits => [reverse @commits], project => $project);
}

__PACKAGE__->meta->make_immutable;

1;
