#
# Test for future videos
# 

use strict;
use lib 'lib';

use Text::Editor::Easy;

# Windows
my $path = 'D:\\site\\audio\\';
my $command = 'D:\\cpan\\oggdec.exe -p';

# Linux
#my $path = '/media/hdc2/site/audio/';
#my $command = 'ogg123';

Text::Editor::Easy->new( {
        'focus'    => 'yes',
		'sub' => 'main',
} );

sub main {
    my ( $editor ) = @_;

    $editor->create_new_server(
        {
             'methods' => [
                'play',
            ],
            'object' => [],
        }
    );
    $editor->create_new_server(
        {
             'methods' => [
                'play2',
            ],
            'object' => [],
        }
    );
    $editor->create_new_server(
        {
             'methods' => [
                'play3',
            ],
            'object' => [],
        }
    );


	my $async = $editor->async;
	# Windows
    $async->play('gladio.ogg');
	$async->play2('Koln_part_2c.ogg');
	$async->play3('room_27.ogg');
	
	# Linux
	#Text::Editor::Easy::Async->play("/media/hdc2/site/audio/gladio.ogg");
	
	$editor->insert("Bonjour\n");
	sleep 2;
	$editor->insert("Suite\n");
	sleep 2;
	$editor->insert("Fin\n");
}


sub play {
		my ( $self, $song ) = @_;

		`$command $path$song`;
}

sub play2 {
		play( @_ );
}

sub play3 {
		play( @_ );
}
