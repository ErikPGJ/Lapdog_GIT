%an_swp2
%analyses sweeps, utilising modded version of Anders an_swp code, and other
%methods
function []= an_sweepmain(an_ind,tabindex,targetfullname)

global an_tabindex;
global target;
global diag_info
global CO IN     % Physica &instrumental constants

dynampath = strrep(mfilename('fullpath'),'/an_sweepmain','');
kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
paths();

cspice_furnsh(kernelFile);


Iph0_start = -8.55e-09;

k=1;

try
    
    for i=1:length(an_ind)
        
        
        
        
        
        %fout=cell(1,7);
        split = 0;
        
        rfile =tabindex{an_ind(i),1};
        rfolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        mode=rfile(end-6:end-4);
        diagmacro=rfile(end-10:end-8);
        probe = rfile(end-5);
        diag_info{1} = strcat(diagmacro,'P',probe);

%        diag_info{1} = strcat('P',probe,'M',diagmacro);
        diag_info{2} = rfile; %let's also remember the full name
        arID = fopen(tabindex{an_ind(i),1},'r');
        
        if arID < 0
            fprintf(1,'Error, cannot open file %s', tabindex{an_ind(i),1});
            break
        end % if I/O error
        
        scantemp = textscan(arID,'%s','delimiter',',','CollectOutput', true);
        
        fclose(arID);
        
        rfile(end-6)='B';
        arID = fopen(rfile,'r');
        scantemp2=textscan(arID,'%*f%f','delimiter',',');
        
        
        % scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
        fclose(arID);
        
        steps=    length(scantemp2{1,1})+5; %current + 4 timestamps + 1 QF
        
        size=    numel(scantemp{1,1});
        
        if mod(size,steps) ~=0
            fprintf(1,'error, bad sweepfile at \n %s \n, aborting %s mode analysis\n',rfile,mode);
            return
        end
        
        
        A= reshape(scantemp{1,1},steps,size/steps);
        Iarr= str2double(A(6:end,1:end));
        timing={A{1,1},A{2,end},A{3,1},A{4,end}};
        Qfarr =str2double(A(5,:));
        
        Vb=scantemp2{1,1};
        
        Tarr= A(1:4,1:end);
        % clear scantemp  A
        
        %    foutarr = cell(size/steps,2);
        %   Iuni = zeros(size/steps,1);
        
        %     [Vb, ~, ic] = unique(Vb); %%sort Vb, and remove duplicates (e.g. sweeps
        %     %from -30 to +30 to -30 creates duplicate potential values)
        %     %also remember the sorting indices, and use them to average multiple
        %     %current measurements on the same potential step (second time again)
        %
        %
        %     for k=1:size/steps
        %
        %         Iuni(k) = accumarray(ic,Iarr(:,k),[],@mean);
        %         foutarr(k,1:2)=Vph_knee(Vb,Iarr(:,k));
        %
        %
        %
        %     end
        %
        
        %special case where V increases e.g. +15to -15 to +15, or -15 to +15 to -15V
        potdiff=diff(Vb);
        if potdiff(1) > 0 && Vb(end)~=max(Vb) % potbias looks like a V
            
            
            %split data
            mind=find(Vb==max(Vb));
            Vb2=Vb(mind:end);
            Iarr2=Iarr(mind:end,:);
            
            Vb=Vb(1:mind);
            Iarr= Iarr(1:mind,:);
            
            split = 1;
            
            
            
        elseif potdiff(1) <0 && Vb(end)~=min(Vb)
            %%potbias looks like upside-down V
            
            %split data
            mind=find(Vb==min(Vb));
            Vb2=Vb(mind:end);
            Iarr2=Iarr(mind:end,:);
            
            Vb=Vb(1:mind);
            Iarr= Iarr(1:mind,:);
            split = -1;
            
            
        end
        
        %'preloaded' is a dummy entry, just so orbit realises spice kernels
        %are already loaded
        [junk,junk,SAA]=orbit('Rosetta',Tarr(1:2,:),target,'ECLIPJ2000','preloaded');
        clear junk
        
        if strcmp(mode(2),'1'); %probe 1???
            %current (Elias) SAA = z axis, Anders = x axis.
            % *Anders values* (converted to the present solar aspect angle definition
            % by ADDING 90 degrees) :
            Phi11 = 131;
            Phi12 = 181;
            
            illuminati = ((SAA < Phi11) | (SAA > Phi12));
            
            
        else %we will hopefully never have sweeps with probe number "3"
            
            %%%
            % *Anders values* (+90 degrees)
            Phi21 = 18;
            Phi22 = 82;
            Phi23 = 107;
            %illuminati = ((SAA < Phi21) | (SAA > Phi22));
            
            illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            % illuminati = illuminati - 0.6*((SAA > Phi22) & (SAA < Phi23));
        end
        
        
        
        len = length(Iarr(1,:));
        %  cspice_str2et(
        
        
        %% initialise output struct
        AP(len).ts       = [];
        AP(len).vx       = [];
        AP(len).Tph      = [];
        AP(len).Iph0      = [];
        AP(len).vs       = [];
        AP(len).lastneg  = [];
        AP(len).firstpos = [];
        AP(len).poli1    = [];
        AP(len).poli2    = [];
        AP(len).pole1    = [];
        AP(len).pole2    = [];
        AP(len).probe    = [];
        AP(len).vbinf    = [];
        AP(len).diinf    = [];
        AP(len).d2iinf   = [];
     
        %EP = extra parameters, not from functions
        
        EP(len).tstamp   = [];
        EP(len).SAA      = [];
        EP(len).qf       = [];
        EP(len).Tarr     = {};
        EP(len).lum      = [];
        EP(len).split    = [];        
        EP(len).ni_ram = [];
      %  EP(len).ni_thermal = [];%1e-6*DP(k).ion_slope*assmpt.ionM*CO.mp*assmpt.vram/(IN.probe_cA*2*CO.e*CO.e);
     %   EP(len).ni_SW = [];%1e-6*DP(k).ion_y_intersect/ IN.probe_cA * assmpt.ionZ*CO.e*assmpt.v_SW;
        EP(len).ne_5eV = [];%1e-6*DP(k).e_slope
        %need to make this as a function of Vsc...
        % EP(len).i_v = [];%sqrt(2*assmpt.ionZ*CO.e*DP(k)DP(k).ion_y_intersect/(DP(k).ion_slope*assmpt.ionM*CO.mp);

        
        EP(len).ass_ni_ram = [];

        EP(len).ass_ne_5eV = [];%1e-6*DP(k).e_slope

            
        DP(len).Iph0                = [];
        DP(len).Tph                 = [];
        DP(len).Vsi                 = [];
        DP(len).Te                  = [];
        DP(len).ne                  = [];
        DP(len).Vsg                 = [];
        DP(len).Vph_knee            = [];
        DP(len).Vsg_sigma           = [];
        DP(len).ion_slope           = [];
        DP(len).ion_y_intersect     = [];
        DP(len).e_slope             = [];
        DP(len).e_y_intersect       = [];
        
        DP(len).Tphc                = [];
        DP(len).nphc                = [];
        DP(len).phc_slope           = [];
        DP(len).phc_y_intersect     = [];
        
        DP(len).Te_exp              = [];
        DP(len).Ie0_exp             = [];
       
        DP(len).Quality  = [];
        
        
        DP_assmpt= DP;
        
        %% initial estimate
        
        
        %lets take the first, up to 50.  
	%note: do this for every 50th sweep?
    
    
    assmpt =[];
    
    assmpt.Vknee = 0; %dummy
    assmpt.Tph = 2; %eC
    assmpt.Iph0 = -8.55e-09; %Amp
    assmpt.vram = 700; %m/s
    assmpt.ionZ = +1; % ion charge
    assmpt.ionM = 16; % proton mass
    assmpt.v_SW = 5E5; %500 km/s
        
    %assmpt.probearea =0.25E-3;
    

    
            %Iion0 = ?Aram qion nion vd,
    
    
    
    
    if len > 1
        
        lmax=min(len,50); %lmax is whichever is smallest, len or 50.
        % 50 sweeps would correspond to ~ 30 minutes of sweeps
        %lind=logical(floor(mean(reshape(illuminati,2,len),1)));% logical index of all sunlit sweeps
        
        lind=logical(floor(mean(reshape(illuminati,2,len),1)));% logical index of all sunlit sweeps
        dind=~logical((mean(reshape(illuminati,2,len),1))); %logical index of all fully shadowed sweeps
        
        
        %one or both of these conditions will be triggered
        if unique(lind(1:lmax)) % if we have sunlit sweeps, do this
            I_50 = mean(Iarr(:,lind),2);   %average each potential step current
            [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vph_knee estimate from that.
            
            assmpt.Vknee =Vknee;
            
            init_1 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,1);  %get initial estimate of all variables in that sweep.
        end
        
        if (unique(~(lind(1:lmax)))) % if we also) have non-sunlit sweeps?
            
            I_50 = mean(Iarr(:,~lind),2);
            [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vsg estimate from that.
            assmpt.Vknee = Vknee;
            init_2 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,0);  %get initial estimate of all variables in that sweep.
        end
        % non-sunlit sweep V_SC should have priority!!
        
        if unique(lind+dind)==0 %if everything is in partial shade
            %            pind= ~dind & ~lind; %partial shade is neither dind nor not lind
            
            I_50 = mean(Iarr(:,1:lmax),2); %all
            [Vknee,sigma]=an_Vplasma(Vb,I_50); %get Vph_knee estimate from that.
            
            assmpt.Vknee =Vknee;
            
            init_1 = an_LP_Sweep_with_assmpt(Vb, I_50,assmpt,0.4);  %get initial estimate of all variables in that sweep.
            
            
        end
        
        
    end
    
        
        % analyse!
        for k=1:len
            

            
            %  a= cspice_str2et(timing{1,k});
            m = k;
            
            %% quality factor check
            qf= Qfarr(k);
            
            if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.05) %rotation of more than 0.05 degrees  %arbitrary chosen value... seems decent
                qf = qf+20; %rotation
            end
            
            EP(k).SAA = mean(SAA(1,2*k-1:2*k));
            EP(k).lum = mean(illuminati(1,2*k-1:2*k));
            
            EP(k).split = 0;
            EP(k).Tarr = {Tarr{:,k}};
            
            %       fout{m,5}={Tarr{:,k}};
            EP(k).tstamp = Tarr{3,k};
            EP(k).qf = qf;
            
            
            %Anders LP sweep analysis
            AP(k)=  an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(k).lum);
            %AP = [AP;temp];
            
  %          fout{m,1} = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati(k));
 %           fout{m,2} = mean(SAA(1,2*k-1:2*k));


