function [maxDrift_estimate, cumulativeDrift_estimate] = bc_maxDriftEstimate(pcFeatures, pcFeatureIdx, spikeTemplates, ...
    spikeTimes, channelPositions_z, thisUnit, driftBinSize, computeDrift, plotThis)
% JF, Estimate the maximum drift for a particular unit
% ------
% Inputs
% ------
% pc_features: nSpikes × nFeaturesPerChannel × nPCFeatures  single
%   matrix giving the PC values for each spike.
% pc_feature_ind: nTemplates × nPCFeatures uint32  matrix specifying which
%   channels contribute to each entry in dim 3 of the pc_features matrix
% spike_templates: nSpikes × 1 uint32 vector giving the identity of each
%   spike's matched template
% thisUnit: unit number
% computeDrift: boolean, whether tocomputeDrift( this is botle-neck slow step
%   that takes almost 2 seconds per unit)
% plotThis: boolean, whether to plot results (not implemented yet for this
%   function)
% ------
% Outputs
% ------
% maxDriftEstimate: maximum absolute difference between peak channels, in
%   um
% cumulativeDrift_estimate: cummulative absolute difference between peak channels, in
%   um
%
% ------
% References
% ------
% For the metric: Siegle, J.H., Jia, X., Durand, S. et al. Survey of spiking in the mouse
% visual system reveals functional hierarchy. Nature 592, 86–92 (2021). https://doi.org/10.1038/s41586-020-03171-x
% For the center of mass estimation, this is based on the method in:
% https://github.com/cortex-lab/spikes/analysis/ksDriftMap
if computeDrift

    %% calculate center of mass for each spike
    % if we selected some "good" times for this unit, where rpvs are low and
    % percent spikes missing too, only keep those times
    goodTimesSpikes = spikeTemplates > 0;
    pcFeatures = pcFeatures(goodTimesSpikes, :, :);
    spikeTemplates = spikeTemplates(goodTimesSpikes, :, :);

    pcFeatures_PC1 = squeeze(pcFeatures(spikeTemplates == thisUnit, 1, :)); % take the first PC
    pcFeatures_PC1(pcFeatures_PC1 < 0) = 0; % remove negative entries - we don't want to push the center of mass away from there.

    spikePC_feature = double(pcFeatureIdx(spikeTemplates, :)); % get channels for each spike
    spikeDepths_inChannels = sum(channelPositions_z(spikePC_feature(spikeTemplates == thisUnit, :)).*pcFeatures_PC1.^2, 2) ./ sum(pcFeatures_PC1.^2, 2); % center of mass: sum(coords.*features)/sum(features)

    %% estimate cumulative drift
    timeBins = min(spikeTimes):driftBinSize:max(spikeTimes);
    median_spikeDepth = arrayfun(@(x) nanmedian(spikeDepths_inChannels(spikeTimes >= x & spikeTimes < x+1)), timeBins); % median
    maxDrift_estimate = max(median_spikeDepth) - min(median_spikeDepth);
    median_spikeDepth(isnan(median_spikeDepth)) = []; % remove times with no spikes
    cumulativeDrift_estimate = sum(abs(diff(median_spikeDepth)));
else
    maxDrift_estimate = NaN;
    cumulativeDrift_estimate = NaN;
end