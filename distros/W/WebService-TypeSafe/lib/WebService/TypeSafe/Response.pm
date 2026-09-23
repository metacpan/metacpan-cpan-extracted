package WebService::TypeSafe::Object;

use strict;
use warnings;
use Carp qw(croak);

sub new { my ($class, $data) = @_; return bless { %$data }, $class }
sub raw { return { %{ $_[0] } } }
sub AUTOLOAD {
    our $AUTOLOAD;
    my ($self) = @_;
    (my $name = $AUTOLOAD) =~ s/.*:://;
    croak "unknown field '$name'" unless exists $self->{$name};
    return $self->{$name};
}
sub DESTROY { }

package WebService::TypeSafe::Answer;
use parent -norequire, 'WebService::TypeSafe::Object';
package WebService::TypeSafe::ChoiceAnswer;
use parent -norequire, 'WebService::TypeSafe::Answer';
package WebService::TypeSafe::NoulAnswer;
use parent -norequire, 'WebService::TypeSafe::Answer';
package WebService::TypeSafe::ScoreAnswer;
use parent -norequire, 'WebService::TypeSafe::Answer';

package WebService::TypeSafe::Response;
use parent -norequire, 'WebService::TypeSafe::Object';

sub from_hash {
    my ($class, $data) = @_;
    my (%answers, %choices, %nouls, %scores);
    for my $name (keys %{ $data->{answers} || {} }) {
        my $raw = $data->{answers}{$name};
        my $answer_class = {
            choice => 'WebService::TypeSafe::ChoiceAnswer',
            noul   => 'WebService::TypeSafe::NoulAnswer',
            score  => 'WebService::TypeSafe::ScoreAnswer',
        }->{ $raw->{type} } || 'WebService::TypeSafe::Answer';
        my $answer = $answer_class->new($raw);
        $answers{$name} = $answer;
        $choices{$name} = $answer if $raw->{type} eq 'choice';
        $nouls{$name}   = $answer if $raw->{type} eq 'noul';
        $scores{$name}  = $answer if $raw->{type} eq 'score';
    }
    return bless {
        %$data,
        answers => \%answers,
        choices => \%choices,
        nouls   => \%nouls,
        scores  => \%scores,
        usage   => WebService::TypeSafe::Object->new($data->{usage} || {}),
    }, $class;
}

1;
