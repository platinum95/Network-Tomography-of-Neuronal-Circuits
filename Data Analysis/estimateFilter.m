function filtEst = estimateFilter( dataX, dataY, numCoeffs )
    % Estimate the equivalent n-order FIR filter from input-output
    % measurements.
    % dataX is the input voltage measurement vector, dataY is the same for
    % the output. dataX and dataY must be the same size.
    % numCoeffs is the number of coefficients in the estimated filter.
    % Return value is a numCoeffs-length vector containing the filter
    % coefficients
    
    % Get the time-shifted matrix of the input data
    mX = getXMat( dataX, numCoeffs );
    % Get the pseudoinverse of the time-shifted input matrix
    mPinvX = pinv( mX );
    % Take the filter coefficients
    filtEst = mPinvX * dataY;

end


function [ outputMat ] = getXMat( dataX, numCoeffs )
    % Construct a time-shifted windowed data matrix for the input data
    % Output matrix is of shape dataX.len x filter order
    
    outputMat = zeros( length( dataX ), numCoeffs );
    
    % For the first `numCoeffs` rows, the window won't completely overlap
    % input data, so pad out with zeroes.
    for ii = 1 : numCoeffs
        mData = dataX( 1 : ii )';
        mData = fliplr( mData );
        padAmount = numCoeffs - ii;
        mRow = padarray( mData', padAmount, 'post' )';
        outputMat( ii, : ) =  mRow;
    end

    % For the remaining data, the window will fully overlap with the input
    % data so just take the window and slot it into the matrix
    for ii = numCoeffs + 1 : length( dataX )
        upperBound = ii;
        lowerBound = upperBound - numCoeffs + 1;
        mData = dataX( lowerBound : upperBound )';
        mData = fliplr( mData );
        outputMat( ii, : ) = mData;
    end

end