%            fout{m,3} = mean(illuminati(1,2*k-1:2*k));
            
%           %new LP sweep analysis

%            test= an_LP_Sweep(Vb, Iarr(:,k),AP(k).vs,EP(k).lum);
                        
            if k>1
                Vguess=DP(k-1).Vph_knee;
            else
                Vguess=AP(k).vs;
            end


            DP(k)= an_LP_Sweep(Vb, Iarr(:,k),Vguess,EP(k).lum);
            DP_assmpt(k) = an_LP_Sweep_with_assmpt(Vb,Iarr(:,k),assmpt,EP(k).lum);

            %need to make this as a function of Vsc...
%            EP(k).i_v = sqrt(2*assmpt.ionZ*CO.e*DP(k)DP(k).ion_y_intersect/(DP(k).ion_slope*assmpt.ionM*CO.mp);
            
            EP(k).ni_ram = -1e-6 * DP(k).ion_slope*assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2);
           
%            EP(k).ni_ram = 1e-6*DP(k).ion_y_intersect/ IN.probe_cA * assmpt.ionZ*CO.e*assmpt.vram; %(CO.probearea*assmpt.qion*assmpt.vram);
            %EP(k).ni_SW = 1e-6*DP(k).ion_y_intersect/ IN.probe_cA * assmpt.ionZ*CO.e*assmpt.v_SW;
            
            Te_guess = 5;%eV
            EP(k).ne_5eV = 1e-6*DP(k).e_y_intersect/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me)));
                        
            EP(k).ass_ni_ram  = -1e-6 * DP_assmpt(k).ion_slope*assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2);
            
            EP(k).ass_ne_5eV = 1e-6*DP_assmpt(k).e_y_intersect/(IN.probe_A*-CO.e*sqrt(CO.e*Te_guess/(2*pi*CO.me)));

            
            %
                        
        end%for
        
        
        
        if (split~=0)
            
            
            for k=1:length(Iarr2(1,:))
                m=k+len;          %add to end of output array (fout{})
                %note Vb =! Vb2, Iarr =! Iarr2, etc.
                %% quality factor check
                qf= Qfarr(k);
                
                if (abs(SAA(1,2*k-1)-SAA(1,2*k)) >0.01) %rotation of more than 0.01 degrees
                    qf = qf+20; %rotation
                end
                
                %               fout{m,1} =an_swp(Vb2,Iarr2(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati);
                %                fout{m,2} = mean(SAA(1,2*k-1:2*k)); %every pair...
                %                fout{m,3} = mean(illuminati(1,2*k-1:2*k));
                
                EP(m).SAA = mean(SAA(1,2*k-1:2*k));
                EP(m).lum = mean(illuminati(1,2*k-1:2*k));
                EP(m).Tarr = {Tarr{:,k}};
                EP(m).tstamp = Tarr{4,k};
                EP(m).qf = qf;
                EP(m).split= split; % 1 for V form, -1 for upsidedownV

                AP(m)     =  an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),EP(m).lum);
                %          fout{m,1} = an_swp(Vb,Iarr(:,k),cspice_str2et(Tarr{1,k}),mode(2),illuminati(k));
                %                fout{m,2} = mean(SAA(1,2*k-1:2*k));

                
                if k>1
                    Vguess=DP(m-1).Vph_knee;
                else
                    Vguess=AP(m).vs; %use last calculation as a first guess
                end

                DP(m) = an_LP_Sweep(Vb2,Iarr2(:,k),Vguess,EP(m).lum);

                
                
                
            end%for
        end%if split
        
    %    fout = sortrows(fout,6);
        %  [foutarr,~] = sortrows{foutarr,6,'ascend'};

        
        [junk,ind] = sort({EP.tstamp});
        
  %      [junk,ind] = sort({EP.tstamp});
        klen=length(ind);

        AP=AP(ind);
        DP=DP(ind);
        EP=EP(ind);
        wfile= rfile;
        wfile(end-6)='A';
        awID= fopen(wfile,'w');
        r2 = 0;
        
