%hf sweep

function [] = an_hf(derivedpath,an_ind,index,fileflag)





% QUALITYFLAG:
% is an 3 digit integer "DDD"
% starting at 000

% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
%
% low sample size(for avgs) = +2
% some zeropadding(for psd) = +2
q=0;

nfft=128;


dirY = datestr(index(an_ind(1)).t0,'YYYY');
dirM = upper(datestr(index(an_ind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(an_ind(1)).t0,'dd'));
ffolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');

fname = sprintf('%sRPCLAP_%s_%s_FRQ_%s.TAB',ffolder,datestr(index(an_ind(1)).t0,'yyyymmdd'),datestr(index(an_ind(1)).t0,'HHMMSS'),fileflag); %%
%fpath = strrep(filename,ffolder,'');
sname = strrep(fname,'FRQ','PSD');%%


plotpsd=[];
plotT=[];
plotSCT=[];



len = length(an_ind);

tmpf = fopen(sname,'w');
fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite

awID= fopen(sname,'a');

for(i=1:len)
    %  fprintf(1,'Calculating V1H spectrum #%.0f of %.0f\n',i,len)
    % [tstr ib vp] = textread(index(ob(p1eh(i))).tabfile,'%s%*f%f%f','delimiter',',');
    % ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFF');
    % [psd,f1eh] = pwelch(vp,[],[],nfft,18750);
    % psd_p1eh = [psd_p1eh; mean(ts) psd'];
    
    
    %  fprintf(1,'Calculating %s spectrum #%.0f of %.0f\n',fileflag,i,len)
    
    trID = fopen(index(an_ind(i)).tabfile,'r');
    %scantemp = textscan(index(an_ind).tabfile,'%s%f%f%f','delimiter',',');
    %[tstr,sct,ib,vp] = textscan(trID,'%s%f%f%f','delimiter',',');
    scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
    
    tstr= scantemp{1,1};
    sct= scantemp{1,2};
    ib=scantemp{1,3};
    vp=scantemp{1,4};
    
    if i==1 timing={tstr{1,1},[],sct(1)}; end
    if i==len timing{1,2}=tstr{end,1};timing{1,4}=sct(end);end
    
    
    
    clear scantemp
    
    fclose(trID);
    
    ts = datenum(tstr(1:end-3),'yyyy-mm-ddTHH:MM:SS.FFF');
    
    
    a=std(ib);
    b=std(vp);
    
    lens = length(vp);
    %  pad = 0;
    q= 0;
    if strcmp(fileflag(1),'V')
        
        
        if std(ib)>1e-8 %
            q=q+20; %bias change QF
        end
        
        
        
        if(lens < 128)
            pad = 128-lens;
            vp = [vp; zeros(pad,1)];
            q=q+2; %zeropadding QF
        elseif(lens > 128)
            lens = 128;
            
        end
        [psd,freq] = pwelch(vp,[],[],nfft,18750);
        
        fprintf(awID,'%s, %s, %16.6f, %16.6f,%03i,%16.6f,',tstr{1,1},tstr{end,1},sct(1),sct(end),q,mean(ib));
        
        
    elseif strcmp(fileflag(1),'I')
        
        if std(vp)>1e-8
            q=q+20; %bias change QF
        end
        
        
        if(lens < 128)
            pad = 128-lens;
            ib = [ib; zeros(pad,1)];
            q=2; %zeropadding QF
        elseif(lens > 128)
            lens = 128;
        end
        [psd,freq] = pwelch(ib,[],[],nfft,18750);
        %    plot(freq,psd)
        psd=psd*1e18; %scale to nA for current files
        fprintf(awID,'%s, %s, %16.6f, %16.6f, %03i, %16.6f,',tstr{1,1},tstr{end,1},sct(1),sct(end),q,mean(vp));
        %23+23+16+16+3+16+6*2
    else
        'Error, wrong fileflag'
        
    end
    
    % fprintf(awID,'%s, %s, %16.6f, %16.6f,%03i,%16.6f,',tstr{1,1},tstr{end,1},sct(1),sct(end),q,mean(ib));
    psdout=(128/lens)^2 * psd;
    dlmwrite(sname,psdout.','-append','precision', '%14.7e', 'delimiter', ','); %appends to end of row, column 5. pretty neat.
    
    subplot(313);
    
    plotpsd=[plotpsd,psdout];
    plotT=[plotT;ts(floor(length(ts)/2))];
    plotSCT=[plotSCT;mean(sct)];
    
    plotF=freq;
    
    
    
    %imagesc( T, F, log(S) ); %plot the log spectrum
    %set(gca,'YDir', 'normal'); % flip the Y Axis so lower frequencies are at the bottom
    
    %  fout=[fout,freq];
    
    
    
    
    %   fprintf(awID,'%s,%s,%16.6f,%16.6f, \n',tstr{1,1},tstr{end,1},sct(1),sct(end))
    % fout = [fout; mean(ts),(128/lens)^2 * psd'];
    
    
end

figure(2);
imagesc( plotT,plotF/1e3,10*log10(plotpsd));
set(gca,'YDir', 'normal'); % flip the Y Axis so lower frequencies are at the bottom

datetick('x',13);
xlabel('HH:MM:SS (UT)');
ylabel('Frequency [kHz]');
titstr = sprintf('LAP %s spectrogram %s',fileflag,datestr(ts(1),29));
title(titstr);
drawnow;
% figure(86);
% %  surf(plotT,plotF/1e3,10*log10(plotpsd(:,1:(2+nfft/2))).','edgecolor','none');
% surf(plotT,plotF/1e3,10*log10(plotpsd),'edgecolor','none');
% 
% view(0,90);
% %datetick(
% 
% datetick('x',13);
% xlabel('HH:MM:SS (UT)');
% ylabel('Frequency [kHz]');
% titstr = sprintf('LAP %s spectrogram %s',fileflag,datestr(ts(1),29));
% title(titstr);
% drawnow;



fclose(awID);
dlmwrite(fname,freq,'precision', '%14.7e');



%afID = fopen(fname,'w');

%dlmwrite(fname,freq,'precision', '%14.7e');


global an_tabindex;

an_tabindex{end+1,1} = fname;%start new line of an_tabindex, and record file name
an_tabindex{end,2} = strrep(fname,ffolder,''); %shortfilename
an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
an_tabindex{end,4} = length(freq); %number of rows
an_tabindex{end,5} = 1; %number of columns
%an_tabindex{end,6} = an_ind(i);
an_tabindex{end,7} = 'frequency'; %type
an_tabindex{end,8} = timing;


an_tabindex{end+1,1} = sname;%start new line of an_tabindex, and record file name
an_tabindex{end,2} = strrep(sname,ffolder,''); %shortfilename
an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
an_tabindex{end,4} = len; %number of rows
an_tabindex{end,5} = 6+length(freq); %number of columns



%an_tabindex{end,6} = an_ind(i);
an_tabindex{end,7} = 'spectra'; %type
an_tabindex{end,8} = timing;




%         figure(156);
%         surf(psd_p1eh(:,1)',f1eh/1e3,10*log10(psd_p1eh(:,2:(2+nfft/2))'),'edgecolor','none');
%         view(0,90);
%         datetick('x','HH:MM');
%         xlabel('HH:MM (UT)');
%         ylabel('Frequency [kHz]');
%         titstr = sprintf('LAP V1H spectrogram %s',datestr(psd_p1eh(1,1),29));
%         title(titstr);
%         drawnow;


end