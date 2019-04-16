% Reconstruct a 4-leaf star topology from measurements of the network and
% trained classifier models

% Data directories of the simulation data and the trained classifiers
dataInputDirPath = "../neurpy_git/4leaf_outputs_force2/";
trainedModelPath = "./cubicSvm64k.mat";

% Get the valid data files
dataFilePaths = dir( dataInputDirPath + "*_probes.csv" );
numFiles = length( dataFilePaths );

% Construct a cell of the predictions from the network simulations
predictedDataCell = cell( numFiles + 1, 3 );
predictedDataCell( 1, : ) = { 'Prediction' 'Actual' 'Metrics' };

% Load in the trained classifiers
models = load( trainedModelPath );


% For each valid simulation file (multi-threaded)
parfor idx = 1:numFiles
    % Load in the measurements data and the meta-data of the network (i.e.
    % actual cell types)
    file = dataFilePaths( idx );
    fileName = file.name;
    probeFilePath = strcat( file.folder, strcat( "/", file.name ) );
    % Metadata is stored in a JSON file with same base-name
    jsonFilePath = strrep( probeFilePath, "_probes.csv", "_meta.json" );
    jsonStr = fileread( jsonFilePath );
    jsonData = jsondecode( jsonStr );

    % Read in the measurements
    probeData = csvread( probeFilePath, 1 );
    
    % Vin for each leaf cell is the same (measurement of central node)
    dataCentralNode = probeData( :, 2 );
    
    % Predict each of the leaf-cells
    estSat1 = predictCell( dataCentralNode, probeData( :, 3 ), models, 64 );
    estSat2 = predictCell( dataCentralNode, probeData( :, 4 ), models, 64 );
    estSat3 = predictCell( dataCentralNode, probeData( :, 5 ), models, 64 );
    estSat4 = predictCell( dataCentralNode, probeData( :, 6 ), models, 64 );
    
    % Group the network prediction together
    networkPrediction = { estSat1, estSat2, estSat3,...    
                          estSat4 };
    % Grab the actual cell types (in the same format as the prediction)
    networkActual = { splitCellType( jsonData.leaf1Type ),...
                      splitCellType( jsonData.leaf2Type ),...
                      splitCellType( jsonData.leaf3Type ),...
                      splitCellType( jsonData.leaf4Type ) };

    % Run a comparison between the prediction and the ground truth
    metrics = compareCells( networkPrediction, networkActual );
    
    % Slot the prediction data into the accumulating cell
    predictedDataCell( idx + 1, : ) = { networkPrediction, networkActual,...
                                     metrics };
    % Print out the current file index just to keep track of it
    fprintf( "File #%d\n", idx );

end

% Convert the data to a table for easier browsing
outputDataTable = cell2table( predictedDataCell( 2:end, : ), ...
        'VariableNames', predictedDataCell( 1, : ) );

% Take the average of the metrics
metrics = outputDataTable.Metrics;
metricsArr = cell2mat( metrics );
metMeans = mean( metricsArr, 1 );

function metrics = compareCells( predictions, actuals )
    % Function that takes a prediction/ground truth set and returns various
    % metrics on the prediction performance.
    
    numSamples = size( predictions, 2 );
    layersCorrect = 0;
    mTypesCorrect = 0;
    eTypesCorrect = 0;
    cellsCorrect = 0;
    for cellIdx = 1:numSamples
        pred = predictions( 1, cellIdx );
        act = actuals( 1, cellIdx );
        pred = pred{ : };
        act = act{ : };
        numPredCorrect = 0;
        % Check if layer/m-type/e-type were correct
        if( strcmp( pred( 1 ), act( 1 ) ) )
            layersCorrect = layersCorrect + 1;
            numPredCorrect = numPredCorrect + 1;
        end
        if( strcmp( pred( 2 ), act( 2 ) ) )
            mTypesCorrect = mTypesCorrect + 1;
            numPredCorrect = numPredCorrect + 1;
        end
        if( strcmp( pred( 3 ), act( 3 ) ) )
            eTypesCorrect = eTypesCorrect + 1;
            numPredCorrect = numPredCorrect + 1;
        end
        if( numPredCorrect == 3 )
            % If we predicted all 3 correctly, the cell is completely
            % predicted
            cellsCorrect = cellsCorrect + 1;
        end
    end
    
    layerAcc = layersCorrect / numSamples;
    mTypeAcc = mTypesCorrect / numSamples;
    eTypeAcc = eTypesCorrect / numSamples;
    cellsAcc = cellsCorrect / numSamples;
    metrics = { layerAcc, mTypeAcc, eTypeAcc, cellsAcc };
    
end

function cellTypeCell = splitCellType( cellStr )
    % Function to take a cell-string and split it into layer, m-type, and
    % e-type
    cSplit = regexp( cellStr, "_", 'split' );
    layer = char( cSplit( 1, 2 ) );
    mType = char( cSplit( 1, 1 ) );
    eType = char( cSplit( 1, 3 ) );
    cellTypeCell = { layer, mType, eType };
end