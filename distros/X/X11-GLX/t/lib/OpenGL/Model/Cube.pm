package OpenGL::Model::Cube;
use Moo 2;
use OpenGL qw( GL_FLOAT GL_VERTEX_ARRAY GL_NORMAL_ARRAY GL_TEXTURE_COORD_ARRAY GL_QUADS );

my $_data_array;
sub _data_array {
	# Coordinates and comments borrowed from:
	#      A demonstration of OpenGL in a ARGB window 
	#      support for composited window transparency
	#      (c) 2011 by Wolfgang 'datenwolf' Draxinger
	
	#    6----7
	#   /|   /|
	#  3----2 |
	#  | 5--|-4
	#  |/   |/
	#  0----1
	$_data_array ||= OpenGL::Array->new_list(
		GL_FLOAT,
		#  X     Y     Z   Nx   Ny   Nz    S    T 
		-1.0, -1.0,  1.0, 0.0, 0.0, 1.0, 0.0, 0.0, # 0
		 1.0, -1.0,  1.0, 0.0, 0.0, 1.0, 1.0, 0.0, # 1
		 1.0,  1.0,  1.0, 0.0, 0.0, 1.0, 1.0, 1.0, # 2
		-1.0,  1.0,  1.0, 0.0, 0.0, 1.0, 0.0, 1.0, # 3

		 1.0, -1.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, # 4
		-1.0, -1.0, -1.0, 0.0, 0.0, -1.0, 1.0, 0.0, # 5
		-1.0,  1.0, -1.0, 0.0, 0.0, -1.0, 1.0, 1.0, # 6
		 1.0,  1.0, -1.0, 0.0, 0.0, -1.0, 0.0, 1.0, # 7

		-1.0, -1.0, -1.0, -1.0, 0.0, 0.0, 0.0, 0.0, # 5
		-1.0, -1.0,  1.0, -1.0, 0.0, 0.0, 1.0, 0.0, # 0
		-1.0,  1.0,  1.0, -1.0, 0.0, 0.0, 1.0, 1.0, # 3
		-1.0,  1.0, -1.0, -1.0, 0.0, 0.0, 0.0, 1.0, # 6

		 1.0, -1.0,  1.0,  1.0, 0.0, 0.0, 0.0, 0.0, # 1
		 1.0, -1.0, -1.0,  1.0, 0.0, 0.0, 1.0, 0.0, # 4
		 1.0,  1.0, -1.0,  1.0, 0.0, 0.0, 1.0, 1.0, # 7
		 1.0,  1.0,  1.0,  1.0, 0.0, 0.0, 0.0, 1.0, # 2

		-1.0, -1.0, -1.0,  0.0, -1.0, 0.0, 0.0, 0.0, # 5
		 1.0, -1.0, -1.0,  0.0, -1.0, 0.0, 1.0, 0.0, # 4
		 1.0, -1.0,  1.0,  0.0, -1.0, 0.0, 1.0, 1.0, # 1
		-1.0, -1.0,  1.0,  0.0, -1.0, 0.0, 0.0, 1.0, # 0

		-1.0, 1.0,  1.0,  0.0,  1.0, 0.0, 0.0, 0.0, # 3
		 1.0, 1.0,  1.0,  0.0,  1.0, 0.0, 1.0, 0.0, # 2
		 1.0, 1.0, -1.0,  0.0,  1.0, 0.0, 1.0, 1.0, # 7
		-1.0, 1.0, -1.0,  0.0,  1.0, 0.0, 0.0, 1.0, # 6
	);
}

sub draw {
	my $self= shift;
	OpenGL::glEnableClientState(GL_VERTEX_ARRAY);
	OpenGL::glEnableClientState(GL_NORMAL_ARRAY);
	OpenGL::glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	my $data= $self->_data_array;
	OpenGL::glVertexPointer_c(3, GL_FLOAT, 4 * 8, $data->ptr);
	OpenGL::glNormalPointer_c(GL_FLOAT, 4 * 8, $data->ptr + 3*4);
	OpenGL::glTexCoordPointer_c(2, GL_FLOAT, 4 * 8, $data->ptr + 6*4);

	OpenGL::glDrawArrays(GL_QUADS, 0, 24);
}

1;