%         fprintf(awID,strcat('EP(k).Tarr{1},EP(k).Tarr{2},EP(k).qf,EP(k).SAA,EP(k).lum',...
%             ',AP(k).vs,AP(k).vx,DP(k).Vsg,DP(k).Vsg_sigma, AP(k).Tph,AP(k).Iph0,AP(k).lastneg,AP(k).firstpos',...
%             ',AP(k).poli1,AP(k).poli2,AP(k).pole1,AP(k).pole2',...
%             ',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf',...
%             ',DP(k).Quality,DP(k).Tph,DP(k).Vsi,DP(k).Vph_knee,DP(k).Te',...
%             ',DP(k).ne,DP(k).ion_slope,DP(k).ion_y_intersect,DP(k).e_slope,DP(k).e_y_intersect',...
%             ',DP(k).Tphc,DP(k).nphc,DP(k).ph_slope,DP(k).ph_y_intersect\n'));
        %        fprintf(awID,strcat('EP(k).Tarr{1},EP(k).Tarr{2},EP(k).qf,EP(k).SAA,EP(k).lum',...
%            ',AP(k).vs,AP(k).vx,DP(k).Vsg,DP(k).Vsg_sigma, AP(k).Tph,AP(k).Iph0,AP(k).lastneg,AP(k).firstpos',...
%            ',AP(k).poli1,AP(k).poli2,AP(k).pole1,AP(k).pole2',...
%           ',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf',...
%            ',DP(k).Iph0,DP(k).Tph,DP(k).Vsi,DP(k).Vph_knee,DP(k).Te',...
%           ',DP(k).ne,DP(k).ion_slope,DP(k).ion_y_intersect,DP(k).e_slope,DP(k).e_y_intersect',...
%            ',DP(k).Tphc,DP(k).nphc,DP(k).ph_slope,DP(k).ph_y_intersect\n'));

