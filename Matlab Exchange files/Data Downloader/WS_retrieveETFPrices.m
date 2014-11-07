%% Retrieve daily data for WealthSimple ETFs
c = yahoo;

% XIC
%XIC = getYahooDailyData('XIC.TO','01/01/1900', '10/31/2014', 'mm/dd/yyyy');
XIC = getYahooDailyData('XIC.TO','01/01/1900', '10/31/2014', 'mm/dd/yyyy');
XIC_dates = datevec(table2array(XIC.(genvarname('XIC.TO'))(:,1)));
XIC_adjustedPrice = table2array(XIC.(genvarname('XIC.TO'))(:,7));
plot(XIC_adjustedPrice);

% VTI 
% VTI = getYahooDailyData('VTI','01/01/1900', '10/31/2014', 'mm/dd/yyyy');
% VTI_dates = datevec(table2array(VTI.(genvarname('VTI'))(:,1)));
% VTI_adjustedPrice = table2array(VTI.(genvarname('VTI'))(:,5));
% [VTI_dates VTI_adjustedPrice];
% plot(VTI_adjustedPrice);

VTI_closePrice = fetch(c,'VTI','Close','01/01/2000','10/31/2014');
VTI_dividends = fetch(c,'VTI','01/01/2000','10/31/2014','v');

Return2002 = find(VTI_dates(:,1)==2013);
Return2002 = VTI_adjustedPrice(Return2002(end))/VTI_adjustedPrice(Return2002(1)) - 1

% close Yahoo! finance connection
close(c);