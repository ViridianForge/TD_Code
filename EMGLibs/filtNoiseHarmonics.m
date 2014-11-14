function [ filteredData ] = ...
    filtNoiseHarmonics( noisyData, sampRate, freq, harmonics, titles )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%HARMONICFILTER Filter the given data at the given frequency for the given
%number of harmonics.
%   This function creates a series of 4th order Butterworth stop band
%   filters based on the given frequency for a number of harmonics passed
%   as an argument.  The passed data is then filtered at each setting in
%   turn, and finally returned in its final filtered form.
%
%   Author -- Wayne Manselle - March 2013
%
%   INPUTS -- noisyData - the data requiring filtering
%             sampRate - the rate the data was sampled at.
%             freq - the frequency to filter at
%             harmonics - the number of harmonics of the frequency to
%             filter.  1 indicates to only filter at the given frequency.
%             titles - titles used in processing review graphs
%
%   OUTPUT -- filteredData - noisyData after passing through all filters
%
%   TODOS --
%       1 - Enable passing a range of frequencies rather than a single
%       frequency for the stopband filter.
%       2 - Enable an optional argument for the order of the filter.
%       3 - Enable an optional argument to set whether you want to filter
%       rows or columns
%       4 - Enable an optional argument to set how wide the notch filter
%       should be by default.  Default is 1 Hz away.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Variable storage for ultimate output and each stage of the filtration.
filteredData = zeros(size(noisyData));

%Nyquist Frequency, important for filtering.
nyquist = sampRate/2;

for datCol=1:size(noisyData,2)
    %Seed the filtered data place holder.
    filtCol = noisyData(:,datCol);
    
    %Throw in a 60Hz notch filter for electrical noise
    [b,a] = butter(4,[59 61]/nyquist,'stop');
    filtCol = filtfilt(b,a,filtCol);
    
    for filtStage=1:harmonics
        %Edges of our notch filter.
        lNotch = (freq*filtStage)-1;
        rNotch = (freq*filtStage)+1;
        [b,a] = butter(4,[lNotch rNotch]/nyquist,'stop');
        filtCol = filtfilt(b,a,filtCol);
    end
    %Place the final filtered column of data in the output matrix.
    filteredData(:,datCol) = filtCol;
end

%Give the user an opportunity to visually inspect the compared data.
review = questdlg('Would you like to review the data with magnetic tracking harmonics removed?','Review Notch Filter?','Yes','No','Yes');

if(strcmp(review,'Yes'))
    %Hackery to preallocate the proper window size
    nfft = max(256,2^nextpow2(size(noisyData,1)/8));
    %Removing the /2 here to account for the 50% window overlap
    windowSize = ift(mod(nfft,2)==0,(nfft+1),(nfft+1));
    pxxNoFilt=zeros(windowSize,size(noisyData,2)-2);
    pxxFilt=zeros(windowSize,size(noisyData,2)-2);
    freqVec = 0;
    for chans=1:size(noisyData,2)-2
        [pxxNoFilt(:,chans), freqVec] = pwelch(noisyData(:,chans),[],[],[],2*nyquist,'onesided');
        pxxNoFilt(:,chans) = 10*log10(pxxNoFilt(:,chans));
        pxxFilt(:,chans) = 10*log10(pwelch(filteredData(:,chans),[],[],[],2*nyquist,'onesided'));
    end
    %Compare the power spectrums of the unfiltered to the filtered data
    visualComparison(pxxNoFilt,pxxFilt,...
        'Pre-Filtered EMG','Filtered EMG 84Hz and Harmonics',titles(1:end-2),...
        freqVec,'Frequency (Hz)','Power (dB/Hz)')
end

end