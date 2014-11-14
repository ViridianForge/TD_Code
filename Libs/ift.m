function [ condVal ] = ift( conditional, arg1, arg2 )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%IFT Conditional Evaluation Function
%   A function that evaluates the truth value of the conditional statement,
%   and returns one of two arguments dependent on that truth value.
%   
%Author:  Wayne Manselle -- October 2013
%
%INPUTS:  conditional -- The condition to be evaluated
%         arg1 -- Returned if condition is true
%         arg2 -- Returned if condition is false
%
%OUTPUTS: comdVal -- The evlulation from the Conditional Assessment.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if conditional
    condVal = arg1;
else
    condVal = arg2;
end
end