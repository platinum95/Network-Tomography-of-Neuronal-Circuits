% Analyse the mutual information and entropy in two-cell network
% simulations

% Input/output paths
%dataInputDirPath = "../Neurpy/2cell_outputs_allSyn/";
dataInputDirPath = "../../offsite/2cell_outputs_freesel_topsyn/";
% dataOutputPath = "./output_kFilt_allSyn_new.csv";

% Get valid simulation files
dataFilePaths = dir( dataInputDirPath + "*_probes.csv" );

numFiles = length( dataFilePaths );

% Construct the output data cell
outputDataCell = cell( numFiles + 1, 10 );
outputDataCell( 1, : ) = { 'DataFile' 'MutualInfo' 'MutualInfoShifted' ...
                           'Entropy_PostSyn' 'PreSyn' 'PostSyn' ...
                           'connCount' 'distance' 'delay' 'weight' };
% For each simulation...
parfor idx = 1:numFiles
    % Get the measurement data and the network parameters
    probeFilePath = dataFilePaths( idx ).name;
    metaFilePath = strrep( probeFilePath, "_probes.csv", "_meta.json" );
    metaFilePath = strcat( dataInputDirPath, metaFilePath );
    probeFilePath = strcat( dataInputDirPath, probeFilePath );
    probeData = csvread( probeFilePath, 1 );
        
    jsonStr = fileread( metaFilePath );
    jsonData = jsondecode( jsonStr );
    preSynStr = jsonData.preSynType;
    postSynStr = jsonData.postSynType;
    connCount = jsonData.connCount;
    distance = jsonData.distance;
    delay = jsonData.edgeDelay;
    weight = jsonData.edgeWeight;
    % Get the mutual information and entropy of the network
    [ mInfo, mInfoShft, entropy ] = analyseFile( probeFilePath );
    
    % Place the data in the output matrix
    outputDataCell( idx + 1, : ) = { probeFilePath mInfo mInfoShft ...
                                     entropy preSynStr postSynStr ...
                                     connCount distance delay weight };
    fprintf( "File %s\n", probeFilePath );
end

% Convert cell to a table and use first row as variable names
outputMInfoDataTable = cell2table( outputDataCell ( 2 : end, : ), ...
                              'VariableNames', outputDataCell( 1 , : ) );

% Write the table to a CSV file
%writetable( outputDataTable, dataOutputPath );

% Function to read in 2-cell simulation data and analyse it, returning
% the mutual information of the channel
function [ mInfo, mInfoShft, entropy ] = analyseFile( filename )
    % Read the data CSV
    data = csvread( filename, 1 );
    dataX = data( :, 2 );
    dataY = data( :, 3 );   
    
    timeInterval = data( 2, 1 ) - data( 1 , 1 );
    
    % Cross-correlate to estimate delay
    [ sigCorr, lags ] = xcorr( dataY, dataX, 150 );
    % Find local maxima in the correlation
    [ peaks, pkLocs ] = findpeaks( sigCorr, lags, 'MinPeakHeight',1.0 );
    % Try to find the lowest lag value that isn't 0
    pkLocs = pkLocs( pkLocs > 0.0 );
    delayEstTimeSteps = 0;
    if( ~isempty( pkLocs ) )
        delayEstTimeSteps = pkLocs( 1 );
    end
    % Delay estimate in simulation timesteps, convert to MS
    delayEstMs = delayEstTimeSteps * timeInterval;
    

    % Pass through the linear model fit during delay estimation
    n_inv = -0.1422;
    m_inv = 0.9249;
    n = -n_inv/m_inv;
    m = 1/m_inv;
    delayLinearPred = @( x ) x*m + n;
    delayAdj = delayLinearPred( delayEstMs ) / timeInterval;
    
    % Advance dataY by delatEstTimeSteps for comparison
    dataYshifted = delayseq( dataY, -delayAdj );
    
    [ tX, dXLevs ] = discretiseTrain( dataX, 0.1 );
    [ tY, dYLevs ] = discretiseTrain( dataY, 0.1 );
    [ tYshft, dYShftLevs ] = discretiseTrain( dataYshifted, 0.1 );

    mInfo = getMutualInfo( dXLevs, dYLevs );
    mInfoShft = getMutualInfo( dXLevs, dYShftLevs );
    entropy = getEntropy( dYLevs );
end

function entropy = getEntropy( dLevs )
    % Calculate the discrete-memoryless entropy from the discretised train
    % Get P( X )
    [ n, x ] = hist( dLevs, [ 0 1 ] );
    pX = n ./ length( dLevs );
    % Get H( X )
    entropy = -( pX( 1 )*log2( pX( 1 ) ) ) - ( pX( 2 )*log2( pX( 2 ) ) );
end