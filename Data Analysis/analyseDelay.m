% Estimate the delays of a set of 2-cell measurements using
% cross-correlation

% Directory of the simulation data
dataInputDirPath = "../../offsite/2cell_outputs_freesel_topsyn/";
%dataInputDirPath = "../Neurpy/2cell_outputs_freesel_topsyn/";

% Time interval in ms
timeInterval = 0.1;

% Valid simulation
dataFilePaths = dir( dataInputDirPath + "*_probes.csv" );
numFiles = length( dataFilePaths );

delayDataCell = cell( numFiles + 1, 2 );
delayDataCell( 1, : ) = { 'ActualDelay' 'EstimatedDelay' };

valids = zeros( 1, numFiles + 1 );
valids( 1 ) = 1;

parfor idx = 1:numFiles
    % Get proble data and delay ground truth
    probeFilePath = dataFilePaths( idx ).name;
    metaFilePath = strrep( probeFilePath, "_probes.csv", "_meta.json" );
    metaFilePath = strcat( dataInputDirPath, metaFilePath );
    probeFilePath = strcat( dataInputDirPath, probeFilePath );
    probeData = csvread( probeFilePath, 1 );
    
    tVec = probeData( :, 1 );
    headVolt = probeData( :, 2 );
    tailVolt = probeData( :, 3 );
    [ spikePeaks, spikePkLocs ] = findpeaks( max( tailVolt, 0.0 ), 'MinPeakProminence',4 );
    %spikePeaks = spikePeaks( spikePeaks > 0.0 );
    %plot( tailVolt );
    if ( length( spikePeaks ) == 0.0 )
        delayDataCell( idx + 1, : ) = { -1.0 -1.0 };
        valids( idx + 1 ) = 0;
        continue
    end
    valids( idx + 1 ) = 1;
    tailVolt = max( tailVolt, 0.0 );
    headVolt = max( headVolt, 0.0 );
       
    headVolt = headVolt / max( headVolt );
    tailVolt = tailVolt / max( tailVolt );
    
    % Cross-correlate input-output signal
    [ sigCorr, lags ] = xcorr( tailVolt, headVolt, 150 );
    
    % Find local maxima in the correlation
    [ peaks, pkLocs ] = findpeaks( sigCorr, lags, 'SortStr', 'descend' );
    %[ peaks, pkLocs ] = findpeaks( sigCorr, lags, 'MinPeakHeight', 0.5 );
    
    % Try to find the lowest lag value that isn't 0
    pkLocs = pkLocs( pkLocs > 0.0 );
    
    if( isempty( pkLocs ) )
        continue;
    end
    delayEstTimeSteps = pkLocs( 1 );
    
    % Delay estimate in simulation timesteps, convert to MS
    delayEstMs = delayEstTimeSteps * timeInterval;
    lags = lags .* timeInterval;
    
    jsonStr = fileread( metaFilePath );
    jsonData = jsondecode( jsonStr );
    actualDelay = jsonData.edgeDelay;
        
    % Place the prediction + ground truth in the data cell
    delayDataCell( idx + 1, : ) = { actualDelay delayEstMs };
    fprintf( "File %s\n" , probeFilePath );
end

%delayDataCell = delayDataCell( 1:curCellIdx + 2, : );

% Convert cell to a table and use first row as variable names
delayDataTable = cell2table( delayDataCell ( 2 : end, : ), ...
                              'VariableNames', delayDataCell( 1 , : ) );

