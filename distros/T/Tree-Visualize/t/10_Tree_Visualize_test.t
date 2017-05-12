#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {


	# Tree
	use_ok('Tree::Visualize');

		# Tree/Visualize
		use_ok('Tree::Visualize::Config');
		use_ok('Tree::Visualize::Exceptions');
		use_ok('Tree::Visualize::Factory');

			# Tree/Visualize/ASCII
			use_ok('Tree::Visualize::ASCII::BoundingBox');

				# Tree/Visualize/ASCII/Connectors

					# Tree/Visualize/ASCII/Connectors/TopDown
					use_ok('Tree::Visualize::ASCII::Connectors::TopDown::LeftRightConnector');
					use_ok('Tree::Visualize::ASCII::Connectors::TopDown::MultiConnector');

					# Tree/Visualize/ASCII/Connectors/RightSide
					use_ok('Tree::Visualize::ASCII::Connectors::RightSide::LeftRightConnector');
					use_ok('Tree::Visualize::ASCII::Connectors::RightSide::MultiConnector');

					# Tree/Visualize/ASCII/Connectors/LeftSide
					use_ok('Tree::Visualize::ASCII::Connectors::LeftSide::LeftRightConnector');
					use_ok('Tree::Visualize::ASCII::Connectors::LeftSide::MultiConnector');

					# Tree/Visualize/ASCII/Connectors/Diagonal
					use_ok('Tree::Visualize::ASCII::Connectors::Diagonal::LeftRightConnector');

					# Tree/Visualize/ASCII/Connectors/BottomUp
					use_ok('Tree::Visualize::ASCII::Connectors::BottomUp::LeftRightConnector');
					use_ok('Tree::Visualize::ASCII::Connectors::BottomUp::MultiConnector');

				# Tree/Visualize/ASCII/Layouts
				use_ok('Tree::Visualize::ASCII::Layouts::Binary');
				use_ok('Tree::Visualize::ASCII::Layouts::Simple');

					# Tree/Visualize/ASCII/Layouts/Binary
					use_ok('Tree::Visualize::ASCII::Layouts::Binary::BottomUp');
					use_ok('Tree::Visualize::ASCII::Layouts::Binary::Diagonal');
					use_ok('Tree::Visualize::ASCII::Layouts::Binary::LeftSide');
					use_ok('Tree::Visualize::ASCII::Layouts::Binary::RightSide');
					use_ok('Tree::Visualize::ASCII::Layouts::Binary::TopDown');

					# Tree/Visualize/ASCII/Layouts/Simple
					use_ok('Tree::Visualize::ASCII::Layouts::Simple::BottomUp');
					use_ok('Tree::Visualize::ASCII::Layouts::Simple::LeftSide');
					use_ok('Tree::Visualize::ASCII::Layouts::Simple::RightSide');
					use_ok('Tree::Visualize::ASCII::Layouts::Simple::TopDown');

				# Tree/Visualize/ASCII/Node
				use_ok('Tree::Visualize::ASCII::Node::Brackets');
				use_ok('Tree::Visualize::ASCII::Node::Parens');
				use_ok('Tree::Visualize::ASCII::Node::PlainBox');

			# Tree/Visualize/Connector
			use_ok('Tree::Visualize::Connector::Factory');
			use_ok('Tree::Visualize::Connector::IConnector');

			# Tree/Visualize/Node
			use_ok('Tree::Visualize::Node::Factory');
			use_ok('Tree::Visualize::Node::INode');

			# Tree/Visualize/Layout
			use_ok('Tree::Visualize::Layout::Factory');
			use_ok('Tree::Visualize::Layout::ILayout');

			# Tree/Visualize/GraphViz

				# Tree/Visualize/GraphViz/Node
				use_ok('Tree::Visualize::GraphViz::Node::PlainNode');

				# Tree/Visualize/GraphViz/Layouts

					# Tree/Visualize/GraphViz/Layouts/Simple
					use_ok('Tree::Visualize::GraphViz::Layouts::Simple::Tree');

					# Tree/Visualize/GraphViz/Layouts/Binary
					use_ok('Tree::Visualize::GraphViz::Layouts::Binary::SearchTree');
					use_ok('Tree::Visualize::GraphViz::Layouts::Binary::Tree');

};

1;
