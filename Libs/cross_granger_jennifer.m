
% save('kinTrial10BDS5','kinTrial10BDS5')
% save('kinTrial10BDS8','kinTrial10BDS8')


%Load in data sets
load('kinTrial10BDS5','kinTrial10BDS5')
load('kinTrial10BDS8','kinTrial10BDS8')

% create trunk and arm variables
T1 = kinTrial10BDS5(:,11:13);
A1 = kinTrial10BDS5(:,14:16);
T2 = kinTrial10BDS8(:,11:13);
A2 = kinTrial10BDS8(:,17:19);


%path length
TP1 = sqrt((T1(:,1)).^2 + (T1(:,2)).^2 + (T1(:,3)).^2);
AP1 = sqrt((A1(:,1)).^2 + (A1(:,2)).^2 + (A1(:,3)).^2);
TP2 = sqrt((T2(:,1)).^2 + (T2(:,2)).^2 + (T2(:,3)).^2);
AP2 = sqrt((A2(:,1)).^2 + (A2(:,2)).^2 + (A2(:,3)).^2);

% compute cross-correlation

% [CC1,LAG1]=xcorr(TP1,AP1);
% [CC2,LAG2]=xcorr(TP2,AP2);

%z number

% TP1 = (TP1-mean(TP1))./std(TP1);
% AP1 = (AP1-mean(AP1))./std(AP1);
% TP2 = (TP2-mean(TP2))./std(TP2);
% AP2 = (AP2-mean(AP2))./std(AP2);

%MATLAB's Cross Corr function does what?  How does this differ from using
%xcorr and the Z-Value?

%Sampled based cross correlation.  The methodology Pablo has chosen returns
%three values.  
%The Cross-Correlation Function between the two datasets passed
%The Sample Lag values for the cross correlation
%The Appoximate Confidence Bounds of the Cross-Correlation assuming the
%passed values are uncorrelated.
[CC1,LAG1,bounds1] = crosscorr(TP1,AP1);
[CC2,LAG2,bounds2] = crosscorr(TP2,AP2);

%Simply returns the index and max value of the absolute-valued Cross
%Correlation
[ll1,maxCC1] = max(abs(CC1));
disp(LAG1(maxCC1))
[ll2,maxCC2] = max(abs(CC2));
disp(LAG2(maxCC2))


% ploting c - c
figure,stem(LAG1,CC1);hold on, plot(LAG1,bounds1(1),'r'),plot(LAG1,bounds1(2),'r')
xlabel('lag'),ylabel('crosscorr'),title('good')

figure,stem(LAG2,CC2);hold on, plot(LAG2,bounds2(1),'r'),plot(LAG2,bounds2(2),'r')
xlabel('lag'),ylabel('crosscorr'),title('bad')




%next idea
% ploting g - c


