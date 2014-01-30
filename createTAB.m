function []= createTAB(derivedpath,tabind,index,fileflag)
%derivedpath   =  filepath
%tabind         = data block indices for each measurement type, array
%index          = index array from earlier creation - Ugly way to remember index
%inside function.
%fileflag       = identifier for type of data

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





%tday = index(tabind(1)).t0;
filename = sprintf('%s/RPCLAP_%s_%s_%d_%s.TAB',derivedpath,datestr(index(tabind(1)).t0,'yyyymmdd'),datestr(index(tabind(1)).t0,'HHMMSS'),index(tabind(1)).macro,fileflag); %%
%mutewarning = mkdir(derivedpath); %

if exist('filename', 'file')==2
    delete(filename)  %remove old files already created since
    %code appends to existing file whenever possible (duplicates!)
end

global tabindex;

tabindex{end+1,1} = filename; %% Let's remember all TABfiles we create
tabindex{end,2} = tabind(1); %% and the first index number



len = length(tabind);
counttemp = 0;
counttemp2 = 0;

if(~index(tabind(1)).sweep); %% if not a sweep, do:
    for(i=1:len);
        tabID = fopen(index(tabind(i)).tabfile);
        scantemp = textscan(tabID,'%s%f%f%f','delimiter',',');
        scanlength = length(scantemp{1,1});
        counttemp = counttemp + scanlength;
        
        
        %     %fours = daysact(datenum(strrep(scantemp{1,1},'T',' ')),datenum(strrep(scantemp{:,1},'T',' ')));
        %     %if this function is too time consuming, do it only when absolutely necessary:
        %     fives = daysact(datenum(strrep(scantemp{end,1},'T',' ')),datenum(strrep(scantemp{1,1},'T',' '))); %actual day difference between final and first date inside .TAB file.
        %     if (fives) %if a day has passed, do:
        %         fours = daysact(datenum(strrep(scantemp{1,1},'T',' ')),datenum(strrep(scantemp{:,1},'T',' '))); % every day difference compared to first date, stored in array
        %         firstdiffrow = find(-diff(fours)); %diff(fours) is 0 or -1 for all rows, find() finds the row index of the n-1 diff array
        %         yday = filename; %store old filename
        %         filename = sprintf('%s/RPCLAP_%s_%s_%d_%s.TAB',derivedpath,datestr(addtodate(tday,1,'day'),'yyyymmdd'),'000000',index(tabind(1)).macro,fileflag);
        %         %add a day to timer, set HHMMSS to 000000, (may be useful for
        %         %now). important to change filename inside loop, such that next
        %         %i counter remembers the new filename
        %
        %
        %         dlmcell(yday,scantemp{1:firstdiffrow,:},'-a',',') %finish old file with data from "yesterday"
        %         dlmcell(filename,scantemp{firstdiffrow+1:end,:},'-a',',') % start new file with data from "today"
        %     else
        
        
        %        dlmcell(filename,textscan(tabID,'%s'),'-a',',')
        
        %        scantemp2 = scantemp{1,1:end}{1};
        
        for (j=1:scanlength)
            
            scantemp2={scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j)};
            dlmcell(filename,scantemp2,'-a',',');
        end
        
        if (i==len)
            tabindex{end,3}= scantemp{1,1}{end,1}; %%remember stop time in universal time and spaceclock time
            tabindex{end,4}= scantemp{1,2}(end); %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            tabindex{end,5}= counttemp;
            
        end
        fclose(tabID);
        
        
        
    end
else %% if sweep, do!
    
    filename2 = filename;
    filename2(end-6) = 'I'; %current data file name according to convention
    if exist('filename2', 'file')==2
        delete('filename2');
    end
    condfile = fopen(filename2,'a');
    for(i=1:len);
        tabID = fopen(index(tabind(i)).tabfile);
        scantemp = textscan(tabID,'%s%f%f%f','delimiter',',');
        scanlength = length(scantemp{1,1});
        counttemp2 = counttemp2 + scanlength;
        
        if (i==1||i==2)
            counttemp = counttemp + scanlength;
            pottemp = scantemp{1,4}(1:end);
            dlmwrite(filename,pottemp,'-append');
        end
        curtemp = scantemp{1,3}(:).';
        fprintf(condfile,'%s,%s,%f,%f,',scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end));
        dlmwrite(filename2,curtemp,'-append');
        
        if (i==len)
            
            tabindex(end,3:5)= {scantemp{1,1}{end,1},scantemp{1,2}(end),counttemp}; %one index for bias voltages
            tabindex(end+1,1:5)={filename2,tabind(1), scantemp{1,1}{end,1},scantemp{1,2}(end),counttemp2};
            
            %one index for currents and two timestamps
            %%remember stop time in universal time and spaceclock time
            %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            %%remember stop time in universal time and spaceclock time
        end
        fclose(tabID);
        
    end
    fclose(condfile);
    
end




end



