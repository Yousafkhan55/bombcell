function [fractionRPVs, nRPVs, overestimateBool] = bc_fractionRPviolations(theseSpikeTimes, theseAmplitudes, ...
    tauR, tauC, timeChunks, plotThis, RPV_tauR_estimate)
% JF, get the estimated fraction of refractory period violation for a unit
% for each timeChunk
% ------
% Inputs
% ------
% theseSpikeTimes: nSpikesforThisUnit × 1 double vector of time in seconds
%   of each of the unit's spikes.
% theseAmplitudes: nSpikesforThisUnit × 1 double vector of the amplitude scaling factor 
%   that was applied to the template when extracting that spike
%   , only needed if plotThis is set to true
% tauR: refractory period
% tauC: censored period
% timeChunk: experiment duration time chunks
% plotThis: boolean, whether to plot ISIs or not
% ------
% Outputs
% ------
% fractionRPVs: fraction of contamination
% nRPVs: number refractory period violations
% overestimateBool: boolean, true if the number of refractory period violations 
%    is too high. we then overestimate the fraction of
%    contamination. 
% ------
% Reference 
% ------
% Hill, Daniel N., Samar B. Mehta, and David Kleinfeld. 
% "Quality metrics to accompany spike sorting of extracellular signals."
% Journal of Neuroscience 31.24 (2011): 8699-8705:
% r = 2*(tauR - tauC) * N^2 * (1-Fp) * Fp / T , solve for Fp , fraction
% refractory period violatons. 2 factor because rogue spikes can occur before or
% after true spike

% initialize variables
fractionRPVs = nan(length(timeChunks)-1, length(tauR)); 
overestimateBool = nan(length(timeChunks)-1, length(tauR)); 
nRPVs  = nan(length(timeChunks)-1, length(tauR));

if plotThis
    figure('Color','none');
    subplot(2,numel(timeChunks)-1, 1:numel(timeChunks)-1)
    scatter(theseSpikeTimes, theseAmplitudes, 4,[0, 0.35, 0.71],'filled'); hold on;
    % chunk lines 
    ylims = ylim;
    for iTimeChunk = 1:length(timeChunks)
        line([timeChunks(iTimeChunk),timeChunks(iTimeChunk)],...
            [ylims(1),ylims(2)], 'Color', [0.7, 0.7, 0.7])
    end
    xlabel('time (s)')
    ylabel(['amplitude scaling' newline 'factor'])
    makepretty('none')
end

for iTimeChunk = 1:length(timeChunks) - 1 %loop through each time chunk
    % number of spikes in chunk 
    N_chunk = length(theseSpikeTimes(theseSpikeTimes >= timeChunks(iTimeChunk) & theseSpikeTimes < timeChunks(iTimeChunk+1)));
    % total times at which refractory period violations can occur
    for iTauR_value = 1:length(tauR)
    a = 2 * (tauR(iTauR_value) - tauC) * N_chunk^2 / abs(diff(timeChunks(iTimeChunk:iTimeChunk+1)));
    % observed number of refractory period violations
    nRPVs = sum(diff(theseSpikeTimes(theseSpikeTimes >= timeChunks(iTimeChunk) & theseSpikeTimes < timeChunks(iTimeChunk+1))) <= tauR(iTauR_value));

    if nRPVs == 0 % no observed refractory period violations - this can 
        % also be because there are no spikes in this interval - use presence ratio to weed this out
        fractionRPVs(iTimeChunk,iTauR_value) = 0;
        overestimateBool(iTimeChunk,iTauR_value) = 0;
    else % otherwise solve the equation above 
        rts = roots([-1, 1, -nRPVs / a]);
        fractionRPVs(iTimeChunk,iTauR_value) = min(rts);
        overestimateBool(iTimeChunk,iTauR_value) = 0;
        if ~isreal(fractionRPVs(iTimeChunk,iTauR_value)) % function returns imaginary number if r is too high: overestimate number.
            overestimateBool(iTimeChunk,iTauR_value) = 1;
            if nRPVs < N_chunk %to not get a negative wierd number or a 0 denominator
                fractionRPVs(iTimeChunk,iTauR_value) = nRPVs / (2 * (tauR(iTauR_value) - tauC) * (N_chunk - nRPVs));
            else
                fractionRPVs(iTimeChunk,iTauR_value) = 1;
            end
        end
        if fractionRPVs(iTimeChunk,iTauR_value) > 1 %it is nonsense to have a rate >1, the assumptions are failing here
            fractionRPVs(iTimeChunk,iTauR_value) = 1;
        end
    end
    end
    
    
    if plotThis
        
        subplot(2, length(timeChunks) - 1, (length(timeChunks) - 1)+iTimeChunk)
        theseISI = diff(theseSpikeTimes(theseSpikeTimes >= timeChunks(iTimeChunk) & theseSpikeTimes < timeChunks(iTimeChunk+1)));
        theseisiclean = theseISI(theseISI >= tauC); % removed duplicate spikes
        [isiProba, edgesISI] = histcounts(theseisiclean*1000, [0:0.5:50]);
        bar(edgesISI(1:end-1)+mean(diff(edgesISI)), isiProba, 'FaceColor', [0, 0.35, 0.71], ...
             'EdgeColor', [0, 0.35, 0.71]); %Check FR
        if iTimeChunk ==1
            xlabel('Interspike interval (ms)')
            ylabel('# of spikes')
        else
            xticks([])
            yticks([])
        end
        ylims = ylim;
        [fr, ~] = histcounts(theseisiclean*1000, [0:0.5:5000]);
        line([0, 10], [nanmean(fr(800:1000)), nanmean(fr(800:1000))], 'Color',[0.86, 0.2, 0.13], 'LineStyle', '--');
        dummyh = line(nan, nan, 'Linestyle', 'none', 'Marker', 'none', 'Color', 'none');
        if isnan(RPV_tauR_estimate)
            for iTauR_value = [1,length(tauR)]
                line([tauR(iTauR_value)*1000, tauR(iTauR_value)*1000], [ylims(1), ylims(2)], 'Color', [0.86, 0.2, 0.13]);
                
            end
             legend([dummyh, dummyh], {[num2str(round(fractionRPVs(iTimeChunk,1)*100,1)), '% rpv'],...
            [num2str(round(fractionRPVs(iTimeChunk,length(tauR))*100,1)), '% rpv']},'Location', 'NorthEast','TextColor', [0.7, 0.7, 0.7], 'Color', 'none');
      
        else
            line([tauR(RPV_tauR_estimate)*1000, tauR(RPV_tauR_estimate)*1000], [ylims(1), ylims(2)], 'Color', [0.86, 0.2, 0.13]);
             legend([dummyh], {[num2str(fractionRPVs(RPV_tauR_estimate)*100,1), '% rpv']},'Location', 'NorthEast','TextColor', [0.7, 0.7, 0.7], 'Color', 'none');
       
        end
        %axis square;

        makepretty('none')
    end
    
end

end