% 
%         fprintf(awID,strcat('START_TIME(UTC),STOP_TIME(UTC),QualityFactor,SAA,illumination(1=sunlit)',...
%             ',old.V_intersect,old.vx,Vsg,Vsg_sigma,old.Tph,old.Iph0,lastneg,firstpos',...
%             ',old.ion_slope,old.ion_y_cross,old.plasma_e_slope,old.plasma_e_y_cross',...
%             ',old.vb_inflection,old.di_inflection,old.d2i_inflection',...
%             ',Iph0,Tph,V_intersect,V_plasma,Te',...
%             ',n_e,ioncurrent_slope,ioncurrent_y_intersect,plasmae_slope,plasmae_y_intersect',...
%             ',T_s(photoelectroncloud),n_s,photelectroncloud_slope,photelectroncloud_y_intersect.\n'));   




                %IF THIS HEADER IS REMOVED (WHICH IT SHOULD BE BEFORE ESA
                %DELIVERY) NOTIFY TONY ALLEN!
%                 fprintf(awID,strcat('START_TIME(UTC),STOP_TIME(UTC),Qualityfactor,SAA,Illumination',...
%             ',old.Vsi,old.Vx,Vsg,Vsg_sigma, old.Tph,old.Iph0,Vb_lastnegcurrent,Vb_firstposcurrent',...
%             ',old.Vb_inflection,old.diinf,old.d2iinf',...
%             ',Iph0,Tph,Vsi,Vph_knee,Te',...
%             ',ne,ion_slope,ion_y_intersect,plasma_e_slope,plasma_e_yintersect',...
%             ',Tphc,nphc,phc_slope,phc_yintersect',...
%             ',split',...
%             '\n'));


            fprintf(awID,strcat('START_TIME(UTC),STOP_TIME(UTC),Qualityfactor,SAA,Illumination',...
            ',old.Vsi,old.Vx,Vsg,Vsg_sigma, old.Tph,old.Iph0,Vb_lastnegcurrent,Vb_firstposcurrent',...
            ',Vbinfl,dIinfl,d2Iinfl',...
            ',Iph0,Tph,Vsi,Vph_knee,Te',...
            ',ne,ion_slope,ion_y_intersect,plasma_e_slope,plasma_e_yintersect',...
            ',Tphc,nphc,phc_slope,phc_yintersect',...
            ',ni_ram,ne_5eV,split',...
            ',ass_Vsg,ass_Vsg_sigma',...
            ',ass_Iph0,ass_Tph,ass_Vsi,ass_Vph_knee,ass_Te',...
            ',ass_ne,ass_ion_slope,ass_ion_y_intersect,ass_plasma_e_slope,ass_plasma_e_yintersect',...
            ',ass_Tphc,ass_nphc,ass_phc_slope,ass_phc_yintersect',...
            ',ass_ni_ram,ass_ne_5eV',...       
            '\n'));



        
        % fpformat = '%s, %s, %03i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e  %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
        for k=1:klen
            %params = [ts vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) p vbinf diinf d2iinf Tph Iph0 vs];
            %time0,time0,quality,mean(SAA),mean(Illuminati)
            
            
