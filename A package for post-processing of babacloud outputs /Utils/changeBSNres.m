%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [output] = changeBSNres(Collection, windowlength, selectedChannel)

% Extract data from Collection
Artefactspadded_raw = Collection.artifacts;
Artefactspadded_raw(Artefactspadded_raw == 3) = 0;
Artefactspadded_raw(Artefactspadded_raw == 5) = 0;
Seizurespadded_raw = Collection.seizures > 0.3131;
NBSpadded = Collection.BSNs;
UNBSpadded = Collection.UBSNs;
LNBSpadded = Collection.LBSNs;
sst_raw = Collection.SSTs;
usst_raw = Collection.USSTs;
lsst_raw = Collection.LSSTs;
NBSpadded_CHs_raw = Collection.BSNs_CH;
UNBSpadded_CHs_raw = Collection.UBSNs_CH;
LNBSpadded_CHs_raw = Collection.LBSNs_CH;

% Check if selectedChannel is 'all' or a specific channel number
if strcmpi(selectedChannel, 'all')
    % Use all channels from the Collection
elseif isnumeric(selectedChannel)
    % Check if the selected channels are within the valid range
    if all(selectedChannel >= 1 & selectedChannel <= size(Collection.BSNs_CH, 1))
        NBSpadded_CHs_raw = Collection.BSNs_CH(selectedChannel, :);
        UNBSpadded_CHs_raw = Collection.UBSNs_CH(selectedChannel, :);
        LNBSpadded_CHs_raw = Collection.LBSNs_CH(selectedChannel, :);
        Artefactspadded_raw = Collection.artifacts(selectedChannel, :);
    else
        warning('Selected channel is out of range. Continuing with all the channels.');
    end
else
    warning('Invalid selected channels. Continuing with all the channels.');
end

% Initialize masks
AR_mask = ones(size(Artefactspadded_raw));
SZ_mask = ones(size(Seizurespadded_raw));

% Apply masks based on artifact types
AR_mask(isnan(Artefactspadded_raw))=NaN;
AR_types = [1, 2, 4, 6, 7];
for type = AR_types
    AR_mask(Artefactspadded_raw == type) = NaN;
end
% AR_mask(Artefactspadded_raw==1)=NaN; %device interference (DI)
% AR_mask(Artefactspadded_raw==2)=NaN; %EMG
% AR_mask(Artefactspadded_raw==3)=NaN; %Movement
% AR_mask(Artefactspadded_raw==4)=NaN; %electrode
% AR_mask(Artefactspadded_raw==6)=NaN; %high-amp & zeros
% AR_mask(Artefactspadded_raw==5)=NaN; %biorythm
% AR_mask(Artefactspadded_raw==7)=NaN; %artefactual epoch

% Apply masks for seizures
SZ_mask(isnan(Seizurespadded_raw))=NaN;
SZ_mask(Seizurespadded_raw == 1)=NaN;

% Apply masks to channel data
NBSpadded_CH = (NBSpadded_CHs_raw.*AR_mask.*SZ_mask);
UNBSpadded_CH = (UNBSpadded_CHs_raw.*AR_mask.*SZ_mask);
LNBSpadded_CH = (LNBSpadded_CHs_raw.*AR_mask.*SZ_mask);

nbs_CH = [];unbs_CH = [];lnbs_CH = [];nbs = [];unbs = [];lnbs = [];
art = [];sei = [];sst = [];usst = [];lsst = [];

W = 1;
t0 = 1;
t1 = W*windowlength;

