# Data Analysis Files
MATLAB scripts for the analysis of the data produced during experimentation  
  
*__analyseDelay__*  
Load in a set of 2-cell simulations and estimate the delay between the neurons using cross-correlation analysis.  
Take the prediction and compare it against the ground truth of the experiment.  
  

*__discretiseTrain__*  
Discretise the spike train in a neuronal voltage measurement into a binary sequence based on thresholding and windowing.  
  
*__getMutualInfo__*  
Calculates the mutual information from 2 discretised spike trains.  
  
*__analyseInfoTheory__*  
Load in a set of 2-cell simulations and calculate the discrete-memoryless mutual information between the cells as well as the entropy of the post-synaptic cell.  
Load in the parameters of the synaptic connection as well, and concatenate all the data together before saving to disk.  
  
*__estimateFilter__*  
Estimate the LNP-ish linear filter from a set of input-output voltage measurements.  
Basically estimates the k-order FIR filter for the input/output voltage vectors.  
  
*__simFeatureExtract__*  
Take the set of neuronal simulation data and construct a trainable-matrix from it.  
Estimates the FIR filter coefficients and takes the network ground-truth, concatenating together into a single data structure.  
  
*__predictCell__*  
Using a previously trained set of classification models, predict cell-type from input-output voltage measurements.  
  
*__estimate_4leaf__*  
Uses *predictCell* above to reconstruct a 4-leaf star topology from endpoint measurements.  
  
*__restructureData__*  
Live script with some useful functions for rejigging the data into classifier-specific friendly forms.  

*__genPlots__*  
Live script containing the code for plotting the figures used in the thesis/paper.  
