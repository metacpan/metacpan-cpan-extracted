#/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Test::More;

unless ($ENV{TEST_AUTHOR}) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ($@) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

Test::Perl::Critic->import(
    -severity => 1,
    -exclude => [
        'ProhibitAccessOfPrivateData',  # False alarms from ARRAY references
        'ProhibitBarewordFileHandles',  # Bareword filehandles is basic
                                        #    Perl, this rule is downright
                                        #    stupid.
        'ProhibitCommentedOutCode',     # False positives from expressions
                                        #    in comments describing
                                        #    invariants.
        'ProhibitDoubleSigils',         # Another anti-Perl style policy,
                                        #    compliance REDUCES readability
        'ProhibitEnumeratedClasses',    # As explained in the documentation
                                        #    for this policy, it is WRONG
                                        #    unless the data processed is
                                        #    from a human.
        'ProhibitEscapedMetacharacters',# False positives on regexes with
                                        #    just a single escape.  Anyway,
                                        #    real escapes are more readable
                                        #    than pseudo-escapes written
                                        #    with [].
        'ProhibitMagicNumbers',         # This module uses a lot of simple
                                        #    constants trivially derived
                                        #    from an introductory comment.
        'ProhibitPostfixControls',      # I love them, plus return not
                                        #    exempt.
        'ProhibitPunctuationVars',      # Punctuation vars are necessary due
                                        #    to the $& etc. side effect of
                                        #    "use English".
        'ProhibitSubroutinePrototypes', # I disagree strongly with this
                                        #    policy: prototypes are a major
                                        #    benefit of the perl 5 syntax,
                                        #    allow easier use of non-scalar
                                        #    args, and DO provide some
                                        #    argument checking at compile
                                        #    time.
        'ProhibitUnlessBlocks',         # Yet another anti-Perl policy,
                                        #    unless(expr) is MORE readable
                                        #    than if (!expr).
        'ProhibitUnusualDelimiters',    # Way too restrictive.  Blocks the
                                        #    common case of using a nonbrace
                                        #    alternative delimiter such as
                                        #    ! or ' when / is in the pattern
        'ProhibitUseBase',              # Contradicts ProhibitExplicitISA
        'RequireBracedFileHandleWithPrint',
                                        # Yet another anti-Perl policy,
                                        #    the suggested braces would
                                        #    suggest an anonymous sub to
                                        #    any real perl coder.
        'RequireDotMatchAnything',      # Causes lots of false positives
                                        #    when regular expressions
                                        #    do not contain a . metachar!
        'RequireExtendedFormatting',    # Causes lots of false positives
                                        #    for simple regexes that don't
                                        #    need embedded comments.
        'RequireLineBoundaryMatching',  # Causes lots of false positives
                                        #    when regular expressions
                                        #    intentionally matches only the
                                        #    start and end of the string.
        'RequirePODUseEncodingUTF8',    # Incompatible with perl 5.6 pod
                                        #    tools.
        'RequirePodAtEnd',              # I disagree strongly with this
                                        #    policy the whole point of pod
                                        #    is to put documentation as
                                        #    close as possible to the
                                        #    documented code, to remind the
                                        #    developer to keep code and docs
                                        #    in sync.
        'RequireRcsKeywords',           # Source ctrl version numbers
                                        #    increment so much faster than
                                        #    release version when source
                                        #    ctrl tools are used actively.
        'RequireUseUTF8',               # Nonsense policy written by someone
                                        #    who didn't understand that this
                                        #    pragma is only needed if the
                                        #    .pm file ITSELF contains
                                        #    non-ASCII chars.
    ],
    -verbose => 11,
    -profile => File::Spec->catfile('t', 'perlcriticrc'),
);
all_critic_ok();