while t0 <= length(NBSpadded) || t1 <= length(NBSpadded)
    if t0 <= length(NBSpadded) && t1 > length(NBSpadded)
        if length(NBSpadded)-t0 >= (t1-t0)/2

            for ijch = 1:size(Artefactspadded_raw,1)
                RsAll(ijch) = majVote(Artefactspadded_raw(ijch,t0:end));
            end
            out = majVote(RsAll);
            ARs = sum(Artefactspadded_raw(:,t0:end));
            RsCheck = sum(ARs~=0)>=0.5*(length(NBSpadded)-t0+1);
            sei = [sei sum(Seizurespadded_raw(1,t0:end))/(30)];
            out_sei = majVote(Seizurespadded_raw(1,t0:end));

            if ~isnan(out) && ~isnan(out_sei)
                nbsall = NBSpadded(t0:end);
                unbsall = UNBSpadded(t0:end);
                lnbsall = LNBSpadded(t0:end);
                sstall = sst_raw(t0:end);
                usstall = usst_raw(t0:end);
                lsstall = lsst_raw(t0:end);

                if (RsCheck == 0) && (out_sei == 0)
                    nbs = [nbs nanmean(nbsall)];
                    unbs = [unbs nanmean(unbsall)];
                    lnbs = [lnbs nanmean(lnbsall)];
                    nbs_CH = [nbs_CH nanmean(NBSpadded_CH(:,t0:end),'all')];
                    unbs_CH = [unbs_CH nanmean(UNBSpadded_CH(:,t0:end),'all')];
                    lnbs_CH = [lnbs_CH nanmean(LNBSpadded_CH(:,t0:end),'all')];
                    sst = [sst nanmean(sstall)];
                    usst = [usst nanmean(usstall)];
                    lsst = [lsst nanmean(lsstall)];
                else
                    nbs = [nbs NaN];
                    unbs = [unbs NaN];
                    lnbs = [lnbs NaN];
                    sst = [sst NaN];
                    usst = [usst NaN];
                    lsst = [lsst NaN];
                    nbs_CH = [nbs_CH NaN];
                    unbs_CH = [unbs_CH NaN];
                    lnbs_CH = [lnbs_CH NaN];
                end

                if out >= RsCheck
                    art = [art out];
                else
                    art = [art 7];
                end
            else
                nbs_CH = [nbs_CH NaN];
                unbs_CH = [unbs_CH NaN];
                lnbs_CH = [lnbs_CH NaN];
                nbs = [nbs NaN];
                unbs = [unbs NaN];
                lnbs = [lnbs NaN];
                art = [art out];
                sst = [sst NaN];
                usst = [usst NaN];
                lsst = [lsst NaN];
            end
        end
    else

        for ijch = 1:size(Artefactspadded_raw,1)
            RsAll(ijch) = majVote(Artefactspadded_raw(ijch,t0:t1));
        end
        out = majVote(RsAll);
        ARs = sum(Artefactspadded_raw(:,t0:t1));
        RsCheck = sum(ARs~=0)>=0.5*(t1-t0+1); 
        sei = [sei sum(Seizurespadded_raw(1,t0:t1))/(30)];
        out_sei = majVote(Seizurespadded_raw(1,t0:t1));

        if ~isnan(out) && ~isnan(out_sei)
            nbsall = NBSpadded(t0:t1);
            unbsall = UNBSpadded(t0:t1);
            lnbsall = LNBSpadded(t0:t1);
            sstall = sst_raw(t0:t1);
            usstall = usst_raw(t0:t1);
            lsstall = lsst_raw(t0:t1);

            if (RsCheck == 0) && (out_sei == 0)
                nbs = [nbs nanmean(nbsall)];
                unbs = [unbs nanmean(unbsall)];
                lnbs = [lnbs nanmean(lnbsall)];
                nbs_CH = [nbs_CH nanmean(NBSpadded_CH(:,t0:t1),'all')];
                unbs_CH = [unbs_CH nanmean(UNBSpadded_CH(:,t0:t1),'all')];
                lnbs_CH = [lnbs_CH nanmean(LNBSpadded_CH(:,t0:t1),'all')];
                sst = [sst nanmean(sstall)];
                usst = [usst nanmean(usstall)];
                lsst = [lsst nanmean(lsstall)];
            else
                nbs = [nbs NaN];
                unbs = [unbs NaN];
                lnbs = [lnbs NaN];
                nbs_CH = [nbs_CH NaN];
                unbs_CH = [unbs_CH NaN];
                lnbs_CH = [lnbs_CH NaN];
                sst = [sst NaN];
                usst = [usst NaN];
                lsst = [lsst NaN];
            end

            if out >= RsCheck
                art = [art out];
            else
                art = [art 7];
            end
        else
            nbs_CH = [nbs_CH NaN];
            unbs_CH = [unbs_CH NaN];
            lnbs_CH = [lnbs_CH NaN];
            nbs = [nbs NaN];
            unbs = [unbs NaN];
            lnbs = [lnbs NaN];
            art = [art out];
            sst = [sst NaN];
            usst = [usst NaN];
            lsst = [lsst NaN];
        end
    end
    t0 = t1 + 1;
    t1 = t0 + W*windowlength - 1;
end

output.BSN = nbs_CH;
output.UBSN = unbs_CH;
output.LBSN = lnbs_CH;

end