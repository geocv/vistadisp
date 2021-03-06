function data = ewWeibulls(subjNum,sessNums)

% Function to go through the dataSum after certain number of sessions
% (each of which contain numStaircases number of staircases) and plot a
% Weibull for each staircase.
%
% subjNum = vector of subject numbers you'd like processed
%
% sessNums = cell array of session numbers you'd like presented, cells are
% indexed by subject number, with each non-empty cell containing a vector
% of sessions one would like processed
%

close all % clean up the figures before plotting these
dataDir = '/Users/rfbowen/PsychophysData/equiWords/';
load(fullfile(dataDir,'ewSubjSess.mat'));

% Foolproof subjNum
if(exist('subjNum','var'))
    if(isempty('subjNum'))
       subjNum = 1:length(SubjList); % process all subjects when none are indicated (empty input)
    end
else
    subjNum = 1:length(SubjList); % process all subjects when none are indicated (no input at all)
end

% Foolproof sessNums
if(exist('sessNums','var'))
    if(isempty('sessNums'))
        for i=subjNum
            sessNums{i} = 1:SessList(i); % process all sessions when none are specified
        end
    else
        for i=subjNum
            if(isempty(sessNums{i}))
                sessNums{i} = 1:SessList(i); % process all sessions for empty cases when only some are specified
            end
        end
    end
else
    for i=subjNum
        sessNums{i} = 1:SessList(i); % process all sessions when none are specified
    end
end

for i=subjNum
    data{i} = [];
    for ii=sessNums{i}
        dataFile = sprintf('S%02ds%02d.mat',i,ii);
        load(fullfile(dataDir,dataFile));
        if ~isfield(dataSum(1).stairParams,'laps')
            dataSum(1).stairParams.laps = 1;
        end
        if(isempty(data{i}))
            for stairNum=1:dataSum(1).stairParams.nStairs % Initialization of all relevant fields
                data{i}(stairNum).history        = dataSum(stairNum).history;
                data{i}(stairNum).stimLevels     = dataSum(stairNum).stimLevels;
                data{i}(stairNum).width          = dataSum(stairNum).width(1);
                data{i}(stairNum).angle          = dataSum(stairNum).angle(1);
                data{i}(stairNum).distance       = dataSum(stairNum).distance(1);
                data{i}(stairNum).numCorrect     = zeros(size(data{i}(stairNum).stimLevels));
                data{i}(stairNum).numTrials      = zeros(size(data{i}(stairNum).stimLevels));
            end
        end
        for lap = 1:dataSum(1).stairParams.laps
            for stairNum = 1:dataSum(1).stairParams.nStairs
                data{i}(stairNum).numCorrect         = data{i}(stairNum).numCorrect + dataSum((dataSum(1).stairParams.nStairs*(lap-1))+stairNum).numCorrect;
                data{i}(stairNum).numTrials          = data{i}(stairNum).numTrials + dataSum((dataSum(1).stairParams.nStairs*(lap-1))+stairNum).numTrials;
            end
        end
    end
    for stairNum=1:dataSum(1).stairParams.nStairs
        data{i}(stairNum).analysis = analyzeStaircase(data{i}(stairNum),'threshErr',50);
        figure(i);
        subplot(dataSum(1).stairParams.measuredSizes,dataSum(1).stairParams.measuredEcc,stairNum); % sizes x eccentricities subplot
        hold on; semilogx(data{i}(stairNum).analysis.x,data{i}(stairNum).analysis.y,'x');
        hold on; plot(data{i}(stairNum).analysis.wx,data{i}(stairNum).analysis.wy); hold on;
        x = 10^-2:0.01:1; 
        y = 0.82; 
        plot(x,y); 
        hold off; % plot line for 82%
        set(gca,'xscale', 'log');
        axis([10^-1 1 .5 1]);  % give them all the same scale
        title(sprintf('%1.2f | %d | %1.1f',data{i}(stairNum).width,data{i}(stairNum).angle,data{i}(stairNum).distance),'FontSize',12);
    end
    % Sort of hacked this in, probably more elegant ways to do it that are
    % also more abstract and thus flexible, but for now it will do
    figure(100+i);
    for iEcc=1:5
        xs = [];
        ys = [];
        xErrs = [];
        yErrs = [];
        for iStair=iEcc:5:20
            y = data{i}(iStair).analysis.thresh;
            x = log10(data{i}(iStair).width);
            xs = [xs x];
            ys = [ys y];
        end
        hold on;
        if data{i}(iEcc).angle==90
            semilogx(xs,ys,'-*b'); % blue sky = above fixation
            for iStair=iEcc:5:20
                yP = data{i}(iStair).analysis.thresh + data{i}(iStair).analysis.threshErr;
                yN = data{i}(iStair).analysis.thresh - data{i}(iStair).analysis.threshErr;
                x = log10(data{i}(iStair).width);
                plot([x x],[yN yP],'-+b');
            end
        elseif data{i}(iEcc).angle==270
            semilogx(xs,ys,'-*g'); % green grass = below fixation
            for iStair=iEcc:5:20
                yP = data{i}(iStair).analysis.thresh + data{i}(iStair).analysis.threshErr;
                yN = data{i}(iStair).analysis.thresh - data{i}(iStair).analysis.threshErr;
                x = log10(data{i}(iStair).width);
                plot([x x],[yN yP],'-+g');
            end
        end
    end
    hold off;
end