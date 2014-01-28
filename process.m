% process -- grind all ops blocks through the mill
% 
%
% Assumes:
% 1. index has been generated and exists in workspace (indexgen.m)
% 2. ops blocks are defined (opsblock.m)

nfft = 128;
outdir = 'data/';

sweeps = 0;
% lf = 0;
% hf = 0;
t321 = [];
v321 = [];
t322 = [];
v322 = [];

    
derivedpath = strrep(archivepath,'RPCLAP-3','RPCLAP-4');
derivedpath = strrep(derivedpath,'CALIB','DERIV');


for b = 1:nob   % Loop through all ops blocks
    
    day = datestr(index(obs(b)).t0,'yyyymmdd');  % convert block start time index to time string, convert to yyyymmdd format 
    
    ob = obs(b):obe(b); %ob goes from start time index to end time index
    ob2 = obs(2):obe(2);
    
    t321 = []; %?
    v321 = [];
    t322 = [];
    v322 = [];
    
    % Find sweeps:
    p1s = find([index(ob).sweep] & ([index(ob).probe] == 1)); %%returns indices of all sweeps for probe 1 for macro operation block 
    p2s = find([index(ob).sweep] & ([index(ob).probe] == 2));
    
    % Find E data:
    p1el = find([index(ob).lf] & [index(ob).efield] & ([index(ob).probe] == 1)); 
    p2el = find([index(ob).lf] & [index(ob).efield] & ([index(ob).probe] == 2));
    p1eh = find([index(ob).hf] & [index(ob).efield] & ([index(ob).probe] == 1));
    p2eh = find([index(ob).hf] & [index(ob).efield] & ([index(ob).probe] == 2));
        
    % Find N data:
    p1nl = find([index(ob).lf] & ~[index(ob).efield] & ([index(ob).probe] == 1));        
    p2nl = find([index(ob).lf] & ~[index(ob).efield] & ([index(ob).probe] == 2));
    p1nh = find([index(ob).hf] & ~[index(ob).efield] & ([index(ob).probe] == 1));
    p2nh = find([index(ob).hf] & ~[index(ob).efield] & ([index(ob).probe] == 2));

    % Find does not preserve label indices, but only the new indices. so
    % index(ob) where ob = 6:10, gives results in the range 1:5
    
    
    %%%% Start TAB/LBL genesis
    
    %Generate sweep files
    % the obs(b) -1 is needed since find will not give answers in the range
    % of all indices, but only relative to obs(b).
    if(~isempty(p1s)) p1s = p1s + obs(b) -1; createTABLBL(derivedpath,p1s,index,'B1S'); end
    if(~isempty(p2s)) p2s = p2s + obs(b) -1; createTABLBL(derivedpath,p2s,index,'B2S'); end
    
    %Generate E data files
    if(~isempty(p1el)) p1el = p1el + obs(b) -1; createTABLBL(derivedpath,p1el,index,'V1L'); end
    if(~isempty(p2el)) p2el = p2el + obs(b) -1; createTABLBL(derivedpath,p2el,index,'V2L'); end
    if(~isempty(p1eh)) p1eh = p1eh + obs(b) -1; createTABLBL(derivedpath,p1eh,index,'V1H'); end
    if(~isempty(p2eh)) p2eh = p2eh + obs(b) -1; createTABLBL(derivedpath,p2eh,index,'V2H'); end
    %Generate N data files
    if(~isempty(p1nl)) p1nl = p1nl + obs(b) -1; createTABLBL(derivedpath,p1nl,index,'I1L');end
    if(~isempty(p2nl)) p2nl = p2nl + obs(b) -1; createTABLBL(derivedpath,p2nl,index,'I2L');end
    if(~isempty(p1nh)) p1nh = p1nh + obs(b) -1; createTABLBL(derivedpath,p1nh,index,'I1H');end
    if(~isempty(p2nh)) p2nh = p2nh + obs(b) -1; createTABLBL(derivedpath,p2nh,index,'I2H');end

    % Mill sweeps in this ob:
    
