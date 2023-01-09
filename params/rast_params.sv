package rast_params;

    localparam SIGFIG = 24; // Bits in color and position.
    // localparam RADIX = 10; // Fraction bits in color and position
    localparam RADIX = 10; // Fraction bits in color and position
    localparam VERTS = 3; // Maximum Vertices in micropolygon
    localparam AXIS = 3; // Number of axis foreach vertex 3 is (x,y,z).
    localparam COLORS = 3; // Number of color channels
    localparam PIPES_BOX = 3; // Number of Pipe Stages in bbox module
    localparam PIPES_ITER = 2; // Number of Pipe Stages in iter module
    // localparam PIPES_BOX = 3; // Number of Pipe Stages in bbox module
    // localparam PIPES_ITER = 2; // Number of Pipe Stages in iter module
    localparam PIPES_HASH = 2; // Number of pipe stages in hash module
    localparam PIPES_SAMP = 2; // Number of Pipe Stages in sample module

endpackage
