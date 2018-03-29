package X11::XRandR::Grammar::Verbose;

# ABSTRACT: The Compiled Pegex Grammar for xrandr --verbose output

use strict;
use warnings;

use base 'Pegex::Grammar';
use constant file => './share/verbose.pgx';

our $VERSION = '0.01';

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.64)
  {
    '+grammar' => 'state',
    '+toprule' => 'state',
    '+version' => '0.0.1',
    'BLANK' => {
      '.rgx' => qr/\G[\ \t]/
    },
    'Border' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GBorder:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'border_values'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'Brightness' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GBrightness:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'float'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'COLON' => {
      '.rgx' => qr/\G:/
    },
    'COMMA' => {
      '.rgx' => qr/\G,/
    },
    'CRTC' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GCRTC:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.rgx' => qr/\G(.*)/
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'CRTCs' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GCRTCs:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.all' => [
            {
              '.ref' => 'integer'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '-skip' => 1,
                  '.ref' => 'BLANK'
                },
                {
                  '.ref' => 'integer'
                }
              ]
            }
          ]
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'Clones' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GClones:/
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'NotSpace'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '+min' => 1,
                  '-skip' => 1,
                  '.ref' => 'BLANK'
                },
                {
                  '.ref' => 'NotSpace'
                }
              ]
            }
          ]
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'EDID_value' => {
      '.all' => [
        {
          '.ref' => 'hexraw'
        },
        {
          '+max' => 7,
          '+min' => 7,
          '-flat' => 1,
          '.all' => [
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'WS'
            },
            {
              '.ref' => 'hexraw'
            }
          ]
        }
      ]
    },
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'Gamma' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GGamma:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => 'float'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'COLON'
                },
                {
                  '.ref' => 'float'
                }
              ]
            }
          ]
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'Identifier' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GIdentifier:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'hexint'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'LPAREN' => {
      '.rgx' => qr/\G\(/
    },
    'NotSpace' => {
      '.rgx' => qr/\G(\S+)/
    },
    'Panning' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GPanning:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'geometry'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'RPAREN' => {
      '.rgx' => qr/\G\)/
    },
    'SLASH' => {
      '.rgx' => qr/\G\//
    },
    'Subpixel' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GSubpixel:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.rgx' => qr/\G(.+)/
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'Timestamp' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GTimestamp:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'integer'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'Tracking' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GTracking:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'geometry'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'Transform' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\GTransform:/
        },
        {
          '.ref' => '__'
        },
        {
          '.all' => [
            {
              '.ref' => 'float'
            },
            {
              '+max' => 8,
              '+min' => 8,
              '-flat' => 1,
              '.all' => [
                {
                  '+min' => 1,
                  '-skip' => 1,
                  '.ref' => 'WS'
                },
                {
                  '.ref' => 'float'
                }
              ]
            }
          ]
        },
        {
          '+max' => 1,
          '.ref' => 'filter'
        }
      ]
    },
    'WS' => {
      '.rgx' => qr/\G\s/
    },
    '_' => {
      '.rgx' => qr/\G\s*/
    },
    '__' => {
      '.rgx' => qr/\G\s+/
    },
    'border' => {
      '.all' => [
        {
          '.rgx' => qr/\Gborder/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'border_values'
        }
      ]
    },
    'border_values' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'left'
        },
        {
          '.ref' => 'SLASH'
        },
        {
          '-wrap' => 1,
          '.ref' => 'top'
        },
        {
          '.ref' => 'SLASH'
        },
        {
          '-wrap' => 1,
          '.ref' => 'right'
        },
        {
          '.ref' => 'SLASH'
        },
        {
          '-wrap' => 1,
          '.ref' => 'bottom'
        }
      ]
    },
    'bottom' => {
      '.rgx' => qr/\G([0-9]+)/
    },
    'cur_crtc' => {
      '.all' => [
        {
          '+max' => 1,
          '.all' => [
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            },
            {
              '-wrap' => 1,
              '.ref' => 'panning'
            }
          ]
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            },
            {
              '-wrap' => 1,
              '.ref' => 'tracking'
            }
          ]
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            },
            {
              '-wrap' => 1,
              '.ref' => 'border'
            }
          ]
        }
      ]
    },
    'cur_mode' => {
      '.all' => [
        {
          '+max' => 1,
          '.all' => [
            {
              '-wrap' => 1,
              '.ref' => 'geometry'
            },
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            }
          ]
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.ref' => 'LPAREN'
            },
            {
              '-wrap' => 1,
              '.ref' => 'mode_id'
            },
            {
              '-skip' => 1,
              '.ref' => 'RPAREN'
            },
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            }
          ]
        },
        {
          '-wrap' => 1,
          '.ref' => 'rotation'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            },
            {
              '-wrap' => 1,
              '.ref' => 'cur_mode_reflection'
            }
          ]
        }
      ]
    },
    'cur_mode_reflection' => {
      '.rgx' => qr/\G(none|X\ axis|Y\ axis|X\ and\ Y\ axis)/
    },
    'dimension' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'x'
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.rgx' => qr/\Gx/
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'y'
        }
      ]
    },
    'dimension_mm' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'x'
        },
        {
          '.rgx' => qr/\Gmm/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.rgx' => qr/\Gx/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'y'
        },
        {
          '.rgx' => qr/\Gmm/
        }
      ]
    },
    'dotClock' => {
      '.ref' => 'frequency'
    },
    'filter' => {
      '.all' => [
        {
          '.rgx' => qr/\G\s+filter:[\ \t]*(\w+)?/
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'float' => {
      '.rgx' => qr/\G([0-9]+?[.][0-9]+)/
    },
    'frequency' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'frequency_value'
        },
        {
          '-wrap' => 1,
          '.ref' => 'frequency_unit'
        }
      ]
    },
    'frequency_unit' => {
      '.rgx' => qr/\G((?:M|K)?Hz)/
    },
    'frequency_value' => {
      '.ref' => 'float'
    },
    'geometry' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'dimension'
        },
        {
          '-wrap' => 1,
          '.ref' => 'offset'
        }
      ]
    },
    'hMode' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\Gh:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'mode_width'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'hSyncStart'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'hSyncEnd'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'hTotal'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'hSkew'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'hSync'
        }
      ]
    },
    'hSkew' => {
      '.rgx' => qr/\Gskew\s+([0-9]+)/
    },
    'hSync' => {
      '.all' => [
        {
          '.rgx' => qr/\Gclock/
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'frequency'
        }
      ]
    },
    'hSyncEnd' => {
      '.rgx' => qr/\Gend\s+([0-9]+)/
    },
    'hSyncStart' => {
      '.rgx' => qr/\Gstart\s+([0-9]+)/
    },
    'hTotal' => {
      '.rgx' => qr/\Gtotal\s+([0-9]+)/
    },
    'hexint' => {
      '.rgx' => qr/\G(0x[0-9a-fA-F]{2})/
    },
    'hexraw' => {
      '.rgx' => qr/\G([0-9a-fA-F]+)/
    },
    'integer' => {
      '.rgx' => qr/\G([0-9]+)/
    },
    'left' => {
      '.rgx' => qr/\G([0-9]+)/
    },
    'mode' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'mode_name'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'LPAREN'
        },
        {
          '-wrap' => 1,
          '.ref' => 'mode_id'
        },
        {
          '.ref' => 'RPAREN'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'dotClock'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'modeFlags'
        },
        {
          '-wrap' => 1,
          '.ref' => 'mode_current'
        },
        {
          '-wrap' => 1,
          '.ref' => 'mode_preferred'
        },
        {
          '.ref' => 'EOL'
        },
        {
          '-wrap' => 1,
          '.ref' => 'hMode'
        },
        {
          '.ref' => 'EOL'
        },
        {
          '-wrap' => 1,
          '.ref' => 'vMode'
        }
      ]
    },
    'modeFlag' => {
      '.rgx' => qr/\G(\+HSync|\-HSync|\+VSync|\-VSync|Interlace|DoubleScan|CSync|\+CSync|\-CSync)/
    },
    'modeFlags' => {
      '.all' => [
        {
          '.ref' => 'modeFlag'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => '__'
            },
            {
              '.ref' => 'modeFlag'
            }
          ]
        }
      ]
    },
    'mode_current' => {
      '+max' => 1,
      '.all' => [
        {
          '+min' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.rgx' => qr/\G\*current/
        }
      ]
    },
    'mode_height' => {
      '.rgx' => qr/\Gheight\s+([0-9]+)/
    },
    'mode_id' => {
      '.ref' => 'hexint'
    },
    'mode_name' => {
      '.rgx' => qr/\G\s+(\w+)/
    },
    'mode_preferred' => {
      '+max' => 1,
      '.all' => [
        {
          '+min' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.rgx' => qr/\G\+preferred/
        }
      ]
    },
    'mode_width' => {
      '.rgx' => qr/\Gwidth\s+([0-9]+)/
    },
    'modes' => {
      '.all' => [
        {
          '.ref' => 'mode'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => 'EOL'
            },
            {
              '.ref' => 'mode'
            }
          ]
        },
        {
          '+max' => 1,
          '.ref' => 'EOL'
        }
      ]
    },
    'offset' => {
      '.all' => [
        {
          '.rgx' => qr/\G(\+|\-)/
        },
        {
          '.ref' => 'x'
        },
        {
          '.rgx' => qr/\G(\+|\-)/
        },
        {
          '.ref' => 'y'
        }
      ]
    },
    'output' => {
      '.all' => [
        {
          '.ref' => 'output_header'
        },
        {
          '-wrap' => 1,
          '.ref' => 'Identifier'
        },
        {
          '-wrap' => 1,
          '.ref' => 'Timestamp'
        },
        {
          '-wrap' => 1,
          '.ref' => 'Subpixel'
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'Gamma'
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'Brightness'
        },
        {
          '-wrap' => 1,
          '.ref' => 'Clones'
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'CRTC'
        },
        {
          '-wrap' => 1,
          '.ref' => 'CRTCs'
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'Panning'
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'Tracking'
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'Border'
        },
        {
          '-wrap' => 1,
          '.ref' => 'Transform'
        },
        {
          '-wrap' => 1,
          '.ref' => 'properties'
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'modes'
        }
      ]
    },
    'output_connection' => {
      '.rgx' => qr/\G(connected|disconnected|unknown\ connection)/
    },
    'output_header' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'output_name'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'output_connection'
        },
        {
          '-wrap' => 1,
          '.ref' => 'output_primary'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            },
            {
              '-wrap' => 1,
              '.ref' => 'cur_mode'
            }
          ]
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'LPAREN'
        },
        {
          '-wrap' => 1,
          '.ref' => 'rotations'
        },
        {
          '.ref' => '_'
        },
        {
          '-wrap' => 1,
          '.ref' => 'output_header_reflections'
        },
        {
          '.ref' => 'RPAREN'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            },
            {
              '-wrap' => 1,
              '.ref' => 'dimension_mm'
            }
          ]
        },
        {
          '+max' => 1,
          '-wrap' => 1,
          '.ref' => 'cur_crtc'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'output_header_reflection_xy' => {
      '.rgx' => qr/\G(x\ axis|y\ axis)/
    },
    'output_header_reflections' => {
      '+max' => 1,
      '.all' => [
        {
          '.ref' => 'output_header_reflection_xy'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => '__'
            },
            {
              '.ref' => 'output_header_reflection_xy'
            }
          ]
        }
      ]
    },
    'output_name' => {
      '.rgx' => qr/\G(\S+)/
    },
    'output_primary' => {
      '+max' => 1,
      '.all' => [
        {
          '+min' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.rgx' => qr/\Gprimary/
        }
      ]
    },
    'outputs' => {
      '+min' => 1,
      '.ref' => 'output'
    },
    'panning' => {
      '.all' => [
        {
          '.rgx' => qr/\Gpanning/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'geometry'
        }
      ]
    },
    'properties' => {
      '.all' => [
        {
          '.ref' => 'property_type'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => 'EOL'
            },
            {
              '.ref' => 'property_type'
            }
          ]
        },
        {
          '+max' => 1,
          '.ref' => 'EOL'
        }
      ]
    },
    'property' => {
      '.all' => [
        {
          '.rgx' => qr/\G\s+([^:\r?\n]+):\s+(.*\S)?/
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '+max' => 1,
          '.any' => [
            {
              '-wrap' => 1,
              '.ref' => 'supported'
            },
            {
              '-wrap' => 1,
              '.ref' => 'ranges'
            }
          ]
        }
      ]
    },
    'property_EDID' => {
      '.all' => [
        {
          '.rgx' => qr/\G\s+EDID:\s+/
        },
        {
          '-wrap' => 1,
          '.ref' => 'EDID_value'
        }
      ]
    },
    'property_type' => {
      '.any' => [
        {
          '.ref' => 'property_EDID'
        },
        {
          '.ref' => 'property'
        }
      ]
    },
    'property_value' => {
      '.rgx' => qr/\G\s*([^,\n]+)/
    },
    'property_values' => {
      '.all' => [
        {
          '.ref' => 'property_value'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => 'COMMA'
            },
            {
              '.ref' => 'property_value'
            }
          ]
        }
      ]
    },
    'range' => {
      '.all' => [
        {
          '.ref' => 'LPAREN'
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'property_values'
        },
        {
          '+min' => 0,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'RPAREN'
        }
      ]
    },
    'ranges' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\Grange:|ranges:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.all' => [
            {
              '-wrap' => 1,
              '.ref' => 'range'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'COMMA'
                },
                {
                  '-wrap' => 1,
                  '.ref' => 'range'
                }
              ]
            },
            {
              '+max' => 1,
              '.ref' => 'COMMA'
            }
          ]
        }
      ]
    },
    'right' => {
      '.rgx' => qr/\G([0-9]+)/
    },
    'rotation' => {
      '.rgx' => qr/\G(normal|left|inverted|right)/
    },
    'rotations' => {
      '+max' => 1,
      '.all' => [
        {
          '.ref' => 'rotation'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => '__'
            },
            {
              '.ref' => 'rotation'
            }
          ]
        }
      ]
    },
    'screen' => {
      '.all' => [
        {
          '.ref' => '_'
        },
        {
          '.rgx' => qr/\GScreen/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'screen_id'
        },
        {
          '.ref' => 'COLON'
        },
        {
          '.ref' => 'screen_dims'
        },
        {
          '.ref' => 'EOL'
        }
      ]
    },
    'screen_dims' => {
      '.all' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G\s+(minimum|maximum|current)/
            },
            {
              '+min' => 1,
              '-skip' => 1,
              '.ref' => 'BLANK'
            },
            {
              '-wrap' => 1,
              '.ref' => 'dimension'
            }
          ]
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => 'COMMA'
            },
            {
              '.all' => [
                {
                  '.rgx' => qr/\G\s+(minimum|maximum|current)/
                },
                {
                  '+min' => 1,
                  '-skip' => 1,
                  '.ref' => 'BLANK'
                },
                {
                  '-wrap' => 1,
                  '.ref' => 'dimension'
                }
              ]
            }
          ]
        },
        {
          '+max' => 1,
          '.ref' => 'COMMA'
        }
      ]
    },
    'screen_id' => {
      '.ref' => 'integer'
    },
    'state' => {
      '.all' => [
        {
          '-wrap' => 1,
          '.ref' => 'screen'
        },
        {
          '-wrap' => 1,
          '.ref' => 'outputs'
        }
      ]
    },
    'supported' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\Gsupported:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'property_values'
        }
      ]
    },
    'top' => {
      '.rgx' => qr/\G([0-9]+)/
    },
    'tracking' => {
      '.all' => [
        {
          '.rgx' => qr/\Gtracking/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '.ref' => 'geometry'
        }
      ]
    },
    'vMode' => {
      '.all' => [
        {
          '.ref' => '__'
        },
        {
          '.rgx' => qr/\Gv:/
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'mode_height'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'vSyncStart'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'vSyncEnd'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'vTotal'
        },
        {
          '+min' => 1,
          '-skip' => 1,
          '.ref' => 'BLANK'
        },
        {
          '-wrap' => 1,
          '.ref' => 'vSync'
        }
      ]
    },
    'vSync' => {
      '.all' => [
        {
          '.rgx' => qr/\Gclock/
        },
        {
          '.ref' => '__'
        },
        {
          '.ref' => 'frequency'
        }
      ]
    },
    'vSyncEnd' => {
      '.rgx' => qr/\Gend\s+([0-9]+)/
    },
    'vSyncStart' => {
      '.rgx' => qr/\Gstart\s+([0-9]+)/
    },
    'vTotal' => {
      '.rgx' => qr/\Gtotal\s+([0-9]+)/
    },
    'x' => {
      '.rgx' => qr/\G([0-9]+)/
    },
    'y' => {
      '.rgx' => qr/\G([0-9]+)/
    }
  }
}

1;

#
# This file is part of X11-XRandR
#
# This software is Copyright (c) 2018 by Diab Jerius.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

X11::XRandR::Grammar::Verbose - The Compiled Pegex Grammar for xrandr --verbose output

=head1 VERSION

version 0.01

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=X11-XRandR> or by email
to L<bug-X11-XRandR@rt.cpan.org|mailto:bug-X11-XRandR@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/x11-xrandr>
and may be cloned from L<git://github.com/djerius/x11-xrandr.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<X11::XRandR|X11::XRandR>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Diab Jerius.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