%             

%             
%             
            %           '1,  2,   3  ,   4   ,   5   ;   6   ,   7   ,    8  ,   9  ;   10  ,   11  ,   12  ,   13  ;   14  ,   15  ,   16  ,   18  ;   19  ,   20  ,   21  \n
            
            %f_format = '%s, %s, %03i, %07.4f, %03.2f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\n';
            %1:5

            
                
            %time0,time0,qualityfactor,mean(SAA),mean(Illuminati)
            str1=sprintf('%s, %s, %03i, %07.3f, %03.2f,',EP(k).Tarr{1,1},EP(k).Tarr{1,2},EP(k).qf,EP(k).SAA,EP(k).lum);
            %time0,time0,qualityfactor,mean(SAA),mean(Illuminati)
 %           str1=sprintf('%s, %s, %03i, %07.3f, %03.2f,',fout{k,5}{1,1},fout{k,5}{1,2},fout{k,7},fout{k,2},fout{k,3});
            %6:9
            %,vs,vx,Vsg,VsgSigma
            str2=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',AP(k).vs,AP(k).vx,DP(k).Vsg,DP(k).Vsg_sigma);
            %,vs,vx,Vsg,VsgSigma
 %           str2=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(15),fout{k,1}(4),fout{k,4}(1),fout{k,4}(2));
            %10:13
            %,Tph,Iph0,vb(lastneg) vb(firstpos),
            str3=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', AP(k).Tph,AP(k).Iph0,AP(k).lastneg,AP(k).firstpos);
            %,Tph,Iph0,vb(lastneg) vb(firstpos),
