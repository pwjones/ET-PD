function data = ImportCodingResults(dataFN, codingFN, IPAcodes, saveBool)
%function ImportCodingResults
%
% Run from the Preprocessed Data folder
% dataFN is the filename of the electrophysiology containing mat file
% codingFN is the speech coding app output file
% IPAcodes is the array target words with each row {TARGET_PHONETIC, TARGET_ROMAN}. 

codingFN = ['AudioCodingFiles' filesep codingFN];
data = open(dataFN);
c = open(codingFN); 

codingM = c.CodingMatrix'; 
for ii=1:120 %Need to convert empty cells to NaNs to get into non-cell arrays 
    if isempty(codingM{ii,5}); codingM{ii,5} = NaN; end
    if isempty(codingM{ii,6}); codingM{ii,6} = NaN; end
    if isempty(codingM{ii,9}); codingM{ii,9} = NaN; end
    if isempty(codingM{ii,10}); codingM{ii,10} = NaN; end
end
spOnset = cell2mat(codingM(:,5));
spOffset = cell2mat(codingM(:,6));
vowelOnset = cell2mat(codingM(:,9));
vowelOffset = cell2mat(codingM(:,10));
nTrials = find(~isnan(spOnset),1,'last');

eventRange = c.SkipEvents + (1:(nTrials*4));
Events = c.EventTimes(eventRange);
Events = reshape(Events,nTrials,[]);
if nTrials < 120 % need to fill in the events to 
    fill = NaN*zeros(120-nTrials,4);
    Events = cat(1, Events, fill);
end

% Start a trials strucure for the datafile
trials.Cue1Stim = Events(:,1); 
trials.Cue2Stim = Events(:,2);
trials.CommandStim = Events(:,3);
trials.ITIStim = Events(:,4);
trials.SpOnset = trials.CommandStim + spOnset;
trials.SpOffset = trials.CommandStim + spOffset;
trials.VowelOnset = trials.CommandStim + vowelOnset;
trials.VowelOffset = trials.CommandStim + vowelOffset;
trials.BaseBack = trials.CommandStim;
trials.BaseFwd = [c.EventTimes(c.SkipEvents); trials.ITIStim(1:119)]; 
trials.nTrials = nTrials;

% The coding cell array gets put into a structure 
cs.PhoneticCode = codingM(:,1);
cs.TargetCode = IPAcodes(:,2);
cs.TargetRoman = IPAcodes(:,1);
cs.C1error = codingM(:,2);
cs.Verror = codingM(:,3);
cs.C2error = codingM(:,4);
cs.TargetRevealed = codingM(:,7);
cs.Notes = codingM(:,8);
trials.coding = cs;

% do some trial rejection based on background noise
Audio=data.Audio(:,1);
Asr=data.Asr; %sampling rate
data.Afs = Asr; %redundant for consistency
audioM=mean(Audio); 
audioS=std(Audio);

trials.BaseRejectNoise=find(cell2mat(arrayfun(@(x,y) any(Audio(round(x*data.Asr):round(y*data.Asr))>(audioM+ 5*audioS)),trials.BaseFwd(1:nTrials),trials.BaseBack(1:nTrials),'UniformOutput',0)));
trials.BaseRejectSpk=find( (trials.ITIStim-trials.SpOffset)<0 | isnan(trials.SpOffset) );

data.trials = trials;

if saveBool
    save(dataFN, '-struct', 'data');
end