%     if(~isempty(p1s))
%         
%     len = length(p1s);
%     row = 1;
%     tstraray = zeros(len*ob(end));
%     n = 4;
% 
% % Create array to save extended index in:
% % index(n).lblfile = [];
% % index(n).tabfile = [];
% % index(n).t0str = [];
% % index(n).t1str = [];
% % index(n).sct0str = [];
% % index(n).sct1str = [];
% 
%     for(i=1:len);
%         tabID = fopen(index(ob(p1s(i))).tabfile)
%         fopen(
%          [tstr sct ip vb] = textread(index(ob(p1s(i))).tabfile,'%s%f%f%f','delimiter',',');
%          tstrarray(row,:) = [ts,sct,ip,vb];
%          row = row + length(sct);
%          
%          textread(
%     end
%     end
    
    
%     if(p1s) 
%       len = length(p1s);
%       p1s_params = zeros(len,16); %%16? returns a zero matrix of len x 16
%       p1s_raw = zeros(len,4);
%       for(i=1:len)
%           %temppath = strcat(archivepath,index(ob(p1s(i))).tabfile);
%          [tstr sct ip vb] = textread(index(ob(p1s(i))).tabfile,'%s%f%f%f','delimiter',','); %%too much is happening, my head hurts 
%          %converts index of p1s to the filepath of tabfile, reads the shit
%          %out of it with a string(time), IGNORES float(S/C seconds),float(I),float(V) seperated by comma.
%          %so tstr = time, ip=current, vb =bias voltage)
%          ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFFFFF');
%          p1s_raw(i,:) = [ts,sct,ip,vb];
%          p1s_params(i,:) = an_swp(ts,vb,ip,1);
%       end
%       createTABLBL(derivedpath,p1s_raw,len,b,B1S);
%     end
    %%%%%%
% 
%     if(p2s)
%       len = length(p2s);
%       p2s_params = zeros(len,16);
%       for(i=1:len)
%           %temppath = strcat(archivepath,index(ob(p2s(i))).tabfile);
%          [tstr ip vb] = textread(index(ob(p2s(i))).tabfile,'%s%*f%f%f','delimiter',',');
%          ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFF');
%          p2s_params(i,:) = an_swp(ts,vb,ip,2);
%       end    
%     end
%     % params = [t len vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) p vbinf diinf d2iinf Tph If0 vs]; 
%     figure(158);
% 
%     subplot(4,1,1);
%     plot(p1s_params(:,1),1e9*p1s_params(:,15),'k.',p2s_params(:,1),1e9*p2s_params(:,15)+7,'r.');
%     ylim([-15 0])
%     grid on;
%     datetick('x',15);
%     ylabel('If0 [nA]');
%     if(~isempty(p1s_params))
%       titstr = sprintf('Sweep summary %s',datestr(p1s_params(1,1),29));
%     else
%       titstr = sprintf('Sweep summary %s',datestr(p2s_params(1,1),29));
%     end
%     title(titstr);
% 
%     subplot(4,1,2);
%     plot(p1s_params(:,1),-p1s_params(:,11),'ko',p2s_params(:,1),-p2s_params(:,11),'ro');
%     hold on;
%     plot(p1s_params(:,1),p1s_params(:,16),'k.',p2s_params(:,1),p2s_params(:,16),'r.');
%     hold off;
%     grid on;
%     datetick('x',15);
%     ylim([-5 5]);
%     ylabel('Vps [V]');
% 
%     subplot(4,1,3);
%     Te1 = p1s_params(:,12)./p1s_params(:,13);
%     Te2 = p2s_params(:,12)./p2s_params(:,13);
%     semilogy(p1s_params(:,1),Te1,'k.',p2s_params(:,1),Te2,'r.',p1s_params(:,1),p1s_params(:,14),'ko',p2s_params(:,1),p2s_params(:,14),'ro');
%     ylim([0.01 10]);
%     grid on;
%     datetick('x',15);
%     ylabel('Te [V]');
% 
%     subplot(4,1,4)
%     % Cal fact n/(dI/dV): (1.6e-19)^1.5 * 4 * pi * 0.025 / sqrt(2*pi*Te*9.1e-31); 
%     k = sqrt(2*pi*9.1e-31) ./ ((1.6e-19)^1.5 * 4 * pi * 0.025^2);
%     semilogy(p1s_params(:,1),1e-6*k*p1s_params(:,8).*sqrt(Te1),'k.',p2s_params(:,1),1e-6*k*p2s_params(:,8).*sqrt(Te2),'r.');
%     ylim([0.1 100]);
%     grid on;
%     datetick('x',15);
%     ylabel('ne [cm-3]');
%     
%     samexaxis('join');
%     drawnow;
%     
%     % Mill the HF data in this ob:
%     psd_p1eh = [];
%     psd_p2eh = [];
%     psd_p1nh = [];
%     psd_p2nh = [];
%     if(p1eh)
%         len = length(p1eh);
%         for(i=1:len)
%             fprintf(1,'Calculating V1H spectrum #%.0f of %.0f\n',i,len)
%             %temparchive = sprintf(archivepath
%            [tstr ib vp] = textread(index(ob(p1eh(i))).tabfile,'%s%*f%f%f','delimiter',',');
%            ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFF');
%            [psd,f1eh] = pwelch(vp,[],[],nfft,18750);
%            psd_p1eh = [psd_p1eh; mean(ts) psd'];
%         end
%         figure(156);
%         surf(psd_p1eh(:,1)',f1eh/1e3,10*log10(psd_p1eh(:,2:(2+nfft/2))'),'edgecolor','none'); 
%         view(0,90); 
%         datetick('x','HH:MM');
%         xlabel('HH:MM (UT)');
%         ylabel('Frequency [kHz]');
%         titstr = sprintf('LAP V1H spectrogram %s',datestr(psd_p1eh(1,1),29));
%         title(titstr);
%         drawnow;
%     end
%     if(p2eh)
%         len = length(p2eh);
%         for(i=1:len)
%             fprintf(1,'Calculating V2H spectrum #%.0f of %.0f\n',i,len)
%            [tstr ib vp] = textread(index(ob(p2eh(i))).tabfile,'%s%*f%f%f','delimiter',',');
%            ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFF');
%            [psd,f2eh] = pwelch(vp,[],[],nfft,18750);
%            psd_p2eh = [psd_p2eh; mean(ts) psd'];
%         end
%         figure(157);
%         surf(psd_p2eh(:,1)',f2eh/1e3,10*log10(psd_p2eh(:,2:(2+nfft/2))'),'edgecolor','none'); 
%         view(0,90); 
%         datetick('x','HH:MM');
%         xlabel('HH:MM (UT)');
%         ylabel('Frequency [kHz]');
%         titstr = sprintf('LAP V2H spectrogram %s',datestr(psd_p2eh(1,1),29));
%         title(titstr);
%         drawnow;
%     end % End of spectral processing -- note that density mode is not implemented
%     
%     % Save spectra:
%     if(~isempty(psd_p1eh))
%         fprintf(1,'Saving V1H spectra...\n',i,len)
%         tabfile = sprintf('%sRPCLAP_VH1_SPEC_%s_%s.TAB',outdir,day,datestr(index(obs(b)).t0,'HHMMSS'));
%         matfile = strrep(tabfile,'TAB','mat');
%         [len,cols] = size(psd_p1eh);
%         fp = fopen(tabfile,'w');
%         for(j=2:cols)
%            fprintf(fp,' %f',f1eh(j-1));
%         end
%         fprintf(fp,'\n');
%         for(i=1:len)
%             fprintf(fp,'%sT%s ',datestr(psd_p1eh(i,1),29),datestr(psd_p1eh(i,1),'HH:MM:SS.FFF'));
%             for(j=2:cols)
%                 fprintf(fp,' %f',psd_p1eh(i,j));
%             end
%             fprintf(fp,'\n');
%         end;
%         fclose(fp);
%         save(matfile,'f1eh','psd_p1eh');
%     end
%     if(~isempty(psd_p2eh))
%         fprintf(1,'Saving V2H spectra...\n',i,len)
%         tabfile = sprintf('%sRPCLAP_VH2_SPEC_%s_%s.TAB',outdir,day,datestr(index(obs(b)).t0,'HHMMSS'));
%         matfile = strrep(tabfile,'TAB','mat');
%         [len,cols] = size(psd_p2eh);
%         fp = fopen(tabfile,'w');
%         for(j=2:cols)
%            fprintf(fp,' %f',f2eh(j-1));
%         end
%         fprintf(fp,'\n');
%         for(i=1:len)
%             fprintf(fp,'%sT%s ',datestr(psd_p2eh(i,1),29),datestr(psd_p2eh(i,1),'HH:MM:SS.FFF'));
%             for(j=2:cols)
%                 fprintf(fp,' %f',psd_p2eh(i,j));
%             end
%             fprintf(fp,'\n');
%         end;
%         fclose(fp);
%         save(matfile,'f1eh','psd_p1eh');
%     end
%          
%     % Mill the V1L data in this ob:
%     if(p1el)
%         fprintf(1,'Milling V1L data...\n',i,len)
%         len = length(p1el);
%         v81 = zeros(4*len,1);
%         i81 = v81;
%         t81 = v81;
%         ts81 = v81;
%         q81 = v81;
%         v321 = zeros(len,1);
%         i321 = v321;
%         t321 = v321;
%         ts321 = v321;
%         q321 = v321;
%         for(i = 1:len) % Loop over all V1L files
%             [tstr ib vp] = textread(index(ob(p1el(i))).tabfile,'%s%*f%f%f','delimiter',',');
%             ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFF');
%             t = 86400*(ts - min(ts));  % Time in sec from start of file
%             % Create 8 s resolution data:
%             t8 = [4 12 20 28]/86400 + index(ob(p1el(i))).t0;
%             v8 = [mean(vp(find(t < 8))) mean(vp(find(t >= 8 & t < 16))) mean(vp(find(t >= 16 & t < 24))) mean(vp(find(t >= 24)))]';
%             i8 = [mean(ib(find(t < 8))) mean(ib(find(t >= 8 & t < 16))) mean(ib(find(t >= 16 & t < 24))) mean(ib(find(t >= 24)))]';
%             t81(4*(i-1)+1:4*i) = t8;
%             ts8 = min(ts) + [4 12 20 28];
%             ts81(4*(i-1)+1:4*i) = ts8;
%             v81(4*(i-1)+1:4*i) = v8;
%             i81(4*(i-1)+1:4*i) = i8;
% 
%             q8 = [10 10 10 10];
%             % Quality 11 if non-negative bias:
%             db = find(ib > 0);
%             if(db)
%                 q8(floor(t(db)/8)+1) = 11;
%             end
% 
%             % Quality 21 if bias changes:
%             db = find(diff(ib));
%             if(db)
%                 q8(floor(t(db)/8)+1) = 21;
%             end
%             q81(4*(i-1)+1:4*i) = q8;
% 
%             % Lower quality flag for 8 s data also record after bias step:
%             ind = find(q81 == 21);
%             if(ind)
%                 q81(ind+1) = 21;
%             end
% 
%         end
%         
%             % Create 32 s resolution data:
% 
%             % t321(i) = (index(ob(p1el(i))).t0 + index(ob(p1el(i))).t1)/2;
%             t321(i) = mean(t)/86400+min(ts);
%             ts321(i) = mean(ts);
%             v321(i) = mean(vp);
%             i321(i) = mean(ib);
% 
%             q321(i) = 10;
%             % Quality 11 if non-negative bias:
%             db = find(ib > 0);
%             if(db)
%                 q321(i)= 11;
%             end
%             % Quality 21 if bias changes:
%             db = find(diff(ib));
%             if(db)
%                 q321(i) = 21;
%             end
% 
%         % Save data products:
% 
%         tabfile = sprintf('%sRPCLAP_VL1_8S_%s_%s.TAB',outdir,day,datestr(index(obs(b)).t0,'HHMMSS'));
%         matfile = strrep(tabfile,'TAB','mat');
%         len = length(t81);
%         fp = fopen(tabfile,'w');
%         for(i=1:len)
%             fprintf(fp,'%sT%s,%.6f,%.7e,%.7e,%.0f\n',datestr(t81(i),29),datestr(t81(i),'HH:MM:SS.FFF'),ts81(i),i81(i),v81(i),q81(i));
%         end;
%         fclose(fp);
%         save(matfile,'t81','i81','v81','q81');
% 
%         tabfile = sprintf('%sRPCLAP_VL1_32S_%s_%s.TAB',outdir,day,datestr(index(obs(b)).t0,'HHMMSS'));
%         matfile = strrep(tabfile,'TAB','mat');
%         len = length(t321);     
%         fp = fopen(tabfile,'w');
%         for(i=1:len)
%             fprintf(fp,'%sT%s,%.6f,%.7e,%.7e,%.0f\n',datestr(t321(i),29),datestr(t321(i),'HH:MM:SS.FFF'),ts321(i),i321(i),v321(i),q321(i));
%         end;
%         fclose(fp);
%         save(matfile,'t321','i321','v321','q321');
% 
%     end % End of V1L processing
% 
%     % Mill the V2L data in this ob:
%     if(p2el)
%         fprintf(1,'Milling V2L data...\n',i,len)
%         len = length(p1el);
%         v82 = zeros(4*len,1);
%         i82 = v82;
%         t82 = v82;
%         ts82 = v82;
%         q82 = v82;
%         v322 = zeros(len,1);
%         i322 = v322;
%         t322 = v322;
%         ts322 = v322;
%         q321 = v321;
%         for(i = 1:len) % Loop over all V2L files
%             [tstr ib vp] = textread(index(ob(p1el(i))).tabfile,'%s%*f%f%f','delimiter',',');
%             ts = datenum(tstr,'yyyy-mm-ddTHH:MM:SS.FFF');
%             t = 86400*(ts - min(ts));  % Time in sec from start of file
% 
%             % Create 8 s resolution data:
% 
%             t8 = [4 12 20 28]/86400 + index(ob(p2el(i))).t0;
%             ts8 = min(ts) + [4 12 20 28];
%             ts82(4*(i-1)+1:4*i) = ts8;
%             v8 = [mean(vp(find(t < 8))) mean(vp(find(t >= 8 & t < 16))) mean(vp(find(t >= 16 & t < 24))) mean(vp(find(t >= 24)))]';
%             i8 = [mean(ib(find(t < 8))) mean(ib(find(t >= 8 & t < 16))) mean(ib(find(t >= 16 & t < 24))) mean(ib(find(t >= 24)))]';
%             t82(4*(i-1)+1:4*i) = t8;
%             v82(4*(i-1)+1:4*i) = v8;
%             i82(4*(i-1)+1:4*i) = i8;
% 
%             q8 = [10 10 10 10];
%             % Quality 11 if non-negative bias:
%             db = find(ib > 0);
%             if(db)
%                 q8(floor(t(db)/8)+1) = 11;
%             end
% 
%             % Quality 21 if bias changes:
%             db = find(diff(ib));
%             if(db)
%                 q8(floor(t(db)/8)+1) = 21;
%             end
%             q82(4*(i-1)+1:4*i) = q8;
%         
%             % Lower quality flag for 8 sec data also for next record after bias step:
%             ind = find(q82 == 21);
%             if(ind)
%                 q82(ind+1) = 21;
%             end
% 
%             % Create 32 s resolution data:
% 
%             % t322(i) = (index(ob(p2el(i))).t0 + index(ob(p2el(i))).t1)/2;
%             t322(i) = mean(t)/86400+min(ts);
%             ts322(i) = mean(ts);
%             v322(i) = mean(vp);
%             i322(i) = mean(ib);
% 
%             q322(i) = 10;
%             % Quality 11 if non-negative bias:
%             db = find(ib > 0);
%             if(db)
%                 q322(i) = 11;
%             end
%             % Quality 21 if bias changes:
%             db = find(diff(ib));
%             if(db)
%                 q322(i) = 21;
%             end
%                 
%         end % Loop over V2L files
% 
%         % Save data products:
% 
%         tabfile = sprintf('%sRPCLAP_VL2_8S_%s_%s.TAB',outdir,day,datestr(index(obs(b)).t0,'HHMMSS'));
%         matfile = strrep(tabfile,'TAB','mat');
%         len = length(t82);       
%         fp = fopen(tabfile,'w');
%         for(i=1:len)
%             fprintf(fp,'%sT%s,%.6f,%.7e,%.7e,%.0f\n',datestr(t82(i),29),datestr(t82(i),'HH:MM:SS.FFF'),ts82(i),i82(i),v82(i),q82(i));
%         end;
%         fclose(fp);
%         save(matfile,'t82','i82','v82','q82');
% 
%         tabfile = sprintf('%sRPCLAP_VL2_32S_%s_%s.TAB',outdir,day,datestr(index(obs(b)).t0,'HHMMSS'));
%         matfile = strrep(tabfile,'TAB','mat');
%         len = length(t322);       
%         fp = fopen(tabfile,'w'); %%w=write
%         for(i=1:len)
%             fprintf(fp,'%sT%s,%.6f,%.7e,%.7e,%.0f\n',datestr(t322(i),29),datestr(t322(i),'HH:MM:SS.FFF'),ts322(i),i322(i),v322(i),q322(i));
%         end;
%         fclose(fp);
%         save(matfile,'t322','i322','v322','q322');
%         
%     end  % End of V2L processing
% 
%     % Summary plot
%     figure(160)
%     sr = 5;
%     subplot(sr,1,1)
%     plot(t321,v321,'k.',t322,v322,'r.');
%     datetick('x','HH:MM');
%     ylabel('Vps [V]');
% 


end  % End of this obs block
