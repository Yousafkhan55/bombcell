function [unitType, qMetric] = bc_qualityMetricsPipeline_JF(animal, day, site, recording, experiment_num, protocol, rerun, plotGUI, runQM)

%% load data 
% animals = {'JF070'};
% bhvprotocol = '';
% 
% animal = animals{1};
experiments = AP_find_experimentsJF(animal, protocol, true);
experiments = experiments([experiments.ephys]);


experiment = experiments(experiment_num).experiment;

ephysPath = AP_cortexlab_filenameJF(animal,day,experiment,'ephys',site,recording);
[spikeTimes_samples, spikeTemplates, ...
    templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, channelPositions] = bc_loadEphysData(ephysPath);
ephysap_path = dir(AP_cortexlab_filenameJF(animal,day,experiment,'ephys_includingCompressed',site, recording));
%ephysMetaDir = dir([ephysap_path, '/../../../structure.oebin']);
ephysMetaDir = dir([ephysap_path.folder, '/*ap.meta']);
ephysDirPath = AP_cortexlab_filenameJF(animal,day,experiment,'ephys_dir',site, recording);
savePath = fullfile(ephysDirPath, 'qMetrics'); 
saveFileFolder = fullfile('/media/julie/Expansion', animal, day, ['site', num2str(site)]);

%% decompress data 
decompress = 0;%QQ
if decompress
    rawFile = bc_manageDataCompression(ephysap_path, saveFileFolder);
else
    rawFile = 'NaN';

end
%% run qmetrics 
param = bc_qualityParamValues(ephysMetaDir, rawFile); 
%param.computeDistanceMetrics = 1;

%% compute quality metrics 
ephysDirPath = AP_cortexlab_filenameJF(animal, day, experiment, 'ephys_dir',site, recording);
savePath = fullfile(ephysDirPath, 'qMetrics');
qMetricsExist = dir(fullfile(savePath, 'templates._bc_qMetrics.parquet'));

if (runQM && isempty(qMetricsExist)) || rerun
    [qMetric, unitType] = bc_runAllQualityMetrics(param, spikeTimes_samples, spikeTemplates, ...
        templateWaveforms, templateAmplitudes,pcFeatures,pcFeatureIdx,channelPositions, savePath);
elseif ~isempty(qMetricsExist)
    [param, qMetric, fractionRPVs_allTauR] = bc_loadSavedMetrics(savePath); 
    unitType = bc_getQualityUnitType(param, qMetric);
else
    uniqueTemplates = unique(spikeTemplates);
    unitType = nan(length(uniqueTemplates),1);
end

%% view units + quality metrics in GUI 
% load data for GUI
if plotGUI
    bc_loadMetricsForGUI;

    bc_unitQualityGUI(memMapData, ephysData, qMetric, forGUI, rawWaveforms, param,...
       probeLocation, unitType, 0);
end
end