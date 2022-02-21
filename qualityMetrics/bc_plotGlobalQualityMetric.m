% 1. multi-venn diagram of units classified as noise/mua by each quality metric
if param.plotGlobal
    figure();
    if param.computeDistanceMetrics && ~isnan(param.isoDmin)
        colorMtx = [rgb('Maroon'); rgb('Chocolate'); rgb('Orange'); rgb('OrangeRed'); ...
            rgb('DarkKhaki'); rgb('Green'); rgb('Teal'); rgb('RoyalBlue'); rgb('Indigo'); rgb('FireBrick'); rgb('HotPink')];
        colorMtx = [colorMtx, repmat(0.6, 11, 1)];

        setsw = {find(qMetric.nPeaks > param.maxNPeaks), find(qMetric.nTroughs > param.maxNTroughs), ...
            find(qMetric.somatic == 0), find(qMetric.Fp > param.maxRPVviolations), ...
            find(qMetric.percSpikesMissing > param.maxPercSpikesMissing), ...
            find(qMetric.nSpikes <= param.minNumSpikes), find(qMetric.rawAmplitude <= param.minAmplitude),...
            find(qMetric.spatialDecaySlope <=  param.minSpatialDecaySlope), ...
            find(qMetric.waveformDuration < param.minWvDuration | qMetric.waveformDuration > param.maxWvDuration), ...
            find(qMetric.waveformBaseline >= param.maxWvBaselineFraction), find(qMetric.isoD <= param.isoDmin)};
        emptyCell = find(cellfun(@isempty,setsw));
        if ~isempty(emptyCell)
            for iEC = 1:length(emptyCell)
            setsw{emptyCell(iEC)} = 0;
            end
        end
        title('# of units classified as noise/mua/non-somatic with quality metrics')
        subplot(1, 5, 1:4)
        vennEulerDiagram(setsw, {'# peaks', '#troughs', 'non-somatic', 'refractory period violations', ...
            'undetected spikes', '# spikes', 'waveform amplitude', 'spatial decay slope', 'waveform duration', ...
            '','isolation distance'}, ...
            'ColorOrder', colorMtx(:, 1:3), ...
            'ShowIntersectionCounts', 1);
        subplot(1, 5, 5) % hacky way to get a legend
        set(gca, 'XColor', 'w', 'YColor', 'w')
        hold on;
        arrayfun(@(x) plot(NaN, NaN, 'linewidth', 2, 'color', colorMtx(x, :)), 1:8);
        legend({'# peaks', '#troughs', 'non-somatic', 'refractory period violations', ...
            'undetected spikes', '# spikes', 'waveform amplitude', 'spatial decay slope', 'waveform duration',...
            'isolation distance'})
        set(gcf, 'color', 'w')

    else
        colorMtx = [rgb('Maroon'); rgb('Chocolate'); rgb('Orange'); rgb('OrangeRed'); ...
            rgb('DarkKhaki'); rgb('Green'); rgb('Teal'); rgb('RoyalBlue'); rgb('Indigo'); rgb('DarkRed')];
        colorMtx = [colorMtx, repmat(0.6, 10, 1)];

        setsw = {find(qMetric.nPeaks > param.maxNPeaks), find(qMetric.nTroughs > param.maxNTroughs), ...
            find(qMetric.somatic == 0), find(qMetric.Fp > param.maxRPVviolations), ...
            find(qMetric.percSpikesMissing > param.maxPercSpikesMissing), ...
            find(qMetric.nSpikes <= param.minNumSpikes), find(qMetric.rawAmplitude <= param.minAmplitude),...
            find(qMetric.spatialDecaySlope <=  param.minSpatialDecaySlope), ...
            find(qMetric.waveformDuration < param.minWvDuration | qMetric.waveformDuration > param.maxWvDuration),...
            find(qMetric.waveformBaseline >= param.maxWvBaselineFraction)};
        title('# of units classified as noise/mua/non-somatic with quality metrics')
        subplot(1, 5, 1:4)
        emptyCell = find(cellfun(@isempty,setsw));
        if ~isempty(emptyCell)
            for iEC = 1:length(emptyCell)
            setsw{emptyCell(iEC)} = 0;
            end
        end
        
        vennEulerDiagram(setsw, {'# peaks', '#troughs', 'non-somatic', 'refractory period violations', ...
            'undetected spikes', '# spikes', 'waveform amplitude', 'spatial decay slope', 'waveform duration', 'waveform baseline'}, ...
            'ColorOrder', colorMtx(:, 1:3), ...
            'ShowIntersectionCounts', 1);
        subplot(1, 5, 5) % hacky way to get a legend
        set(gca, 'XColor', 'w', 'YColor', 'w')
        hold on;
        arrayfun(@(x) plot(NaN, NaN, 'linewidth', 2, 'color', colorMtx(x, :)), 1:7);
        legend({'# peaks', '#troughs', 'non-somatic', 'refractory period violations', ...
            'undetected spikes', '# spikes', 'waveform amplitude', 'spatial decay slope', 'waveform duration'})
        set(gcf, 'color', 'w')
    end
    
    
    % 1. single/multi/noise/axonal waveforms 
    figure('Color', 'w');
    subplot(131)
    title('Single unit template waveforms');hold on;
    singleU = uniqueTemplates(find(unitType==1));
    set(gca, 'XColor', 'w', 'YColor', 'w')
    singleUnitLines = arrayfun(@(x) plot(squeeze(templateWaveforms(singleU(x),:,qMetric.maxChannels(singleU(x)))), 'linewidth', 1, 'Color', 'k'), 1:size(singleU,1));
    
    subplot(132)
    set(gca, 'XColor', 'w', 'YColor', 'w')
    multiU = uniqueTemplates(find(unitType==2));
    title('Multi unit template waveforms');hold on;
    multiUnitLines = arrayfun(@(x) plot(squeeze(templateWaveforms(multiU(x),:,qMetric.maxChannels(multiU(x)))), 'linewidth', 1, 'Color', 'k'), 1:size(multiU,1));
    
    subplot(133)
    set(gca, 'XColor', 'w', 'YColor', 'w')
    noiseU = uniqueTemplates(find(unitType==0));
    title('Noise unit template waveforms');hold on;
    noiseUnitLines = arrayfun(@(x) plot(squeeze(templateWaveforms(noiseU(x),:,qMetric.maxChannels(noiseU(x)))), 'linewidth', 1, 'Color', 'k'), 1:size(noiseU,1));

    % 2. histogram for each quality metric, red line indicates
    % classification threshold
    figure();
    suptitle([num2str(sum(unitType==1)) ' single units, ', num2str(sum(unitType==2)), ' multi-units, ', num2str(sum(unitType==0)), ' noise units'])
    set(gcf, 'color', 'w')

    subplot(3, 5,  1)
    
    hold on;
    histogram(qMetric.nPeaks, 'FaceColor', colorMtx(1, 1:3), 'FaceAlpha', colorMtx(1, 4));
    yLim = ylim;
    line([param.maxNPeaks + 0.5, param.maxNPeaks + 0.5], [0, yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel('# peaks')
    makepretty;

    subplot(3, 5,  2)
    
    hold on;
    histogram(qMetric.nTroughs, 'FaceColor', colorMtx(2, 1:3), 'FaceAlpha', colorMtx(2, 4));
    yLim = ylim;
    line([param.maxNTroughs + 0.5, param.maxNTroughs + 0.5], [0, yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel('# troughs')
    makepretty;

    subplot(3, 5,  3)
    
    hold on;
    histogram(1-qMetric.somatic, 'FaceColor', colorMtx(3, 1:3), 'FaceAlpha', colorMtx(3, 4));
    yLim = ylim;
    line([param.somatic - 0.5, param.somatic - 0.5], [0, yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel('non somatic')
    makepretty;

    subplot(3, 5,  4)
    
    hold on;
    histogram(qMetric.Fp, 'FaceColor', colorMtx(4, 1:3), 'FaceAlpha', colorMtx(4, 4), 'BinEdges', [0:5:max(qMetric.Fp)]);
    set(gca, 'yscale', 'log')
    yLim = ylim;
    line([param.maxRPVviolations + 0.5, param.maxRPVviolations + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel(['refractory period' newline 'violations (%)'])
    makepretty;

    subplot(3, 5,  5)
    
    hold on;
    histogram(qMetric.percSpikesMissing, 'FaceColor', colorMtx(5, 1:3), 'FaceAlpha', colorMtx(5, 4), 'BinEdges', [0:5:max(qMetric.percSpikesMissing)]);
    
    yLim = ylim;
    line([param.maxPercSpikesMissing + 0.5, param.maxPercSpikesMissing + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel(['spikes below' newline 'detection threshold (%)'])
    makepretty;

    subplot(3, 5,  6)
    
    hold on;
    set(gca, 'xscale', 'log')
    histogram(qMetric.nSpikes, 'FaceColor', colorMtx(6, 1:3), 'FaceAlpha', colorMtx(6, 4), 'BinEdges', [0:100:max(qMetric.nSpikes)]);
    
    yLim = ylim;
    line([param.minNumSpikes + 0.5, param.minNumSpikes + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel('# spikes')
    makepretty;

    subplot(3, 5,  7)
    
    hold on;
     set(gca, 'xscale', 'log')
    histogram(qMetric.rawAmplitude, 'FaceColor', colorMtx(7, 1:3), 'FaceAlpha', colorMtx(7, 4), 'BinEdges', [0:10:max(qMetric.rawAmplitude)]);
    yLim = ylim;
    line([param.minAmplitude + 0.5, param.minAmplitude + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel(['mean raw waveform' newline ' peak amplitude (uV)'])
    makepretty;
    
    subplot(3, 5,  8) 
    hold on;
    histogram(qMetric.spatialDecaySlope, 'FaceColor', colorMtx(8, 1:3), 'FaceAlpha', colorMtx(8, 4), 'BinEdges', [min(qMetric.spatialDecaySlope):10:max(qMetric.spatialDecaySlope)]);
    yLim = ylim;
    line([ param.minSpatialDecaySlope + 0.5,  param.minSpatialDecaySlope + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel('spatial decay slope')
    makepretty;
        
    subplot(3, 5,  9)
    hold on;
    histogram(qMetric.waveformDuration, 'FaceColor', colorMtx(9, 1:3), 'FaceAlpha', colorMtx(9, 4), 'BinEdges', [0:40:max(qMetric.waveformDuration)]);
    yLim = ylim;
    line([param.minWvDuration + 0.5, param.minWvDuration + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    line([param.maxWvDuration + 0.5, param.maxWvDuration + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel('waveform duration')
    makepretty;
    
    subplot(3, 5,  10)
    hold on;
    histogram(qMetric.waveformBaseline, 'FaceColor', colorMtx(10, 1:3), 'FaceAlpha', colorMtx(10, 4), 'BinEdges', [0:0.05:max(qMetric.waveformBaseline)]);
    yLim = ylim;
    line([param.maxWvBaselineFraction + 0.5, param.maxWvBaselineFraction + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
    ylabel('unit count')
    xlabel('waveform baseline ''flatness''')
    makepretty;
    
        
    if param.computeDistanceMetrics && ~isnan(param.isoDmin)
        subplot(3, 5,  11)
        
        hold on;
        histogram(qMetric.isoD, 'FaceColor', colorMtx(11, 1:3), 'FaceAlpha', colorMtx(11, 4), 'BinEdges', [0:10:max(qMetric.isoD)]);
        yLim = ylim;
        line([param.isoDmin + 0.5, param.isoDmin + 0.5], [yLim(1), yLim(2)], 'Color', 'r', 'LineWidth', 2)
        ylabel('unit count')
        xlabel('isolation distance')
        makepretty;
    end
    

end
