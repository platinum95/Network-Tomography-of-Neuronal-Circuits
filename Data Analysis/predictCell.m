function prediction = predictCell( Vin, Vout, models, numCoeffs )
% Predict what cell is observed from a set of input-output measurements,
% and apretrained set of models. Vin/Vout are the input-output voltage
% vectors (must be same shape). `models` is a table of the trained models.
% `numCoeffs` is the number of FIR coefficients in the filters used to
% train the models.
% Return value is a cell of strings with the estimated layer, m-type, and
% e-type.

% Construct the observation matrix for the classifiers with enough space
% for the filter coefficients, the layer, and the m-type
fDataCell = cell( 2, numCoeffs + 2 );
for idx = 1:numCoeffs
    % Need to name the observations.
    fDataCell( 1, idx ) = cellstr( sprintf( "k_%i", idx ) );
end
fDataCell( 1, numCoeffs + 1 ) = cellstr( "layers" );
fDataCell( 1, numCoeffs + 2 ) = cellstr( "mTypes" );
% Get the LNP-ish filter estimate
filterCoeffs = estimateFilter( Vin, Vout, numCoeffs );
fDataCell( 2, 1 : numCoeffs ) = num2cell( filterCoeffs' );
% Convert the observations to a table for the classifiers
fDataTable = cell2table( fDataCell ( 2 : end, : ), ...
                         'VariableNames', fDataCell( 1 , : ) );

% Predict the layer
layer = models.layerModel.predictFcn( fDataTable );
fDataTable.layers( 1 ) = layer;

% Predict the m-type
mType = models.mTypeModel.predictFcn( fDataTable );
fDataTable.mTypes( 1 ) = mType;

% Predict the e-type
eType = models.eTypeModel.predictFcn( fDataTable );

% Return the predictions
prediction = { char( layer ), char( mType ), char( eType ) };
