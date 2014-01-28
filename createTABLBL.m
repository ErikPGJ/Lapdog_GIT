function [] = createTABLBL(derivedpath,tabind,index,fileflag)
  
%dereivedpath   =  filepath 
%tabind         = data block indices for each measurement type, array
%index          = index array from earlier creation - Ugly way to remember index
%inside function.
%fileflag       = identifier for type of data

%will not handle macros that last longer than a day

%    FILE GENESIS
%After Discussion 24/1 2014
%%FILE CONVENTION: RPCLAP_YYMMDD_hhmmss_MMM_APC
%%MMM = MacroID, A= Measured quantity (B/I/V)%% , P=Probe number
%%(1/2/3), C = Mode (H/L/S)
% B = probe bias voltage file
% I = Current file, static Vb
% V = potential
%
% H = High frequency data
% L = Low frequency data
% S = Voltage sweep data (bias voltage file or current file)
% File should contain Time, spacecraft time, current, bias potential
%Qualityfactor
% TIME STAMP example : 2011-09-05T13:45:20.026075
%YYYY-MM-DDThh:mm:ss.ffffff % double[s],double[A],double [V],int



tday = index(tabind(1)).t0;
filename = sprintf('%s/RPCLAP_%s_%s_%d_%s.TAB',derivedpath,datestr(index(tabind(1)).t0,'yyyymmdd'),datestr(index(tabind(1)).t0,'HHMMSS'),index(tabind(1)).macro,fileflag); %%

%need function to check if file exists already and delete it, since
%code appends to existing file whenever possible (duplicates!)



len = length(tabind);

for(i=1:len);
    tabID = fopen(index(tabind(i)).tabfile);
    scantemp = textscan(tabID,'%s%f%f%f','delimiter',',');
    
    %fours = daysact(datenum(strrep(scantemp{1,1},'T',' ')),datenum(strrep(scantemp{:,1},'T',' ')));
    %if this function is too time consuming, do it only when absolutely necessary:
    fives = daysact(datenum(strrep(scantemp{end,1},'T',' ')),datenum(strrep(scantemp{1,1},'T',' '))); %actual day difference between final and first date inside .TAB file.
    if (fives) %if a day has passed, do:
        fours = daysact(datenum(strrep(scantemp{1,1},'T',' ')),datenum(strrep(scantemp{:,1},'T',' '))); % every day difference compared to first date, stored in array
        firstdiffrow = find(-diff(fours)); %diff(fours) is 0 or -1 for all rows, find() finds the row index of the n-1 diff array
        yday = filename; %store old filename
        filename = sprintf('%s/RPCLAP_%s_%s_%d_%s.TAB',derivedpath,datestr(addtodate(tday,1,'day'),'yyyymmdd'),'000000',index(tabind(1)).macro,fileflag);
        %add a day to timer, set HHMMSS to 000000 (may be useful for
        %now). important to change filename inside loop, such that next
        %i counter remembers the new filename
        
        
        dlmcell(yday,scantemp{1:firstdiffrow,:},'-a',',') %finish old file with data from "yesterday"
        dlmcell(filename,scantemp{firstdiffrow+1:end,:},'-a',',') % start new file with data from "today"
    else
        dlmcell(filename,scantemp,'-a',',')
    end
    clear scantemp tstr sct ip vb
    fclose(tabID);
end



end

