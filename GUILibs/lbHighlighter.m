function [ hldString ] = lbHighlighter( string, highlight )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LBHIGHLIGHTER adds html/css highlighting to strings for a listbox 
%   This is an internal library that adds background coloration to items
%   added to a listbox for the HBSubtract and muscleOnset selection GUIs
%   for the Rachwani-Santamaria experimental analysis paradigm.
%
%   Author - Wayne Manselle - March 2013
%
%   INPUTS - string -- the string to be highlighted.
%          - highlight -- the highlighting to give the string.
%                       - 1 - Green - Information reviewed
%                       - 2 - Yellow - No Muscle Onset Found
%                       - 3 - Red - Not yet Visited
%
%   OUTPUTS - hldStrings - the highlighted strings.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    lhSides = {'<html><DIV bgcolor="lime"><font size="4" color="black">',...
        '<html><DIV bgcolor="yellow"><font size="4" color="black">',...
        '<html><DIV bgcolor="red"><font size="4" color="black">'};
    
    hldString = [lhSides{highlight} string '</font></DIV></html>'];
end