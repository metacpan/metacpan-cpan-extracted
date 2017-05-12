package inc::TSRMakeMaker;
use Moose;

# ABSTRACT: insert checks for Subversion prerequisites into Makefile.PL

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

my $makefile_text = <<'MAKEFILE_TEXT';

use File::Temp ();
use IPC::Cmd qw( can_run );
use IPC::Run qw( run );

sub svn_is_installed {

    my %path;

    # Check that the basic svn commands are available.
    for my $cmd (qw( svn svnadmin svnserve )) {
        return unless $path{$cmd} = can_run($cmd);
    }

    my $temp = File::Temp::newdir('temp.XXXX',
                                  CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);

    # Check that we can create a repo
    return unless run([ $path{svnadmin}, 'create', $temp ]);

    # Check that we can spawn a server for the repo
    my ($in, $out, $err);
    return unless run([ $path{svnserve}, '-i', '-r' => $temp, '--foreground' ],
                        \$in, \$out, \$err);

    return 1;
}

if (!svn_is_installed()) {
    warn 'Subversion does not appear to be installed correctly, exiting';
    exit 0;
}
MAKEFILE_TEXT

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;
    my $template = super();

    $template =~ s/\nuse\s+ExtUtils::MakeMaker.*\n/$&$makefile_text/m;

    return $template;
};

__PACKAGE__->meta->make_immutable;
1;
