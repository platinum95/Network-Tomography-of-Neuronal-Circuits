% Estimate the LNP-ish linear-filter of the post-synaptic cell from a set 
% of 2-cell simulations

% Input/output paths
dataInputDirPath = "../../offsite/2cell_outputs_freesel_topsyn/";
%dataInputDirPath = "../Neurpy/2cell_outputs_freesel_topsyn/";
dataOutputPath = "./outputFeatures_offsite_freesel_topsyn.csv";

% Get valid simulation files
dataFilePaths = dir( dataInputDirPath + "*_probes.csv" );

numFiles = length( dataFilePaths );

% Construct output cell
outputDataCell = cell( numFiles + 1, 5 );
outputDataCell( 1, : ) = { 'DataFile' 'k' 'layer' 'mtype' 'etype' };

% For each simulation
parfor idx = 1:numFiles
    % Get the measurement data and post-synaptic cell name
    probeFilePath = dataFilePaths( idx ).name;
    metaFilePath = strrep( probeFilePath, "_probes.csv", "_meta.json" );
    metaFilePath = strcat( dataInputDirPath, metaFilePath );
    probeFilePath = strcat( dataInputDirPath, probeFilePath );
    probeData = csvread( probeFilePath, 1 );
    
%    tailVolt = probeData( :, 3 );
%    [ spikePeaks, spikePkLocs ] = findpeaks( tailVolt );
%    spikePeaks = spikePeaks( spikePeaks > 0.0 );
%    if ( length( spikePeaks ) < 2.0 )
%        continue
%    end
    
    jsonStr = fileread( metaFilePath );
    jsonData = jsondecode( jsonStr );
    postSynStr = jsonData.postSynType;
    cSplit = regexp( postSynStr, "_", 'split' );
    layer = cSplit( 1, 2 );
    mType = cSplit( 1, 3 );
    eType = cSplit( 1, 1 );
    
    % Get the filter coefficients
    kFilt = analyseFile( probeFilePath );
    
    % Place the data in the output cell
    outputDataCell( idx + 1, : ) = { probeFilePath kFilt layer ...
                                     mType eType }; 
    fprintf( "File %s\n", probeFilePath );
end

% Convert cell to a table and use first row as variable names
outputDataTable = cell2table( outputDataCell ( 2 : end, : ), ...
                              'VariableNames', outputDataCell( 1 , : ) );

% Write the table to a CSV file
writetable( outputDataTable, dataOutputPath );

% Load table in again (to flatten the filter coeffs)
data = readtable( dataOutputPath );

% Function to read in 2-cell simulation data and analyse it, returning
% the mutual information of the channel
function kFilt = analyseFile( filename )
    numFilterCoeffs = 64;
    % Read the data CSV
    data = csvread( filename, 1 );
    dataX = data( :, 2 );
    dataY = data( :, 3 );
    
    % Grab the filter coefficient estimates
    kFilt = estimateFilter( dataX, dataY, numFilterCoeffs );   
end