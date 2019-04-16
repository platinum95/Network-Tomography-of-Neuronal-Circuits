function mutInfo = getMutualInfo( X, Y )
% Get the discrete-memoryless mutual information between the discretised
% spike trains X and Y

% Get P( X )
[ n, x ] = hist( X, [ 0 1 ] );
pX = n ./ length( X );

% Get P( Y )
[ n, x ] = hist( Y, [ 0 1 ] );
pY = n ./ length( Y );

XY = [ X ; Y ];
% Get P( X, Y )
pXY = hist3( transpose( XY ), 'NBins', [ 2, 2 ] ) ./ length( X );

% Get P( X | Y )
pXgY = [ ( pXY( 1, 1 ) / pY( 1 ) ) ( pXY( 1, 2 ) / pY( 2 ) ) ;
         ( pXY( 2, 1 ) / pY( 1 ) ) ( pXY( 2, 2 ) / pY( 2 ) ) 
       ];

mutInfo = 0;

% Sum over symbol set {0, 1} and calculate mutual information
for j = 1 : 2
   for k = 1 : 2
       symbInfo = ( pXY( j, k ) * log2( pX( j ) * pXgY( j, k ) ) );
       if( isnan( symbInfo ) & pXY( j, k ) == 0 )
           symbInfo = 0;
       end
       mutInfo = mutInfo + symbInfo;
   end
end
mutInfo = -mutInfo;
end