%            str3=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,', fout{k,1}(13),fout{k,1}(14),fout{k,1}(2),fout{k,1}(3));
            %14:17
            %poli(1),poli(2),pole,pole,
            %poli(1),poli(2),pole,pole,
            str4='';
     %       str4=sprintf(' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(5),fout{k,1}(6),fout{k,1}(7),fout{k,1}(8));
            %18:20
            %  vbinf,diinf,d2iinf
            str5=sprintf(' %14.7e, %14.7e, %14.7e,',AP(k).vbinf,AP(k).diinf,AP(k).d2iinf);
            %  vbinf,diinf,d2iinf
       %     str5=sprintf(' %14.7e, %14.7e, %14.7e',fout{k,1}(10),fout{k,1}(11),fout{k,1}(12));
       
       
            
            str6 = sprintf( ' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).Iph0,DP(k).Tph,DP(k).Vsi,DP(k).Vph_knee,DP(k).Te);
            
            str7 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).ne,DP(k).ion_slope,DP(k).ion_y_intersect,DP(k).e_slope,DP(k).e_y_intersect);
            
            str8 = sprintf( ' %14.7e, %14.7e, %14.7e, %14.7e,',DP(k).Tphc,DP(k).nphc,DP(k).phc_slope,DP(k).phc_y_intersect);
            
   
            
            str9 = sprintf( ' %14.7e, %14.7e, %1i,',EP(k).ne_5eV,EP(k).ni_ram,abs(split));
            
            
            
            str15=sprintf(' %14.7e, %14.7e,',DP_assmpt(k).Vsg,DP_assmpt(k).Vsg_sigma);
            
            str16 = sprintf( ' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_assmpt(k).Iph0,DP_assmpt(k).Tph,DP_assmpt(k).Vsi,DP_assmpt(k).Vph_knee,DP_assmpt(k).Te);
            
            str17 = sprintf(' %14.7e, %14.7e, %14.7e, %14.7e, %14.7e,',DP_assmpt(k).ne,DP_assmpt(k).ion_slope,DP_assmpt(k).ion_y_intersect,DP_assmpt(k).e_slope,DP_assmpt(k).e_y_intersect);
            
            str18 = sprintf( ' %14.7e, %14.7e, %14.7e, %14.7e,',DP_assmpt(k).Tphc,DP_assmpt(k).nphc,DP_assmpt(k).phc_slope,DP_assmpt(k).phc_y_intersect);
            
            str19 = sprintf( ' %14.7e, %14.7e',EP(k).ass_ne_5eV,EP(k).ass_ni_ram);

            
            
            


% %14.7e, %14.7e, %14.7e',split,DP(k).nphc,DP(k).ph_slope,DP(k).ph_y_intersect);

            
            strtot= strcat(str1,str2,str3,str4,str5,str6,str7,str8,str9,str15,str16,str17,str18,str19);
            %strtot=strrep(strtot,'NaN','   ');
            
%                     DP(len).Iph0      = [];
%         DP(len).Tph      = [];
%         DP(len).Vsi = [];
%         DP(len).Te       = [];
%         DP(len).ne       = [];
%         DP(len).Vsg      = [];
%         DP(len).Vsg_sigma   = [];
%         DP(len).ion_slope       = [];
%         DP(len).ion_y_intersect       = [];
%         DP(len).e_slope       = [];
%         DP(len).e_y_intersect       = [];
%         DP(len).Quality  = [];
%             
%             
            
            %If you need to change NaN to something (e.g. N/A, as accepted by Rosetta Archiving Guidelines) change it here!
            
            
            row_bytes =fprintf(awID,'%s\n',strtot);
            %             if (row_bytes ~= r2 && r2~= 0)
            %                 s= strcat(str6,r3)
            %
            %                 'hello'
            %
            % %             end
            %             r2 = row_bytes;
            %             r3 =str6;
            %
            
            
            
        end
        fclose(awID);
        
        an_tabindex{end+1,1} = wfile;%start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(wfile,rfolder,''); %shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i),3}; %first calib data file index
        %an_tabindex{end,3} = an_ind(1); %first calib data file index of first derived file in this set
        an_tabindex{end,4} = klen; %number of rows
        an_tabindex{end,5} = 19; %number of columns
        an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'sweep'; %type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = row_bytes;
        
        %clear output structs before looping again
        clear AP DP EP
    end
    
    cspice_unload(kernelFile);  %unload kernels when exiting function
%     
catch err
    
    fprintf(1,'Error at loop step %i, file %s',i,tabindex{an_ind(i),1});
    if ~isempty(k)
        fprintf(1,'\n Error at loop step k=%i,',k);
    end
    err.identifier
    err.message
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end
    cspice_unload(kernelFile);
        
    
end


end
