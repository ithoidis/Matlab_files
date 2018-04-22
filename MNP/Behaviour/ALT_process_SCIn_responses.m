clear all
dbstop if error % optional instruction to stop at a breakpoint if there is an error - useful for debugging

%% 1. ADD FUNCTIONS/TOOLBOXES TO MATLAB PATH
paths = {'C:\Data\Matlab\Matlab_files\MNP','C:\Data\Matlab\Matlab_files\_generic_eeglab_batch\eeglab_batch_supporting_functions'};
subpaths = [1 1]; % add subdirectories too?

for p = 1:length(paths)
    if subpaths(p)
        addpath(genpath(paths{p}));
    else
        addpath(paths{p});
    end
end

%% 2. FOLDER AND FILENAME DEFINITIONS

% FILE NAMING
% Name the input files as <study name>_<participant ID>_<sessions name_<block name>_<condition name>
% For example: EEGstudy_P1_S1_B1_C1.mat
% Any of the elements can be left out. But all must be separated by underscores.
clear S
S.version = 2; % version of the ALT design
S.rawpath = 'C:\Data\MNP\Pilots\ALTv2\raw'; % unprocessed data in original format
S.anapath = 'C:\Data\MNP\Pilots\ALTv2\processed'; % folder to save processed .set data
S.fnameparts = {'subject','block','',''}; % parts of the input filename separated by underscores, e.g.: {'study','subject','session','block','cond'};
S.subjects = {'cab'}; % either a single subject, or leave blank to process all subjects in folder
S.sessions = {};
%S.blocks = {'Sequence_ALT_OptionAdaptive'}; % blocks to load (each a separate file) - empty means all of them, or not defined
S.blocks = {'Sequence_ALT_OptionALT_assoc'}; % blocks to load (each a separate file) - empty means all of them, or not defined
S.conds = {}; % conditions to load (each a separate file) - empty means all of them, or not defined
S.datfile = 'C:\Data\MNP\Pilots\ALTv2\Participant_Data.xlsx'; % .xlsx file to group participants; contains columns named 'Subject', 'Group', and any covariates of interest
save(fullfile(S.anapath,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable

%% 3. DATA IMPORT, REFORMAT

% SETTINGS
S.loadext = 'mat'; 
S.loadprefixes = {'Output','Sequence'};
S.saveprefix = ''; % prefix to add to output file, if needed
S.savesuffix = ''; % suffix to add to output file, if needed
% RUN
[S,D]=SCIn_data_import(S);
save(fullfile(S.anapath,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable
save(fullfile(S.anapath,'D'),'D'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable

%% 4. PROCESSING
% SET PROCESSING OPTIONS
S.accuracy.on = 1;
%S.accuracy.buttons = {'LeftArrow','RightArrow'};%{'DownArrow','UpArrow'};
S.accuracy.signal = [1 2];
switch S.version
    case 1
        S.accuracy.target_resp = {[1 2],[1 2]}; % for each target (1st cell) which is the correct response (2nd cell)
        S.signal.target = 1; % which row of signal is the target being responded to?
        S.signal.cue = 0;
    case 2
        S.accuracy.target_resp = {[1 2 3 4],[1 2 1 2]}; % for each target (1st cell) which is the correct response (2nd cell)
        S.signal.target = 2; % which row of signal is the target being responded to?
        S.signal.cue = 1;
end
S.RT = 1;
S.trialmax = {1000};%{16,20,24,28,32}; % max number of trials to include per condition - to work out min num of trials needed
% RUN
[S,D]=SCIn_data_process(S,D);
save(fullfile(S.anapath,'S'),'S'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable
save(fullfile(S.anapath,'D'),'D'); % saves 'S' - will be overwritten each time the script is run, so is just a temporary variable

%% 5. PLOTS
close all
% PLOT sequence
figure;plot(D(1).Sequence.condnum)
if isfield(D(1).Sequence,'adapttype');
    hold on; plot(D(1).Sequence.adapttype,'r')
end

%5. PLOT %correct
for d = 1:length(D)
    for tm = 1:length(S.trialmax)
        Y=D(d).Processed.condcorrectfract{tm};
        X=1:length(Y);
        figure
        bar(X,Y)
        labels = arrayfun(@(value) num2str(value,'%2.0f'),cell2mat(D(d).Processed.numtrials{tm}),'UniformOutput',false);
        text(X,Y,labels,'HorizontalAlignment','center','VerticalAlignment','bottom') 
          % clears X axis data
          %set(gca,'XTick',[]);
        ylabel('fraction correct')
        xlabel('condition')
        switch S.version
            case 1
                %labels = {'adaptive: low','adaptive: high','low prob: low','low prob: high','equal prob: low','equal prob: high','high prob: low','high prob: high',};
                labels = {'low prob: low','low prob: high','equal prob: low','equal prob: high','high prob: low','high prob: high',}; % v1
            case 2
                labels = {'high prob: pair 1','low prob: pair 2','equal prob: pair 1','equal prob: pair 2','high prob: pair 2','low prob: pair 1',}; % v2
        end
        set(gca,'xticklabel', labels)
        title([D(d).subname ', trial number: ' num2str(S.trialmax{tm})])
        hold on
        plot(xlim,[0.5 0.5], 'k--')
    end
end

%5. PLOT %correct for some conditions only, across blocks
%close all
if S.version==1
    plotcond = [3 4];
    for d = 1:length(D)
        for tm = 1:length(S.trialmax)
            figure
            dat=cell2mat(D(d).Processed.blockcondcorrectfract{tm}(plotcond)')';
            b = bar([dat])
            ylabel('fraction correct')
            xlabel('block')
            legend(b,{'low','high'});
            title(D(d).subname)
            hold on
            plot(xlim,[0.5 0.5], 'k--')
        end
    end
end

% PLOT by stimulus
if isfield(D.Processed,'stimcondcorrectfract')
    for d = 1:length(D)
        for tm = 1:length(S.trialmax)

            % for each condition, breaking down by stimulus type
            Y=cell2mat(D.Processed.stimcondcorrectfract{:}');
            figure
            b=bar(Y)
            ylabel('fraction correct')
            xlabel('condition')
            switch S.version
                case 1
                    %labels = {'adaptive: low','adaptive: high','low prob: low','low prob: high','equal prob: low','equal prob: high','high prob: low','high prob: high',};
                    labels = {'low prob: low','low prob: high','equal prob: low','equal prob: high','high prob: low','high prob: high',}; % v1
                case 2
                    labels = {'high prob: pair 1','low prob: pair 2','equal prob: pair 1','equal prob: pair 2','high prob: pair 2','low prob: pair 1',}; % v2
            end
            set(gca,'xticklabel', labels)
            title([D(d).subname ', trial number: ' num2str(S.trialmax{tm})])
            legend(b,{'low','high','low x2','high x2'});
            hold on
            plot(xlim,[0.5 0.5], 'k--')

            % plot stims averaged across all conditions
            Y = mean(Y,1);
            figure
            b=bar(Y)
            ylabel('fraction correct')
            xlabel('stimulus type')
            switch S.version
                case 2
                    labels = {'low','high','low x2','high x2'}; % v2
            end
            set(gca,'xticklabel', labels)
            title([D(d).subname ', trial number: ' num2str(S.trialmax{tm})])
            hold on
            plot(xlim,[0.5 0.5], 'k--')
        end
    end
end

% PLOT by cue/stimulus
if isfield(D.Processed,'stimcuecorrectfract')
    for d = 1:length(D)
        for tm = 1:length(S.trialmax)

            % for each cue, breaking down by stimulus type
            Y=cell2mat(D.Processed.stimcuecorrectfract{:}');
            figure
            b=bar(Y)
            ylabel('fraction correct')
            xlabel('cue type')
            switch S.version
                case 2
                    labels = {'high pitch','low pitch',}; % v2
            end
            set(gca,'xticklabel', labels)
            title([D(d).subname ', trial number: ' num2str(S.trialmax{tm})])
            legend(b,{'low','high','low x2','high x2'});
            hold on
            plot(xlim,[0.5 0.5], 'k--')

        end
    end
end

% PLOT adaptive thresholds
if isfield(D(1).Sequence,'adapttype');
    n_rev = 6;
    av_type = 1;
    av_para = [50 75 100]; col = {'r','m','y'};
    for d = 1:length(D)
        for atype = 1:2
            ind = find(D(d).Output.adaptive(:,10)==atype & ~isnan(D(d).Output.adaptive(:,7)));
            if ~isempty(ind)
                thresh = D(d).Output.adaptive(ind,7);
                rev = D(d).Output.adaptive(ind,3);
                block = D(d).Output.adaptive(ind,7);

                % re-calc thresholds
                %if n_rev
                %    thresh = nan(length(thresh),1);
                %    for i = n_rev:length(thresh)
                %        thresh(i)=mean(rev(i-(n_rev-1):i,1));
                %    end
                %end

                av_thresh = nan(length(av_para),length(thresh));
                switch av_type
                    case 1
                        % moving average
                        for av = 1:length(av_para)
                            for i = av_para(av):length(thresh)
                                av_thresh(av,i) = mean(thresh((i-av_para(av)+1):i,1));
                            end
                        end
                    case 2
                        % polynomial
                        for av = 1:length(av_para)
                            p = polyfit(1:length(thresh),thresh',av_para(av));
                            av_thresh(av,:)=1:length(thresh); 
                            av_thresh(av,:)=av_thresh(av,:)*p(1)+p(2);
                            av_thresh(av,:)=av_thresh(av,:)';
                        end
                    case 3
                        % smooth
                        for av = 1:length(av_para)
                            for i = 1:length(thresh)
                                sm_thresh = smooth(thresh(1:i,1),min(i,av_para(av)),'lowess');
                                av_thresh(av,i) = sm_thresh(end);
                            end
                        end
                    case 4
                        % weighted moving average 
                        for av = 1:length(av_para)
                            for i = av_para(av):length(thresh)
                                %alpha = 0.06;
                                %sm_thresh = filter(alpha, [1 alpha-1], thresh((i-av_para+1):i,1));
                                W = 1:av_para(av); % relative weights
                                sm_thresh = conv(thresh((i-av_para(av)+1):i,1)', W./sum(W), 'full'); % linear weighting
                                av_thresh(av,i) = sm_thresh(av_para(av));
                            end
                        end
                end

                % identify stabilty
                stab_type = 3;
                maxpercentchange = 0.5;
                npairs = 20;


                stable_thresh = nan(av,length(thresh));
                if ismember(stab_type,[1 2]);
                    for av = 1:length(av_para)
                        mavg = av_thresh(av,:);
                        mavg_ind = find(~isnan(mavg));
                        range = max(thresh)-min(thresh);
                        for m = npairs+1:length(mavg_ind)
                            switch stab_type
                                case 1
                                    % linear fit
                                    p = polyfit(1:npairs,mavg(mavg_ind(m-npairs+1):mavg_ind(m)),1);
                                    slope=abs(p(1)); 
                                    if (slope/range)*100<maxpercentchange
                                        stable_thresh(av,mavg_ind(m)) = mavg(mavg_ind(m));
                                    end

                                case 2
                                    % 
                                    diffval = [];
                                    for i = 1:npairs
                                        diffval(i) = abs(diff([mavg(mavg_ind(m-(i-1)-1)),mavg(mavg_ind(m-(i-1)))]));
                                    end
                                    if all((diffval/range)*100<maxpercentchange)
                                        stable_thresh(av,mavg_ind(m)) = mavg(mavg_ind(m));
                                    end

                            end
                        end
                    end
                elseif ismember(stab_type,3);
                    % get max mavg length and it's index
                    [maxlen,maxi] = max(av_para);
                    % indices of max mavg
                    maxmavg = av_thresh(maxi,:);
                    mavg_ind = find(~isnan(maxmavg));
                    for m = 1:length(mavg_ind)
                        trend = [];
                        for av = 1:length(av_para)-1
                            trend(av) = (av_thresh(av,mavg_ind(m))-av_thresh(av+1,mavg_ind(m)));
                        end
                        if ~all(trend>0) && ~all(trend<0)
                            stable_thresh(1,mavg_ind(m)) = mean(av_thresh(:,mavg_ind(m)));
                        end
                    end
                end
            end

            figure
            scatter(1:length(thresh),thresh,'b');
            hold on
            for av = 1:length(av_para)
                scatter(1:length(thresh),av_thresh(av,:),col{av});
            end
            %for av = 1:length(av_para)
            %    scatter(1:length(thresh),stable_thresh(av,:),'k','filled');
            %end
            scatter(1:length(thresh),D(d).Output.adaptive(ind,11),'k','filled');
            hold off
        end
    end
end

% plot RT distribution
for d = 1:length(D)
    figure
    hist(D(d).Output.RT);
    title(D(d).subname)
end