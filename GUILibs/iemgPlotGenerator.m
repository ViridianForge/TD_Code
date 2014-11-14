function [ iemgPlotData ] = iemgPlotGenerator( normChanData, binSize )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%IEMGPLOTGENERATOR.M -- Returns bin data plottable against full data
%This function returns a version of the iEMG binned data that has been
%extended in order to be easily plottable against raw signal from the
%binned channel of data.
%
%Author -- Wayne Manselle - April 2014
%INPUTS -- normChanData - the binned data of a single muscle channel
%          binSize - how many datapoints each bin represents
%OUTPUTS -- iemgPlotData - the converted iEMG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    iemgPlotData=zeros(size(normChanData,1)*binSize,1);
    
    for bin=1:size(normChanData,1)
        iemgPlotData(binSize*(bin-1)+1:binSize*bin)=normChanData(bin);
    end
end